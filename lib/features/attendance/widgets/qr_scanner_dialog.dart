import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class QrScannerDialog extends StatefulWidget {
  final Function(String) onScanned;

  const QrScannerDialog({super.key, required this.onScanned});

  @override
  State<QrScannerDialog> createState() => _QrScannerDialogState();
}

class _QrScannerDialogState extends State<QrScannerDialog> {
  bool _isProcessing = false;

  void _simulateScanSuccess() async {
    setState(() {
      _isProcessing = true;
    });

    await Future.delayed(const Duration(milliseconds: 1200));

    if (mounted) {
      widget.onScanned('SESI-AKTIF-MODUL-04');
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        height: 420,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Kamera Scanner Anti-Kecurangan',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Viewfinder Frame
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.praktikan, width: 2.5),
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                    child: _isProcessing
                        ? const Center(
                            child: CircularProgressIndicator(color: AppColors.praktikan),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.qr_code_scanner, color: Colors.white70, size: 60),
                              SizedBox(height: 8),
                              Text(
                                'Arahkan ke QR Code Aslab',
                                style: TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Validasi Sesi Aktif: Memverifikasi waktu dan token 15 detik untuk memastikan kehadiran nyata di lab.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 11),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _simulateScanSuccess,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Simulasi Pindai Berhasil'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.praktikan,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
