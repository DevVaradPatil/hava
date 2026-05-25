/// Represents air quality data (from IQAir or OpenWeatherMap).
class AqiModel {
  /// US AQI value (0 – 500+).
  final int aqi;

  /// Dominant pollutant key (e.g. "p2", "p1", "o3").
  final String dominantPollutant;

  /// Individual pollutant concentrations (µg/m³).
  final double? pm25;
  final double? pm10;
  final double? o3;
  final double? no2;
  final double? so2;
  final double? co;

  final DateTime dateTime;

  const AqiModel({
    required this.aqi,
    required this.dominantPollutant,
    this.pm25,
    this.pm10,
    this.o3,
    this.no2,
    this.so2,
    this.co,
    required this.dateTime,
  });

  // ────────────────────────────────────────────
  //  IQAir parsing
  // ────────────────────────────────────────────

  /// Parses the **current** pollution block from the IQAir
  /// `/v2/nearest_city` response.
  ///
  /// ```json
  /// { "data": { "current": { "pollution": { "aqius": 18, "mainus": "p2", ... } } } }
  /// ```
  factory AqiModel.fromIqAirJson(Map<String, dynamic> json) {
    final pollution =
        json['data']?['current']?['pollution'] as Map<String, dynamic>? ?? {};

    // Extract concentration from an individual pollutant block if present.
    double? conc(String key) {
      final block = pollution[key];
      if (block is Map) return (block['conc'] as num?)?.toDouble();
      return null;
    }

    return AqiModel(
      aqi: (pollution['aqius'] as num?)?.toInt() ?? 0,
      dominantPollutant: _iqAirPollutantLabel(
        (pollution['mainus'] as String?) ?? 'p2',
      ),
      pm25: conc('p2'),
      pm10: conc('p1'),
      o3: conc('o3'),
      no2: conc('n2'),
      so2: conc('s2'),
      co: conc('co'),
      dateTime:
          DateTime.tryParse(pollution['ts']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  /// Parses a single **forecast** entry from the IQAir response.
  ///
  /// ```json
  /// { "ts": "…", "aqius": 21, "pm25": 66.96, "pm10": 183.05, … }
  /// ```
  factory AqiModel.fromIqAirForecastJson(Map<String, dynamic> json) {
    return AqiModel(
      aqi: (json['aqius'] as num?)?.toInt() ?? 0,
      dominantPollutant: 'pm25',
      pm25: (json['pm25'] as num?)?.toDouble(),
      pm10: (json['pm10'] as num?)?.toDouble(),
      dateTime:
          DateTime.tryParse(json['ts']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  // ────────────────────────────────────────────
  //  OpenWeatherMap parsing (fallback)
  // ────────────────────────────────────────────

  /// Parses the `/data/2.5/air_pollution` response.
  ///
  /// **Important**: OpenWeatherMap returns a 1-5 European index, not
  /// US AQI. We convert PM2.5 concentration to US AQI via EPA
  /// breakpoints; falls back to a rough mapping when PM2.5 is absent.
  factory AqiModel.fromOpenWeatherJson(Map<String, dynamic> json) {
    final list = (json['list'] as List?)?.isNotEmpty == true
        ? json['list'][0]
        : <String, dynamic>{};
    final components = list['components'] ?? {};
    final pm25 = (components['pm2_5'] as num?)?.toDouble();
    final europeanIndex = (list['main']?['aqi'] as num?)?.toInt() ?? 0;

    final usAqi = pm25 != null
        ? pm25ToUsAqi(pm25)
        : europeanToApproxUsAqi(europeanIndex);

    return AqiModel(
      aqi: usAqi,
      dominantPollutant: 'pm25',
      pm25: pm25,
      pm10: (components['pm10'] as num?)?.toDouble(),
      o3: (components['o3'] as num?)?.toDouble(),
      no2: (components['no2'] as num?)?.toDouble(),
      so2: (components['so2'] as num?)?.toDouble(),
      co: (components['co'] as num?)?.toDouble(),
      dateTime: DateTime.fromMillisecondsSinceEpoch(
        ((list['dt'] as num?)?.toInt() ?? 0) * 1000,
      ),
    );
  }

  // ────────────────────────────────────────────
  //  Serialisation
  // ────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
    'aqi': aqi,
    'dominant_pollutant': dominantPollutant,
    'pm25': pm25,
    'pm10': pm10,
    'o3': o3,
    'no2': no2,
    'so2': so2,
    'co': co,
    'dt': dateTime.millisecondsSinceEpoch ~/ 1000,
  };

  // ────────────────────────────────────────────
  //  Helpers
  // ────────────────────────────────────────────

  /// Human-readable label for an IQAir pollutant code.
  static String _iqAirPollutantLabel(String code) {
    switch (code) {
      case 'p2':
        return 'pm25';
      case 'p1':
        return 'pm10';
      case 'o3':
        return 'o3';
      case 'n2':
        return 'no2';
      case 's2':
        return 'so2';
      case 'co':
        return 'co';
      default:
        return code;
    }
  }

  // ────────────────────────────────────────────
  //  EPA PM2.5 → US AQI conversion (OWM fallback)
  // ────────────────────────────────────────────

  /// EPA breakpoints: (C_lo, C_hi, I_lo, I_hi).
  static const List<(double, double, int, int)> pm25Breakpoints = [
    (0.0, 12.0, 0, 50),
    (12.1, 35.4, 51, 100),
    (35.5, 55.4, 101, 150),
    (55.5, 150.4, 151, 200),
    (150.5, 250.4, 201, 300),
    (250.5, 350.4, 301, 400),
    (350.5, 500.4, 401, 500),
  ];

  static int pm25ToUsAqi(double concentration) {
    for (final (cLo, cHi, iLo, iHi) in pm25Breakpoints) {
      if (concentration >= cLo && concentration <= cHi) {
        return (((iHi - iLo) / (cHi - cLo)) * (concentration - cLo) + iLo)
            .round();
      }
    }
    return 500;
  }

  /// Rough fallback mapping from the OpenWeatherMap 1-5 European index
  /// to a representative US AQI value.
  static int europeanToApproxUsAqi(int index) {
    switch (index) {
      case 1:
        return 25;
      case 2:
        return 65;
      case 3:
        return 120;
      case 4:
        return 175;
      case 5:
        return 275;
      default:
        return 0;
    }
  }
}

/// Container returned by [AqiApiService.fetchFullAqiData] so both
/// current and forecast AQI can come from a single IQAir API call.
class IqAirFullData {
  const IqAirFullData({required this.current, required this.forecast});
  final AqiModel current;
  final List<AqiModel> forecast;
}
