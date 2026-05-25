import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:hava/app.dart';
import 'package:hava/data/datasources/local/cache_service.dart';
import 'package:hava/providers/app_providers.dart';

void main() {
  testWidgets('App renders without crashing', (WidgetTester tester) async {
    // Initialise Hive in a temp directory for testing.
    Hive.init('${Directory.systemTemp.path}/hava_test');
    final weatherBox = await Hive.openBox<String>(CacheKeys.weatherBox);
    final prefsBox = await Hive.openBox<dynamic>(CacheKeys.prefsBox);
    final cache = CacheService(weatherBox, prefsBox);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [cacheServiceProvider.overrideWithValue(cache)],
        child: const HavaApp(),
      ),
    );

    // The onboarding screen should be the initial route.
    expect(find.text('Welcome to Hava'), findsOneWidget);

    // Cleanup.
    await weatherBox.close();
    await prefsBox.close();
  });
}
