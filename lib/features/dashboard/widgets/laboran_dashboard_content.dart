import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'stat_metric_card.dart';

class LaboranDashboardContent extends StatelessWidget {
  final VoidCallback onNavigateToAttendance;
  final VoidCallback onNavigateToReports;
  final VoidCallback onOpenInventaris;

  const LaboranDashboardContent({
    super.key,
    required this.onNavigateToAttendance,
    required this.onNavigateToReports,
    required this.onOpenInventaris,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Welcome Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.laboran, Color(0xFFB45309)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.monitor_heart_outlined, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Live Monitoring & Manajemen Lab Aktif',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Halo, Pengawas Laboran!',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Otoritas persetujuan ruangan, tiket kerusakan, & inventaris PC/software.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: onNavigateToAttendance,
                    icon: const Icon(Icons.badge, size: 16),
                    label: const Text('Presensi Aslab On-Duty'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.laboran,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onOpenInventaris,
                    icon: const Icon(Icons.computer, size: 16, color: Colors.white),
                    label: const Text('Cek PC & Tools', style: TextStyle(color: Colors.white)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white70),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Metrik Ringkas Laboran
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.45,
          children: const [
            StatMetricCard(
              title: 'Lab Beroperasi',
              value: '3 / 4 Lab',
              subtitle: 'Sedang berlangsung',
              icon: Icons.meeting_room_outlined,
              color: AppColors.laboran,
            ),
            StatMetricCard(
              title: 'Tiket Perbaikan',
              value: '4 Laporan',
              subtitle: 'PC, AC & Proyektor',
              icon: Icons.confirmation_number_outlined,
              color: AppColors.danger,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Live Monitoring Lab Real-time
        const Text(
          'Live Monitoring: Status Ruangan Lab & Asisten On-Duty',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        _buildLiveLabCard(
          ruang: 'Lab Komputer 3',
          matkul: 'Pemrograman Mobile (Kelas A)',
          asistenOnDuty: 'Abbil Rizki & Daniele Christian',
          rasioKehadiran: '29 / 32 Mahasiswa (90.6%)',
          status: 'Sedang Aktif',
          statusColor: AppColors.success,
        ),
        const SizedBox(height: 10),
        _buildLiveLabCard(
          ruang: 'Lab Basis Data',
          matkul: 'Basis Data Terdistribusi (Kelas B)',
          asistenOnDuty: 'Reagan Brian & Andre Sebayang',
          rasioKehadiran: '31 / 34 Mahasiswa (91.1%)',
          status: 'Sedang Aktif',
          statusColor: AppColors.success,
        ),
        const SizedBox(height: 20),

        // Approval Permintaan Peminjaman Ruangan
        const Text(
          'Approval Peminjaman Ruangan Praktikum Pengganti',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Request: Lab Komputer 2', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text('Kamis, 15:30 WIB', style: TextStyle(fontSize: 12, color: AppColors.laboran, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Pemohon: Himpunan Mahasiswa Informatika / Aslab Pengganti', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const Text('Keperluan: Respon Akhir & Make-up Class Praktikum Mobile', style: TextStyle(fontSize: 12)),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                    ),
                    child: const Text('Tolak'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Peminjaman ruangan lab disetujui!')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.laboran,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Setujui Ruangan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLiveLabCard({
    required String ruang,
    required String matkul,
    required String asistenOnDuty,
    required String rasioKehadiran,
    required String status,
    required Color statusColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(ruang, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(matkul, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.person_pin, size: 14, color: AppColors.aslab),
              const SizedBox(width: 4),
              Text('Aslab On-Duty: $asistenOnDuty', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.people_alt_outlined, size: 14, color: AppColors.laboran),
              const SizedBox(width: 4),
              Text('Rasio Kehadiran Mahasiswa: $rasioKehadiran', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}
