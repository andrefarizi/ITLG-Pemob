import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/services/location_service.dart';

/// Widget Google Maps nyata untuk presensi.
class PrakGoogleMap extends StatefulWidget {
  final bool inside;
  final LatLng? userPos;

  /// Nama lab sesi aktif untuk judul penanda (teks saja).
  final String labName;

  /// Titik & radius lab sesi (bawaan: titik cadangan Lab Jaringan 1).
  final double labLat;
  final double labLng;
  final double radius;

  const PrakGoogleMap({
    super.key,
    required this.inside,
    this.userPos,
    this.labName = 'Lab Jaringan 1',
    this.labLat = kLabLat,
    this.labLng = kLabLng,
    this.radius = kLabRadius,
  });

  @override
  State<PrakGoogleMap> createState() => _PrakGoogleMapState();
}

class _PrakGoogleMapState extends State<PrakGoogleMap> {
  LatLng get _labCoords => LatLng(widget.labLat, widget.labLng);

  GoogleMapController? _mapController;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PrakGoogleMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.inside != widget.inside || oldWidget.userPos != widget.userPos) {
      _moveCamera();
    }
  }

  void _moveCamera() {
    if (_mapController == null) return;
    final user = widget.userPos;

    if (widget.inside || user == null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: user ?? _labCoords,
            zoom: 18.0,
          ),
        ),
      );
    } else {
      // Sesuaikan tampilan kamera peta agar mencakup titik pengguna dan lab
      final swLat = math.min(_labCoords.latitude, user.latitude);
      final swLng = math.min(_labCoords.longitude, user.longitude);
      final neLat = math.max(_labCoords.latitude, user.latitude);
      final neLng = math.max(_labCoords.longitude, user.longitude);

      if ((neLat - swLat).abs() < 0.0005 && (neLng - swLng).abs() < 0.0005) {
        _mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(target: user, zoom: 17.5),
          ),
        );
      } else {
        final bounds = LatLngBounds(
          southwest: LatLng(swLat, swLng),
          northeast: LatLng(neLat, neLng),
        );
        _mapController!.animateCamera(
          CameraUpdate.newLatLngBounds(bounds, 42),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.userPos;

    final circles = <Circle>{
      Circle(
        circleId: const CircleId('lab_radius'),
        center: _labCoords,
        radius: widget.radius,
        fillColor: const Color(0x338B1A1A),
        strokeColor: const Color(0xFF8B1A1A),
        strokeWidth: 2,
      ),
    };

    final markers = <Marker>{
      // Penanda titik presensi lab
      Marker(
        markerId: const MarkerId('lab_marker'),
        position: _labCoords,
        infoWindow: InfoWindow(
          title: 'Titik Presensi: ${widget.labName}',
          snippet: 'Gedung C Lantai 2, Fasilkom-TI USU',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
      // Marker Posisi Perangkat Pengguna
      if (user != null)
        Marker(
          markerId: const MarkerId('user_marker'),
          position: user,
          infoWindow: InfoWindow(
            title: 'Lokasi Perangkat Anda',
            snippet: widget.inside
                ? 'Di Dalam Area Lab (Presensi Diizinkan)'
                : 'Di Luar Area Lab',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            widget.inside ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueAzure,
          ),
        ),
    };

    final initialTarget = user ?? _labCoords;

    return AspectRatio(
      aspectRatio: 338 / 180,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialTarget,
            zoom: widget.inside ? 18.0 : 15.5,
          ),
          circles: circles,
          markers: markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: true,
          scrollGesturesEnabled: true,
          zoomGesturesEnabled: true,
          onMapCreated: (ctrl) {
            _mapController = ctrl;
            _moveCamera();
          },
        ),
      ),
    );
  }
}
