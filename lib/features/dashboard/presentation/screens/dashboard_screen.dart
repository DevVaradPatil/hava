import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:hava/core/core.dart';
import 'package:hava/data/models/models.dart';
import 'package:hava/providers/app_providers.dart';
import 'package:go_router/go_router.dart';

import 'package:hava/routing/route_names.dart';
import 'package:hava/shared/widgets/widgets.dart';
import 'package:hava/features/dashboard/presentation/widgets/aura_background.dart';
import 'package:hava/features/dashboard/presentation/widgets/breathability_ring.dart';
import 'package:hava/features/dashboard/presentation/widgets/countdown_timer.dart';
import 'package:hava/features/dashboard/presentation/widgets/aqi_trend_chart.dart';
import 'package:hava/features/dashboard/presentation/widgets/activity_timeline.dart';
import 'package:hava/features/dashboard/presentation/widgets/gear_advisor_row.dart';
import 'package:hava/features/dashboard/presentation/widgets/health_impact_card.dart';
import 'package:hava/features/dashboard/presentation/widgets/ventilation_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // ───────────────────────── helpers ─────────────────────────

  Future<void> _onRefresh() async {
    ref.invalidate(currentWeatherProvider);
    ref.invalidate(currentAqiProvider);
    ref.invalidate(hourlyForecastProvider);
    ref.invalidate(hourlyAqiForecastProvider);
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
        ref.read(locationProvider.notifier).state = location;
        ref
            .read(cacheServiceProvider)
            .setSavedLocation(jsonEncode(location.toJson()));
      }
    });
  }

  // ───────────────────────── build ───────────────────────────

  @override
  Widget build(BuildContext context) {
    final location = ref.watch(locationProvider);
    final weatherAsync = ref.watch(currentWeatherProvider);
    final aqiAsync = ref.watch(currentAqiProvider);
    final forecastAsync = ref.watch(hourlyForecastProvider);
    final aqiForecastAsync = ref.watch(hourlyAqiForecastProvider);
    final recommendationAsync = ref.watch(recommendationProvider);
    final breathabilityAsync = ref.watch(breathabilityProvider);
    final hourlyBreathabilityAsync = ref.watch(hourlyBreathabilityProvider);
    final gearAsync = ref.watch(gearSuggestionsProvider);
    final ventilationAsync = ref.watch(ventilationAdviceProvider);
    final healthImpactAsync = ref.watch(healthImpactProvider);

    final currentAqi = aqiAsync.valueOrNull;
    final breathabilityColor = breathabilityAsync.valueOrNull?.color;

    return Scaffold(
      body: AuraBackground(
        aqi: currentAqi?.aqi ?? 50,
        breathabilityColor: breathabilityColor,
        child: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            color: AppColors.accent,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                // ── Top bar ──
                SliverToBoxAdapter(
                  child: _TopBar(
                    location: location,
                    onSearchTap: _openSearch,
                    onSettingsTap: () => context.push(RoutePaths.settings),
                    lastUpdated: weatherAsync.valueOrNull?.dateTime,
                    currentAqi: currentAqi?.aqi,
                    weatherDescription: weatherAsync.valueOrNull?.description,
                    feelsLike: weatherAsync.valueOrNull?.feelsLike,
                  ),
                ),

                // ── Hero: Breathability Ring ──
                SliverToBoxAdapter(
                  child: breathabilityAsync.when(
                    data: (result) => result != null
                        ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 20,
                                ),
                                child: BreathabilityRing(result: result),
                              )
                              .animate()
                              .fadeIn(duration: AppConstants.animEntrance)
                              .scale(
                                begin: const Offset(0.95, 0.95),
                                end: const Offset(1.0, 1.0),
                                duration: AppConstants.animEntrance,
                                curve: Curves.easeOutCubic,
                              )
                        : const ShimmerCard(height: 320),
                    loading: () => const ShimmerCard(height: 320),
                    error: (_, __) => ErrorCard(
                      message: 'Could not load air quality',
                      onRetry: () => ref.invalidate(breathabilityProvider),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // ── Recommendation headline ──
                SliverToBoxAdapter(
                  child: recommendationAsync.when(
                    data: (rec) => rec != null
                        ? Padding(
                                padding: AppSpacing.screenPadding,
                                child: _RecommendationHeadline(
                                  recommendation: rec,
                                ),
                              )
                              .animate()
                              .fadeIn(
                                duration: AppConstants.animEntrance,
                                delay: 30.ms,
                              )
                              .slideY(
                                begin: 0.03,
                                duration: AppConstants.animEntrance,
                                delay: 30.ms,
                              )
                        : const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // ── Weather row ──
                SliverToBoxAdapter(
                  child: weatherAsync.when(
                    data: (weather) => weather != null
                        ? _WeatherRow(weather: weather)
                              .animate()
                              .fadeIn(
                                duration: AppConstants.animEntrance,
                                delay: 50.ms,
                              )
                              .slideY(
                                begin: 0.03,
                                duration: AppConstants.animEntrance,
                                delay: 50.ms,
                              )
                        : const SizedBox.shrink(),
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: ShimmerBlock(
                              width: 70,
                              height: 70,
                              borderRadius: BorderRadius.all(
                                Radius.circular(16),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: ShimmerBlock(
                              width: 70,
                              height: 70,
                              borderRadius: BorderRadius.all(
                                Radius.circular(16),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: ShimmerBlock(
                              width: 70,
                              height: 70,
                              borderRadius: BorderRadius.all(
                                Radius.circular(16),
                              ),
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: ShimmerBlock(
                              width: 70,
                              height: 70,
                              borderRadius: BorderRadius.all(
                                Radius.circular(16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    error: (_, __) => ErrorCard(
                      compact: true,
                      message: 'Weather unavailable',
                      onRetry: () => ref.invalidate(currentWeatherProvider),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // ── Countdown timer ──
                SliverToBoxAdapter(
                  child: recommendationAsync.when(
                    data: (rec) => rec != null
                        ? Column(
                                children: [
                                  SectionHeader(
                                    title: 'Safe Window',
                                    onHelp: () => showHelpSheet(
                                      context,
                                      title: 'Safe Window',
                                      description:
                                          'The safe window shows the best time today to be outdoors based on forecasted air quality.',
                                      items: const [
                                        HelpItem(
                                          label: 'Countdown',
                                          explanation:
                                              'Time remaining until the next safe outdoor window begins.',
                                          icon: Icons.timer_outlined,
                                        ),
                                        HelpItem(
                                          label: 'Window AQI',
                                          explanation:
                                              'The expected AQI during the safe window — lower is better.',
                                          icon: Icons.air_rounded,
                                        ),
                                        HelpItem(
                                          label: 'No safe window',
                                          explanation:
                                              'When air quality stays poor all day, it\'s best to remain indoors.',
                                          icon: Icons.shield_outlined,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: AppSpacing.screenPadding,
                                    child:
                                        rec.bestWindowStart != null &&
                                            rec.bestWindowEnd != null
                                        ? CountdownTimer(
                                            safeWindowStart:
                                                rec.bestWindowStart!,
                                            safeWindowEnd: rec.bestWindowEnd!,
                                            safeWindowAqi:
                                                rec.bestWindowAqi ?? rec.aqi,
                                          )
                                        : _NoSafeWindowCard(
                                            recommendation: rec,
                                          ),
                                  ),
                                ],
                              )
                              .animate()
                              .fadeIn(
                                duration: AppConstants.animEntrance,
                                delay: 100.ms,
                              )
                              .slideY(
                                begin: 0.05,
                                duration: AppConstants.animEntrance,
                                delay: 100.ms,
                              )
                        : const SizedBox.shrink(),
                    loading: () => const ShimmerCard(height: 80),
                    error: (_, __) => ErrorCard(
                      compact: true,
                      message: 'Recommendations unavailable',
                      onRetry: () => ref.invalidate(recommendationProvider),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // ── Gear advisor ──
                SliverToBoxAdapter(
                  child: gearAsync.when(
                    data: (items) => items.isNotEmpty
                        ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SectionHeader(
                                    title: 'Gear Advisor',
                                    onHelp: () => showHelpSheet(
                                      context,
                                      title: 'Gear Advisor',
                                      description:
                                          'Suggested gear based on current weather and air quality conditions.',
                                      items: const [
                                        HelpItem(
                                          label: 'Mask',
                                          explanation:
                                              'Recommended when AQI is high. An N95 mask filters fine particulates.',
                                          icon: Icons.masks_rounded,
                                        ),
                                        HelpItem(
                                          label: 'Sunscreen & Sunglasses',
                                          explanation:
                                              'Suggested when UV index is moderate or higher.',
                                          icon: Icons.wb_sunny_outlined,
                                        ),
                                        HelpItem(
                                          label: 'Umbrella & Rain Gear',
                                          explanation:
                                              'Shown when rain is expected in the hourly forecast.',
                                          icon: Icons.umbrella_rounded,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: AppSpacing.screenPadding,
                                    child: GearAdvisorRow(items: items),
                                  ),
                                ],
                              )
                              .animate()
                              .fadeIn(
                                duration: AppConstants.animEntrance,
                                delay: 120.ms,
                              )
                              .slideY(
                                begin: 0.04,
                                duration: AppConstants.animEntrance,
                                delay: 120.ms,
                              )
                        : const SizedBox.shrink(),
                    loading: () => const ShimmerCard(height: 56),
                    error: (_, __) => ErrorCard(
                      compact: true,
                      message: 'Gear suggestions unavailable',
                      onRetry: () => ref.invalidate(gearSuggestionsProvider),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // ── Ventilation card ──
                SliverToBoxAdapter(
                  child: ventilationAsync.when(
                    data: (advice) => advice != null
                        ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SectionHeader(
                                    title: 'Ventilation',
                                    onHelp: () => showHelpSheet(
                                      context,
                                      title: 'Ventilation',
                                      description:
                                          'Advice on whether to open or close windows based on indoor vs. outdoor air quality.',
                                      items: const [
                                        HelpItem(
                                          label: 'Open Windows',
                                          explanation:
                                              'Outdoor air is cleaner — let fresh air in to improve indoor quality.',
                                          icon: Icons.open_in_new_rounded,
                                        ),
                                        HelpItem(
                                          label: 'Keep Closed',
                                          explanation:
                                              'Outdoor air quality is poor — keeping windows shut protects you from pollutants.',
                                          icon: Icons.close_rounded,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: AppSpacing.screenPadding,
                                    child: VentilationCard(advice: advice),
                                  ),
                                ],
                              )
                              .animate()
                              .fadeIn(
                                duration: AppConstants.animEntrance,
                                delay: 140.ms,
                              )
                              .slideY(
                                begin: 0.05,
                                duration: AppConstants.animEntrance,
                                delay: 140.ms,
                              )
                        : const SizedBox.shrink(),
                    loading: () => const ShimmerCard(height: 140),
                    error: (_, __) => ErrorCard(
                      compact: true,
                      message: 'Ventilation data unavailable',
                      onRetry: () => ref.invalidate(ventilationAdviceProvider),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // ── Health impact card ──
                SliverToBoxAdapter(
                  child: healthImpactAsync.when(
                    data: (impact) => impact != null
                        ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SectionHeader(
                                    title: 'Health Impact',
                                    onHelp: () => showHelpSheet(
                                      context,
                                      title: 'Health Impact',
                                      description:
                                          'Everyday equivalents that illustrate how current air pollution affects your body.',
                                      items: const [
                                        HelpItem(
                                          label: 'Cigarette Equivalent',
                                          explanation:
                                              'Number of cigarettes worth of pollution you inhale daily at this AQI level. Based on PM2.5 research.',
                                          icon: Icons.smoke_free_rounded,
                                        ),
                                        HelpItem(
                                          label: 'Lung Burden',
                                          explanation:
                                              'Qualitative rating of how hard your lungs are working to filter pollutants from the air.',
                                          icon: Icons.health_and_safety_rounded,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: AppSpacing.screenPadding,
                                    child: HealthImpactCard(result: impact),
                                  ),
                                ],
                              )
                              .animate()
                              .fadeIn(
                                duration: AppConstants.animEntrance,
                                delay: 160.ms,
                              )
                              .slideY(
                                begin: 0.05,
                                duration: AppConstants.animEntrance,
                                delay: 160.ms,
                              )
                        : const SizedBox.shrink(),
                    loading: () => const ShimmerCard(height: 140),
                    error: (_, __) => ErrorCard(
                      compact: true,
                      message: 'Health data unavailable',
                      onRetry: () => ref.invalidate(healthImpactProvider),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // ── AQI trend chart ──
                SliverToBoxAdapter(
                  child: aqiForecastAsync.when(
                    data: (forecast) => forecast.isNotEmpty
                        ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SectionHeader(
                                    title: 'AQI Trend',
                                    onHelp: () => showHelpSheet(
                                      context,
                                      title: 'AQI Trend',
                                      description:
                                          'Hourly Air Quality Index forecast for the next 24 hours. Lower values mean cleaner air.',
                                      items: const [
                                        HelpItem(
                                          label: '0 – 50 (Good)',
                                          explanation:
                                              'Air quality is satisfactory and poses little or no risk.',
                                          icon: Icons.check_circle_outline,
                                        ),
                                        HelpItem(
                                          label: '51 – 100 (Moderate)',
                                          explanation:
                                              'Acceptable, but sensitive individuals may experience minor effects.',
                                          icon: Icons.info_outline_rounded,
                                        ),
                                        HelpItem(
                                          label:
                                              '101 – 150 (Unhealthy for Sensitive)',
                                          explanation:
                                              'Sensitive groups such as children, elderly, and those with respiratory conditions should reduce outdoor activity.',
                                          icon: Icons.warning_amber_rounded,
                                        ),
                                        HelpItem(
                                          label: '151+ (Unhealthy)',
                                          explanation:
                                              'Everyone may begin to experience health effects. Limit prolonged outdoor exertion.',
                                          icon: Icons.dangerous_outlined,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: AppSpacing.screenPadding,
                                    child: AqiTrendChart(data: forecast),
                                  ),
                                ],
                              )
                              .animate()
                              .fadeIn(
                                duration: AppConstants.animEntrance,
                                delay: 180.ms,
                              )
                              .slideY(
                                begin: 0.04,
                                duration: AppConstants.animEntrance,
                                delay: 180.ms,
                              )
                        : const SizedBox.shrink(),
                    loading: () => const ShimmerCard(height: 220),
                    error: (_, __) => ErrorCard(
                      compact: true,
                      message: 'AQI trend unavailable',
                      onRetry: () => ref.invalidate(hourlyAqiForecastProvider),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // ── Activity timeline ──
                SliverToBoxAdapter(
                  child: hourlyBreathabilityAsync.when(
                    data: (entries) => entries.isNotEmpty
                        ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SectionHeader(
                                    title: 'Activity Timeline',
                                    onHelp: () => showHelpSheet(
                                      context,
                                      title: 'Activity Timeline',
                                      description:
                                          'Hour-by-hour breathability scores showing when conditions are best for outdoor activities.',
                                      items: const [
                                        HelpItem(
                                          label: 'Green hours',
                                          explanation:
                                              'Excellent or good conditions — ideal for outdoor exercise.',
                                          icon: Icons.check_circle_outline,
                                        ),
                                        HelpItem(
                                          label: 'Yellow / Orange hours',
                                          explanation:
                                              'Moderate conditions — light activity is fine, avoid strenuous exercise.',
                                          icon: Icons.warning_amber_rounded,
                                        ),
                                        HelpItem(
                                          label: 'Red hours',
                                          explanation:
                                              'Poor conditions — stay indoors if possible.',
                                          icon: Icons.dangerous_outlined,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: AppSpacing.screenPadding,
                                    child: ActivityTimeline(
                                      hourlyResults: entries,
                                    ),
                                  ),
                                ],
                              )
                              .animate()
                              .fadeIn(
                                duration: AppConstants.animEntrance,
                                delay: 200.ms,
                              )
                              .slideY(
                                begin: 0.04,
                                duration: AppConstants.animEntrance,
                                delay: 200.ms,
                              )
                        : const SizedBox.shrink(),
                    loading: () => const ShimmerCard(height: 80),
                    error: (_, __) => ErrorCard(
                      compact: true,
                      message: 'Timeline unavailable',
                      onRetry: () =>
                          ref.invalidate(hourlyBreathabilityProvider),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // ── Hourly forecast row ──
                SliverToBoxAdapter(
                  child: forecastAsync.when(
                    data: (hours) => hours.isNotEmpty
                        ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SectionHeader(
                                    title: 'Hourly Forecast',
                                    onHelp: () => showHelpSheet(
                                      context,
                                      title: 'Hourly Forecast',
                                      description:
                                          'Weather conditions for the next few hours including temperature, icons, and rain probability.',
                                      items: const [
                                        HelpItem(
                                          label: 'Temperature',
                                          explanation:
                                              'The expected temperature at that hour.',
                                          icon: Icons.thermostat_rounded,
                                        ),
                                        HelpItem(
                                          label: 'Rain Probability',
                                          explanation:
                                              'Chance of precipitation. Shown as a blue droplet percentage when above 10%.',
                                          icon: Icons.water_drop_rounded,
                                        ),
                                      ],
                                    ),
                                  ),
                                  _HourlyForecastRow(hours: hours),
                                ],
                              )
                              .animate()
                              .fadeIn(
                                duration: AppConstants.animEntrance,
                                delay: 220.ms,
                              )
                              .slideY(
                                begin: 0.04,
                                duration: AppConstants.animEntrance,
                                delay: 220.ms,
                              )
                        : const SizedBox.shrink(),
                    loading: () => const ShimmerCard(height: 100),
                    error: (_, __) => ErrorCard(
                      compact: true,
                      message: 'Forecast unavailable',
                      onRetry: () => ref.invalidate(hourlyForecastProvider),
                    ),
                  ),
                ),

                // Bottom safe area spacer
                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  TOP BAR
// ─────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.location,
    required this.onSearchTap,
    required this.onSettingsTap,
    this.lastUpdated,
    this.currentAqi,
    this.weatherDescription,
    this.feelsLike,
  });

  final LocationModel? location;
  final VoidCallback onSearchTap;
  final VoidCallback onSettingsTap;
  final DateTime? lastUpdated;
  final int? currentAqi;
  final String? weatherDescription;
  final double? feelsLike;

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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onSearchTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_rounded,
                        size: 14,
                        color: AppColors.accent,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          location?.city ?? 'Set Location',
                          style: AppTypography.titleSmall.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16,
                        color: textSecondary,
                      ),
                    ],
                  ),
                  if (location?.country != null ||
                      weatherDescription != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (weatherDescription != null)
                          _capitalize(weatherDescription!),
                        if (feelsLike != null) 'Feels ${feelsLike!.round()}°',
                        if (location?.state != null) location!.state!,
                        if (location?.country != null) location!.country!,
                      ].join(' · '),
                      style: AppTypography.labelSmall.copyWith(
                        color: textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (currentAqi != null) ...[
            const SizedBox(width: 8),
            _AqiBadge(aqi: currentAqi!),
          ],
          if (lastUpdated != null)
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(
                _formatUpdatedAgo(lastUpdated!),
                style: AppTypography.labelSmall.copyWith(
                  color: textSecondary,
                  fontSize: 9,
                ),
              ),
            ),
          const SizedBox(width: 4),
          IconButton(
            onPressed: onSettingsTap,
            icon: Icon(Icons.tune_rounded, color: textPrimary, size: 22),
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? AppColors.darkSurfaceVariant
                  : AppColors.lightSurfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: AppShapes.borderRadiusSM,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';

  static String _formatUpdatedAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MMM d').format(time);
  }
}

// ─────────────────────────────────────────────────────────────
//  AQI BADGE
// ─────────────────────────────────────────────────────────────

class _AqiBadge extends StatelessWidget {
  const _AqiBadge({required this.aqi});

  final int aqi;

  static String _aqiLabel(int aqi) {
    if (aqi <= 50) return 'Good';
    if (aqi <= 100) return 'Moderate';
    if (aqi <= 150) return 'Sensitive';
    if (aqi <= 200) return 'Unhealthy';
    if (aqi <= 300) return 'Very Poor';
    return 'Hazardous';
  }

  @override
  Widget build(BuildContext context) {
    final color = AppColors.aqiColor(aqi);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppShapes.borderRadiusSM,
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'AQI',
                style: AppTypography.labelSmall.copyWith(
                  color: color.withValues(alpha: 0.7),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$aqi',
                style: AppTypography.labelLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          Text(
            _aqiLabel(aqi),
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  WEATHER ROW
// ─────────────────────────────────────────────────────────────

class _WeatherRow extends StatelessWidget {
  const _WeatherRow({required this.weather});

  final WeatherModel weather;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: StatChip(
              icon: Icons.thermostat_rounded,
              label: 'Temp',
              value: '${weather.temperature.round()}°',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatChip(
              icon: Icons.water_drop_outlined,
              label: 'Humidity',
              value: '${weather.humidity}%',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatChip(
              icon: Icons.air_rounded,
              label: 'Wind',
              value: '${weather.windSpeed.toStringAsFixed(1)} m/s',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: StatChip(
              icon: Icons.wb_sunny_outlined,
              label: 'UV',
              value: weather.uvIndex.round().toString(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  HOURLY FORECAST ROW
// ─────────────────────────────────────────────────────────────

class _HourlyForecastRow extends StatelessWidget {
  const _HourlyForecastRow({required this.hours});

  final List<ForecastHourModel> hours;

  static IconData _weatherIcon(String iconCode) {
    switch (iconCode.replaceAll(RegExp(r'[dn]$'), '')) {
      case '01':
        return iconCode.endsWith('n')
            ? Icons.nightlight_round
            : Icons.wb_sunny_rounded;
      case '02':
        return Icons.cloud_queue_rounded;
      case '03':
      case '04':
        return Icons.cloud_rounded;
      case '09':
        return Icons.grain_rounded;
      case '10':
        return Icons.water_drop_rounded;
      case '11':
        return Icons.thunderstorm_rounded;
      case '13':
        return Icons.ac_unit_rounded;
      case '50':
        return Icons.foggy;
      default:
        return Icons.wb_cloudy_rounded;
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
    final hourFormat = DateFormat('ha');

    final displayHours = hours.length > AppConstants.forecastHours
        ? hours.sublist(0, AppConstants.forecastHours)
        : hours;

    return Padding(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: displayHours.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final hour = displayHours[index];
                final isNow = index == 0;
                final hasRain = hour.precipitationProbability > 0.1;
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isNow
                        ? AppColors.accent.withValues(alpha: 0.1)
                        : (isDark
                                  ? AppColors.darkSurfaceVariant
                                  : AppColors.lightSurfaceVariant)
                              .withValues(alpha: 0.5),
                    borderRadius: AppShapes.borderRadiusMD,
                    border: isNow
                        ? Border.all(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            width: 1,
                          )
                        : null,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isNow ? 'Now' : hourFormat.format(hour.dateTime),
                        style: AppTypography.labelSmall.copyWith(
                          color: isNow ? AppColors.accent : textSecondary,
                          fontWeight: isNow ? FontWeight.w700 : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        _weatherIcon(hour.iconCode),
                        size: 20,
                        color: isNow ? AppColors.accent : textSecondary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${hour.temperature.round()}°',
                        style: AppTypography.titleSmall.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (hasRain) ...[
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.water_drop,
                              size: 8,
                              color: AppColors.rain,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${(hour.precipitationProbability * 100).round()}%',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.rain,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  NO SAFE WINDOW CARD
// ─────────────────────────────────────────────────────────────

class _NoSafeWindowCard extends StatelessWidget {
  const _NoSafeWindowCard({required this.recommendation});

  final Recommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final isSafeNow = recommendation.type == RecommendationType.safeNow;
    final color = isSafeNow
        ? AppColors.goodPrimary
        : AppColors.unhealthyPrimary;
    final icon = isSafeNow ? Icons.check_circle_rounded : Icons.shield_outlined;
    final title = isSafeNow ? 'Air is safe right now' : 'No safe window today';
    final subtitle = isSafeNow
        ? 'Go ahead and enjoy outdoor activities.'
        : 'AQI is expected to remain elevated. Stay indoors if possible.';

    return FocusBlock(
      borderColor: color.withValues(alpha: 0.2),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: AppShapes.borderRadiusSM,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.titleSmall.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.labelMedium.copyWith(
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
//  RECOMMENDATION HEADLINE
// ─────────────────────────────────────────────────────────────

class _RecommendationHeadline extends StatelessWidget {
  const _RecommendationHeadline({required this.recommendation});

  final Recommendation recommendation;

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    final color = switch (recommendation.severity) {
      RecommendationSeverity.good => AppColors.goodPrimary,
      RecommendationSeverity.moderate => AppColors.moderatePrimary,
      RecommendationSeverity.warning => AppColors.usgPrimary,
      RecommendationSeverity.danger => AppColors.unhealthyPrimary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppShapes.borderRadiusMD,
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Icon(recommendation.icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation.headline,
                  style: AppTypography.titleSmall.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  recommendation.body,
                  style: AppTypography.bodySmall.copyWith(color: textSecondary),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
