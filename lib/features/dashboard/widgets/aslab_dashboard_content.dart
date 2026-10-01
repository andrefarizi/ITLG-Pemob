import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'stat_metric_card.dart';

class AslabDashboardContent extends StatelessWidget {
  final VoidCallback onNavigateToAttendance;
  final VoidCallback onNavigateToReports;
  final VoidCallback onOpenTicketing;

  const AslabDashboardContent({
    super.key,
    required this.onNavigateToAttendance,
    required this.onNavigateToReports,
    required this.onOpenTicketing,
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
              colors: [AppColors.aslab, Color(0xFF6D28D9)],
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
                  Icon(Icons.timer_outlined, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Sesi QR Dinamis Auto-Refresh (15 Detik)',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Halo, Asisten Laboratorium!',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Shift Aktif: Lab Komputer 3 (13:00 - 15:30 WIB)',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: onNavigateToAttendance,
                    icon: const Icon(Icons.qr_code_2, size: 16),
                    label: const Text('Buka QR Sesi Presensi'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.aslab,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: onOpenTicketing,
                    icon: const Icon(Icons.report_problem_outlined, size: 16, color: Colors.white),
                    label: const Text('Lapor Kendala', style: TextStyle(color: Colors.white)),
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

        // Metrik Ringkas Aslab
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.45,
          children: const [
            StatMetricCard(
              title: 'Antrian Evaluasi',
              value: '18 Tugas',
              subtitle: 'Rubrik DB & Query',
              icon: Icons.rate_review_outlined,
              color: AppColors.warning,
            ),
            StatMetricCard(
              title: 'Shift Jaga',
              value: '3 Sesi',
              subtitle: 'Jadwal minggu ini',
              icon: Icons.calendar_month_outlined,
              color: AppColors.aslab,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Evaluasi & Grading Antrian
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Antrian Evaluasi & Grading Tugas',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
            ),
            TextButton(
              onPressed: onNavigateToReports,
              child: const Text('Buka Semua', style: TextStyle(fontSize: 12, color: AppColors.aslab)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.aslab.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.code, color: AppColors.aslab),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Modul 03: Relasi DB & Eksekusi Query SQL',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '32 pengumpulan praktikan • Rubrik grading siap diinput',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: onNavigateToReports,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.aslab,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                ),
                child: const Text('Nilai', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Koordinasi Shift Jaga & Tukar Shift
        const Text(
          'Koordinasi Shift Jaga Aslab',
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
                  Text('Rabu, 08:00 - 10:30 WIB', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text('Lab Basis Data', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
              const SizedBox(height: 4),
              const Text('Mata Kuliah: Basis Data Terdistribusi (Kelas B)', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('Rekan: Daniele Christian', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Permintaan swap request tukar shift dikirim ke rekan aslab!')),
                      );
                    },
                    icon: const Icon(Icons.swap_horiz, size: 14),
                    label: const Text('Ajukan Tukar Shift', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
