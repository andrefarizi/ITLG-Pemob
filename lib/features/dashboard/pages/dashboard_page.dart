import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/constants.dart';
import '../../auth/auth_controller.dart';
import '../../auth/widgets/role_badge.dart';
import '../../praktikan/dashboard/praktikan_dashboard_page.dart';
import '../../aslab/dashboard/aslab_dashboard_page.dart';
import '../../laboran/dashboard/laboran_dashboard_page.dart';
import '../../dosen/dashboard/dosen_dashboard_page.dart';

class DashboardPage extends StatefulWidget {
  final Function(int) onTabChange;

  const DashboardPage({super.key, required this.onTabChange});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final AuthController _authController = AuthController.instance;

  @override
  void initState() {
    super.initState();
    _authController.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    _authController.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  void _showRoleSwitchDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Ganti Peran Pengguna (Role)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: UserRole.values.map((role) {
              final isCurrent = _authController.currentRole == role;
              return ListTile(
                leading: Icon(role.icon, color: role.color),
                title: Text(role.displayName, style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal)),
                trailing: isCurrent ? Icon(Icons.check, color: role.color) : null,
                onTap: () {
                  _authController.setRole(role);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showTicketingDialog() {
    final TextEditingController pcController = TextEditingController();
    final TextEditingController issueController = TextEditingController();
    String selectedCategory = 'PC / Monitor';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.report_problem, color: AppColors.danger),
                  SizedBox(width: 8),
                  Text(
                    'Laporan Kendala Lab (Ticketing Instan)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Laporan ini akan langsung diterima oleh Laboran pengawas.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: const InputDecoration(labelText: 'Kategori Kerusakan'),
                items: ['PC / Monitor', 'Proyektor', 'AC Ruangan', 'Koneksi Jaringan', 'Software / Tools Basis Data']
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 13))))
                    .toList(),
                onChanged: (val) {
                  if (val != null) selectedCategory = val;
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: pcController,
                decoration: const InputDecoration(
                  labelText: 'Nomor Meja / Kode Perangkat',
                  hintText: 'Contoh: PC-08 Lab Komputer 3',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: issueController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Detail Kendala',
                  hintText: 'Jelaskan kerusakan secara singkat...',
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tiket kendala berhasil dilaporkan ke Laboran!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.danger,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Kirim Laporan Tiket'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInventarisModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  const Text(
                    'Data Inventaris Meja, PC & Tools Lab',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  const Text('Laboran Otoritas: Daftar kelengkapan software & hardware', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 14),
                  _buildInventarisItem('Lab 3 - Meja 01 s/d 36', '36 Unit PC Core i7, 16GB RAM, SSD 512GB', 'Visual Studio Code, Flutter SDK, PostgreSQL', true),
                  _buildInventarisItem('Lab 2 - Meja 01 s/d 36', '36 Unit PC Core i5, 16GB RAM', 'MySQL Workbench, Oracle 19c Client', true),
                  _buildInventarisItem('Lab Jaringan - Rack 1 & 2', 'Router MikroTik RB750Gr3, Cisco Catalyst', 'Wireshark, Cisco Packet Tracer', true),
                  _buildInventarisItem('Proyektor Lab 3', 'Epson EB-X400 (3300 Lumens)', 'Kabel HDMI & Wireless Dongle', false),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInventarisItem(String nama, String spek, String tools, bool isReady) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(nama, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isReady ? AppColors.success : AppColors.warning).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  isReady ? 'Siap Pakai' : 'Perlu Pengecekan',
                  style: TextStyle(
                    color: isReady ? AppColors.success : AppColors.warning,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('Spek: $spek', style: const TextStyle(fontSize: 11, color: AppColors.textPrimary)),
          Text('Software/Tools: $tools', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final role = _authController.currentRole;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: role.color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.biotech, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppConstants.appName,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  _authController.userName,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Ganti Role',
            icon: RoleBadge(role: role),
            onPressed: _showRoleSwitchDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _buildRoleContent(role),
      ),
    );
  }

  Widget _buildRoleContent(UserRole role) {
    switch (role) {
      case UserRole.praktikan:
        return PraktikanDashboardPage(
          onNavigateToAttendance: () => widget.onTabChange(1),
          onNavigateToReports: () => widget.onTabChange(2),
        );
      case UserRole.aslab:
        return AslabDashboardPage(
          onNavigateToAttendance: () => widget.onTabChange(1),
          onNavigateToReports: () => widget.onTabChange(2),
          onOpenTicketing: _showTicketingDialog,
        );
      case UserRole.laboran:
        return LaboranDashboardPage(
          onNavigateToAttendance: () => widget.onTabChange(1),
          onNavigateToReports: () => widget.onTabChange(2),
          onOpenInventaris: _showInventarisModal,
        );
      case UserRole.dosen:
        return DosenDashboardPage(
          onNavigateToReports: () => widget.onTabChange(2),
        );
    }
  }
}
