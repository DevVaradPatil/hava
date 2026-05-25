import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:dio/dio.dart';

import 'package:hava/core/utils/aqi_utils.dart';
import 'package:hava/data/datasources/local/cache_service.dart';
import 'package:hava/data/datasources/remote/api_client.dart';
import 'package:hava/data/datasources/remote/aqi_api_service.dart';
import 'package:hava/data/datasources/remote/weather_api_service.dart';
import 'package:hava/data/models/models.dart';
import 'package:hava/data/repositories/aqi_repository_impl.dart';
import 'package:hava/data/repositories/weather_repository_impl.dart';
import 'package:hava/services/recommendation/recommendation_engine.dart';
import 'package:hava/services/breathability/breathability_engine.dart';
import 'package:hava/services/gear/gear_advisor.dart';
import 'package:hava/services/ventilation/ventilation_assistant.dart';
import 'package:hava/services/health_impact/health_impact_engine.dart';
import 'package:hava/features/dashboard/presentation/widgets/activity_timeline.dart';

// ──────────────────────────────────────────────
//  LOW-LEVEL INFRASTRUCTURE
// ──────────────────────────────────────────────

/// Dio instance for OpenWeatherMap.
final openWeatherDioProvider = Provider<Dio>((ref) => createOpenWeatherDio());

/// Dio instance for IQAir.
final iqAirDioProvider = Provider<Dio>((ref) => createIqAirDio());

/// Weather API Service.
final weatherApiServiceProvider = Provider<WeatherApiService>(
  (ref) => WeatherApiService(ref.watch(openWeatherDioProvider)),
);

/// AQI API Service (IQAir).
final aqiApiServiceProvider = Provider<AqiApiService>(
  (ref) => AqiApiService(ref.watch(iqAirDioProvider)),
);

/// Hive cache service — must be initialised before use (see [initHive]).
final cacheServiceProvider = Provider<CacheService>((ref) {
  throw UnimplementedError(
    'CacheService must be overridden after Hive initialisation.',
  );
});

// ──────────────────────────────────────────────
//  REPOSITORIES
// ──────────────────────────────────────────────

final weatherRepositoryProvider = Provider<WeatherRepositoryImpl>(
  (ref) => WeatherRepositoryImpl(
    apiService: ref.watch(weatherApiServiceProvider),
    cacheService: ref.watch(cacheServiceProvider),
  ),
);

final aqiRepositoryProvider = Provider<AqiRepositoryImpl>(
  (ref) => AqiRepositoryImpl(
    weatherApiService: ref.watch(weatherApiServiceProvider),
    iqAirApiService: ref.watch(aqiApiServiceProvider),
    cacheService: ref.watch(cacheServiceProvider),
  ),
);

// ──────────────────────────────────────────────
//  PREFERENCES (persisted via Hive)
// ──────────────────────────────────────────────

/// Whether onboarding has been completed.
final onboardingCompleteProvider = StateProvider<bool>((ref) {
  return ref.watch(cacheServiceProvider).isOnboardingComplete;
});

/// Current health profile.
final healthProfileProvider = StateProvider<HealthProfile>((ref) {
  final index = ref.watch(cacheServiceProvider).healthProfileIndex;
  return HealthProfile.values[index.clamp(0, HealthProfile.values.length - 1)];
});

/// Theme mode: 0 = system, 1 = light, 2 = dark.
final themeModeProvider = StateProvider<ThemeMode>((ref) {
  final index = ref.watch(cacheServiceProvider).themeModeIndex;
  switch (index) {
    case 1:
      return ThemeMode.light;
    case 2:
      return ThemeMode.dark;
    default:
      return ThemeMode.system;
  }
});

// ──────────────────────────────────────────────
//  LOCATION
// ──────────────────────────────────────────────

/// The user's active location. Null until set via GPS or manual search.
final locationProvider = StateProvider<LocationModel?>((ref) {
  final cache = ref.watch(cacheServiceProvider);
  final json = cache.savedLocationJson;
  if (json != null) {
    try {
      return LocationModel.fromJson(
        Map<String, dynamic>.from(jsonDecode(json) as Map),
      );
    } catch (_) {}
  }
  return null;
});

// ──────────────────────────────────────────────
//  DATA: WEATHER
// ──────────────────────────────────────────────

/// Fetches current weather for the active location.
final currentWeatherProvider = FutureProvider.autoDispose<WeatherModel?>((
  ref,
) async {
  final loc = ref.watch(locationProvider);
  if (loc == null) return null;
  return ref
      .watch(weatherRepositoryProvider)
      .getCurrentWeather(lat: loc.latitude, lon: loc.longitude);
});

