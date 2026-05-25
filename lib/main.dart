import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'providers/app_providers.dart';
import 'services/background/background_service.dart';
import 'services/notification/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait on phones (tablets may override later).
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initialise Hive and get the cache service override.
  final cacheOverride = await initHive();

  // Initialise notification channels.
  await NotificationService.instance.init();

  // Register periodic background fetch (Android WorkManager).
  await initBackgroundService();

  runApp(ProviderScope(overrides: [cacheOverride], child: const HavaApp()));
}
