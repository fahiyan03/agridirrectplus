import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as p;

class StorageService {
  final _supabase = Supabase.instance.client;
  static const String _bucket = 'agri-images';

  // ── Image Upload ──────────────────────────────────────────

  Future<String?> uploadImage(File file, String folder) async {
    try {
      final userId  = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final fileName = '${DateTime.now().millisecondsSinceEpoch}${p.extension(file.path)}';
      final path     = '$userId/$folder/$fileName';

      await _supabase.storage.from(_bucket).upload(path, file,
          fileOptions: const FileOptions(upsert: true));

      return _supabase.storage.from(_bucket).getPublicUrl(path);
    } catch (_) {
      return null;
    }
  }

  // ── Profile Image Upload ──────────────────────────────────

  Future<String?> uploadProfileImage(File file) async {
    return await uploadImage(file, 'profiles');
  }

  // ── Product Image Upload ──────────────────────────────────

  Future<String?> uploadProductImage(File file) async {
    return await uploadImage(file, 'products');
  }

  // ── Delete Image ──────────────────────────────────────────

  Future<void> deleteImage(String imageUrl) async {
    try {
      // URL থেকে path বের করো
      final uri  = Uri.parse(imageUrl);
      final path = uri.pathSegments
          .skipWhile((s) => s != _bucket)
          .skip(1)
          .join('/');

      await _supabase.storage.from(_bucket).remove([path]);
    } catch (_) {}
  }

  // ── Get Public URL ────────────────────────────────────────

  String getPublicUrl(String path) {
    return _supabase.storage.from(_bucket).getPublicUrl(path);
  }
}