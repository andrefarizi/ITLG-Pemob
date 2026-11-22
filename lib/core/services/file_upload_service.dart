import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Hasil pemilihan berkas nyata dari penyimpanan perangkat + unggah ke BE.
class UploadedDeviceFile {
  final String name;
  final String localPath;
  final int sizeBytes;
  final String mimeType;
  final String? remoteUrl;
  final bool uploadedToCloud;

  const UploadedDeviceFile({
    required this.name,
    required this.localPath,
    required this.sizeBytes,
    required this.mimeType,
    this.remoteUrl,
    this.uploadedToCloud = false,
  });

  String get extensionLabel {
    final idx = name.lastIndexOf('.');
    if (idx != -1 && idx < name.length - 1) {
      return name.substring(idx + 1).toUpperCase();
    }
    if (mimeType.contains('pdf')) return 'PDF';
    if (mimeType.contains('image')) return 'IMG';
    return 'FILE';
  }

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).round()} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} MB';
  }

  String get metaLabel =>
      '$extensionLabel • $formattedSize${uploadedToCloud ? ' • Tersimpan di BE' : ''}';
}

/// Service pemilih berkas/foto nyata dari penyimpanan perangkat (Android SAF)
/// sekaligus pengunggah langsung ke Supabase Storage bucket `itlg-uploads`.
class FileUploadService {
  static final FileUploadService instance = FileUploadService._();
  FileUploadService._();

  static const String bucketName = 'itlg-uploads';
  static const MethodChannel _channel =
      MethodChannel('com.example.itlg_mobile/files');

  /// Membuka pemilih berkas/galeri asli perangkat lalu langsung mengunggahnya
  /// ke Supabase Storage (`itlg-uploads/<folder>/...`).
  /// Mengembalikan `null` jika pengguna membatalkan pemilihan.
  Future<UploadedDeviceFile?> pickAndUpload({
    required String folder,
    bool imagesOnly = false,
  }) async {
    if (kIsWeb || !Platform.isAndroid) return null;

    Map<String, dynamic>? picked;
    try {
      picked = await _channel.invokeMapMethod<String, dynamic>(
        'pickFile',
        {'imagesOnly': imagesOnly},
      );
    } catch (e) {
      debugPrint('[FileUpload] pickFile error: $e');
      return null;
    }

    if (picked == null) return null;

    final name = (picked['name'] as String?) ?? 'berkas';
    final path = (picked['path'] as String?) ?? '';
    final size = (picked['size'] as num?)?.toInt() ?? 0;
    final mimeType =
        (picked['mimeType'] as String?) ?? 'application/octet-stream';

    if (path.isEmpty) return null;

    String? remoteUrl;
    bool uploaded = false;

    final client = SupabaseService.instance.client;
    if (client != null) {
      try {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          final safeName = name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
          final objectPath =
              '$folder/${DateTime.now().millisecondsSinceEpoch}_$safeName';

          await client.storage.from(bucketName).uploadBinary(
                objectPath,
                bytes,
                fileOptions: FileOptions(
                  contentType: mimeType,
                  upsert: true,
                ),
              );
          remoteUrl = client.storage.from(bucketName).getPublicUrl(objectPath);
          uploaded = true;
          debugPrint('[FileUpload] Berhasil unggah ke Supabase Storage: $objectPath');
        }
      } catch (e) {
        debugPrint(
            '[FileUpload] Gagal unggah ke bucket $bucketName (tetap pakai berkas perangkat): $e');
      }
    }

    return UploadedDeviceFile(
      name: name,
      localPath: path,
      sizeBytes: size,
      mimeType: mimeType,
      remoteUrl: remoteUrl,
      uploadedToCloud: uploaded,
    );
  }
}
