import 'package:flutter/material.dart';

import '../auth/pages/forgot_password_page_1.dart';
import '../auth/widgets/auth_design.dart';
import '../laboran/widgets/laboran_ui.dart';
import 'pages/praktikan_ajukan_izin_page.dart';
import 'pages/praktikan_detail_absensi_page.dart';
import 'pages/praktikan_detail_materi_page.dart';
import 'pages/praktikan_detail_nilai_page.dart';
import 'pages/praktikan_detail_pertemuan_page.dart';
import 'pages/praktikan_detail_praktikum_page.dart';
import 'pages/praktikan_edit_tugas_page.dart';
import 'pages/praktikan_hasil_kuis_page.dart';
import 'pages/praktikan_kuis_page.dart';
import 'pages/praktikan_laporkan_kerusakan_page.dart';
import 'pages/praktikan_meja_kamu_page.dart';
import 'pages/praktikan_notifikasi_page.dart';
import 'pages/praktikan_penilaian_asisten_page.dart';
import 'pages/praktikan_pengumuman_page.dart';
import 'pages/praktikan_pilih_meja_page.dart';
import 'pages/praktikan_pilih_metode_page.dart';
import 'pages/praktikan_sanggah_nilai_page.dart';
import 'pages/praktikan_scan_qr_page.dart';
import 'pages/praktikan_tanda_tangan_page.dart';
import 'pages/praktikan_tombol_hadir_page.dart';
import 'praktikan_store.dart';

/// Indeks tab navbar Praktikan.
class PrakTab {
  PrakTab._();
  static const int beranda = 0;
  static const int praktikum = 1;
  static const int absensi = 2;
  static const int nilai = 3;
  static const int profil = 4;
}

/// Semua perpindahan halaman Praktikan, mengikuti prototipe Figma.
///
/// Halaman detail masuk dari kanan (300 ms). "Ganti" (replace) dipakai bila
/// di prototipe halaman berpindah ke saudara satu tingkat, supaya tombol
/// Kembali tetap kembali ke halaman asalnya.
class PraktikanNav {
  final PraktikanStore store;

  /// Tutup semua halaman detail lalu buka tab tertentu.
  final void Function(int tab) goTab;

  /// Context milik PraktikanShell (tetap ada setelah halaman detail ditutup).
  final BuildContext Function() rootContext;

  PraktikanNav({
    required this.store,
    required this.goTab,
    required this.rootContext,
  });

  void home() => goTab(PrakTab.beranda);

  Future<void> _open(BuildContext context, Widget page, bool replace) {
    if (!replace) return labPush(context, page);
    return Navigator.of(context).pushReplacement(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
    );
  }

  // --- Beranda ---------------------------------------------------------------

  Future<void> notifikasi(BuildContext c) =>
      _open(c, PraktikanNotifikasiPage(nav: this), false);

  Future<void> pengumuman(BuildContext c) =>
      _open(c, PraktikanPengumumanPage(nav: this), false);

  // --- Praktikum -------------------------------------------------------------

  Future<void> detailPraktikum(BuildContext c, PrakCourse course) =>
      _open(c, PraktikanDetailPraktikumPage(nav: this, course: course), false);

  Future<void> detailPertemuan(
    BuildContext c,
    PrakCourse course,
    PrakMeeting meeting,
  ) =>
      _open(
        c,
        PraktikanDetailPertemuanPage(nav: this, course: course, meeting: meeting),
        false,
      );

  Future<void> detailMateri(
    BuildContext c, {
    PrakCourse? course,
    PrakMeeting? meeting,
    bool replace = false,
  }) =>
      _open(
        c,
        PraktikanDetailMateriPage(nav: this, course: course, meeting: meeting),
        replace,
      );

  Future<void> editTugas(
    BuildContext c, {
    PrakCourse? course,
    PrakMeeting? meeting,
  }) =>
      _open(
        c,
        PraktikanEditTugasPage(nav: this, course: course, meeting: meeting),
        false,
      );

  Future<void> kuis(
    BuildContext c, {
    PrakCourse? course,
    PrakMeeting? meeting,
  }) =>
      _open(
        c,
        PraktikanKuisPage(nav: this, course: course, meeting: meeting),
        false,
      );

