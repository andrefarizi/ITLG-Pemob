import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (!SupabaseConfig.isConfigured) {
      debugPrint('[Supabase] Kredensial belum diisi di supabase_config.dart. Berjalan dalam mode Dummy Data.');
      return;
    }
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );
      _initialized = true;
      debugPrint('[Supabase] Berhasil terhubung ke Supabase!');
    } catch (e) {
      debugPrint('[Supabase] Gagal inisialisasi: $e');
      _initialized = false;
    }
  }

  SupabaseClient? get client {
    if (!_initialized) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
}