/// Fetches the hourly forecast for the active location.
final hourlyForecastProvider =
    FutureProvider.autoDispose<List<ForecastHourModel>>((ref) async {
      final loc = ref.watch(locationProvider);
      if (loc == null) return [];
      return ref
          .watch(weatherRepositoryProvider)
          .getHourlyForecast(lat: loc.latitude, lon: loc.longitude);
    });

// ──────────────────────────────────────────────
//  DATA: AQI
// ──────────────────────────────────────────────

/// Fetches current AQI for the active location.
final currentAqiProvider = FutureProvider.autoDispose<AqiModel?>((ref) async {
  final loc = ref.watch(locationProvider);
  if (loc == null) return null;
  return ref
      .watch(aqiRepositoryProvider)
      .getCurrentAqi(lat: loc.latitude, lon: loc.longitude);
});

/// Fetches hourly AQI forecast for the active location.
final hourlyAqiForecastProvider = FutureProvider.autoDispose<List<AqiModel>>((
  ref,
) async {
  final loc = ref.watch(locationProvider);
  if (loc == null) return [];
  return ref
      .watch(aqiRepositoryProvider)
      .getHourlyAqiForecast(lat: loc.latitude, lon: loc.longitude);
});

// ──────────────────────────────────────────────
//  CITY SEARCH
// ──────────────────────────────────────────────

/// City search query — drives the search results provider.
final citySearchQueryProvider = StateProvider<String>((ref) => '');

/// City search results from the geocoding API.
final citySearchResultsProvider =
    FutureProvider.autoDispose<List<LocationModel>>((ref) async {
      final query = ref.watch(citySearchQueryProvider);
      if (query.trim().length < 2) return [];

      // Debounce: let UI handle the delay; provider just fetches.
      return ref.watch(weatherRepositoryProvider).searchCities(query.trim());
    });

// ──────────────────────────────────────────────
//  RECOMMENDATION ENGINE
// ──────────────────────────────────────────────

/// Singleton engine instance.
final recommendationEngineProvider = Provider<RecommendationEngine>(
  (ref) => const RecommendationEngine(),
);

/// The primary recommendation for the dashboard Action Card.
///
/// Depends on current AQI, AQI forecast, weather forecast, and health profile.
final recommendationProvider = FutureProvider.autoDispose<Recommendation?>((
  ref,
) async {
  final currentAqi = await ref.watch(currentAqiProvider.future);
  if (currentAqi == null) return null;

  final aqiForecast = await ref.watch(hourlyAqiForecastProvider.future);
  final weatherForecast = await ref.watch(hourlyForecastProvider.future);
  final profile = ref.watch(healthProfileProvider);
  final engine = ref.watch(recommendationEngineProvider);

  return engine.generate(
    currentAqi: currentAqi,
    aqiForecast: aqiForecast,
    weatherForecast: weatherForecast,
    profile: profile,
  );
});

// ──────────────────────────────────────────────
//  BREATHABILITY INDEX
// ──────────────────────────────────────────────

/// Singleton Breathability engine.
final breathabilityEngineProvider = Provider<BreathabilityEngine>(
  (ref) => const BreathabilityEngine(),
);

/// Current Breathability Index result (computed from weather + AQI).
final breathabilityProvider = FutureProvider.autoDispose<BreathabilityResult?>((
  ref,
) async {
  final weather = await ref.watch(currentWeatherProvider.future);
  final aqi = await ref.watch(currentAqiProvider.future);
  if (weather == null || aqi == null) return null;

  final profile = ref.watch(healthProfileProvider);
  final engine = ref.watch(breathabilityEngineProvider);

  return engine.compute(
    aqi: aqi.aqi,
    temperature: weather.temperature,
    humidity: weather.humidity,
    uvIndex: weather.uvIndex,
    windSpeed: weather.windSpeed,
    profile: profile,
  );
});

