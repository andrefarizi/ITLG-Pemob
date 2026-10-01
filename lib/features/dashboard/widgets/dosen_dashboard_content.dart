import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'stat_metric_card.dart';

class DosenDashboardContent extends StatelessWidget {
  final VoidCallback onNavigateToReports;

  const DosenDashboardContent({
    super.key,
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
              colors: [AppColors.dosen, Color(0xFF1D4ED8)],
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
                  Icon(Icons.analytics_outlined, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Dashboard Metrik & Sinkronisasi Portal Akademik',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Selamat Datang, Dosen Pengampu!',
                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pantau metrik kehadiran, rata-rata nilai, validasi rekap, & unduh laporan.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Mengunduh Berkas Rekapitulasi Nilai (Spreadsheet/Excel)...')),
                  );
                },
                icon: const Icon(Icons.table_chart_outlined, size: 16),
                label: const Text('1-Klik Unduh Rekap (Spreadsheet/PDF)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.dosen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // Metrik Ringkas Dosen
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.45,
          children: const [
            StatMetricCard(
              title: 'Rasio Kehadiran',
              value: '93.4%',
              subtitle: '4 Grup Praktikum',
              icon: Icons.pie_chart_outline,
              color: AppColors.dosen,
            ),
            StatMetricCard(
              title: 'Rata-rata Performa',
              value: '84.8 / 100',
              subtitle: 'Tugas & Kuis Lab',
              icon: Icons.trending_up,
              color: AppColors.praktikan,
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Statistik Per Grup Praktikum
        const Text(
          'Performa Rata-rata Kelas per Grup Praktikum',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 10),
        _buildKelasMetricRow('Pemrograman Mobile (Kelas A)', '32 Mhs', 0.94, 'Rata-rata Nilai: 86.2'),
        _buildKelasMetricRow('Pemrograman Mobile (Kelas B)', '34 Mhs', 0.91, 'Rata-rata Nilai: 83.5'),
        _buildKelasMetricRow('Basis Data Terdistribusi (Kelas A)', '30 Mhs', 0.96, 'Rata-rata Nilai: 87.0'),
        const SizedBox(height: 20),

        // Validasi Rekapitulasi Akhir
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Validasi Rekapitulasi Akhir Nilai',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
            ),
            TextButton(
              onPressed: onNavigateToReports,
              child: const Text('Detail Lengkap', style: TextStyle(fontSize: 12, color: AppColors.dosen)),
            ),
          ],
        ),
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
                  const Text('Pemrograman Mobile - Seluruh Modul', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('Perlu Validasi', style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 11)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text('Disusun oleh Tim Aslab: Abbil Rizki & Daniele Christian', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const Text('Total mahasiswa dinilai: 66 praktikan (Kelas A & B)', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const Divider(height: 20),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: onNavigateToReports,
                    icon: const Icon(Icons.preview_outlined, size: 16),
                    label: const Text('Tinjau Nilai', style: TextStyle(fontSize: 12)),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Nilai tervalidasi dan siap disinkronisasi ke portal akademik!')),
                      );
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 16),
                    label: const Text('Validasi & Sinkronisasi', style: TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.dosen,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKelasMetricRow(String kelas, String mhs, double attendanceRate, String rataRata) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(kelas, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              Text(mhs, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: attendanceRate,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.dosen),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tingkat Kehadiran: ${(attendanceRate * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Text(rataRata, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            ],
          ),
        ],
      ),
    );
  }
}
