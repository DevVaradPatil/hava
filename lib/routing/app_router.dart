import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:hava/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:hava/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:hava/features/settings/presentation/screens/settings_screen.dart';
import 'package:hava/providers/app_providers.dart';
import 'route_names.dart';

/// Creates a [GoRouter] that redirects based on onboarding completion.
///
/// Must be created inside a Riverpod context so it can read
/// [onboardingCompleteProvider].
final appRouterProvider = Provider<GoRouter>((ref) {
  final isOnboardingComplete = ref.watch(onboardingCompleteProvider);

  return GoRouter(
    initialLocation: RoutePaths.onboarding,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final goingToOnboarding = state.matchedLocation == RoutePaths.onboarding;

      if (isOnboardingComplete && goingToOnboarding) {
        return RoutePaths.dashboard;
      }
      if (!isOnboardingComplete && !goingToOnboarding) {
        return RoutePaths.onboarding;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: RoutePaths.onboarding,
        name: RouteNames.onboarding,
        pageBuilder: (context, state) => _fadeTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.dashboard,
        name: RouteNames.dashboard,
        pageBuilder: (context, state) => _fadeTransitionPage(
          key: state.pageKey,
          child: const DashboardScreen(),
        ),
      ),
      GoRoute(
        path: RoutePaths.settings,
        name: RouteNames.settings,
        pageBuilder: (context, state) => _slideTransitionPage(
          key: state.pageKey,
          child: const SettingsScreen(),
        ),
      ),
    ],
  );
});

// ──────────────────────────────────────────────
//  Custom page transitions
// ──────────────────────────────────────────────

CustomTransitionPage<void> _fadeTransitionPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    transitionsBuilder: (context, animation, _, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

CustomTransitionPage<void> _slideTransitionPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 350),
    transitionsBuilder: (context, animation, _, child) {
      final tween = Tween(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).chain(CurveTween(curve: Curves.easeOutCubic));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}
