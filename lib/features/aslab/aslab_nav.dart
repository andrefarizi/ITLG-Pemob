import 'package:flutter/material.dart';

import '../auth/pages/forgot_password_page_1.dart';
import '../auth/widgets/auth_design.dart';
import '../laboran/widgets/laboran_ui.dart';
import 'aslab_store.dart';
import 'pages/aslab_ajukan_tukar_shift_page.dart';
import 'pages/aslab_buat_pengumuman_page.dart';
import 'pages/aslab_buat_sesi_page.dart';
import 'pages/aslab_bukti_presensi_page.dart';
import 'pages/aslab_detail_absensi_page.dart';
import 'pages/aslab_detail_modul_page.dart';
import 'pages/aslab_detail_pertemuan_page.dart';
import 'pages/aslab_detail_praktikum_page.dart';
import 'pages/aslab_detail_presensi_page.dart';
import 'pages/aslab_edit_modul_page.dart';
import 'pages/aslab_edit_tugas_page.dart';
import 'pages/aslab_evaluasi_tugas_page.dart';
import 'pages/aslab_hasil_kuis_page.dart';
import 'pages/aslab_lapor_kendala_page.dart';
import 'pages/aslab_notifikasi_page.dart';
import 'pages/aslab_penilaian_tugas_page.dart';
import 'pages/aslab_persetujuan_izin_page.dart';
import 'pages/aslab_riwayat_tukar_shift_page.dart';
import 'pages/aslab_sesi_aktif_page.dart';
import 'pages/aslab_shift_jaga_page.dart';
import 'pages/aslab_tambah_materi_page.dart';

/// Indeks tab navbar Asisten Lab.
class AslabTab {
  AslabTab._();
  static const int beranda = 0;
  static const int praktikum = 1;
  static const int penilaian = 2;
  static const int absensi = 3;
  static const int profil = 4;
}

/// Semua perpindahan halaman Asisten Lab, mengikuti prototipe Figma.
class AslabNav {
  final AslabStore store;

  /// Tutup semua halaman detail lalu buka tab tertentu.
  final void Function(int tab) goTab;

  AslabNav({required this.store, required this.goTab});

  void home() => goTab(AslabTab.beranda);

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
      _open(c, AslabNotifikasiPage(nav: this), false);

  Future<void> shiftJaga(BuildContext c) =>
      _open(c, AslabShiftJagaPage(nav: this), false);

  Future<void> riwayatTukarShift(BuildContext c) =>
      _open(c, AslabRiwayatTukarShiftPage(nav: this), false);

  Future<void> ajukanTukarShift(BuildContext c) =>
      _open(c, AslabAjukanTukarShiftPage(nav: this), false);

  Future<void> laporKendala(BuildContext c) =>
      _open(c, AslabLaporKendalaPage(nav: this), false);

  Future<void> buatPengumuman(BuildContext c) =>
      _open(c, AslabBuatPengumumanPage(nav: this), false);

  Future<void> persetujuanIzin(BuildContext c) =>
      _open(c, AslabPersetujuanIzinPage(nav: this), false);

  // --- Praktikum Saya --------------------------------------------------------

  Future<void> detailPraktikum(BuildContext c, AslabCourse course) =>
      _open(c, AslabDetailPraktikumPage(nav: this, course: course), false);

  Future<void> detailPertemuan(
    BuildContext c,
    AslabMeeting meeting, {
    String courseId = 'pemob',
  }) =>
      _open(
        c,
        AslabDetailPertemuanPage(
            nav: this, meeting: meeting, courseId: courseId),
        false,
      );

  Future<void> detailModul(
    BuildContext c, {
    String courseId = 'pemob',
    int meetingNumber = 4,
  }) =>
      _open(
        c,
        AslabDetailModulPage(
            nav: this, courseId: courseId, meetingNumber: meetingNumber),
        false,
      );

  /// [kind]: 0 modul, 1 tugas, 2 kuis.
  Future<void> tambahMateri(
    BuildContext c, {
    int kind = 0,
    String courseId = 'pemob',
    int? meetingNumber,
  }) =>
      _open(
        c,
        AslabTambahMateriPage(
          nav: this,
          kind: kind,
          courseId: courseId,
          meetingNumber: meetingNumber,
        ),
        false,
      );

  Future<void> editModul(
    BuildContext c, {
    String courseId = 'pemob',
    int meetingNumber = 4,
  }) =>
      _open(
        c,
        AslabEditModulPage(
            nav: this, courseId: courseId, meetingNumber: meetingNumber),
        false,
      );

  Future<void> editTugas(
    BuildContext c, {
    String courseId = 'pemob',
    int meetingNumber = 4,
  }) =>
      _open(
        c,
        AslabEditTugasPage(
            nav: this, courseId: courseId, meetingNumber: meetingNumber),
        false,
      );

  Future<void> hasilKuis(
    BuildContext c, {
    String courseId = 'pemob',
    int meetingNumber = 4,
  }) =>
      _open(
        c,
        AslabHasilKuisPage(
            nav: this, courseId: courseId, meetingNumber: meetingNumber),
        false,
      );

  // --- Penilaian -------------------------------------------------------------

  Future<void> evaluasiTugas(
    BuildContext c, {
    String courseId = 'pemob',
    int meetingNumber = 4,
  }) =>
      _open(
        c,
        AslabEvaluasiTugasPage(
            nav: this, courseId: courseId, meetingNumber: meetingNumber),
        false,
      );

  Future<void> penilaianTugas(
    BuildContext c, {
    AslabStudent student = kRina,
    String courseId = 'pemob',
    int meetingNumber = 4,
  }) =>
      _open(
        c,
        AslabPenilaianTugasPage(
          nav: this,
          student: student,
          courseId: courseId,
          meetingNumber: meetingNumber,
        ),
        false,
      );

  // --- Absensi ---------------------------------------------------------------

  Future<void> detailAbsensi(BuildContext c, AslabCourse course) =>
      _open(c, AslabDetailAbsensiPage(nav: this, course: course), false);

  Future<void> buatSesi(
    BuildContext c, {
    String courseId = 'pemob',
    int meetingNumber = 5,
  }) =>
      _open(
        c,
        AslabBuatSesiPage(
          nav: this,
          courseId: courseId,
          meetingNumber: meetingNumber,
        ),
        false,
      );

  Future<void> sesiAktif(BuildContext c, {bool replace = false}) =>
      _open(c, AslabSesiAktifPage(nav: this), replace);

  Future<void> detailPresensi(BuildContext c) =>
      _open(c, AslabDetailPresensiPage(nav: this), false);

  Future<void> buktiPresensi(BuildContext c) =>
      _open(c, AslabBuktiPresensiPage(nav: this), false);

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

  void openNotif(BuildContext c, AslabNotifTarget target) {
    switch (target) {
      case AslabNotifTarget.evaluasi:
        evaluasiTugas(c);
        break;
      case AslabNotifTarget.shiftJaga:
        shiftJaga(c);
        break;
      case AslabNotifTarget.persetujuanIzin:
        persetujuanIzin(c);
        break;
      case AslabNotifTarget.laporKendala:
        laporKendala(c);
        break;
      case AslabNotifTarget.detailPresensi:
        detailPresensi(c);
        break;
      case AslabNotifTarget.hasilKuis:
        hasilKuis(c);
        break;
    }
  }
}
