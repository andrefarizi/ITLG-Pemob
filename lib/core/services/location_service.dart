import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Koordinat Lab Komputer 1, Gedung C Lantai 2, Fasilkom-TI USU, Medan.
const double kLabLat = 3.5621;
const double kLabLng = 98.6600;

/// Radius area presensi dalam meter.
const double kLabRadius = 50.0;

/// Service GPS dan Geocoding untuk presensi akurat.
class LocationService {
  static final LocationService instance = LocationService._();
  LocationService._();

  static const String _mapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  /// Minta permission lokasi dan dapatkan posisi saat ini dengan akurasi terbaik.
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    // 1. Coba ambil posisi akurasi tinggi terkini
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
          forceLocationManager: false,
          intervalDuration: const Duration(seconds: 1),
          timeLimit: const Duration(seconds: 7),
        ),
      );
      return pos;
    } catch (_) {
      // 2. Fallback cepat ke last known position jika timeout
      try {
        return await Geolocator.getLastKnownPosition();
      } catch (_) {
        return null;
      }
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

  /// Periksa apakah posisi ada di dalam radius lab (<= 50m).
  static bool isInsideLab(Position pos) {
    final d = distanceInMeters(pos.latitude, pos.longitude, kLabLat, kLabLng);
    return d <= kLabRadius;
  }

  /// Hitung jarak dari posisi ke lab (meter).
  static double distanceToLab(Position pos) =>
      distanceInMeters(pos.latitude, pos.longitude, kLabLat, kLabLng);

  /// Mengambil nama jalan dan detail alamat akurat berdasarkan koordinat GPS.
  Future<({String title, String detail})> getAddress(
      double lat, double lng) async {
    // Jika berada dalam radius 50m dari Lab Komputer 1
    final dist = distanceInMeters(lat, lng, kLabLat, kLabLng);
    if (dist <= kLabRadius) {
      return (
        title: 'Lab Komputer 1, Gedung C Lantai 2',
        detail: 'Fasilkom-TI USU, Jl. Alumni, Padang Bulan, Medan',
      );
    }

    // Coba Reverse Geocoding via Google Geocoding API resmi
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$_mapsApiKey&language=id',
      );
      final client = HttpClient();
      final request = await client.getUrl(url);
      final response =
          await request.close().timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        if (data['status'] == 'OK' &&
            (data['results'] as List?)?.isNotEmpty == true) {
          final results = data['results'] as List;
          final first = results.first as Map<String, dynamic>;
          final formatted = first['formatted_address'] as String? ?? '';

          String street = '';
          final components = first['address_components'] as List? ?? [];
          for (final c in components) {
            final types = (c['types'] as List).cast<String>();
            if (types.contains('route') ||
                types.contains('point_of_interest') ||
                types.contains('premise')) {
              street = c['long_name'] as String;
              break;
            }
          }

          final title = street.isNotEmpty
              ? street
              : 'Jl. Dr. Mansyur, Padang Bulan';
          final detail = formatted.isNotEmpty
              ? formatted
              : 'Kec. Medan Baru, Kota Medan, Sumatera Utara';
          return (title: title, detail: detail);
        }
      }
    } catch (e) {
      debugPrint('[LocationService] Geocoding API offline/timeout: $e');
    }

    // Fallback cerdas berdasarkan zona wilayah
    // Wilayah Jl. Dr. Mansyur (Fore Coffee Mansyur & sekitar kampus USU)
    if (lat >= 3.564 && lat <= 3.575 && lng >= 98.650 && lng <= 98.665) {
      return (
        title: 'Jl. Dr. Mansyur, Padang Bulan',
        detail: 'Fore Coffee, Jl. Dr. Mansyur, Medan',
      );
    }

    return (
      title: 'Jl. Dr. Mansyur, Padang Bulan',
      detail: 'Kec. Medan Baru, Kota Medan, Sumatera Utara',
    );
  }
}
