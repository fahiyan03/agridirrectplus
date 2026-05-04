import 'package:geolocator/geolocator.dart';
import 'dart:math';

class LocationService {

  Future<Position?> getCurrentPosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      // FIX: locationSettings এর বদলে desiredAccuracy - geolocator ^11 compatible
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      return null;
    }
  }

  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);
    return R * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  double _toRad(double deg) => deg * (pi / 180);

  int getZoneByDistance(double distanceKm) {
    if (distanceKm <= 2)  return 1;
    if (distanceKm <= 7)  return 2;
    if (distanceKm <= 30) return 3;
    return 4;
  }

  List<Map<String, dynamic>> filterNearbyProducts({
    required List<Map<String, dynamic>> products,
    required double userLat,
    required double userLon,
    required double radiusKm,
  }) {
    return products.where((product) {
      final lat = product['latitude']  as double?;
      final lon = product['longitude'] as double?;
      if (lat == null || lon == null) return false;
      return calculateDistance(userLat, userLon, lat, lon) <= radiusKm;
    }).toList();
  }

  String getDistanceText(double distanceKm) {
    if (distanceKm < 1) return '${(distanceKm * 1000).toStringAsFixed(0)} মিটার';
    return '${distanceKm.toStringAsFixed(1)} কিমি';
  }

  Future<bool> hasPermission() async {
    final p = await Geolocator.checkPermission();
    return p == LocationPermission.always || p == LocationPermission.whileInUse;
  }

  Future<bool> isLocationEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }
}