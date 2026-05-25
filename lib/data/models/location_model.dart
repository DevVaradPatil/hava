/// Represents a geographical location (from GPS or manual city search).
class LocationModel {
  final double latitude;
  final double longitude;
  final String? city;
  final String? state;
  final String? country;

  const LocationModel({
    required this.latitude,
    required this.longitude,
    this.city,
    this.state,
    this.country,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    final lat = json['lat'] ?? json['latitude'];
    final lon = json['lon'] ?? json['longitude'];
    
    return LocationModel(
      latitude: (lat as num).toDouble(),
      longitude: (lon as num).toDouble(),
      city: (json['name'] ?? json['city']) as String?,
      state: json['state'] as String?,
      country: json['country'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'lat': latitude,
    'lon': longitude,
    'name': city,
    'state': state,
    'country': country,
  };

  /// Human-readable name for display (e.g. "Kanpur, Uttar Pradesh, IN").
  String get displayName {
    final parts = <String>[];
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (state != null && state!.isNotEmpty) parts.add(state!);
    if (country != null && country!.isNotEmpty) parts.add(country!);
    return parts.isNotEmpty ? parts.join(', ') : '$latitude, $longitude';
  }

  /// Key used for deduplication — lowercase "city|state|country".
  String get _deduplicationKey {
    return [
      (city ?? '').toLowerCase().trim(),
      (state ?? '').toLowerCase().trim(),
      (country ?? '').toLowerCase().trim(),
    ].join('|');
  }

  /// Removes duplicate entries that share the same city + state + country,
  /// keeping the first (most relevant) result from the geocoding API.
  static List<LocationModel> deduplicate(List<LocationModel> locations) {
    final seen = <String>{};
    return locations.where((loc) => seen.add(loc._deduplicationKey)).toList();
  }
}
