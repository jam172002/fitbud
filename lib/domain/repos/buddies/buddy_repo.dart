import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../domain/models/buddies/buddy_request.dart';
import '../../../domain/models/buddies/friendship.dart';
import '../../../domain/models/chat/conversation.dart';
import '../../../domain/models/chat/conversation_participant.dart';
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
        .where('userAId', isEqualTo: uid)
        .snapshots()
        .map((q) => q.docs.map(Friendship.fromDoc).toList());
    // Note: to include userBId==uid, either:
    // (A) store a mirror index collection, or
    // (B) store an array field "userIds": [a,b] then query arrayContains.
  }

  /// Preferred for Firebase: store `userIds: [a,b]` and query with arrayContains.
  Stream<List<Friendship>> watchMyFriendshipsArrayContains() {
    final uid = _uid();
    return col(FirestorePaths.friendships)
        .where('userIds', arrayContains: uid)
        .snapshots()
        .map((q) => q.docs.map(Friendship.fromDoc).toList());
  }
}
