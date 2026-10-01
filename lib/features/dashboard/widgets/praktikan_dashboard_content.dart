import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'stat_metric_card.dart';

class PraktikanDashboardContent extends StatelessWidget {
  final VoidCallback onNavigateToAttendance;
  final VoidCallback onNavigateToReports;

  const PraktikanDashboardContent({
    super.key,
    required this.onNavigateToAttendance,
    required this.onNavigateToReports,
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
              colors: [AppColors.praktikan, Color(0xFF0F766E)],
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
                  Icon(Icons.verified_user_outlined, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Presensi Anti-Kecurangan Aktif',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Halo, Praktikan!',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'NIM: 241402105 • Kelas Praktikum Mobile (Lab 3)',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: onNavigateToAttendance,
                icon: const Icon(Icons.qr_code_scanner, size: 16),
                label: const Text('Scan QR Presensi Sesi Aktif'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.praktikan,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Metrik Ringkas
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.45,
          children: const [
            StatMetricCard(
              title: 'Kehadiran',
              value: '95%',
              subtitle: 'Memenuhi syarat ujian',
              icon: Icons.check_circle_outline,
              color: AppColors.praktikan,
            ),
            StatMetricCard(
              title: 'Akumulasi Nilai',
              value: '88.5',
              subtitle: 'Transparansi nilai harian',
              icon: Icons.grade_outlined,
              color: AppColors.dosen,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Jadwal & Modul Minggu Berjalan
        const Text(
          'Jadwal & Modul Praktikum Minggu Ini',
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.praktikan.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Senin, 13:00 - 15:30 WIB',
                      style: TextStyle(color: AppColors.praktikan, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ),
                  const Text('Lab Komputer 3', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Pemrograman Mobile: Modul 04 - Clean Architecture & SQLite',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              const Text(
                'Asisten: Abbil Rizki & Daniele Christian',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Mengunduh Modul_04.pdf ke penyimpanan lokal...')),
                      );
                    },
                    icon: const Icon(Icons.download_rounded, size: 16),
                    label: const Text('Unduh Modul PDF', style: TextStyle(fontSize: 12)),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: onNavigateToReports,
                    icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                    label: const Text('Kirim Tugas', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.praktikan,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Transparansi Nilai & Catatan Evaluasi Asisten
        const Text(
          'Catatan Evaluasi & Feedback Asisten Terakhir',
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tugas Modul 3: Relasi Database', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Nilai: 92/100', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Feedback Aslab (Abbil): "Struktur query foreign key dan eksekusi join sudah sangat rapi. Perhatikan indexing untuk optimasi performa."',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
