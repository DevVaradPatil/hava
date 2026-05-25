import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:hava/core/core.dart';
import 'package:hava/data/models/models.dart';
import 'package:hava/providers/app_providers.dart';
import 'package:hava/routing/route_names.dart';
import 'package:hava/services/location/location_service.dart';
import 'package:hava/services/notification/notification_service.dart';
import 'package:hava/shared/widgets/widgets.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  static const _totalPages = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.animateToPage(
        _currentPage + 1,
        duration: AppConstants.animNormal,
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    await ref.read(cacheServiceProvider).setOnboardingComplete(true);
    ref.read(onboardingCompleteProvider.notifier).state = true;
    if (mounted) context.go(RoutePaths.dashboard);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                physics: const BouncingScrollPhysics(),
                children: [
                  _WelcomePage(onNext: _nextPage),
                  _LocationPage(
                    onNext: _nextPage,
                    onLocationSet: (loc) {
                      ref.read(locationProvider.notifier).state = loc;
                      ref
                          .read(cacheServiceProvider)
                          .setSavedLocation(jsonEncode(loc.toJson()));
                    },
                  ),
                  _HealthProfilePage(
                    onNext: _nextPage,
                    onProfileChanged: (profile) {
                      ref.read(healthProfileProvider.notifier).state = profile;
                      ref
                          .read(cacheServiceProvider)
                          .setHealthProfileIndex(profile.index);
                    },
                  ),
                  _NotificationPage(onComplete: _completeOnboarding),
                ],
              ),
            ),
            _PageIndicator(current: _currentPage, total: _totalPages),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PAGE 1 — WELCOME
// ─────────────────────────────────────────────────────────────

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent,
                      AppColors.accent.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: AppShapes.borderRadiusLG,
                ),
                child: const Icon(
                  Icons.air_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              )
              .animate()
              .fadeIn(duration: AppConstants.animEntrance)
              .scale(
                begin: const Offset(0.8, 0.8),
                duration: AppConstants.animEntrance,
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: 32),
          Text(
            'Hava',
            style: AppTypography.displayLarge.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ).animate().fadeIn(
            duration: AppConstants.animEntrance,
            delay: 200.ms,
          ),
          const SizedBox(height: 12),
          Text(
            'Your intelligent air quality companion.\nBreathe smarter, live better.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge.copyWith(
              color: textSecondary,
              height: 1.5,
            ),
          ).animate().fadeIn(
            duration: AppConstants.animEntrance,
            delay: 350.ms,
          ),
          const SizedBox(height: 48),
          SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onNext,
                  child: const Text('Get Started'),
                ),
              )
              .animate()
              .fadeIn(duration: AppConstants.animEntrance, delay: 500.ms)
              .slideY(begin: 0.1, duration: AppConstants.animEntrance),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PAGE 2 — LOCATION
// ─────────────────────────────────────────────────────────────

class _LocationPage extends StatefulWidget {
  const _LocationPage({required this.onNext, required this.onLocationSet});

  final VoidCallback onNext;
  final ValueChanged<LocationModel> onLocationSet;

