import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/services/location_service.dart';

/// Widget Google Maps nyata untuk presensi.
/// Menampilkan:
/// - Titik Lab Komputer 1 (Merah) dengan radius 50m
/// - Titik Lokasi Perangkat Anda yang didapat langsung dari sensor GPS
class PrakGoogleMap extends StatefulWidget {
  final bool inside;
  final LatLng? userPos;

  const PrakGoogleMap({
    super.key,
    required this.inside,
    this.userPos,
  });

  @override
  State<PrakGoogleMap> createState() => _PrakGoogleMapState();
}

class _PrakGoogleMapState extends State<PrakGoogleMap> {
  static const LatLng _labCoords = LatLng(kLabLat, kLabLng);

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
      // Tampilkan area yang mencakup posisi pengguna dan titik lab
      final midLat = (_labCoords.latitude + user.latitude) / 2;
      final midLng = (_labCoords.longitude + user.longitude) / 2;
      final dist = LocationService.distanceInMeters(
        user.latitude,
        user.longitude,
        _labCoords.latitude,
        _labCoords.longitude,
      );

      // Sesuaikan zoom level berdasarkan jarak
      double zoom = 16.0;
      if (dist > 5000) {
        zoom = 12.0;
      } else if (dist > 2000) {
        zoom = 13.5;
      } else if (dist > 500) {
        zoom = 15.0;
      }

      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(midLat, midLng),
            zoom: zoom,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.userPos;

    final circles = <Circle>{
      Circle(
        circleId: const CircleId('lab_radius'),
        center: _labCoords,
        radius: kLabRadius,
        fillColor: const Color(0x338B1A1A),
        strokeColor: const Color(0xFF8B1A1A),
        strokeWidth: 2,
      ),
    };

    final markers = <Marker>{
      // Marker Lab Komputer 1
      Marker(
        markerId: const MarkerId('lab_marker'),
        position: _labCoords,
        infoWindow: const InfoWindow(
          title: 'Titik Presensi: Lab Komputer 1',
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
