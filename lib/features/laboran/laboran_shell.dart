import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/widgets/itlg_ui.dart';
import '../auth/auth_controller.dart';
import 'laboran_store.dart';
import 'pages/laboran_approval_page.dart';
import 'pages/laboran_beranda_page.dart';
import 'pages/laboran_denah_meja_page.dart';
import 'pages/laboran_detail_tiket_page.dart';
import 'pages/laboran_inventaris_page.dart';
import 'pages/laboran_notifikasi_page.dart';
import 'pages/laboran_presensi_asisten_page.dart';
import 'pages/laboran_profil_page.dart';
import 'pages/laboran_tiket_page.dart';
import 'widgets/laboran_ui.dart';

/// Kerangka peran Laboran: header ITLG + navbar 5 tab (Beranda, Tiket,
/// Ruangan, Inventaris, Profil). Perpindahan tab memakai fade 200 ms seperti
/// prototipe Figma.
class LaboranShell extends StatefulWidget {
  const LaboranShell({super.key});

  static const int tabBeranda = 0;
  static const int tabTiket = 1;
  static const int tabRuangan = 2;
  static const int tabInventaris = 3;
  static const int tabProfil = 4;

  @override
  State<LaboranShell> createState() => _LaboranShellState();
}

class _LaboranShellState extends State<LaboranShell> {
  final LaboranStore _store = LaboranStore();
  int _tab = LaboranShell.tabBeranda;

  static const List<LabNavItem> _items = [
    LabNavItem('Beranda', 'home'),
    LabNavItem('Perbaikan', 'ticket'),
    LabNavItem('Ruangan', 'door'),
    LabNavItem('Inventaris', 'desktop_device'),
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

  void _openDenahMeja() {
    labPush(
      context,
      LaboranDenahMejaPage(
        store: _store,
        onLogoTap: () => _openTabFromSubPage(LaboranShell.tabBeranda),
        onOpenTiketTab: () => _openTabFromSubPage(LaboranShell.tabTiket),
      ),
    );
  }

  void _openPresensi() {
    labPush(
      context,
      LaboranPresensiAsistenPage(
        store: _store,
        onLogoTap: () => _openTabFromSubPage(LaboranShell.tabBeranda),
      ),
    );
  }

  void _openTicket(LabTicket ticket) {
    labPush(
      context,
      LaboranDetailTiketPage(
        ticket: ticket,
        onLogoTap: () => _openTabFromSubPage(LaboranShell.tabBeranda),
      ),
    );
  }

  void _openNotifikasi() {
    labPush(
      context,
      LaboranNotifikasiPage(
        store: _store,
        onLogoTap: () => _openTabFromSubPage(LaboranShell.tabBeranda),
        onOpen: (target) {
          switch (target) {
            case LabNotifTarget.tiket:
              _openTabFromSubPage(LaboranShell.tabTiket);
              break;
            case LabNotifTarget.ruangan:
              _openTabFromSubPage(LaboranShell.tabRuangan);
              break;
            case LabNotifTarget.inventaris:
              _openTabFromSubPage(LaboranShell.tabInventaris);
              break;
            case LabNotifTarget.presensi:
              _openPresensi();
              break;
            case LabNotifTarget.detailTiket:
              _openTicket(_store.tickets[2]);
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
      case LaboranShell.tabTiket:
        return LaboranTiketPage(store: _store, onOpenTicket: _openTicket);
      case LaboranShell.tabRuangan:
        return LaboranApprovalPage(store: _store);
      case LaboranShell.tabInventaris:
        return LaboranInventarisPage(
          store: _store,
          onLogoTap: () => _openTabFromSubPage(LaboranShell.tabBeranda),
        );
      case LaboranShell.tabProfil:
        return LaboranProfilPage(
          store: _store,
          onLogout: () async => await AuthController.instance.logout(),
        );
      default:
        return LaboranBerandaPage(
          onOpenTab: _openTab,
          onOpenPresensi: _openPresensi,
          onOpenNotifikasi: _openNotifikasi,
          onOpenDenahMeja: _openDenahMeja,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark
          .copyWith(statusBarColor: Colors.transparent),
      child: PopScope(
        canPop: _tab == LaboranShell.tabBeranda,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _tab != LaboranShell.tabBeranda) {
            _openTab(LaboranShell.tabBeranda);
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
                child: LabTopBar(
                  onLogoTap: () => _openTab(LaboranShell.tabBeranda),
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
      ),
    );
  }
}
