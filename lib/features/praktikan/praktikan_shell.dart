import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/widgets/itlg_ui.dart';
import '../auth/auth_controller.dart';
import '../laboran/widgets/laboran_ui.dart';
import 'pages/praktikan_absensi_page.dart';
import 'pages/praktikan_beranda_page.dart';
import 'pages/praktikan_daftar_praktikum_page.dart';
import 'pages/praktikan_nilai_page.dart';
import 'pages/praktikan_profil_page.dart';
import 'praktikan_nav.dart';
import 'praktikan_store.dart';

/// Kerangka peran Praktikan: header ITLG + navbar 5 tab (Beranda, Praktikum,
/// Absensi, Nilai, Profil). Komponen tampilannya sama dengan peran Laboran
/// & Dosen (lib/features/laboran/widgets/laboran_ui.dart).
class PraktikanShell extends StatefulWidget {
  const PraktikanShell({super.key});

  @override
  State<PraktikanShell> createState() => _PraktikanShellState();
}

class _PraktikanShellState extends State<PraktikanShell> {
  final PraktikanStore _store = PraktikanStore();
  late final PraktikanNav _nav = PraktikanNav(
    store: _store,
    goTab: _openTabFromSubPage,
    rootContext: () => context,
  );
  int _tab = PrakTab.beranda;

  static const List<LabNavItem> _items = [
    LabNavItem('Beranda', 'home'),
    LabNavItem('Praktikum', 'book_open'),
    LabNavItem('Absensi', 'circle_check'),
    LabNavItem('Nilai', 'trophy'),
    LabNavItem('Profil', 'person'),
  ];

  void _openTab(int tab) {
    if (tab != _tab) setState(() => _tab = tab);
  }

  /// Dipanggil dari halaman detail: tutup semua halaman detail lalu pindah tab.
  void _openTabFromSubPage(int tab) {
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    setState(() => _tab = tab);
  }

  Widget _page() {
    switch (_tab) {
      case PrakTab.praktikum:
        return PraktikanDaftarPraktikumPage(nav: _nav);
      case PrakTab.absensi:
        return PraktikanAbsensiPage(nav: _nav);
      case PrakTab.nilai:
        return PraktikanNilaiPage(nav: _nav);
      case PrakTab.profil:
        return PraktikanProfilPage(
          nav: _nav,
          onLogout: () async => await AuthController.instance.logout(),
        );
      default:
        return PraktikanBerandaPage(nav: _nav);
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
              child: LabTopBar(onLogoTap: () => _openTab(PrakTab.beranda)),
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
