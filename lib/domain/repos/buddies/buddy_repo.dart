import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../domain/models/buddies/buddy_request.dart';
import '../../../domain/models/buddies/friendship.dart';
import '../../../domain/models/chat/conversation.dart';
import '../../../domain/models/chat/conversation_participant.dart';
import '../../models/auth/app_user.dart';
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

  // ---------- Buddy Requests ----------

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
    if (toUserId == uid) throw ValidationException('Cannot send request to yourself');

    // Optional: prevent duplicates (best-effort)
    final existing = await col(FirestorePaths.buddyRequests)
        .where('fromUserId', isEqualTo: uid)
        .where('toUserId', isEqualTo: toUserId)
        .where('status', isEqualTo: BuddyRequestStatus.pending.name)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return existing.docs.first.id;

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
      if (d['fromUserId'] != uid) throw PermissionException('Only sender can cancel');
      final status = d['status'] as String? ?? 'pending';
      if (status != BuddyRequestStatus.pending.name) return;
      tx.update(ref, {
        'status': BuddyRequestStatus.cancelled.name,
        'respondedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Accept incoming request:
  /// 1) mark request accepted
  /// 2) create Friendship doc
  /// 3) create or ensure direct Conversation
  Future<String> acceptBuddyRequest({
    required String requestId,
    bool createDirectChat = true,
  }) async {
    final uid = _uid();
    final reqRef = doc('${FirestorePaths.buddyRequests}/$requestId');

    return db.runTransaction<String>((tx) async {
      final reqSnap = await tx.get(reqRef);
      if (!reqSnap.exists) throw NotFoundException('Request not found');
      final d = reqSnap.data()!;
      final toUserId = d['toUserId'] as String? ?? '';
      final fromUserId = d['fromUserId'] as String? ?? '';
      final status = d['status'] as String? ?? BuddyRequestStatus.pending.name;

      if (toUserId != uid) throw PermissionException('Only receiver can accept');
      if (status != BuddyRequestStatus.pending.name) {
        // already handled
        return '';
      }

      // Update request
      tx.update(reqRef, {
        'status': BuddyRequestStatus.accepted.name,
        'respondedAt': FieldValue.serverTimestamp(),
      });

      // Create friendship with deterministic id (sorted ids)
      final a = [fromUserId, toUserId]..sort();
      final friendshipId = '${a[0]}_${a[1]}';
      final fRef = doc('${FirestorePaths.friendships}/$friendshipId');
      final fSnap = await tx.get(fRef);
      if (!fSnap.exists) {
        tx.set(fRef, {
          'userAId': a[0],
          'userBId': a[1],
          'createdAt': FieldValue.serverTimestamp(),
          'isBlocked': false,
          'blockedByUserId': '',
        });
      }

      if (!createDirectChat) return '';

      // Create a deterministic direct conversation id too (optional)
      final convId = 'direct_${a[0]}_${a[1]}';
      final cRef = doc('${FirestorePaths.conversations}/$convId');
      final cSnap = await tx.get(cRef);
      if (!cSnap.exists) {
        tx.set(cRef, Conversation(
          id: convId,
          type: ConversationType.direct,
          title: '',
          groupId: '',
          createdByUserId: uid,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ).toMap()..addAll({
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'lastMessageId': '',
          'lastMessagePreview': '',
          'lastMessageAt': null,
        }));

        // participants
        final p1 = doc('${FirestorePaths.conversationParticipants(convId)}/${a[0]}');
        final p2 = doc('${FirestorePaths.conversationParticipants(convId)}/${a[1]}');

        tx.set(p1, ConversationParticipant(
          id: a[0],
          conversationId: convId,
          userId: a[0],
          joinedAt: DateTime.now(),
        ).toMap()..addAll({'joinedAt': FieldValue.serverTimestamp()}));

        tx.set(p2, ConversationParticipant(
          id: a[1],
          conversationId: convId,
          userId: a[1],
          joinedAt: DateTime.now(),
        ).toMap()..addAll({'joinedAt': FieldValue.serverTimestamp()}));
      }

      return convId;
    });
  }

  Future<void> declineBuddyRequest(String requestId) async {
    final uid = _uid();
    final ref = doc('${FirestorePaths.buddyRequests}/$requestId');

    await db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw NotFoundException('Request not found');
      final d = snap.data()!;
      if (d['toUserId'] != uid) throw PermissionException('Only receiver can decline');
      final status = d['status'] as String? ?? 'pending';
      if (status != BuddyRequestStatus.pending.name) return;

      tx.update(ref, {
        'status': BuddyRequestStatus.rejected.name,
        'respondedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  // ---------- Friendships ----------

  Stream<List<Friendship>> watchMyFriendships() {
    final uid = _uid();
    return col(FirestorePaths.friendships)
        .where('userIds', arrayContains: uid)
        .snapshots()
        .map((q) => q.docs.map(Friendship.fromDoc).toList());
  }

  /// Stream list of actual buddies users (AppUser)
  Stream<List<AppUser>> watchMyBuddiesUsers({int limit = 200}) {
    final uid = _uid();
    return watchMyFriendships().asyncMap((items) async {
      final otherIds = <String>{};

      for (final f in items) {
        if (f.isBlocked) continue;
        if (f.userAId == uid) {
          otherIds.add(f.userBId);
        } else if (f.userBId == uid) {
          otherIds.add(f.userAId);
        } else {
          // Defensive: if old docs had unsorted ids
          otherIds.add(f.userAId);
          otherIds.add(f.userBId);
          otherIds.remove(uid);
        }
      }

      final ids = otherIds.toList();
      if (ids.isEmpty) return <AppUser>[];

      // Firestore whereIn max 10 -> chunk
      final out = <AppUser>[];
      for (var i = 0; i < ids.length; i += 10) {
        final chunk = ids.sublist(i, (i + 10).clamp(0, ids.length));
        // You already have repos.authRepo.getUser(id), but that is one-by-one.
        // If you have a users collection, batch fetch is better:
        final snap = await db.collection(FirestorePaths.users).where(FieldPath.documentId, whereIn: chunk).get();
        out.addAll(snap.docs.map((d) => AppUser.fromDoc(d)));
      }

      // Sort by display name for UI
      out.sort((a, b) => (a.displayName ?? '').compareTo(b.displayName ?? ''));
      return out;
    });
  }

  /// Shows "recent buddies" if possible; otherwise falls back to "past buddies"
  /// (any friendships where userIds contains uid).
  ///
  /// Recent = orderBy(createdAt desc) if field exists.
  /// Fallback = no orderBy (works even if some docs are missing createdAt).
  /// Step 1: RECENT buddies (ordered)
  Stream<List<AppUser>> watchRecentBuddies({int limit = 10}) {
    final uid = _uid();

    return col(FirestorePaths.friendships)
        .where('userIds', arrayContains: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap((snap) => _friendshipsToUsers(uid, snap.docs));
  }

  /// Step 2: FALLBACK buddies (no orderBy)
  Future<List<AppUser>> loadAnyBuddies({int limit = 10}) async {
    final uid = _uid();

    final snap = await col(FirestorePaths.friendships)
        .where('userIds', arrayContains: uid)
        .limit(limit)
        .get();

    return _friendshipsToUsers(uid, snap.docs);
  }

  Future<List<AppUser>> _friendshipsToUsers(
      String uid,
      List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
      ) async {
    if (docs.isEmpty) return [];

    final friendships = docs.map(Friendship.fromDoc).toList();
    final otherIds = friendships
        .map((f) => f.userAId == uid ? f.userBId : f.userAId)
        .toList();

    final usersSnap = await col(FirestorePaths.users)
        .where(FieldPath.documentId, whereIn: otherIds)
        .get();

    final users = usersSnap.docs.map(AppUser.fromDoc).toList();
    final map = {for (final u in users) u.id: u};

    return otherIds.map((id) => map[id]).whereType<AppUser>().toList();
  }
}
