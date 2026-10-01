import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class DynamicQrCard extends StatefulWidget {
  final String sessionTitle;
  final String labName;

  const DynamicQrCard({
    super.key,
    required this.sessionTitle,
    required this.labName,
  });

  @override
  State<DynamicQrCard> createState() => _DynamicQrCardState();
}

class _DynamicQrCardState extends State<DynamicQrCard> {
  int _secondsLeft = 15;
  Timer? _timer;
  int _tokenSeed = 8291;

  @override
  void initState() {
    super.initState();
    _startAutoRefreshTimer();
  }

  void _startAutoRefreshTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsLeft > 1) {
            _secondsLeft--;
          } else {
            _secondsLeft = 15;
            _tokenSeed = (_tokenSeed + 137) % 9999;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.sessionTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(widget.labName, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.aslab.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sync, size: 14, color: AppColors.aslab),
                    const SizedBox(width: 4),
                    Text('Auto-refresh ${_secondsLeft}s', style: const TextStyle(fontSize: 11, color: AppColors.aslab, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // QR Code representation
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.qr_code_2_rounded,
                  size: 180,
                  color: AppColors.aslab.withValues(alpha: 0.9),
                ),
                const SizedBox(height: 8),
                Text(
                  'TOKEN SESI: ITLG-M4-$_tokenSeed',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Anti-Kecurangan: QR Code dinamis berganti setiap 15 detik untuk mencegah pemindaian lewat screenshot.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