  @override
  State<_LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<_LocationPage> {
  bool _loading = false;
  String? _error;
  LocationModel? _location;

  Future<void> _detectLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final loc = await LocationService().getCurrentLocation();
      widget.onLocationSet(loc);
      setState(() => _location = loc);
    } on LocationServiceException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Failed to detect location.');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _openSearch() {
    showModalBottomSheet<LocationModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      builder: (_) => const CitySearchSheet(),
    ).then((location) {
      if (location != null && mounted) {
        widget.onLocationSet(location);
        setState(() => _location = location);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_on_rounded, size: 48, color: AppColors.accent),
          const SizedBox(height: 24),
          Text(
            'Set Your Location',
            style: AppTypography.headlineMedium.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'We need your location to provide\naccurate air quality data.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          if (_location != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: AppShapes.borderRadiusMD,
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.accent,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _location!.displayName,
                      style: AppTypography.bodyMedium.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: widget.onNext,
                child: const Text('Continue'),
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loading ? null : _detectLocation,
                icon: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.my_location_rounded),
                label: Text(_loading ? 'Detecting…' : 'Use GPS'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _openSearch,
                icon: const Icon(Icons.search_rounded),
                label: const Text('Search City'),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.aqiColor(200),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PAGE 3 — HEALTH PROFILE
// ─────────────────────────────────────────────────────────────

class _HealthProfilePage extends StatefulWidget {
  const _HealthProfilePage({
    required this.onNext,
    required this.onProfileChanged,
  });

  final VoidCallback onNext;
  final ValueChanged<HealthProfile> onProfileChanged;

  @override
  State<_HealthProfilePage> createState() => _HealthProfilePageState();
}

class _HealthProfilePageState extends State<_HealthProfilePage> {
  HealthProfile _selected = HealthProfile.standard;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_rounded, size: 48, color: AppColors.accent),
          const SizedBox(height: 24),
          Text(
            'Health Profile',
            style: AppTypography.headlineMedium.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This helps us tailor AQI thresholds\nand recommendations for you.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(
              color: textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 28),
          ...HealthProfile.values.map(
            (profile) => _ProfileOption(
              profile: profile,
              isSelected: _selected == profile,
              onTap: () {
                setState(() => _selected = profile);
                widget.onProfileChanged(profile);
              },
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: widget.onNext,
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileOption extends StatelessWidget {
  const _ProfileOption({
    required this.profile,
    required this.isSelected,
    required this.onTap,
  });

  final HealthProfile profile;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: AppConstants.animFast,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accent.withValues(alpha: 0.08)
                : isDark
                ? AppColors.darkSurface
                : AppColors.lightSurface,
            borderRadius: AppShapes.borderRadiusMD,
            border: Border.all(
              color: isSelected
                  ? AppColors.accent.withValues(alpha: 0.4)
                  : isDark
                  ? AppColors.darkGlassBorder
                  : AppColors.lightGlassBorder,
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: AppConstants.animFast,
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppColors.accent : Colors.transparent,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.accent
                        : isDark
                        ? AppColors.darkTextTertiary
                        : AppColors.lightTextTertiary,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 12, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 12),
              Text(
                profile.label,
                style: AppTypography.bodyMedium.copyWith(
                  color: textPrimary,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  NOTIFICATION PAGE
// ─────────────────────────────────────────────────────────────

class _NotificationPage extends StatefulWidget {
  const _NotificationPage({required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<_NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<_NotificationPage> {
  bool _requesting = false;

  Future<void> _enableNotifications() async {
    setState(() => _requesting = true);
    try {
      await NotificationService.instance.requestPermission();
    } catch (_) {
      // Permission denied or error — continue anyway
    }
    if (mounted) {
      setState(() => _requesting = false);
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 2),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_outlined,
              size: 44,
              color: AppColors.accent,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Stay Informed',
            style: AppTypography.headlineLarge.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Get timely updates so you never miss a safe window.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyLarge.copyWith(color: textSecondary),
          ),
          const SizedBox(height: 32),
          _NotifFeature(
            icon: Icons.wb_sunny_outlined,
            title: 'Daily Digest',
            subtitle: 'Morning air quality summary',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          const SizedBox(height: 14),
          _NotifFeature(
            icon: Icons.warning_amber_rounded,
            title: 'AQI Alerts',
            subtitle: 'When air quality drops significantly',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          const SizedBox(height: 14),
          _NotifFeature(
            icon: Icons.umbrella_outlined,
            title: 'Weather Alerts',
            subtitle: 'Rain & extreme weather heads-up',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
          ),
          const Spacer(flex: 3),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _requesting ? null : _enableNotifications,
              child: _requesting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Enable Notifications'),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: widget.onComplete,
            child: Text(
              'Skip for now',
              style: AppTypography.bodyMedium.copyWith(color: textSecondary),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _NotifFeature extends StatelessWidget {
  const _NotifFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.textPrimary,
    required this.textSecondary,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 22, color: AppColors.accent),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodyMedium.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(color: textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  PAGE INDICATOR
// ─────────────────────────────────────────────────────────────

class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: AppConstants.animFast,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.accent
                : isDark
                ? AppColors.darkTextTertiary
                : AppColors.lightTextTertiary,
            borderRadius: AppShapes.borderRadiusFull,
          ),
        );
      }),
    );
  }
}
