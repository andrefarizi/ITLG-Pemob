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
      '$extensionLabel • $formattedSize${uploadedToCloud ? ' • Tersimpan di server' : ''}';
}

/// Service pemilih berkas/foto nyata dari penyimpanan perangkat (Android SAF)
class FileUploadService {
  static final FileUploadService instance = FileUploadService._();
  FileUploadService._();

  static const String bucketName = 'itlg-uploads';
  static const MethodChannel _channel =
      MethodChannel('com.example.itlg_mobile/files');

  final Map<String, String> _localPathByName = {};
  final Map<String, String> _remotePathByName = {};

  String? localPathForName(String name) => _localPathByName[name];
  String? remotePathForName(String name) => _remotePathByName[name];

  /// Daftarkan path Storage untuk nama berkas yang dibaca dari database
  void registerRemote(String name, String? objectPath) {
    if (objectPath == null || objectPath.trim().isEmpty) return;
    _remotePathByName[name] = objectPath.trim();
  }

  /// Cari objek Storage untuk [name] di salah satu [folders]. Berkas unggahan
  Future<String?> findRemote(String name, List<String> folders) async {
    final known = _remotePathByName[name];
    if (known != null) return known;
    final client = SupabaseService.instance.client;
    if (client == null || folders.isEmpty) return null;
    final safe = name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    for (final folder in folders) {
      try {
        final items = await client.storage.from(bucketName).list(
              path: folder,
              searchOptions: const SearchOptions(
                limit: 1000,
                sortBy: SortBy(column: 'created_at', order: 'desc'),
              ),
            );
        for (final it in items) {
          if (it.name == safe || it.name.endsWith('_$safe')) {
            final objectPath = '$folder/${it.name}';
            _remotePathByName[name] = objectPath;
            return objectPath;
          }
        }
      } catch (e) {
        debugPrint('[FileUpload] Gagal mencari $name di $folder: $e');
      }
    }
    return null;
  }

  /// Membuka pemilih berkas/galeri asli perangkat lalu langsung mengunggahnya
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
          _remotePathByName[name] = objectPath;
          uploaded = true;
          debugPrint('[FileUpload] Berhasil unggah ke Supabase Storage: $objectPath');
        }
      } catch (e) {
        debugPrint(
            '[FileUpload] Gagal unggah ke bucket $bucketName (tetap pakai berkas perangkat): $e');
      }
    }

    _localPathByName[name] = path;

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
