import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/services/location_service.dart';

/// Widget Google Maps nyata untuk presensi.
/// Menampilkan:
/// - Titik Lab Komputer 1 (Merah) dengan radius 50m
/// - Titik Lokasi Anda (Hijau jika di dalam, Oranye/Biru jika di luar area, misal Fore Coffee Dr. Mansyur)
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
    final user = widget.userPos ?? (widget.inside
        ? const LatLng(3.56218, 98.66012)
        : const LatLng(3.5678, 98.6552));

    if (widget.inside) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          const CameraPosition(
            target: _labCoords,
            zoom: 18.0,
          ),
        ),
      );
    } else {
      // Tampilkan area antara Lab Komputer dan posisi user (misal Fore Coffee Mansyur)
      final midLat = (_labCoords.latitude + user.latitude) / 2;
      final midLng = (_labCoords.longitude + user.longitude) / 2;
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(midLat, midLng),
            zoom: 15.5,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.userPos ?? (widget.inside
        ? const LatLng(3.56218, 98.66012)
        : const LatLng(3.5678, 98.6552));

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
      // Marker Posisi Anda
      Marker(
        markerId: const MarkerId('user_marker'),
        position: user,
        infoWindow: InfoWindow(
          title: 'Lokasi Anda Saat Ini',
          snippet: widget.inside
              ? 'Di Dalam Area Lab (12 m)'
              : 'Di Luar Area Lab (Fore Coffee Mansyur)',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          widget.inside ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueAzure,
        ),
      ),
    };

    return AspectRatio(
      aspectRatio: 338 / 180,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: widget.inside
                ? _labCoords
                : LatLng((_labCoords.latitude + user.latitude) / 2, (_labCoords.longitude + user.longitude) / 2),
            zoom: widget.inside ? 18.0 : 15.5,
          ),
          circles: circles,
          markers: markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
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
