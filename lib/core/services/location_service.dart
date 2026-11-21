import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../config/app_config.dart';

/// Koordinat Lab Komputer 1, Gedung C Lantai 2, Fasilkom-TI USU, Medan.
const double kLabLat = 3.5621;
const double kLabLng = 98.6600;

/// Radius area presensi dalam meter.
const double kLabRadius = 50.0;

/// Service GPS dan Geocoding perangkat aktual.
class LocationService {
  static final LocationService instance = LocationService._();
  LocationService._();

  static const String _mapsApiKey = AppConfig.googleMapsApiKey;

  /// Mengambil posisi GPS aktual dari perangkat dengan akurasi tertinggi.
  Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationService] Layanan lokasi (GPS) tidak aktif.');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[LocationService] Izin lokasi ditolak oleh pengguna.');
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] Izin lokasi ditolak permanen.');
        return null;
      }

      // 1. Ambil posisi GPS terbaru dengan akurasi tinggi
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 0,
          forceLocationManager: false,
          intervalDuration: const Duration(seconds: 1),
          timeLimit: const Duration(seconds: 8),
        ),
      );
      debugPrint('[LocationService] GPS aktual: ${pos.latitude}, ${pos.longitude} (Akurasi: ±${pos.accuracy}m)');
      return pos;
    } catch (e) {
      debugPrint('[LocationService] getCurrentPosition error: $e. Fallback ke lastKnownPosition...');
      try {
        final last = await Geolocator.getLastKnownPosition();
        if (last != null) {
          debugPrint('[LocationService] Menggunakan lastKnownPosition: ${last.latitude}, ${last.longitude}');
        }
        return last;
      } catch (_) {
        return null;
      }
    }
  }

  /// Hitung jarak (meter) antara dua titik koordinat menggunakan formula Haversine.
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

  /// Periksa apakah posisi berada dalam radius 50 meter dari lab.
  static bool isInsideLab(Position pos) {
    final d = distanceInMeters(pos.latitude, pos.longitude, kLabLat, kLabLng);
    return d <= kLabRadius;
  }

  /// Hitung jarak dari posisi ke lab (meter).
  static double distanceToLab(Position pos) =>
      distanceInMeters(pos.latitude, pos.longitude, kLabLat, kLabLng);

  /// Reverse Geocoding real-time menggunakan Google Maps Geocoding API & fallback Nominatim.
  Future<({String title, String detail})> getAddress(
      double lat, double lng) async {
    // 1. Jika berada dalam radius 50m dari Lab Komputer 1
    final dist = distanceInMeters(lat, lng, kLabLat, kLabLng);
    if (dist <= kLabRadius) {
      return (
        title: 'Lab Komputer 1, Gedung C Lantai 2',
        detail: 'Fasilkom-TI USU, Jl. Alumni, Padang Bulan, Medan',
      );
    }

    // 2. Real-time Geocoding via Google Maps Geocoding API
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
          String subdistrict = '';
          String district = '';
          String city = '';
          final components = first['address_components'] as List? ?? [];
          for (final c in components) {
            final types = (c['types'] as List).cast<String>();
            if (types.contains('route') || types.contains('point_of_interest')) {
              street = c['long_name'] as String;
            }
            if (types.contains('administrative_area_level_4') ||
                types.contains('sublocality')) {
              subdistrict = c['long_name'] as String;
            }
            if (types.contains('administrative_area_level_3')) {
              district = c['long_name'] as String;
            }
            if (types.contains('administrative_area_level_2')) {
              city = c['long_name'] as String;
            }
          }

          final title = street.isNotEmpty ? street : 'Lokasi Terdeteksi';
          final details = <String>[];
          if (subdistrict.isNotEmpty) details.add(subdistrict);
          if (district.isNotEmpty) details.add(district);
          if (city.isNotEmpty) details.add(city);
          final detailText =
              details.isNotEmpty ? details.join(', ') : formatted;

          debugPrint('[LocationService] Google Geocoded: $title • $detailText');
          return (title: title, detail: detailText);
        }
      }
    } catch (e) {
      debugPrint('[LocationService] Google Geocoding error: $e');
    }

    // 3. Fallback ke Nominatim OpenStreetMap
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json&accept-language=id',
      );
      final client = HttpClient();
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'ITLGMobileApp/1.0');
      final response =
          await request.close().timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          final road = address['road'] as String? ??
              address['amenity'] as String? ??
              address['suburb'] as String? ??
              'Lokasi Terdeteksi';

          final sub = address['suburb'] as String?;
          final district = address['city_district'] as String?;
          final city = address['city'] as String? ?? 'Kota Medan';
          final state = address['state'] as String? ?? 'Sumatera Utara';

          final details = <String>[];
          if (sub != null && sub != road) details.add(sub);
          if (district != null) details.add(district);
          details.add(city);
          details.add(state);

          final detailText = details.join(', ');
          debugPrint('[LocationService] Nominatim Geocoded: $road • $detailText');
          return (title: road, detail: detailText);
        }
      }
    } catch (e) {
      debugPrint('[LocationService] Nominatim error: $e');
    }

    // 4. Fallback jika offline
    return (
      title: 'Lokasi Perangkat Anda',
      detail: 'Koordinat: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}',
    );
  }
}