  Future<void> hasilKuis(
    BuildContext c, {
    PrakCourse? course,
    PrakMeeting? meeting,
    bool replace = false,
  }) =>
      _open(
        c,
        PraktikanHasilKuisPage(nav: this, course: course, meeting: meeting),
        replace,
      );

  Future<void> penilaianAsisten(
    BuildContext c,
    PrakCourse course, {
    bool open = false,
    bool replace = false,
  }) =>
      _open(
        c,
        PraktikanPenilaianAsistenPage(nav: this, course: course, open: open),
        replace,
      );

  // --- Presensi --------------------------------------------------------------

  Future<void> presensi(BuildContext c) =>
      _open(c, PraktikanPilihMetodePage(nav: this), false);

  Future<void> scanQr(BuildContext c, {bool replace = false}) =>
      _open(c, PraktikanScanQrPage(nav: this), replace);

  Future<void> tombolHadir(BuildContext c, {bool replace = false}) =>
      _open(c, PraktikanTombolHadirPage(nav: this), replace);

  Future<void> tandaTangan(
    BuildContext c, {
    String method = 'location',
    double? lat,
    double? lng,
    double? distanceMeters,
  }) =>
      _open(
        c,
        PraktikanTandaTanganPage(
          nav: this,
          method: method,
          lat: lat,
          lng: lng,
          distanceMeters: distanceMeters,
        ),
        false,
      );

  /// Dari pop-up "Presensi Tercatat": kembali ke Beranda lalu buka Pilih
  /// Meja, sehingga Kembali di Pilih Meja menuju Beranda (sesuai Figma).
  void pilihMejaFromPresensi() {
    home();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final c = rootContext();
      if (c.mounted) labPush(c, PraktikanPilihMejaPage(nav: this));
    });
  }

  /// Setelah booking: Pilih Meja diganti Meja Kamu (Kembali → Beranda).
  Future<void> mejaKamu(BuildContext c, {bool replace = false}) =>
      _open(c, PraktikanMejaKamuPage(nav: this), replace);

  Future<void> laporkanKerusakan(BuildContext c) =>
      _open(c, PraktikanLaporkanKerusakanPage(nav: this), false);

  // --- Absensi ---------------------------------------------------------------

  Future<void> detailAbsensi(BuildContext c, PrakCourse course) =>
      _open(c, PraktikanDetailAbsensiPage(nav: this, course: course), false);

  Future<void> ajukanIzin(
    BuildContext c,
    PrakCourse course,
    PrakMeeting meeting, {
    bool replace = false,
  }) =>
      _open(
        c,
        PraktikanAjukanIzinPage(nav: this, course: course, meeting: meeting),
        replace,
      );

  // --- Nilai -----------------------------------------------------------------

  Future<void> detailNilai(BuildContext c, PrakCourse course) =>
      _open(c, PraktikanDetailNilaiPage(nav: this, course: course), false);

  Future<void> sanggah(BuildContext c, PrakCourse course, PrakGrade grade) =>
      _open(c,
          PraktikanSanggahNilaiPage(nav: this, course: course, grade: grade),
          false);

  // --- Profil ----------------------------------------------------------------

  Future<void> ubahKataSandi(BuildContext c) {
    return Navigator.of(c).push(
      PageRouteBuilder<void>(
        settings: const RouteSettings(name: kForgotPasswordRoute),
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (_, __, ___) => const ForgotPasswordPage1(),
        transitionsBuilder: (_, anim, __, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      ),
    );
  }

  // --- Notifikasi ------------------------------------------------------------

  void openNotif(BuildContext c, PrakNotifTarget target) {
    switch (target) {
      case PrakNotifTarget.editTugas:
        editTugas(c);
        break;
      case PrakNotifTarget.presensi:
        presensi(c);
        break;
      case PrakNotifTarget.pengumuman:
        pengumuman(c);
        break;
      case PrakNotifTarget.detailAbsensi:
        detailAbsensi(c, store.mobile);
        break;
      case PrakNotifTarget.kuis:
        kuis(c);
        break;
      case PrakNotifTarget.detailNilai:
        detailNilai(c, store.mobile);
        break;
    }
  }
}
