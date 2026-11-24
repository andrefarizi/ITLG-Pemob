import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../config/app_config.dart';

/// Koordinat cadangan (Lab Jaringan 1, Gedung C Lantai 2, Fasilkom-TI USU)
/// bila sesi tidak membawa koordinat lab. Titik sebenarnya diambil dari sesi
/// presensi yang dibuka Aslab (tabel `labs` → `attendance_sessions.lat/lng`).
const double kLabLat = 3.5621;
const double kLabLng = 98.6600;

/// Radius cadangan area presensi dalam meter.
const double kLabRadius = 50.0;

/// Akurasi GPS terburuk yang masih diterima untuk presensi (meter). Posisi
/// dari jaringan/IP (ratusan meter) tidak cukup untuk membuktikan berada di lab.
const double kMaxGpsAccuracy = 100.0;

/// Umur maksimal posisi terakhir yang tersimpan di perangkat. Posisi lama
/// (mis. saat masih di lab tadi pagi) tidak boleh dipakai untuk presensi.
const Duration kMaxLastKnownAge = Duration(minutes: 2);

/// Service GPS real-time dan Reverse Geocoding perangkat aktual.
class LocationService {
  static final LocationService instance = LocationService._();
  LocationService._();

  static const MethodChannel _configChannel =
      MethodChannel('com.example.itlg_mobile/config');

  String? _resolvedMapsApiKey;
  bool? _cachedIsEmulator;

