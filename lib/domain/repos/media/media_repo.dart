import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../repo_exceptions.dart';

class MediaRepo {
  final FirebaseStorage storage;
  final FirebaseAuth auth;
  MediaRepo(this.storage, this.auth);

  String _uid() {
    final u = auth.currentUser;
    if (u == null) throw PermissionException('User is not signed in');
    return u.uid;
  }

  Future<String> uploadProfilePhotoBytes({
    required Uint8List bytes,
    String mimeType = 'image/jpeg',
  }) async {
    final uid = _uid();
    final ref = storage.ref('users/$uid/profile.jpg');
    await ref.putData(bytes, SettableMetadata(contentType: mimeType));
    return ref.getDownloadURL();
  }

  Future<String> uploadChatMediaBytes({
    required String conversationId,
    required Uint8List bytes,
    required String ext,
    String mimeType = 'image/jpeg',
  }) async {
    final uid = _uid();
    final name = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = storage.ref('chat/$conversationId/$uid/$name.$ext');
    await ref.putData(bytes, SettableMetadata(contentType: mimeType));
    return ref.getDownloadURL();
  }
}
