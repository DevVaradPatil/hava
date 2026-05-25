import 'package:flutter/material.dart';

// ──────────────────────────────────────────────
//  Gear Advisor — contextual gear suggestions
// ──────────────────────────────────────────────

/// A single gear recommendation.
class GearItem {
  const GearItem({
    required this.icon,
    required this.label,
    required this.reason,
    required this.priority,
  });

  /// Icon displayed on the chip.
  final IconData icon;

  /// Short label, e.g. "Wear N95 Mask".
  final String label;

  /// Longer explanation shown on tap.
  final String reason;

  /// Higher = more critical (used for sorting).
  final int priority;
}

/// Produces contextual gear suggestions based on current weather + AQI.
class GearAdvisor {
  const GearAdvisor();

  /// Returns a list of gear suggestions (may be empty if conditions are ideal).
  List<GearItem> suggest({
    required int aqi,
    required double temperature,
    required double feelsLike,
    required int humidity,
    required double uvIndex,
    required double windSpeed,
    required double precipitationProbability,
  }) {
    final items = <GearItem>[];

    // ── Air Quality gear ──
    if (aqi > 200) {
      items.add(
        const GearItem(
          icon: Icons.masks_rounded,
          label: 'Wear N95 Mask',
          reason:
              'AQI is above 200 — very unhealthy. An N95 mask filters fine particulate matter and protects your lungs.',
          priority: 100,
        ),
      );
    } else if (aqi > 150) {
      items.add(
        const GearItem(
          icon: Icons.masks_rounded,
          label: 'Wear N95 Mask',
          reason:
              'AQI is above 150 — unhealthy for everyone. A mask significantly reduces particulate inhalation.',
          priority: 90,
        ),
      );
    } else if (aqi > 100) {
      items.add(
        const GearItem(
          icon: Icons.masks_outlined,
          label: 'Consider a Mask',
          reason:
              'AQI is above 100 — unhealthy for sensitive groups. A mask can help if you have respiratory conditions.',
          priority: 60,
        ),
      );
    }

    // ── UV Protection ──
    if (uvIndex >= 8) {
      items.add(
        const GearItem(
          icon: Icons.wb_sunny_rounded,
          label: 'SPF 50+ Sunscreen',
          reason:
              'UV index is very high. Apply broad-spectrum SPF 50+ and reapply every 2 hours. Wear a hat and sunglasses.',
          priority: 85,
        ),
      );
    } else if (uvIndex >= 6) {
      items.add(
        const GearItem(
          icon: Icons.wb_sunny_outlined,
          label: 'Apply Sunscreen',
          reason:
              'UV index is high. Apply SPF 30+ sunscreen and consider wearing a hat.',
          priority: 70,
        ),
      );
    } else if (uvIndex >= 3) {
      items.add(
        const GearItem(
          icon: Icons.wb_sunny_outlined,
          label: 'Sunglasses',
          reason:
              'UV index is moderate. Sunglasses will protect your eyes during extended outdoor time.',
          priority: 30,
        ),
      );
    }

    // ── Rain gear ──
    if (precipitationProbability >= 0.7) {
      items.add(
        const GearItem(
          icon: Icons.umbrella_rounded,
          label: 'Carry Umbrella',
          reason:
              'High chance of rain. Bring an umbrella or rain jacket to stay dry.',
          priority: 80,
        ),
      );
    } else if (precipitationProbability >= 0.4) {
      items.add(
        const GearItem(
          icon: Icons.umbrella_outlined,
          label: 'Pack an Umbrella',
          reason:
              'Moderate chance of rain. It\'s wise to pack rain protection just in case.',
          priority: 50,
        ),
      );
    }

    // ── Heat protection ──
    if (feelsLike >= 40) {
      items.add(
        const GearItem(
          icon: Icons.local_drink_rounded,
          label: 'Stay Hydrated!',
          reason:
              'Heat index is extreme. Drink water every 15-20 minutes. Avoid prolonged outdoor exertion.',
          priority: 95,
        ),
      );
    } else if (feelsLike >= 35) {
      items.add(
        const GearItem(
          icon: Icons.local_drink_outlined,
          label: 'Stay Hydrated',
          reason:
              'It feels very hot outside. Carry extra water and take frequent shade breaks.',
          priority: 75,
        ),
      );
    } else if (feelsLike >= 30) {
      items.add(
        const GearItem(
          icon: Icons.water_drop_outlined,
          label: 'Bring Water',
          reason:
              'Warm conditions — bring a water bottle and stay in shade when possible.',
          priority: 40,
        ),
      );
    }

    // ── Cold gear ──
    if (temperature <= -10) {
      items.add(
        const GearItem(
          icon: Icons.ac_unit_rounded,
          label: 'Heavy Winter Gear',
          reason:
              'Extreme cold! Wear insulated layers, thermal gloves, and a face cover to prevent frostbite.',
          priority: 95,
        ),
      );
    } else if (temperature <= 0) {
      items.add(
        const GearItem(
          icon: Icons.ac_unit_rounded,
          label: 'Dress Warmly',
          reason:
              'Freezing temperatures — layer up with a warm jacket, gloves, and a hat.',
          priority: 70,
        ),
      );
    } else if (temperature <= 10) {
      items.add(
        const GearItem(
          icon: Icons.checkroom_rounded,
          label: 'Wear a Jacket',
          reason:
              'It\'s chilly outside. A jacket or sweater will keep you comfortable.',
          priority: 35,
        ),
      );
    }

    // ── Wind gear ──
    if (windSpeed >= 15) {
      items.add(
        const GearItem(
          icon: Icons.air_rounded,
          label: 'Windbreaker',
          reason:
              'Very windy conditions. A windbreaker jacket helps reduce wind chill and protects exposed skin.',
          priority: 65,
        ),
      );
    } else if (windSpeed >= 10) {
      items.add(
        const GearItem(
          icon: Icons.air_outlined,
          label: 'Light Windbreaker',
          reason:
              'Breezy conditions. A light wind-resistant layer adds comfort during extended outdoor time.',
          priority: 35,
        ),
      );
    }

    // ── Humidity advisory ──
    if (humidity >= 85 && temperature >= 28) {
      items.add(
        const GearItem(
          icon: Icons.water_rounded,
          label: 'Moisture-Wicking Clothes',
          reason:
              'High humidity combined with heat makes sweat evaporation difficult. Wear light, moisture-wicking fabrics.',
          priority: 55,
        ),
      );
    }

    // Sort by priority (highest first).
    items.sort((a, b) => b.priority.compareTo(a.priority));

    return items;
  }
}
