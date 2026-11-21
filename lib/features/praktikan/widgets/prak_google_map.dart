import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/services/location_service.dart';
import '../../../core/widgets/itlg_ui.dart';
import '../../laboran/widgets/laboran_ui.dart';

/// Widget Google Maps sesungguhnya untuk halaman presensi.
/// Menampilkan marker Lab Komputer 1 + posisi user + lingkaran radius 50m.
/// Ukuran: AspectRatio 338/180 (sama dengan PrakLocationMap lama).
class PrakGoogleMap extends StatefulWidget {
  /// Posisi GPS user saat ini. Null = belum diketahui / loading.
  final Position? userPos;

  /// Apakah user di dalam radius lab.
  final bool inside;

  const PrakGoogleMap({super.key, this.userPos, required this.inside});

  @override
  State<PrakGoogleMap> createState() => _PrakGoogleMapState();
}

class _PrakGoogleMapState extends State<PrakGoogleMap> {
  static const LatLng _lab = LatLng(kLabLat, kLabLng);

  GoogleMapController? _ctrl;
  bool _mapReady = false;

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(PrakGoogleMap old) {
    super.didUpdateWidget(old);
    if (widget.userPos != null && _mapReady) {
      _animateCamera();
    }
  }

  void _animateCamera() {
    if (_ctrl == null || widget.userPos == null) return;
    final userLatLng =
        LatLng(widget.userPos!.latitude, widget.userPos!.longitude);
    // Pusat antara lab dan user
    final midLat = (_lab.latitude + userLatLng.latitude) / 2;
    final midLng = (_lab.longitude + userLatLng.longitude) / 2;
    _ctrl!.animateCamera(CameraUpdate.newLatLngZoom(
      LatLng(midLat, midLng),
      widget.inside ? 17.5 : 16.0,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final userLatLng = widget.userPos != null
        ? LatLng(widget.userPos!.latitude, widget.userPos!.longitude)
        : null;

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('lab'),
        position: _lab,
        infoWindow: const InfoWindow(
          title: 'Lab Komputer 1',
          snippet: 'Gedung C Lantai 2, Fasilkom-TI USU',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
      if (userLatLng != null)
        Marker(
          markerId: const MarkerId('user'),
          position: userLatLng,
          infoWindow: const InfoWindow(title: 'Posisi Anda'),
          icon: BitmapDescriptor.defaultMarkerWithHue(
              widget.inside
                  ? BitmapDescriptor.hueGreen
                  : BitmapDescriptor.hueOrange),
        ),
    };

    final circles = <Circle>{
      Circle(
        circleId: const CircleId('lab_radius'),
        center: _lab,
        radius: kLabRadius,
        fillColor: const Color(0x228B1A1A),
        strokeColor: const Color(0xFF8B1A1A),
        strokeWidth: 2,
      ),
    };

    return AspectRatio(
      aspectRatio: 338 / 180,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          initialCameraPosition: CameraPosition(
            target: userLatLng ?? _lab,
            zoom: 17.0,
          ),
          markers: markers,
          circles: circles,
          myLocationEnabled: false,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          liteModeEnabled: false,
          onMapCreated: (c) {
            _ctrl = c;
            setState(() => _mapReady = true);
            if (widget.userPos != null) _animateCamera();
          },
        ),
      ),
    );
  }
}

/// Widget loading map (saat GPS belum siap).
class PrakMapLoading extends StatelessWidget {
  const PrakMapLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 338 / 180,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: ItlgColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Memuat lokasi GPS...',
              style: labText(12, c: ItlgColors.textSubtle),
            ),
          ],
        ),
      ),
    );
  }
}
