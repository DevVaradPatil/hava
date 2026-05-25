import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:hava/core/core.dart';
import 'package:hava/data/models/location_model.dart';
import 'package:hava/providers/app_providers.dart';
import 'package:hava/services/location/location_service.dart';

/// Bottom sheet with debounced city search and GPS detection.
class CitySearchSheet extends ConsumerStatefulWidget {
  const CitySearchSheet({super.key});

  @override
  ConsumerState<CitySearchSheet> createState() => _CitySearchSheetState();
}

class _CitySearchSheetState extends ConsumerState<CitySearchSheet> {
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _detectingLocation = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(citySearchQueryProvider.notifier).state = value;
    });
  }

  Future<void> _detectLocation() async {
    setState(() => _detectingLocation = true);
    try {
      final loc = await LocationService().getCurrentLocation();
      if (mounted) Navigator.of(context).pop(loc);
    } on LocationServiceException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to detect location.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _detectingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.darkTextPrimary
        : AppColors.lightTextPrimary;
    final textSecondary = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;
    final resultsAsync = ref.watch(citySearchResultsProvider);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkGlass : AppColors.lightGlass,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                border: Border(
                  top: BorderSide(
                    color: isDark
                        ? AppColors.darkGlassBorder
                        : AppColors.lightGlassBorder,
                  ),
                ),
              ),
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkTextTertiary
                            : AppColors.lightTextTertiary,
                        borderRadius: AppShapes.borderRadiusFull,
                      ),
                    ),
                  ),
                  AppSpacing.verticalSM,
                  Text(
                    'Search City',
                    style: AppTypography.headlineMedium.copyWith(
                      color: textPrimary,
                    ),
                  ),
                  AppSpacing.verticalLG,
                  // GPS detect location button
                  ClipRRect(
                    borderRadius: AppShapes.borderRadiusMD,
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Material(
                        color: isDark
                            ? AppColors.darkGlass
                            : AppColors.lightGlass,
                        borderRadius: AppShapes.borderRadiusMD,
                        child: InkWell(
                          onTap: _detectingLocation ? null : _detectLocation,
                          borderRadius: AppShapes.borderRadiusMD,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            child: Row(
                              children: [
                                _detectingLocation
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppColors.accent,
                                        ),
                                      )
                                    : Icon(
                                        Icons.my_location_rounded,
                                        color: AppColors.accent,
                                        size: 20,
                                      ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _detectingLocation
                                        ? 'Detecting your location…'
                                        : 'Use current location',
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: textSecondary,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  AppSpacing.verticalMD,
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    onChanged: _onSearchChanged,
                    style: AppTypography.bodyLarge.copyWith(color: textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Enter city name...',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: textSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                  AppSpacing.verticalXL,
                  Expanded(
                    child: resultsAsync.when(
                      data: (results) {
                        if (_controller.text.trim().length < 2) {
                          return Center(
                            child: Text(
                              'Type at least 2 characters',
                              style: AppTypography.bodyMedium.copyWith(
                                color: textSecondary,
                              ),
                            ),
                          );
                        }
                        if (results.isEmpty) {
                          return Center(
                            child: Text(
                              'No cities found',
                              style: AppTypography.bodyMedium.copyWith(
                                color: textSecondary,
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          controller: scrollController,
                          itemCount: results.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: isDark
                                ? AppColors.darkDivider
                                : AppColors.lightDivider,
                          ),
                          itemBuilder: (context, index) {
                            final city = results[index];
                            final subtitleParts = <String>[];
                            if (city.state != null && city.state!.isNotEmpty) {
                              subtitleParts.add(city.state!);
                            }
                            if (city.country != null &&
                                city.country!.isNotEmpty) {
                              subtitleParts.add(city.country!);
                            }
                            final subtitle = subtitleParts.isNotEmpty
                                ? subtitleParts.join(', ')
                                : null;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 4,
                              ),
                              leading: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(
                                    alpha: 0.1,
                                  ),
                                  borderRadius: AppShapes.borderRadiusSM,
                                ),
                                child: Icon(
                                  Icons.location_on_outlined,
                                  size: 18,
                                  color: AppColors.accent,
                                ),
                              ),
                              title: Text(
                                city.city ??
                                    '${city.latitude}, ${city.longitude}',
                                style: AppTypography.titleSmall.copyWith(
                                  color: textPrimary,
                                ),
                              ),
                              subtitle: subtitle != null
                                  ? Text(
                                      subtitle,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: textSecondary,
                                      ),
                                    )
                                  : null,
                              shape: RoundedRectangleBorder(
                                borderRadius: AppShapes.borderRadiusSM,
                              ),
                              onTap: () => Navigator.of(context).pop(city),
                            );
                          },
                        );
                      },
                      loading: () => Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accent,
                        ),
                      ),
                      error: (err, _) => Center(
                        child: Text(
                          'Search failed',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

Future<LocationModel?> showCitySearchSheet(BuildContext context) {
  return showModalBottomSheet<LocationModel>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    showDragHandle: false,
    useSafeArea: true,
    builder: (_) => const CitySearchSheet(),
  );
}
