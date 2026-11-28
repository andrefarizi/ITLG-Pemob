import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/services/device_notification_service.dart';
import '../../core/widgets/itlg_ui.dart';
import '../auth/auth_controller.dart';
import '../laboran/widgets/laboran_ui.dart';
import 'aslab_nav.dart';
import 'aslab_store.dart';
import 'pages/aslab_absensi_page.dart';
import 'pages/aslab_beranda_page.dart';
import 'pages/aslab_penilaian_page.dart';
import 'pages/aslab_praktikum_saya_page.dart';
import 'pages/aslab_profil_page.dart';

/// Kerangka navigasi utama peran Asisten Lab.
class AslabShell extends StatefulWidget {
  const AslabShell({super.key});

  @override
  State<AslabShell> createState() => _AslabShellState();
}

class _AslabShellState extends State<AslabShell> {
  final AslabStore _store = AslabStore();
  late final AslabNav _nav = AslabNav(store: _store, goTab: _openTabFromSubPage);
  int _tab = AslabTab.beranda;

  static const List<LabNavItem> _items = [
    LabNavItem('Beranda', 'home'),
    LabNavItem('Praktikum', 'book_open'),
    LabNavItem('Penilaian', 'clipboard'),
    LabNavItem('Absensi', 'circle_check'),
    LabNavItem('Profil', 'person'),
  ];

  void _handleNotifTap() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
      _nav.notifikasi(context);
    });
  }

  @override
  void initState() {
    super.initState();
    DeviceNotificationService.instance.requestPermissionOnce();
    DeviceNotificationService.instance.registerTapHandler(_handleNotifTap);
  }

  @override
  void dispose() {
    DeviceNotificationService.instance.unregisterTapHandler(_handleNotifTap);
    super.dispose();
  }

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
      case AslabTab.praktikum:
        return AslabPraktikumSayaPage(nav: _nav);
      case AslabTab.penilaian:
        return AslabPenilaianPage(nav: _nav);
      case AslabTab.absensi:
        return AslabAbsensiPage(nav: _nav);
      case AslabTab.profil:
        return AslabProfilPage(
          nav: _nav,
          onLogout: () async => await AuthController.instance.logout(),
        );
      default:
        return AslabBerandaPage(
          nav: _nav,
          onOpenTab: _openTab,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark
          .copyWith(statusBarColor: Colors.transparent),
      child: PopScope(
        canPop: _tab == AslabTab.beranda,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _tab != AslabTab.beranda) {
            _openTab(AslabTab.beranda);
          }
        },
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
                child: LabTopBar(onLogoTap: () => _openTab(AslabTab.beranda)),
              ),
            ],
          ),
          bottomNavigationBar: LabNavBar(
            items: _items,
            index: _tab,
            onChanged: _openTab,
          ),
        ),
      ),
    );
  }
}
