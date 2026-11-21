import 'dart:math';
import 'package:geolocator/geolocator.dart';

/// Koordinat Lab Komputer 1, Gedung C Lantai 2, Fasilkom-TI USU, Medan.
const double kLabLat = 3.5621;
const double kLabLng = 98.6600;

/// Radius area presensi dalam meter.
const double kLabRadius = 50.0;

/// Service GPS untuk verifikasi lokasi presensi.
class LocationService {
  static final LocationService instance = LocationService._();
  LocationService._();

  /// Minta permission lokasi dan dapatkan posisi saat ini.
  /// Return null jika permission ditolak atau GPS mati.
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
    } catch (_) {
      return null;
    }
  }

  /// Hitung jarak (meter) antara dua titik koordinat menggunakan Haversine.
  static double distanceInMeters(
      double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0; // radius bumi meter
    final dLat = _rad(lat2 - lat1);
    final dLng = _rad(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_rad(lat1)) * cos(_rad(lat2)) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  static double _rad(double deg) => deg * pi / 180;

  /// Periksa apakah posisi ada di dalam radius lab.
  static bool isInsideLab(Position pos) {
    final d = distanceInMeters(pos.latitude, pos.longitude, kLabLat, kLabLng);
    return d <= kLabRadius;
  }

  /// Hitung jarak dari posisi ke lab (meter).
  static double distanceToLab(Position pos) =>
      distanceInMeters(pos.latitude, pos.longitude, kLabLat, kLabLng);
}
