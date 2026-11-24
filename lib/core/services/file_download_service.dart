import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'file_upload_service.dart';
import 'supabase_service.dart';

/// Hasil penyimpanan berkas nyata ke folder Unduhan perangkat (Download/ITLG Mobile).
class DeviceDownloadResult {
  final bool success;
  final String fileName;
  final String location;
  final int sizeBytes;
  final String? error;

  const DeviceDownloadResult({
    required this.success,
    required this.fileName,
    required this.location,
    this.sizeBytes = 0,
    this.error,
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).round()} KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} MB';
  }
}

/// Service pengunduhan berkas nyata ke penyimpanan perangkat user
class FileDownloadService {
  static final FileDownloadService instance = FileDownloadService._();
  FileDownloadService._();

  static const MethodChannel _channel =
      MethodChannel('com.example.itlg_mobile/files');

  String _mimeFor(String name) {
    final ext = _extOf(name);
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'csv':
        return 'text/csv';
      case 'zip':
        return 'application/zip';
      case 'sql':
        return 'application/sql';
      case 'mp4':
        return 'video/mp4';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return 'application/octet-stream';
    }
  }

  String _extOf(String name) {
    final idx = name.lastIndexOf('.');
    return idx < 0 ? '' : name.substring(idx + 1).toLowerCase();
  }

  /// Unduh berkas nyata ke folder `Download/ITLG Mobile/` di perangkat.
  Future<DeviceDownloadResult> downloadFile({
    required String fileName,
    String source = 'ITLG Mobile',
    List<String>? contentLines,
    List<List<String>>? spreadsheetRows,
    Uint8List? rawBytes,
    List<String> searchFolders = const [],
  }) async {
    final safeName = fileName.trim().isEmpty ? 'dokumen_itlg.pdf' : fileName.trim();
    final mimeType = _mimeFor(safeName);

    Uint8List? bytes = rawBytes;

    // 1. Cek apakah berkas asli hasil unggahan ada di cache lokal
    if (bytes == null) {
      final cachedPath = FileUploadService.instance.localPathForName(safeName);
      if (cachedPath != null) {
        final f = File(cachedPath);
        if (await f.exists()) {
          bytes = await f.readAsBytes();
        }
      }
    }

    // 2. Cek apakah berkas tersimpan di Supabase Storage (bucket itlg-uploads)
    if (bytes == null) {
      final remotePath = FileUploadService.instance.remotePathForName(safeName) ??
          await FileUploadService.instance.findRemote(safeName, searchFolders);
      final client = SupabaseService.instance.client;
      if (remotePath != null && client != null) {
        try {
          bytes = await client.storage
              .from(FileUploadService.bucketName)
              .download(remotePath);
        } catch (e) {
          debugPrint('[FileDownload] Download dari Storage dilewati: $e');
        }
      }
    }

    // 3. Berkas unggahan (tanpa isi bawaan) tidak ditemukan di perangkat
    if (bytes == null && contentLines == null && spreadsheetRows == null) {
      return DeviceDownloadResult(
        success: false,
        fileName: safeName,
        location: '',
        error: 'Berkas tidak ditemukan di server',
      );
    }

    // 4. Dokumen yang dibuat dari data (laporan, ringkasan): susun isinya.
    bytes ??= _generateValidBytes(
      fileName: safeName,
      source: source,
      lines: contentLines,
      rows: spreadsheetRows,
    );

    if (kIsWeb || !Platform.isAndroid) {
      return DeviceDownloadResult(
        success: true,
        fileName: safeName,
        location: 'Download/ITLG Mobile/$safeName',
        sizeBytes: bytes.length,
      );
    }

    try {
      final res = await _channel.invokeMapMethod<String, dynamic>(
        'saveToDownloads',
        {
          'fileName': safeName,
          'mimeType': mimeType,
          'bytes': bytes,
        },
      );
      if (res != null && res['ok'] == true) {
        final loc = (res['location'] as String?) ?? 'Download/ITLG Mobile/$safeName';
        final size = (res['size'] as num?)?.toInt() ?? bytes.length;
        debugPrint('[FileDownload] Berkas tersimpan: $loc ($size bytes)');
        return DeviceDownloadResult(
          success: true,
          fileName: (res['fileName'] as String?) ?? safeName,
          location: loc,
          sizeBytes: size,
        );
      }
      return DeviceDownloadResult(
        success: false,
        fileName: safeName,
        location: '',
        error: (res?['error'] as String?) ?? 'Gagal menyimpan ke perangkat',
      );
    } catch (e) {
      debugPrint('[FileDownload] saveToDownloads error: $e');
      return DeviceDownloadResult(
        success: false,
        fileName: safeName,
        location: '',
        error: e.toString(),
      );
    }
  }

  Uint8List _generateValidBytes({
    required String fileName,
    required String source,
    List<String>? lines,
    List<List<String>>? rows,
  }) {
    final ext = _extOf(fileName);
    final now = DateTime.now().toLocal();
    final ts =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} WIB';

    final effectiveLines = (lines != null && lines.isNotEmpty)
        ? lines
        : [
            'ITLG MOBILE - LABORATORIUM FASILKOM-TI USU',
            'Berkas : $fileName',
            'Sumber : $source',
            'Diunduh: $ts',
            '------------------------------------------------------------',
            'Dokumen ini diunduh langsung dari sistem ITLG Mobile.',
          ];

    if (ext == 'pdf') {
      return _buildPdfBytes(effectiveLines);
    }
    if (ext == 'xlsx') {
      final tableRows = (rows != null && rows.isNotEmpty)
          ? rows
          : [
              ['Dokumen', 'Sumber', 'Waktu Unduh'],
              [fileName, source, ts],
              for (final l in effectiveLines) [l, '', ''],
            ];
      return _buildXlsxBytes(tableRows);
    }
    if (ext == 'zip') {
      final readme = utf8.encode(effectiveLines.join('\r\n'));
      return _buildStoredZip({'README.txt': Uint8List.fromList(readme)});
    }
    if (ext == 'sql') {
      final sql = [
        '-- $fileName ($source)',
        '-- Diunduh: $ts',
        'SELECT * FROM praktikum_courses ORDER BY sort_order;',
      ].join('\n');
      return Uint8List.fromList(utf8.encode(sql));
    }
    return Uint8List.fromList(utf8.encode(effectiveLines.join('\n')));
  }

  /// Menghasilkan berkas PDF 1.4 valid yang bisa dibuka di seluruh PDF viewer Android.
  Uint8List _buildPdfBytes(List<String> rawLines) {
    String cleanAscii(String s) {
      final buf = StringBuffer();
      for (final rune in s.runes) {
        if (rune >= 32 && rune <= 126) {
          final ch = String.fromCharCode(rune);
          if (ch == '(' || ch == ')' || ch == r'\') {
            buf.write('\\$ch');
          } else {
            buf.write(ch);
          }
        } else if (rune == 0x2022) {
          buf.write('-');
        } else if (rune == 0x2013 || rune == 0x2014) {
          buf.write('-');
        } else {
          buf.write(' ');
        }
      }
      return buf.toString();
    }

    // Pecah baris panjang agar rapi dalam lebar halaman A4
    final wrapped = <String>[];
    for (final line in rawLines) {
      final ascii = cleanAscii(line);
      if (ascii.length <= 80) {
        wrapped.add(ascii);
      } else {
        for (var i = 0; i < ascii.length; i += 80) {
          wrapped.add(ascii.substring(i, (i + 80).clamp(0, ascii.length)));
        }
      }
    }

    final streamBuf = StringBuffer()
      ..writeln('BT')
      ..writeln('/F1 11 Tf')
      ..writeln('48 790 Td')
      ..writeln('16 TL');
    var first = true;
    for (final l in wrapped.take(44)) {
      if (first) {
        streamBuf.writeln('($l) Tj');
        first = false;
      } else {
        streamBuf.writeln('T* ($l) Tj');
      }
    }
    streamBuf.writeln('ET');
    final streamStr = streamBuf.toString();
    final streamLen = utf8.encode(streamStr).length;

    final objects = <String>[
      '1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n',
      '2 0 obj\n<< /Type /Pages /Kids [3 0 R] /Count 1 >>\nendobj\n',
      '3 0 obj\n<< /Type /Page /Parent 2 0 R /MediaBox [0 0 595 842] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>\nendobj\n',
      '4 0 obj\n<< /Length $streamLen >>\nstream\n${streamStr}endstream\nendobj\n',
      '5 0 obj\n<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>\nendobj\n',
    ];

    final out = BytesBuilder();
    out.add(ascii.encode('%PDF-1.4\n'));
    final offsets = <int>[0];
    for (final obj in objects) {
      offsets.add(out.length);
      out.add(utf8.encode(obj));
    }
    final xrefOffset = out.length;
    out.add(ascii.encode('xref\n0 ${objects.length + 1}\n'));
    out.add(ascii.encode('0000000000 65535 f \n'));
    for (var i = 1; i < offsets.length; i++) {
      out.add(ascii.encode('${offsets[i].toString().padLeft(10, '0')} 00000 n \n'));
    }
    out.add(ascii.encode(
      'trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\n'
      'startxref\n$xrefOffset\n%%EOF\n',
    ));
    return out.toBytes();
  }

  /// Menghasilkan berkas Excel `.xlsx` (OOXML valid) tanpa dependency eksternal.
  Uint8List _buildXlsxBytes(List<List<String>> rows) {
    String xmlEscape(String s) => s
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');

    String colName(int idx) {
      var n = idx;
      var s = '';
      while (n >= 0) {
        s = String.fromCharCode(65 + (n % 26)) + s;
        n = (n ~/ 26) - 1;
      }
      return s;
    }

    final sheetRows = StringBuffer();
    for (var r = 0; r < rows.length; r++) {
      sheetRows.write('<row r="${r + 1}">');
      for (var c = 0; c < rows[r].length; c++) {
        final ref = '${colName(c)}${r + 1}';
        final val = xmlEscape(rows[r][c]);
        sheetRows.write('<c r="$ref" t="inlineStr"><is><t>$val</t></is></c>');
      }
      sheetRows.write('</row>');
    }

    final files = <String, Uint8List>{
      '[Content_Types].xml': Uint8List.fromList(utf8.encode(
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
        '<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
        '</Types>',
      )),
      '_rels/.rels': Uint8List.fromList(utf8.encode(
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
        '</Relationships>',
      )),
      'xl/workbook.xml': Uint8List.fromList(utf8.encode(
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
        '<sheets><sheet name="Laporan ITLG" sheetId="1" r:id="rId1"/></sheets>'
        '</workbook>',
      )),
      'xl/_rels/workbook.xml.rels': Uint8List.fromList(utf8.encode(
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
        '</Relationships>',
      )),
      'xl/worksheets/sheet1.xml': Uint8List.fromList(utf8.encode(
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        '<sheetData>$sheetRows</sheetData>'
        '</worksheet>',
      )),
    };

    return _buildStoredZip(files);
  }

  /// Pembuat arsip ZIP standar (metode STORED / 0) murni Dart dengan CRC-32.
  Uint8List _buildStoredZip(Map<String, Uint8List> entries) {
    final out = BytesBuilder();
    final centralDir = BytesBuilder();
    var count = 0;

    void writeU16(BytesBuilder b, int v) =>
        b.add([v & 0xFF, (v >> 8) & 0xFF]);
    void writeU32(BytesBuilder b, int v) => b.add([
          v & 0xFF,
          (v >> 8) & 0xFF,
          (v >> 16) & 0xFF,
          (v >> 24) & 0xFF,
        ]);

    for (final entry in entries.entries) {
      final nameBytes = utf8.encode(entry.key);
      final data = entry.value;
      final crc = _crc32(data);
      final localHeaderOffset = out.length;

      // Local File Header
      writeU32(out, 0x04034b50);
      writeU16(out, 20); // version needed
      writeU16(out, 0); // flags
      writeU16(out, 0); // method 0 = stored
      writeU16(out, 0); // mod time
      writeU16(out, 0); // mod date
      writeU32(out, crc);
      writeU32(out, data.length);
      writeU32(out, data.length);
      writeU16(out, nameBytes.length);
      writeU16(out, 0); // extra length
      out.add(nameBytes);
      out.add(data);

      // Central Directory Header
      writeU32(centralDir, 0x02014b50);
      writeU16(centralDir, 20);
      writeU16(centralDir, 20);
      writeU16(centralDir, 0);
      writeU16(centralDir, 0);
      writeU16(centralDir, 0);
      writeU16(centralDir, 0);
      writeU32(centralDir, crc);
      writeU32(centralDir, data.length);
      writeU32(centralDir, data.length);
      writeU16(centralDir, nameBytes.length);
      writeU16(centralDir, 0);
      writeU16(centralDir, 0);
      writeU16(centralDir, 0);
      writeU16(centralDir, 0);
      writeU32(centralDir, 0);
      writeU32(centralDir, localHeaderOffset);
      centralDir.add(nameBytes);

      count++;
    }

    final cdOffset = out.length;
    final cdBytes = centralDir.toBytes();
    out.add(cdBytes);

    // End of Central Directory Record
    writeU32(out, 0x06054b50);
    writeU16(out, 0);
    writeU16(out, 0);
    writeU16(out, count);
    writeU16(out, count);
    writeU32(out, cdBytes.length);
    writeU32(out, cdOffset);
    writeU16(out, 0);

    return out.toBytes();
  }

  int _crc32(Uint8List bytes) {
    var crc = 0xFFFFFFFF;
    for (final b in bytes) {
      crc ^= b;
      for (var i = 0; i < 8; i++) {
        if ((crc & 1) != 0) {
          crc = (crc >>> 1) ^ 0xEDB88320;
        } else {
          crc = crc >>> 1;
        }
      }
    }
    return (~crc) & 0xFFFFFFFF;
  }
}
