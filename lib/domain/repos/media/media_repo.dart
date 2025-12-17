import 'dart:io';
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

  Future<String> uploadProfilePhoto(File file) async {
    final uid = _uid();
    final ref = storage.ref('users/$uid/profile.jpg');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }

  Future<String> uploadChatMedia({
    required String conversationId,
    required File file,
    required String ext, // jpg/mp4/aac/pdf...
  }) async {
    final uid = _uid();
    final name = DateTime.now().millisecondsSinceEpoch.toString();
    final ref = storage.ref('chat/$conversationId/$uid/$name.$ext');
    await ref.putFile(file);
    return ref.getDownloadURL();
  }
}