/// Hourly Breathability timeline entries for the Activity Timeline.
final hourlyBreathabilityProvider =
    FutureProvider.autoDispose<List<TimelineEntry>>((ref) async {
      final forecast = await ref.watch(hourlyForecastProvider.future);
      final aqiForecast = await ref.watch(hourlyAqiForecastProvider.future);
      if (forecast.isEmpty) return [];

      final profile = ref.watch(healthProfileProvider);
      final engine = ref.watch(breathabilityEngineProvider);

      // Build AQI lookup by hour.
      final aqiMap = <int, int>{};
      for (final a in aqiForecast) {
        aqiMap[a.dateTime.hour] = a.aqi;
      }

      final hours = forecast.length > 24 ? forecast.sublist(0, 24) : forecast;

      return hours.map((hour) {
        final hourAqi = aqiMap[hour.dateTime.hour] ?? hour.aqi ?? 50;
        final result = engine.computeFromForecast(
          hour: hour,
          aqi: hourAqi,
          profile: profile,
        );
        return TimelineEntry(dateTime: hour.dateTime, result: result);
      }).toList();
    });

// ──────────────────────────────────────────────
//  GEAR ADVISOR
// ──────────────────────────────────────────────

/// Singleton Gear Advisor.
final gearAdvisorProvider = Provider<GearAdvisor>((ref) => const GearAdvisor());

/// Current gear suggestions based on live conditions.
final gearSuggestionsProvider = FutureProvider.autoDispose<List<GearItem>>((
  ref,
) async {
  final weather = await ref.watch(currentWeatherProvider.future);
  final aqi = await ref.watch(currentAqiProvider.future);
  final forecast = await ref.watch(hourlyForecastProvider.future);
  if (weather == null || aqi == null) return [];

  // Get max precipitation probability in the next 6 hours.
  final now = DateTime.now();
  final cutoff = now.add(const Duration(hours: 6));
  double maxPrecip = 0;
  for (final hour in forecast) {
    if (hour.dateTime.isAfter(now) && hour.dateTime.isBefore(cutoff)) {
      if (hour.precipitationProbability > maxPrecip) {
        maxPrecip = hour.precipitationProbability;
      }
    }
  }

  final advisor = ref.watch(gearAdvisorProvider);
  return advisor.suggest(
    aqi: aqi.aqi,
    temperature: weather.temperature,
    feelsLike: weather.feelsLike,
    humidity: weather.humidity,
    uvIndex: weather.uvIndex,
    windSpeed: weather.windSpeed,
    precipitationProbability: maxPrecip,
  );
});

// ──────────────────────────────────────────────
//  VENTILATION ASSISTANT
// ──────────────────────────────────────────────

/// Singleton Ventilation Assistant.
final ventilationAssistantProvider = Provider<VentilationAssistant>(
  (ref) => const VentilationAssistant(),
);

/// Ventilation advice based on current AQI + forecast + health profile.
final ventilationAdviceProvider =
    FutureProvider.autoDispose<VentilationAdvice?>((ref) async {
      final currentAqi = await ref.watch(currentAqiProvider.future);
      if (currentAqi == null) return null;

      final aqiForecast = await ref.watch(hourlyAqiForecastProvider.future);
      final profile = ref.watch(healthProfileProvider);
      final assistant = ref.watch(ventilationAssistantProvider);

      return assistant.evaluate(
        currentAqi: currentAqi,
        aqiForecast: aqiForecast,
        profile: profile,
      );
    });

// ──────────────────────────────────────────────
//  HEALTH IMPACT ("Cigarette Equivalent")
// ──────────────────────────────────────────────

/// Singleton Health Impact engine.
final healthImpactEngineProvider = Provider<HealthImpactEngine>(
  (ref) => const HealthImpactEngine(),
);

/// Health impact result — cigarette-equivalent metric from current AQI/PM2.5.
final healthImpactProvider = FutureProvider.autoDispose<HealthImpactResult?>((
  ref,
) async {
  final currentAqi = await ref.watch(currentAqiProvider.future);
  if (currentAqi == null) return null;

  final engine = ref.watch(healthImpactEngineProvider);

  return engine.compute(
    pm25: currentAqi.pm25,
    aqi: currentAqi.aqi,
    outdoorHours: 2.0,
  );
});

// ──────────────────────────────────────────────
//  HIVE INITIALISATION HELPER
// ──────────────────────────────────────────────

/// Initialises Hive and returns a [ProviderScope] override for
/// [cacheServiceProvider].
///
/// Call once in `main()` before `runApp`.
Future<Override> initHive() async {
  await Hive.initFlutter();
  final weatherBox = await Hive.openBox<String>(CacheKeys.weatherBox);
  final prefsBox = await Hive.openBox<dynamic>(CacheKeys.prefsBox);

  return cacheServiceProvider.overrideWithValue(
    CacheService(weatherBox, prefsBox),
  );
}
