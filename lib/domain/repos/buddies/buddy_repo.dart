// lib/domain/repos/buddies/buddy_repo.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/auth/app_user.dart';
import '../../models/buddies/buddy_request.dart';
import '../../models/buddies/friendship.dart';
import '../firestore_paths.dart';
import '../firestore_repo_base.dart';
import '../repo_exceptions.dart';

class BuddyRepo extends RepoBase {
  final FirebaseAuth auth;
  BuddyRepo(super.db, this.auth);

  String _uid() {
    final u = auth.currentUser;
    if (u == null) throw PermissionException('User is not signed in');
    return u.uid;
  }

  // -----------------------------
  // Buddy Requests
  // -----------------------------

  Stream<List<BuddyRequest>> watchIncomingRequests() {
    final uid = _uid();
    return col(FirestorePaths.buddyRequests)
        .where('toUserId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((q) => q.docs.map(BuddyRequest.fromDoc).toList());
  }

  Stream<List<BuddyRequest>> watchOutgoingRequests() {
    final uid = _uid();
    return col(FirestorePaths.buddyRequests)
        .where('fromUserId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((q) => q.docs.map(BuddyRequest.fromDoc).toList());
  }

  Future<String> sendBuddyRequest({
    required String toUserId,
    String message = '',
  }) async {
    final uid = _uid();
    if (toUserId == uid) {
      throw ValidationException('Cannot send request to yourself');
    }

    // Block if already buddies
    final ids = [uid, toUserId]..sort();
    final friendshipId = '${ids[0]}_${ids[1]}';
    final f = await doc('${FirestorePaths.friendships}/$friendshipId').get();
    if (f.exists) {
      throw ValidationException('You are already buddies');
    }

    // If reverse pending exists, do NOT create duplicate
    final reversePending = await col(FirestorePaths.buddyRequests)
        .where('fromUserId', isEqualTo: toUserId)
        .where('toUserId', isEqualTo: uid)
        .where('status', isEqualTo: BuddyRequestStatus.pending.name)
        .limit(1)
        .get();
    if (reversePending.docs.isNotEmpty) {
      throw ValidationException('This user has already sent you a request');
    }

    // Find any prior request from me -> them (pending/rejected/cancelled)
    final existingAny = await col(FirestorePaths.buddyRequests)
        .where('fromUserId', isEqualTo: uid)
        .where('toUserId', isEqualTo: toUserId)
        .orderBy('createdAt', descending: true)
        .limit(5)
        .get();

    if (existingAny.docs.isNotEmpty) {
      final doc0 = existingAny.docs.first;
      final d = doc0.data();
      final status = (d['status'] as String?) ?? BuddyRequestStatus.pending.name;

      // If pending already exists, return it
      if (status == BuddyRequestStatus.pending.name) return doc0.id;

      // If rejected/cancelled, re-open to pending (so sender can send again)
      if (status == BuddyRequestStatus.rejected.name ||
          status == BuddyRequestStatus.cancelled.name) {
        await doc0.reference.update({
          'status': BuddyRequestStatus.pending.name,
          'message': message,
          'createdAt': FieldValue.serverTimestamp(),
          'respondedAt': null,
        });
        return doc0.id;
      }

      // accepted/blocked: do not resend
      if (status == BuddyRequestStatus.accepted.name) {
        throw ValidationException('You are already buddies');
      }
      if (status == BuddyRequestStatus.blocked.name) {
        throw PermissionException('Cannot send request');
      }
    }

    // Create new
    final ref = col(FirestorePaths.buddyRequests).doc();
    await ref.set({
      'fromUserId': uid,
      'toUserId': toUserId,
      'status': BuddyRequestStatus.pending.name,
      'message': message,
      'createdAt': FieldValue.serverTimestamp(),
      'respondedAt': null,
    });
    return ref.id;
  }

  Future<void> cancelBuddyRequest(String requestId) async {
    final uid = _uid();
    final ref = doc('${FirestorePaths.buddyRequests}/$requestId');

    await db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw NotFoundException('Request not found');
      final d = snap.data()!;

      if (d['fromUserId'] != uid) {
        throw PermissionException('Only sender can cancel');
      }

      final status = (d['status'] as String?) ?? BuddyRequestStatus.pending.name;
      if (status != BuddyRequestStatus.pending.name) return;

      tx.update(ref, {
        'status': BuddyRequestStatus.cancelled.name,
        'respondedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> declineBuddyRequest(String requestId) async {
    final uid = _uid();
    final ref = doc('${FirestorePaths.buddyRequests}/$requestId');

    await db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw NotFoundException('Request not found');
      final d = snap.data()!;

      if (d['toUserId'] != uid) {
        throw PermissionException('Only receiver can decline');
      }

      final status = (d['status'] as String?) ?? BuddyRequestStatus.pending.name;
      if (status != BuddyRequestStatus.pending.name) return;

      tx.update(ref, {
        'status': BuddyRequestStatus.rejected.name,
        'respondedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Receiver cleanup: remove a rejected request doc from their rejected list.
  Future<void> deleteRejectedIncomingRequest(String requestId) async {
    final uid = _uid();
    final ref = doc('${FirestorePaths.buddyRequests}/$requestId');

    await db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final d = snap.data()!;

      if (d['toUserId'] != uid) {
        throw PermissionException('Only receiver can delete');
      }
      final status = (d['status'] as String?) ?? '';
      if (status != BuddyRequestStatus.rejected.name) return;

      tx.delete(ref);
    });
  }

  /// Accept request:
  /// - mark request accepted
  /// - create friendship doc (with userIds array)
  Future<void> acceptBuddyRequest({required String requestId}) async {
    final uid = _uid();
    final reqRef = doc('${FirestorePaths.buddyRequests}/$requestId');

    await db.runTransaction((tx) async {
      // READS FIRST
      final reqSnap = await tx.get(reqRef);
      if (!reqSnap.exists) throw NotFoundException('Request not found');

      final d = reqSnap.data()!;
      final toUserId = (d['toUserId'] as String?) ?? '';
      final fromUserId = (d['fromUserId'] as String?) ?? '';
      final status = (d['status'] as String?) ?? BuddyRequestStatus.pending.name;

      if (toUserId != uid) throw PermissionException('Only receiver can accept');
      if (status != BuddyRequestStatus.pending.name) return;

      final ids = [fromUserId, toUserId]..sort();
      final friendshipId = '${ids[0]}_${ids[1]}';
      final fRef = doc('${FirestorePaths.friendships}/$friendshipId');

      final fSnap = await tx.get(fRef); // ✅ read BEFORE writes

      // WRITES AFTER ALL READS
      tx.update(reqRef, {
        'status': BuddyRequestStatus.accepted.name,
        'respondedAt': FieldValue.serverTimestamp(),
      });

      if (!fSnap.exists) {
        tx.set(fRef, {
          'userAId': ids[0],
          'userBId': ids[1],
          'userIds': ids,
          'createdAt': FieldValue.serverTimestamp(),
          'isBlocked': false,
          'blockedByUserId': '',
        });
      }
    });
  }


  // -----------------------------
  // Friendships
  // -----------------------------

  Stream<List<Friendship>> watchMyFriendships({int limit = 200}) {
    final uid = _uid();
    return col(FirestorePaths.friendships)
        .where('userIds', arrayContains: uid)
        .limit(limit)
        .snapshots()
        .map((q) => q.docs.map(Friendship.fromDoc).toList());
  }

  Stream<List<AppUser>> watchMyBuddiesUsers({int limit = 200}) {
    final uid = _uid();
    return watchMyFriendships(limit: limit).asyncMap((items) async {
      final otherIds = <String>{};

      for (final f in items) {
        if (f.isBlocked) continue;

        if (f.userAId == uid) {
          otherIds.add(f.userBId);
        } else if (f.userBId == uid) {
          otherIds.add(f.userAId);
        } else {
          otherIds.addAll(f.userIds);
          otherIds.remove(uid);
        }
      }

      final ids = otherIds.toList();
      if (ids.isEmpty) return <AppUser>[];

      final out = <AppUser>[];
      for (var i = 0; i < ids.length; i += 10) {
        final chunk = ids.sublist(i, (i + 10).clamp(0, ids.length));
        final snap = await db
            .collection(FirestorePaths.users)
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        out.addAll(snap.docs.map((d) => AppUser.fromDoc(d)));
      }

      out.sort((a, b) => (a.displayName ?? '').compareTo(b.displayName ?? ''));
      return out;
    });
  }

  // -----------------------------
  // Users discovery helpers
  // -----------------------------

  Future<List<AppUser>> loadDiscoverUsers({
    int limit = 30,
    String? activity,
    String? city,
  }) async {
    final uid = _uid();

    Query<Map<String, dynamic>> q =
    db.collection(FirestorePaths.users).where('isActive', isEqualTo: true);

    if (city != null && city.trim().isNotEmpty) {
      q = q.where('city', isEqualTo: city.trim());
    }

    if (activity != null && activity.trim().isNotEmpty) {
      q = q.where('activities', arrayContains: activity.trim());
    }

    final snap = await q.limit(limit + 10).get();
    final users = snap.docs.map((d) => AppUser.fromDoc(d)).toList();
    users.removeWhere((u) => u.id == uid);

    return users.take(limit).toList();
  }

  Future<Map<String, AppUser>> loadUsersMapByIds(List<String> ids) async {
    final map = <String, AppUser>{};
    if (ids.isEmpty) return map;

    for (var i = 0; i < ids.length; i += 10) {
      final chunk = ids.sublist(i, (i + 10).clamp(0, ids.length));
      final snap = await db
          .collection(FirestorePaths.users)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      for (final d in snap.docs) {
        final u = AppUser.fromDoc(d);
        map[u.id] = u;
      }
    }

    return map;
  }

  Future<List<AppUser>> loadAnyBuddies({int limit = 10}) async {
    final uid = _uid();

    final snap = await col(FirestorePaths.friendships)
        .where('userIds', arrayContains: uid)
        .limit(limit)
        .get();

    if (snap.docs.isEmpty) return [];

    final friendships = snap.docs.map(Friendship.fromDoc).toList();

    final otherUserIds = <String>[];
    for (final f in friendships) {
      if (f.isBlocked) continue;

      if (f.userAId == uid) {
        otherUserIds.add(f.userBId);
      } else if (f.userBId == uid) {
        otherUserIds.add(f.userAId);
      }
    }

    if (otherUserIds.isEmpty) return [];

    final ids = otherUserIds.take(10).toList();

    final usersSnap = await col(FirestorePaths.users)
        .where(FieldPath.documentId, whereIn: ids)
        .get();

    return usersSnap.docs.map(AppUser.fromDoc).toList();
  }
}
