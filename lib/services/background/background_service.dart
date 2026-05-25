import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:workmanager/workmanager.dart';

import 'package:hava/core/constants/app_constants.dart';
import 'package:hava/core/utils/aqi_utils.dart';
import 'package:hava/data/datasources/local/cache_service.dart';
import 'package:hava/data/datasources/remote/api_client.dart';
import 'package:hava/data/datasources/remote/aqi_api_service.dart';
import 'package:hava/data/datasources/remote/weather_api_service.dart';
import 'package:hava/data/models/models.dart';
import 'package:hava/data/repositories/aqi_repository_impl.dart';
import 'package:hava/data/repositories/weather_repository_impl.dart';
import 'package:hava/services/notification/notification_service.dart';
import 'package:hava/services/recommendation/recommendation_engine.dart';

/// Unique task name registered with WorkManager.
const String _periodicTaskName = 'hava_background_fetch';

// ─────────────────────────────────────────────
//  Cache keys used only by the background job
// ─────────────────────────────────────────────

const String _lastDigestDateKey = 'bg_last_digest_date';
const String _lastUmbrellaHourKey = 'bg_last_umbrella_hour';
const String _lastAqiAlertHourKey = 'bg_last_aqi_alert_hour';
const String _lastUvAlertHourKey = 'bg_last_uv_alert_hour';
const String _lastConditionsHourKey = 'bg_last_conditions_hour';
const String _previousAqiKey = 'bg_previous_aqi';

// ─────────────────────────────────────────────
//  Top-level callback dispatcher
// ─────────────────────────────────────────────

/// Entry point for the WorkManager background isolate.
///
/// Must be a **top-level** function.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      await _performBackgroundFetch();
    } catch (_) {
      // Silently swallow — WorkManager will retry on its own schedule.
    }
    return true;
  });
}

// ─────────────────────────────────────────────
//  Public API
// ─────────────────────────────────────────────

