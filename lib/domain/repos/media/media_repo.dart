import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/supabase_config.dart';
import '../repo_exceptions.dart';

class MediaRepo {
  final SupabaseClient db;
  MediaRepo(this.db);

  String _uid() {
    final u = db.auth.currentUser;
    if (u == null) throw PermissionException('User is not signed in');
    return u.id;
  }

  Future<String> uploadProfilePhotoBytes({
    required Uint8List bytes,
    String mimeType = 'image/jpeg',
  }) async {
    final uid = _uid();
    final path = 'users/$uid/profile.jpg';
    final bucket = db.storage.from(SupabaseConfig.profileBucket);
    await bucket.uploadBinary(path, bytes, fileOptions: FileOptions(contentType: mimeType, upsert: true));
    return '${bucket.getPublicUrl(path)}?v=${DateTime.now().millisecondsSinceEpoch}';
  }

  Future<String> uploadChatMediaBytes({
    required String conversationId,
    required Uint8List bytes,
    required String ext,
    String mimeType = 'image/jpeg',
  }) async {
    final uid = _uid();
    final name = DateTime.now().millisecondsSinceEpoch.toString();
    final path = '$conversationId/$uid/$name.$ext';
    final bucket = db.storage.from(SupabaseConfig.chatBucket);
    await bucket.uploadBinary(path, bytes, fileOptions: FileOptions(contentType: mimeType));
    return bucket.getPublicUrl(path);
  }

  /// Group avatar (written at group-creation time).
  Future<String> uploadGroupAvatarBytes({
    required String groupId,
    required Uint8List bytes,
    String mimeType = 'image/jpeg',
  }) async {
    _uid();
    final path = 'groups/$groupId/avatar.jpg';
    final bucket = db.storage.from(SupabaseConfig.profileBucket);
    await bucket.uploadBinary(path, bytes, fileOptions: FileOptions(contentType: mimeType, upsert: true));
    return '${bucket.getPublicUrl(path)}?v=${DateTime.now().millisecondsSinceEpoch}';
  }
}
