/// Represents current weather conditions from OpenWeatherMap.
class WeatherModel {
  final double temperature; // Celsius (metric)
  final double feelsLike;
  final int humidity; // 0-100 %
  final double windSpeed; // m/s
  final int windDeg;
  final double uvIndex;
  final String description;
  final String iconCode; // e.g. "01d"
  final int cloudiness; // 0-100 %
  final int visibility; // metres
  final DateTime dateTime;

  const WeatherModel({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.windDeg,
    required this.uvIndex,
    required this.description,
    required this.iconCode,
    required this.cloudiness,
    required this.visibility,
    required this.dateTime,
  });

  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      temperature: (json['temp'] as num).toDouble(),
      feelsLike: (json['feels_like'] as num).toDouble(),
      humidity: (json['humidity'] as num).toInt(),
      windSpeed: (json['wind_speed'] as num).toDouble(),
      windDeg: (json['wind_deg'] as num?)?.toInt() ?? 0,
      uvIndex: (json['uvi'] as num?)?.toDouble() ?? 0,
      description: (json['weather'] as List?)?.isNotEmpty == true
          ? (json['weather'][0]['description'] as String?) ?? ''
          : (json['description'] as String?) ?? '',
      iconCode: (json['weather'] as List?)?.isNotEmpty == true
          ? (json['weather'][0]['icon'] as String?) ?? '01d'
          : (json['icon'] as String?) ?? '01d',
      cloudiness: ((json['clouds'] is Map) 
          ? (json['clouds']['all'] as num?) 
          : (json['clouds'] as num?))?.toInt() ?? 0,
      visibility: (json['visibility'] as num?)?.toInt() ?? 10000,
      dateTime: DateTime.fromMillisecondsSinceEpoch(
        ((json['dt'] as num).toInt()) * 1000,
      ),
    );
  }

  /// Parses the `/data/2.5/weather` free-tier response.
  factory WeatherModel.fromFreeJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>? ?? {};
    final wind = json['wind'] as Map<String, dynamic>? ?? {};
    final clouds = json['clouds'] as Map<String, dynamic>? ?? {};
    final weather = json['weather'] as List<dynamic>? ?? [];

    return WeatherModel(
      temperature: (main['temp'] as num?)?.toDouble() ?? 0,
      feelsLike: (main['feels_like'] as num?)?.toDouble() ?? 0,
      humidity: (main['humidity'] as num?)?.toInt() ?? 0,
      windSpeed: (wind['speed'] as num?)?.toDouble() ?? 0,
      windDeg: (wind['deg'] as num?)?.toInt() ?? 0,
      uvIndex: 0, // not available in free endpoint
      description: weather.isNotEmpty
          ? (weather[0]['description'] as String?) ?? ''
          : '',
      iconCode: weather.isNotEmpty
          ? (weather[0]['icon'] as String?) ?? '01d'
          : '01d',
      cloudiness: (clouds['all'] as num?)?.toInt() ?? 0,
      visibility: (json['visibility'] as num?)?.toInt() ?? 10000,
      dateTime: DateTime.fromMillisecondsSinceEpoch(
        ((json['dt'] as num?)?.toInt() ?? 0) * 1000,
      ),
    );
  }

  /// Returns a copy with the given [uvIndex] overridden.
  WeatherModel copyWithUvIndex(double uvIndex) => WeatherModel(
    temperature: temperature,
    feelsLike: feelsLike,
    humidity: humidity,
    windSpeed: windSpeed,
    windDeg: windDeg,
    uvIndex: uvIndex,
    description: description,
    iconCode: iconCode,
    cloudiness: cloudiness,
    visibility: visibility,
    dateTime: dateTime,
  );

  Map<String, dynamic> toJson() => {
    'temp': temperature,
    'feels_like': feelsLike,
    'humidity': humidity,
    'wind_speed': windSpeed,
    'wind_deg': windDeg,
    'uvi': uvIndex,
    'description': description,
    'icon': iconCode,
    'clouds': cloudiness,
    'visibility': visibility,
    'dt': dateTime.millisecondsSinceEpoch ~/ 1000,
  };
}
