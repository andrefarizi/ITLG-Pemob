import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/widgets/itlg_ui.dart';
import '../auth/auth_controller.dart';
import '../laboran/widgets/laboran_ui.dart';
import 'dosen_store.dart';
import 'pages/dosen_beranda_page.dart';
import 'pages/dosen_detail_peringatan_page.dart';
import 'pages/dosen_laporan_page.dart';
import 'pages/dosen_notifikasi_page.dart';
import 'pages/dosen_peringatan_page.dart';
import 'pages/dosen_profil_page.dart';
import 'pages/dosen_validasi_page.dart';

/// Kerangka peran Dosen Pengampu: header ITLG + navbar 5 tab (Beranda,
/// Validasi, Laporan, Peringatan, Profil). Komponen tampilannya sama dengan
/// peran Laboran (lib/features/laboran/widgets/laboran_ui.dart).
class DosenShell extends StatefulWidget {
  const DosenShell({super.key});

  static const int tabBeranda = 0;
  static const int tabValidasi = 1;
  static const int tabLaporan = 2;
  static const int tabPeringatan = 3;
  static const int tabProfil = 4;

  @override
  State<DosenShell> createState() => _DosenShellState();
}

class _DosenShellState extends State<DosenShell> {
  final DosenStore _store = DosenStore();
  int _tab = DosenShell.tabBeranda;

  static const List<LabNavItem> _items = [
    LabNavItem('Beranda', 'home'),
    LabNavItem('Validasi', 'shield_check_outline'),
    LabNavItem('Laporan', 'file'),
    LabNavItem('Peringatan', 'triangle_alert'),
    LabNavItem('Profil', 'person'),
  ];

  void _openTab(int tab) {
    if (tab != _tab) setState(() => _tab = tab);
  }

  /// Dipanggil dari halaman detail: tutup semua halaman detail lalu pindah tab.
  void _openTabFromSubPage(int tab) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    _openTab(tab);
  }

  void _openDetail(DosenStudent student) {
    labPush(
      context,
      DosenDetailPeringatanPage(
        student: student,
        onLogoTap: () => _openTabFromSubPage(DosenShell.tabBeranda),
      ),
    );
  }

  void _openNotifikasi() {
    labPush(
      context,
      DosenNotifikasiPage(
        store: _store,
        onLogoTap: () => _openTabFromSubPage(DosenShell.tabBeranda),
        onOpen: (target) {
          switch (target) {
            case DosenNotifTarget.peringatan:
              _openTabFromSubPage(DosenShell.tabPeringatan);
              break;
            case DosenNotifTarget.validasi:
              _openTabFromSubPage(DosenShell.tabValidasi);
              break;
            case DosenNotifTarget.laporan:
              _openTabFromSubPage(DosenShell.tabLaporan);
              break;
            case DosenNotifTarget.detailPeringatan:
              _openDetail(_store.students.first);
              break;
          }
        },
      ),
    ).then((_) {
      if (mounted) setState(() {});
    });
  }

  Widget _page() {
    switch (_tab) {
      case DosenShell.tabValidasi:
        return DosenValidasiPage(store: _store);
      case DosenShell.tabLaporan:
        return DosenLaporanPage(store: _store);
      case DosenShell.tabPeringatan:
        return DosenPeringatanPage(store: _store, onOpenDetail: _openDetail);
      case DosenShell.tabProfil:
        return DosenProfilPage(
          store: _store,
          onLogout: () => AuthController.instance.logout(),
        );
      default:
        return DosenBerandaPage(
          onOpenTab: _openTab,
          onOpenNotifikasi: _openNotifikasi,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: ItlgColors.surfaceWhite,
        body: Stack(
          children: [
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeOut,
                layoutBuilder: (current, previous) => Stack(
                  fit: StackFit.expand,
                  children: [
                    ...previous,
                    if (current != null) current,
                  ],
                ),
                child: KeyedSubtree(key: ValueKey<int>(_tab), child: _page()),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: LabTopBar(
                onLogoTap: () => _openTab(DosenShell.tabBeranda),
              ),
            ),
          ],
        ),
        bottomNavigationBar: LabNavBar(
          items: _items,
          index: _tab,
          onChanged: _openTab,
        ),
      ),
    );
  }
}