/// Registers the periodic background fetch task with WorkManager.
///
/// Call once at app start in `main()`.
Future<void> initBackgroundService() async {
  await Workmanager().initialize(callbackDispatcher);

  await Workmanager().registerPeriodicTask(
    _periodicTaskName,
    _periodicTaskName,
    frequency: Duration(hours: AppConstants.backgroundFetchIntervalHours),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}

// ─────────────────────────────────────────────
//  Background fetch implementation
// ─────────────────────────────────────────────

/// The actual work performed in the background isolate:
///
/// 1. Open Hive boxes.
/// 2. Read saved location from cache.
/// 3. Fetch fresh AQI + weather data via network.
/// 4. Run the recommendation engine.
/// 5. Decide which notifications to show (with de-duplication).
/// 6. Data is automatically cached by the repositories.
Future<void> _performBackgroundFetch() async {
  // ── 1. Hive ──
  await Hive.initFlutter();
  final weatherBox = await Hive.openBox<String>(CacheKeys.weatherBox);
  final prefsBox = await Hive.openBox<dynamic>(CacheKeys.prefsBox);
  final cache = CacheService(weatherBox, prefsBox);

  // ── 2. Location ──
  final locationJson = cache.savedLocationJson;
  if (locationJson == null) return; // No location — nothing to do.

  final location = LocationModel.fromJson(
    Map<String, dynamic>.from(jsonDecode(locationJson) as Map),
  );

  // ── 3. Fetch data ──
  final weatherDio = createOpenWeatherDio();
  final iqAirDio = createIqAirDio();

  try {
    final weatherApi = WeatherApiService(weatherDio);
    final aqiApi = AqiApiService(iqAirDio);

    final weatherRepo = WeatherRepositoryImpl(
      apiService: weatherApi,
      cacheService: cache,
    );
    final aqiRepo = AqiRepositoryImpl(
      weatherApiService: weatherApi,
      iqAirApiService: aqiApi,
      cacheService: cache,
    );

    final AqiModel currentAqi;
    try {
      currentAqi = await aqiRepo.getCurrentAqi(
        lat: location.latitude,
        lon: location.longitude,
      );
    } catch (_) {
      return; // Network failure — data already cached by repo for next launch.
    }

    final aqiForecast = await aqiRepo.getHourlyAqiForecast(
      lat: location.latitude,
      lon: location.longitude,
    );

    WeatherModel? currentWeather;
    try {
      currentWeather = await weatherRepo.getCurrentWeather(
        lat: location.latitude,
        lon: location.longitude,
      );
    } catch (_) {
      // Weather fetch failed — continue without it.
    }

    final weatherForecast = await weatherRepo.getHourlyForecast(
      lat: location.latitude,
      lon: location.longitude,
    );

    // ── 4. Health profile ──
    final profileIndex = cache.healthProfileIndex;
    final profile = HealthProfile
        .values[profileIndex.clamp(0, HealthProfile.values.length - 1)];

    // ── 5. Recommendation ──
    const engine = RecommendationEngine();
    final rec = engine.generate(
      currentAqi: currentAqi,
      aqiForecast: aqiForecast,
      weatherForecast: weatherForecast,
      profile: profile,
    );

    // ── 6. Notifications ──
    await NotificationService.instance.init();
    final now = DateTime.now();

    _maybeSendDailyDigest(
      prefsBox, rec, now, currentWeather, currentAqi, profile,
    );
    _maybeSendUmbrellaReminder(prefsBox, rec, weatherForecast, now);
    _maybeSendAqiAlert(prefsBox, currentAqi, profile, now);
    _maybeSendUvAlert(prefsBox, currentWeather, now);
    _maybeSendConditionsUpdate(prefsBox, currentAqi, profile, now);
  } finally {
    weatherDio.close();
    iqAirDio.close();
  }
}

// ─────────────────────────────────────────────
//  Notification decision helpers
// ─────────────────────────────────────────────

/// Show the daily digest between [dailyDigestHour] and [dailyDigestHour + 1],
/// at most once per calendar day.
///
/// Enhanced with UV, temperature, and specific action items.
Future<void> _maybeSendDailyDigest(
  Box<dynamic> prefsBox,
  Recommendation rec,
  DateTime now,
  WeatherModel? weather,
  AqiModel currentAqi,
  HealthProfile profile,
) async {
  if (now.hour < AppConstants.dailyDigestHour ||
      now.hour >= AppConstants.dailyDigestHour + 1) {
    return;
  }

  final todayStr = '${now.year}-${now.month}-${now.day}';
  final lastDigest = prefsBox.get(_lastDigestDateKey) as String?;
  if (lastDigest == todayStr) return;

  // Build a rich, informative digest body.
  final parts = <String>[];

  // AQI summary.
  parts.add('AQI ${currentAqi.aqi} (${AqiUtils.label(currentAqi.aqi)})');

  // Temperature + UV if available.
  if (weather != null) {
    parts.add('${weather.temperature.round()}°C, '
        'Humidity ${weather.humidity}%');
    if (weather.uvIndex > 0) {
      parts.add('UV Index: ${weather.uvIndex.round()} '
          '(${_uvLabel(weather.uvIndex)})');
    }
  }

  // Best window info from recommendation.
  if (rec.bestWindowStart != null && rec.bestWindowEnd != null) {
    final startStr = _formatTime(rec.bestWindowStart!);
    final endStr = _formatTime(rec.bestWindowEnd!);
    parts.add('Best outdoor window: $startStr – $endStr');
  }

  // Profile-specific advice.
  parts.add(AqiUtils.advice(currentAqi.aqi, profile));

  final title = '☀️ Good morning! ${rec.title}';
  final body = parts.join('\n');

  await NotificationService.instance.showDailyDigest(
    title: title,
    body: body,
  );
  await prefsBox.put(_lastDigestDateKey, todayStr);
}

/// Show an umbrella reminder if rain is imminent (within 2 hours) or if the
/// engine already flagged an umbrella recommendation.
///
/// Enhanced with specific precipitation probability and timing.
Future<void> _maybeSendUmbrellaReminder(
  Box<dynamic> prefsBox,
  Recommendation rec,
  List<ForecastHourModel> forecast,
  DateTime now,
) async {
  // Find the soonest rain event.
  final rainEvent = _findSoonestRain(forecast, now);
  final isUmbrella = rec.type == RecommendationType.umbrella ||
      rainEvent != null;
  if (!isUmbrella) return;

  final lastHour = prefsBox.get(_lastUmbrellaHourKey) as int?;
  if (lastHour == now.hour) return;

  String body;
  if (rainEvent != null) {
    final pct = (rainEvent.precipitationProbability * 100).round();
    final timeStr = _formatTime(rainEvent.dateTime);
    final diff = rainEvent.dateTime.difference(now);
    final minStr = diff.inMinutes <= 60
        ? '${diff.inMinutes} min'
        : '${diff.inHours}h ${diff.inMinutes % 60}min';
    body = '$pct% chance of rain at $timeStr (in ~$minStr). '
        'Carry an umbrella if heading out.';
  } else {
    body = 'Rain is expected soon. Carry rain protection if heading out.';
  }

  await NotificationService.instance.showUmbrellaReminder(
    title: '🌧️ Rain Alert',
    body: body,
  );
  await prefsBox.put(_lastUmbrellaHourKey, now.hour);
}

/// Show an AQI alert using profile-aware thresholds instead of a
/// hard-coded 150 cutoff. This makes alerts more useful for sensitive
/// users and athletes.
///
/// At most once per hour.
Future<void> _maybeSendAqiAlert(
  Box<dynamic> prefsBox,
  AqiModel currentAqi,
  HealthProfile profile,
  DateTime now,
) async {
  final threshold = profile.safeAqiThreshold;

  // Alert when AQI exceeds the user's personal safe threshold.
  if (currentAqi.aqi <= threshold) return;

  final lastHour = prefsBox.get(_lastAqiAlertHourKey) as int?;
  if (lastHour == now.hour) return;

  // Build context-rich notification body.
  final severity = currentAqi.aqi > 200
      ? '🔴 Very Unhealthy'
      : currentAqi.aqi > 150
          ? '🟠 Unhealthy'
          : currentAqi.aqi > 100
              ? '🟡 Unhealthy for Sensitive Groups'
              : '⚠️ Above your safe threshold';

  final body = StringBuffer()
    ..write('$severity — AQI ${currentAqi.aqi}')
    ..write('\n${AqiUtils.advice(currentAqi.aqi, profile)}');

  if (currentAqi.pm25 != null) {
    body.write('\nPM2.5: ${currentAqi.pm25!.toStringAsFixed(1)} µg/m³');
  }

  if (currentAqi.aqi > 150) {
    body.write('\n💡 Close windows and use air purifier if available.');
  }

  await NotificationService.instance.showAqiAlert(
    title: 'AQI Alert: ${AqiUtils.label(currentAqi.aqi)}',
    body: body.toString(),
  );
  await prefsBox.put(_lastAqiAlertHourKey, now.hour);
}

/// Show a UV alert when UV index is dangerously high (≥ 6).
///
/// At most once per hour.
Future<void> _maybeSendUvAlert(
  Box<dynamic> prefsBox,
  WeatherModel? weather,
  DateTime now,
) async {
  if (weather == null || weather.uvIndex < 6) return;

  // Only alert during daytime hours (6 AM – 6 PM).
  if (now.hour < 6 || now.hour > 18) return;

  final lastHour = prefsBox.get(_lastUvAlertHourKey) as int?;
  if (lastHour == now.hour) return;

  final uvInt = weather.uvIndex.round();
  final label = _uvLabel(weather.uvIndex);

  String body;
  if (weather.uvIndex >= 11) {
    body = 'UV Index $uvInt ($label). Extreme UV radiation! '
        'Avoid sun exposure between 10 AM and 4 PM. '
        'Apply SPF 50+ sunscreen, wear hat and sunglasses.';
  } else if (weather.uvIndex >= 8) {
    body = 'UV Index $uvInt ($label). Very high UV radiation. '
        'Apply SPF 30+ sunscreen every 2 hours. '
        'Seek shade during peak hours (10 AM – 4 PM).';
  } else {
    body = 'UV Index $uvInt ($label). '
        'Apply sunscreen and wear protective clothing '
        'if spending extended time outdoors.';
  }

  await NotificationService.instance.showUvAlert(
    title: '☀️ High UV Alert',
    body: body,
  );
  await prefsBox.put(_lastUvAlertHourKey, now.hour);
}

/// Show a positive "conditions improving" notification when AQI
/// drops from above the user's threshold to below it.
///
/// This is the "real-time" feel — the user gets told when it's safe
/// to go out again, not just when it's bad.
Future<void> _maybeSendConditionsUpdate(
  Box<dynamic> prefsBox,
  AqiModel currentAqi,
  HealthProfile profile,
  DateTime now,
) async {
  final threshold = profile.safeAqiThreshold;
  final previousAqi = prefsBox.get(_previousAqiKey) as int?;

  // Save current AQI for next comparison.
  await prefsBox.put(_previousAqiKey, currentAqi.aqi);

  // Only trigger when AQI *was* above threshold and *now* is below.
  if (previousAqi == null || previousAqi <= threshold) return;
  if (currentAqi.aqi > threshold) return;

  // At most once per 3 hours.
  final lastHour = prefsBox.get(_lastConditionsHourKey) as int?;
  final hoursSinceLast = lastHour != null
      ? (now.hour - lastHour).abs()
      : 99;
  if (hoursSinceLast < 3) return;

  await NotificationService.instance.showConditionsUpdate(
    title: '🌿 Air Quality Improved!',
    body: 'AQI dropped from $previousAqi to ${currentAqi.aqi} '
        '(${AqiUtils.label(currentAqi.aqi)}). '
        'Conditions are now safe for outdoor activities.',
  );
  await prefsBox.put(_lastConditionsHourKey, now.hour);
}

// ─────────────────────────────────────────────
//  Helpers
// ─────────────────────────────────────────────

/// Finds the earliest upcoming forecast hour with rain probability
/// above the umbrella threshold, within a 2-hour window.
ForecastHourModel? _findSoonestRain(
  List<ForecastHourModel> forecast,
  DateTime now,
) {
  final cutoff = now.add(const Duration(hours: 2));
  final threshold = AppConstants.umbrellaThreshold / 100;

  for (final hour in forecast) {
    if (hour.dateTime.isAfter(now) &&
        hour.dateTime.isBefore(cutoff) &&
        hour.precipitationProbability >= threshold) {
      return hour;
    }
  }
  return null;
}

/// Human-readable UV index label.
String _uvLabel(double uvi) {
  if (uvi < 3) return 'Low';
  if (uvi < 6) return 'Moderate';
  if (uvi < 8) return 'High';
  if (uvi < 11) return 'Very High';
  return 'Extreme';
}

/// Format time as "7:30 AM".
String _formatTime(DateTime dt) {
  final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final min = dt.minute.toString().padLeft(2, '0');
  final period = dt.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$min $period';
}
