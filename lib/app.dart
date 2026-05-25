import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hava/core/constants/app_constants.dart';
import 'package:hava/core/theme/app_theme.dart';
import 'package:hava/providers/app_providers.dart';
import 'package:hava/routing/app_router.dart';

/// Root MaterialApp using GoRouter and the Hava theme system.
///
/// Wrapped by [ProviderScope] in `main.dart` so that all descendants
/// have access to Riverpod providers.
class HavaApp extends ConsumerWidget {
  const HavaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
