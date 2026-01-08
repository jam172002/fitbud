import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../../domain/models/auth/app_user.dart';
import '../../../domain/models/auth/user_settings.dart';
import '../../models/auth/user_address.dart';
import '../firestore_paths.dart';
import '../firestore_repo_base.dart';
import '../repo_exceptions.dart';

class AuthRepo extends RepoBase {
  final FirebaseAuth auth;
  AuthRepo(super.db, this.auth);

  Stream<User?> authState() => auth.authStateChanges();

  String requireUid() {
    final u = auth.currentUser;
    if (u == null) throw PermissionException('User is not signed in');
    return u.uid;
  }

  Future<void> signOut() => auth.signOut();

  // ---- Profile (users/{uid}) ----

  Stream<AppUser?> watchMe() {
    final uid = requireUid();
    return doc('${FirestorePaths.users}/$uid')
        .snapshots()
        .map((s) => s.exists ? AppUser.fromDoc(s) : null);
  }

  Future<AppUser> getUser(String uid) async {
    final snap = await doc('${FirestorePaths.users}/$uid').get();
    if (!snap.exists) throw NotFoundException('User not found');
    return AppUser.fromDoc(snap);
  }

  Future<void> upsertMe({
    required AppUser user,
    bool merge = true,
  }) async {
    final uid = requireUid();
    if (user.id != uid) throw PermissionException('Cannot write another user profile');
    await doc('${FirestorePaths.users}/$uid').set(user.toMap(), SetOptions(merge: merge));
  }

  Future<void> updateMeFields(Map<String, dynamic> fields) async {
    final uid = requireUid();
    await doc('${FirestorePaths.users}/$uid').update({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ---- Settings (users/{uid}/settings/settings) ----

  Stream<UserSettings?> watchMySettings() {
    final uid = requireUid();
    return doc(FirestorePaths.userSettings(uid))
        .snapshots()
        .map((s) => s.exists ? UserSettings.fromDoc(s) : null);
  }

  Future<void> upsertMySettings(UserSettings settings) async {
    final uid = requireUid();
    await doc(FirestorePaths.userSettings(uid)).set(
      {
        ...settings.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// One-time fetch of current signed-in user's profile
  Future<AppUser?> getMeOnce() async {
    final uid = requireUid();
    final snap = await doc('${FirestorePaths.users}/$uid').get();
    if (!snap.exists) return null;
    return AppUser.fromDoc(snap);
  }

  /// Uploads profile image and returns download URL
  Future<String> uploadMyProfileImage(File file) async {
    final uid = requireUid();

    // You can change file name later if you want unique versions.
    final ref = FirebaseStorage.instance.ref('users/$uid/profile.jpg');

    // Upload (contentType optional)
    await ref.putFile(
      file,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await ref.getDownloadURL();
  }

  // ---- Addresses (users/{uid}/addresses) ----

  Stream<List<UserAddress>> watchMyAddresses({int limit = 50}) {
    final uid = requireUid();
    return db
        .collection(FirestorePaths.userAddresses(uid))
        .orderBy('isDefault', descending: true)
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((q) => q.docs.map((d) => UserAddress.fromDoc(d)).toList());
  }

  /// Optional: fetch once
  Future<List<UserAddress>> getMyAddressesOnce({int limit = 50}) async {
    final uid = requireUid();
    final q = await db
        .collection(FirestorePaths.userAddresses(uid))
        .orderBy('isDefault', descending: true)
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .get();

    return q.docs.map((d) => UserAddress.fromDoc(d)).toList();
  }


}
