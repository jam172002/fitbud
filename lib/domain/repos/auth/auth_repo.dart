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

  Future<String> addAddressEnforceMax2({
    required UserAddress address,
    bool makeDefaultIfFirst = true,
  }) async {
    final uid = requireUid();
    final colRef = db.collection(FirestorePaths.userAddresses(uid));

    // 1) Fetch existing docs OUTSIDE transaction (older plugin limitation)
    final pre = await colRef
        .orderBy('isDefault', descending: true)
        .orderBy('updatedAt', descending: true)
        .limit(10)
        .get();

    final refs = pre.docs.map((d) => d.reference).toList();

    // 2) Now transaction reads ONLY DocumentReferences
    return db.runTransaction((tx) async {
      // Read snapshots using tx.get(docRef)
      final snaps = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final r in refs) {
        final s = await tx.get(r);
        if (s.exists) snaps.add(s);
      }

      // Convert to models
      final existing = snaps.map((s) => UserAddress.fromDoc(s)).toList();

      final now = FieldValue.serverTimestamp();
      final shouldBeDefault = existing.isEmpty && makeDefaultIfFirst;

      // Helper: pick oldest by updatedAt/createdAt (null-safe)
      UserAddress pickOldest(List<UserAddress> list) {
        int score(UserAddress a) {
          final u = a.updatedAt?.millisecondsSinceEpoch ?? 0;
          final c = a.createdAt?.millisecondsSinceEpoch ?? 0;
          return (u != 0 ? u : c);
        }

        final copy = [...list];
        copy.sort((a, b) => score(a).compareTo(score(b)));
        return copy.first;
      }

      // 3) If already 2 → remove one (prefer non-default)
      if (existing.length >= 2) {
        final nonDefault = existing.where((a) => a.isDefault == false).toList();
        final toDelete = nonDefault.isNotEmpty ? pickOldest(nonDefault) : pickOldest(existing);
        tx.delete(colRef.doc(toDelete.id));
      }

      // 4) If first address should be default → set others false (mostly no-op)
      if (shouldBeDefault) {
        for (final s in snaps) {
          tx.update(s.reference, {
            'isDefault': false,
            'updatedAt': now,
          });
        }
      }

      // 5) Insert new address
      final newDoc = colRef.doc();
      tx.set(
        newDoc,
        {
          ...address.toMap(),
          'isDefault': shouldBeDefault ? true : (address.isDefault),
          'createdAt': now,
          'updatedAt': now,
        },
        SetOptions(merge: true),
      );

      return newDoc.id;
    });
  }

  Stream<String?> watchSelectedAddressId() {
    return watchMySettings().map((s) => s?.selectedAddressId);
  }

  Future<void> setSelectedAddressId(String addressId) async {
    final uid = requireUid();
    await doc(FirestorePaths.userSettings(uid)).set(
      {
        'selectedAddressId': addressId,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }


}