  Future<bool> _isAndroidEmulator() async {
    if (_cachedIsEmulator != null) return _cachedIsEmulator!;
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final v = await _configChannel.invokeMethod<bool>('isEmulator');
        _cachedIsEmulator = v ?? false;
        return _cachedIsEmulator!;
      } catch (_) {}
    }
    _cachedIsEmulator = false;
    return false;
  }

  /// Deteksi koordinat default bawaan Android Emulator (Googleplex, California)
  bool _isDefaultGoogleplex(Position pos) {
    return distanceInMeters(pos.latitude, pos.longitude, 37.421998, -122.084) <
        5000.0;
  }

  /// Fallback otomatis berbasis Google Geolocation API / IP khusus untuk
  Future<Position?> _fetchNetworkFallbackPosition() async {
    final apiKey = await _getMapsApiKey();
    if (apiKey.isNotEmpty) {
      try {
        final url = Uri.parse(
          'https://www.googleapis.com/geolocation/v1/geolocate?key=$apiKey',
        );
        final client = HttpClient();
        final req = await client.postUrl(url);
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode({'considerIp': true}));
        final res = await req.close().timeout(const Duration(seconds: 5));
        if (res.statusCode == 200) {
          final body = await res.transform(utf8.decoder).join();
          final data = jsonDecode(body) as Map<String, dynamic>;
          final loc = data['location'] as Map<String, dynamic>?;
          final lat = (loc?['lat'] as num?)?.toDouble();
          final lng = (loc?['lng'] as num?)?.toDouble();
          final acc = (data['accuracy'] as num?)?.toDouble() ?? 50.0;
          if (lat != null && lng != null) {
            debugPrint(
                '[LocationService] Emulator fallback Google Geolocation: $lat, $lng (±${acc}m)');
            return Position(
              longitude: lng,
              latitude: lat,
              timestamp: DateTime.now(),
              accuracy: acc,
              altitude: 0,
              altitudeAccuracy: 0,
              heading: 0,
              headingAccuracy: 0,
              speed: 0,
              speedAccuracy: 0,
            );
          }
        }
      } catch (e) {
        debugPrint('[LocationService] Google Geolocation fallback error: $e');
      }
    }

    try {
      final url = Uri.parse('https://ipwho.is/');
      final client = HttpClient();
      final req = await client.getUrl(url);
      final res = await req.close().timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final body = await res.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        final lat = (data['latitude'] as num?)?.toDouble();
        final lng = (data['longitude'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          debugPrint('[LocationService] Emulator fallback ipwho.is: $lat, $lng');
          return Position(
            longitude: lng,
            latitude: lat,
            timestamp: DateTime.now(),
            accuracy: 100.0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
        }
      }
    } catch (e) {
      debugPrint('[LocationService] ipwho.is fallback error: $e');
    }
    return null;
  }

  Future<String> _getMapsApiKey() async {
    if (_resolvedMapsApiKey != null) return _resolvedMapsApiKey!;
    if (AppConfig.googleMapsApiKey.isNotEmpty &&
        AppConfig.googleMapsApiKey != 'YOUR_GOOGLE_MAPS_API_KEY') {
      _resolvedMapsApiKey = AppConfig.googleMapsApiKey;
      return _resolvedMapsApiKey!;
    }
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final key =
            await _configChannel.invokeMethod<String>('getMapsApiKey');
        if (key != null &&
            key.isNotEmpty &&
            key != 'YOUR_GOOGLE_MAPS_API_KEY') {
          _resolvedMapsApiKey = key;
          return key;
        }
      } catch (e) {
        debugPrint('[LocationService] Gagal membaca Maps API Key native: $e');
      }
    }
    _resolvedMapsApiKey = '';
    return '';
  }

  /// Pastikan layanan lokasi aktif dan izin diberikan.
  Future<bool> ensurePermission() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('[LocationService] Layanan lokasi (GPS) tidak aktif.');
        return false;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('[LocationService] Izin lokasi ditolak oleh pengguna.');
          return false;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        debugPrint('[LocationService] Izin lokasi ditolak permanen.');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('[LocationService] ensurePermission error: $e');
      return false;
    }
  }

  LocationSettings _locationSettings({int distanceFilter = 0}) {
    if (!kIsWeb && Platform.isAndroid) {
      return AndroidSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: distanceFilter,
        forceLocationManager: false,
        intervalDuration: const Duration(seconds: 2),
      );
    }
    return LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: distanceFilter,
    );
  }

  /// Mengambil posisi GPS aktual terbaru dari perangkat dengan akurasi tertinggi.
  Future<Position?> getCurrentPosition() async {
    final allowed = await ensurePermission();
    if (!allowed) return null;

    try {
      final settings = (!kIsWeb && Platform.isAndroid)
          ? AndroidSettings(
              accuracy: LocationAccuracy.bestForNavigation,
              distanceFilter: 0,
              forceLocationManager: false,
              intervalDuration: const Duration(seconds: 1),
              timeLimit: const Duration(seconds: 10),
            )
          : const LocationSettings(
              accuracy: LocationAccuracy.bestForNavigation,
              timeLimit: Duration(seconds: 10),
            );

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: settings,
      );
      debugPrint(
          '[LocationService] GPS aktual: ${pos.latitude}, ${pos.longitude} (Akurasi: ±${pos.accuracy}m)');
      if (await _isAndroidEmulator() && _isDefaultGoogleplex(pos)) {
        final netPos = await _fetchNetworkFallbackPosition();
        if (netPos != null) return netPos;
      }
      return pos;
    } catch (e) {
      debugPrint(
          '[LocationService] getCurrentPosition error: $e. Fallback ke lastKnownPosition...');
      try {
        final last = await Geolocator.getLastKnownPosition();
        // Posisi tersimpan yang sudah lama ditolak (bisa dari waktu lain).
        if (last != null &&
            DateTime.now().difference(last.timestamp).abs() <=
                kMaxLastKnownAge) {
          if (await _isAndroidEmulator() && _isDefaultGoogleplex(last)) {
            final netPos = await _fetchNetworkFallbackPosition();
            if (netPos != null) return netPos;
          }
          debugPrint(
              '[LocationService] Menggunakan lastKnownPosition: ${last.latitude}, ${last.longitude}');
          return last;
        }
        if (await _isAndroidEmulator()) {
          return await _fetchNetworkFallbackPosition();
        }
        return null;
      } catch (_) {
        if (await _isAndroidEmulator()) {
          return await _fetchNetworkFallbackPosition();
        }
        return null;
      }
    }
  }

  /// Stream lokasi real-time: otomatis memancarkan posisi baru setiap perangkat
  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: _locationSettings(distanceFilter: 3),
    );
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

  /// Cek apakah posisi berada dalam radius laboratorium.
  static bool isInsideLab(Position pos) {
    final d = distanceInMeters(pos.latitude, pos.longitude, kLabLat, kLabLng);
    return d <= kLabRadius;
  }

  /// Hitung jarak dari posisi ke lab (meter).
  static double distanceToLab(Position pos) =>
      distanceInMeters(pos.latitude, pos.longitude, kLabLat, kLabLng);

  /// Hitung jarak dari posisi ke titik lab sesi (meter).
  static double distanceToPoint(Position pos, double lat, double lng) =>
      distanceInMeters(pos.latitude, pos.longitude, lat, lng);

  /// Reverse Geocoding real-time menggunakan Google Maps Geocoding API & fallback.
  Future<({String title, String detail})> getAddress(
      double lat, double lng) async {
    // 1. Jika berada dalam radius 50m dari titik cadangan (Lab Jaringan 1)
    final dist = distanceInMeters(lat, lng, kLabLat, kLabLng);
    if (dist <= kLabRadius) {
      return (
        title: 'Lab Jaringan 1, Gedung C Lantai 2',
        detail: 'Fasilkom-TI USU, Jl. Alumni, Padang Bulan, Medan',
      );
    }

    // 2. Real-time Geocoding via Google Maps Geocoding API
    final apiKey = await _getMapsApiKey();
    if (apiKey.isNotEmpty) {
      try {
        final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$apiKey&language=id',
        );
        final client = HttpClient();
        final request = await client.getUrl(url);
        final response =
            await request.close().timeout(const Duration(seconds: 5));

        if (response.statusCode == 200) {
          final body = await response.transform(utf8.decoder).join();
          final data = jsonDecode(body) as Map<String, dynamic>;
          if (data['status'] == 'OK' &&
              (data['results'] as List?)?.isNotEmpty == true) {
            final results = data['results'] as List;
            final first = results.first as Map<String, dynamic>;
            final formatted = first['formatted_address'] as String? ?? '';

            String poi = '';
            String street = '';
            String streetNumber = '';
            String subdistrict = '';
            String district = '';
            String city = '';
            final components = first['address_components'] as List? ?? [];
            for (final c in components) {
              final types = (c['types'] as List).cast<String>();
              if (types.contains('point_of_interest') ||
                  types.contains('establishment') ||
                  types.contains('premise')) {
                if (poi.isEmpty) poi = c['long_name'] as String;
              }
              if (types.contains('route')) {
                street = c['long_name'] as String;
              }
              if (types.contains('street_number')) {
                streetNumber = c['long_name'] as String;
              }
              if (types.contains('administrative_area_level_4') ||
                  types.contains('sublocality')) {
                if (subdistrict.isEmpty) subdistrict = c['long_name'] as String;
              }
              if (types.contains('administrative_area_level_3')) {
                district = c['long_name'] as String;
              }
              if (types.contains('administrative_area_level_2')) {
                city = c['long_name'] as String;
              }
            }

            final streetFull = street.isNotEmpty
                ? (streetNumber.isNotEmpty ? '$street No. $streetNumber' : street)
                : '';
            final title = poi.isNotEmpty
                ? poi
                : (streetFull.isNotEmpty
                    ? streetFull
                    : (subdistrict.isNotEmpty
                        ? subdistrict
                        : 'Lokasi Terdeteksi'));
            final details = <String>[];
            if (poi.isNotEmpty && streetFull.isNotEmpty) {
              details.add(streetFull);
            }
            if (subdistrict.isNotEmpty && subdistrict != title) {
              details.add(subdistrict);
            }
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
    }

    // 3. Fallback ke Nominatim OpenStreetMap
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json&accept-language=id&zoom=18',
      );
      final client = HttpClient();
      final request = await client.getUrl(uri);
      request.headers.set('User-Agent', 'ITLGMobileApp/1.0');
      final response =
          await request.close().timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;

        if (address != null) {
          final road = address['amenity'] as String? ??
              address['building'] as String? ??
              address['road'] as String? ??
              address['suburb'] as String? ??
              'Lokasi Terdeteksi';

          final sub = address['suburb'] as String? ??
              address['village'] as String? ??
              address['neighbourhood'] as String?;
          final district = address['city_district'] as String?;
          final city = address['city'] as String? ??
              address['town'] as String? ??
              'Kota Medan';
          final state = address['state'] as String? ?? 'Sumatera Utara';

          final details = <String>[];
          if (sub != null && sub != road) details.add(sub);
          if (district != null && district != sub) details.add(district);
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
