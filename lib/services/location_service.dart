import 'package:geolocator/geolocator.dart';

class LocationService {
  static const _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.bestForNavigation,
    distanceFilter: 5,
  );

  static Stream<Position> get positionStream =>
      Geolocator.getPositionStream(locationSettings: _locationSettings);

  static Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<bool> isLocationServiceEnabled() =>
      Geolocator.isLocationServiceEnabled();

  static Future<LocationPermission> checkPermission() =>
      Geolocator.checkPermission();

  static Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  static double distanceBetween(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) =>
      Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
}
