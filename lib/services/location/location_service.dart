import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';

import 'package:hava/data/models/location_model.dart';

/// Service for obtaining the device's GPS location.
class LocationService {
  /// Checks and requests location permissions, then returns the current
  /// position as a [LocationModel].
  ///
  /// Performs **reverse geocoding** so the returned model includes
  /// a human-readable city and country name.
  ///
  /// Throws a [LocationServiceException] on failure.
  Future<LocationModel> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceException('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationServiceException('Location permission denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationServiceException(
        'Location permission permanently denied. '
        'Please enable it in app settings.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );

    // Reverse-geocode to get city name.
    String? city;
    String? state;
    String? country;
    try {
      final placemarks = await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        city = place.locality?.isNotEmpty == true
            ? place.locality
            : place.subAdministrativeArea;
        state = place.administrativeArea;
        country = place.isoCountryCode ?? place.country;
      }
    } catch (_) {
      // Reverse geocoding failed — we still have coordinates.
    }

    return LocationModel(
      latitude: position.latitude,
      longitude: position.longitude,
      city: city,
      state: state,
      country: country,
    );
  }

  /// Returns `true` if the app already has location permission.
  Future<bool> hasPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }
}

/// Exception thrown by [LocationService].
class LocationServiceException implements Exception {
  LocationServiceException(this.message);
  final String message;

  @override
  String toString() => 'LocationServiceException: $message';
}
