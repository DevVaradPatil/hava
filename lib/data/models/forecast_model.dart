/// Represents one hour in a forecast.
class ForecastHourModel {
  final DateTime dateTime;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final double uvIndex;
  final int cloudiness;
  final double precipitationProbability; // 0.0 – 1.0
  final String description;
  final String iconCode;

  /// AQI value for this hour (may be null if unavailable).
  final int? aqi;

  const ForecastHourModel({
    required this.dateTime,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.uvIndex,
    required this.cloudiness,
    required this.precipitationProbability,
    required this.description,
    required this.iconCode,
    this.aqi,
  });

  factory ForecastHourModel.fromJson(Map<String, dynamic> json) {
    return ForecastHourModel(
      dateTime: DateTime.fromMillisecondsSinceEpoch(
        ((json['dt'] as num).toInt()) * 1000,
      ),
      temperature: (json['temp'] as num).toDouble(),
      feelsLike: (json['feels_like'] as num).toDouble(),
      humidity: (json['humidity'] as num).toInt(),
      windSpeed: (json['wind_speed'] as num).toDouble(),
      uvIndex: (json['uvi'] as num?)?.toDouble() ?? 0,
      cloudiness: (json['clouds'] as num?)?.toInt() ?? 0,
      precipitationProbability: (json['pop'] as num?)?.toDouble() ?? 0,
      description: (json['weather'] as List?)?.isNotEmpty == true
          ? (json['weather'][0]['description'] as String?) ?? ''
          : '',
      iconCode: (json['weather'] as List?)?.isNotEmpty == true
          ? (json['weather'][0]['icon'] as String?) ?? '01d'
          : '01d',
      aqi: json['aqi'] as int?,
    );
  }

  /// Parses one entry from the `/data/2.5/forecast` free-tier response.
  factory ForecastHourModel.fromFreeJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>? ?? {};
    final wind = json['wind'] as Map<String, dynamic>? ?? {};
    final clouds = json['clouds'] as Map<String, dynamic>? ?? {};
    final weather = json['weather'] as List<dynamic>? ?? [];

    return ForecastHourModel(
      dateTime: DateTime.fromMillisecondsSinceEpoch(
        ((json['dt'] as num).toInt()) * 1000,
      ),
      temperature: (main['temp'] as num?)?.toDouble() ?? 0,
      feelsLike: (main['feels_like'] as num?)?.toDouble() ?? 0,
      humidity: (main['humidity'] as num?)?.toInt() ?? 0,
      windSpeed: (wind['speed'] as num?)?.toDouble() ?? 0,
      uvIndex: 0, // not available in free endpoint
      cloudiness: (clouds['all'] as num?)?.toInt() ?? 0,
      precipitationProbability: (json['pop'] as num?)?.toDouble() ?? 0,
      description: weather.isNotEmpty
          ? (weather[0]['description'] as String?) ?? ''
          : '',
      iconCode: weather.isNotEmpty
          ? (weather[0]['icon'] as String?) ?? '01d'
          : '01d',
    );
  }

  /// Creates a copy with an AQI overlay.
  ForecastHourModel copyWithAqi(int? aqi) => ForecastHourModel(
    dateTime: dateTime,
    temperature: temperature,
    feelsLike: feelsLike,
    humidity: humidity,
    windSpeed: windSpeed,
    uvIndex: uvIndex,
    cloudiness: cloudiness,
    precipitationProbability: precipitationProbability,
    description: description,
    iconCode: iconCode,
    aqi: aqi,
  );

  /// Returns a copy with the given [uvIndex] overridden.
  ForecastHourModel copyWithUvIndex(double uvIndex) => ForecastHourModel(
    dateTime: dateTime,
    temperature: temperature,
    feelsLike: feelsLike,
    humidity: humidity,
    windSpeed: windSpeed,
    uvIndex: uvIndex,
    cloudiness: cloudiness,
    precipitationProbability: precipitationProbability,
    description: description,
    iconCode: iconCode,
    aqi: aqi,
  );
}
