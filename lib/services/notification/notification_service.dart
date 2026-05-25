import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service for displaying local notifications.
///
/// Five notification channels:
/// - **Daily Digest** — morning summary with best outdoor window, UV, and AQI.
/// - **Umbrella Reminder** — rain expected soon.
/// - **AQI Alert** — air quality spike or profile-specific warning.
/// - **UV Alert** — high UV index requiring sun protection.
/// - **Conditions Update** — air quality improvement or other helpful changes.
class NotificationService {
  NotificationService._();

  /// Singleton instance — safe to call from background isolates.
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialised = false;

  // ── Notification IDs ──
  static const int _dailyDigestId = 1;
  static const int _umbrellaReminderId = 2;
  static const int _aqiAlertId = 3;
  static const int _uvAlertId = 4;
  static const int _conditionsUpdateId = 5;

  // ── Channel IDs ──
  static const String _dailyDigestChannelId = 'daily_digest';
  static const String _umbrellaChannelId = 'umbrella_reminder';
  static const String _aqiAlertChannelId = 'aqi_alert';
  static const String _uvAlertChannelId = 'uv_alert';
  static const String _conditionsUpdateChannelId = 'conditions_update';

  // ─────────────────────────────────────────────
  //  Initialisation
  // ─────────────────────────────────────────────

  /// Initialise the notification plugin and create Android channels.
  ///
  /// Safe to call multiple times — subsequent calls are no-ops.
  Future<void> init() async {
    if (_initialised) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(settings);

    // Create Android notification channels.
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (android != null) {
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _dailyDigestChannelId,
          'Daily Digest',
          description: "Morning summary of the day's best outdoor window",
          importance: Importance.defaultImportance,
        ),
      );
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _umbrellaChannelId,
          'Umbrella Reminder',
          description: 'Alert when rain is expected soon',
          importance: Importance.high,
        ),
      );
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _aqiAlertChannelId,
          'AQI Alert',
          description: 'Alerts for air quality changes affecting your health',
          importance: Importance.high,
        ),
      );
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _uvAlertChannelId,
          'UV Alert',
          description: 'Alerts when UV index is dangerously high',
          importance: Importance.high,
        ),
      );
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          _conditionsUpdateChannelId,
          'Conditions Update',
          description: 'Updates when outdoor conditions improve',
          importance: Importance.defaultImportance,
        ),
      );
    }

    _initialised = true;
  }

  // ─────────────────────────────────────────────
  //  Permission
  // ─────────────────────────────────────────────

  /// Request notification permission on Android 13+.
  ///
  /// Returns `true` if permission was granted (or not required on older OS).
  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }
    return true;
  }

  // ─────────────────────────────────────────────
  //  Daily Digest
  // ─────────────────────────────────────────────

  /// Show the morning daily digest notification.
  Future<void> showDailyDigest({
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      _dailyDigestId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _dailyDigestChannelId,
          'Daily Digest',
          channelDescription:
              "Morning summary of the day's best outdoor window",
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Umbrella Reminder
  // ─────────────────────────────────────────────

  /// Show an umbrella reminder when rain is imminent.
  Future<void> showUmbrellaReminder({
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      _umbrellaReminderId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _umbrellaChannelId,
          'Umbrella Reminder',
          channelDescription: 'Alert when rain is expected soon',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  AQI Spike Alert
  // ─────────────────────────────────────────────

  /// Show an AQI alert when air quality deteriorates.
  Future<void> showAqiAlert({
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      _aqiAlertId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _aqiAlertChannelId,
          'AQI Alert',
          channelDescription: 'Alerts for air quality changes affecting your health',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  UV Alert
  // ─────────────────────────────────────────────

  /// Show a UV alert when UV index is dangerously high.
  Future<void> showUvAlert({
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      _uvAlertId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _uvAlertChannelId,
          'UV Alert',
          channelDescription: 'Alerts when UV index is dangerously high',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Conditions Update (e.g. air improving)
  // ─────────────────────────────────────────────

  /// Show a conditions update (e.g., air has cleared up).
  Future<void> showConditionsUpdate({
    required String title,
    required String body,
  }) async {
    await _plugin.show(
      _conditionsUpdateId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _conditionsUpdateChannelId,
          'Conditions Update',
          channelDescription: 'Updates when outdoor conditions improve',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
    );
  }
}
