import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../domain/models/sessions/session.dart';
import '../../../domain/models/sessions/session_invite.dart';
import '../../../domain/models/sessions/session_participant.dart';
import '../firestore_paths.dart';
import '../firestore_repo_base.dart';
import '../repo_exceptions.dart';

class SessionRepo extends RepoBase {
  final FirebaseAuth auth;
  SessionRepo(super.db, this.auth);

  String _uid() {
    final u = auth.currentUser;
    if (u == null) throw PermissionException('User is not signed in');
    return u.uid;
  }

  Stream<List<Session>> watchMySessions({int limit = 50}) {
    final uid = _uid();
    return col(FirestorePaths.sessions)
        .where('createdByUserId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((q) => q.docs.map(Session.fromDoc).toList());
  }

  Future<String> createSession(Session session) async {
    final uid = _uid();
    final ref = col(FirestorePaths.sessions).doc();
    await ref.set({
      ...session.toMap(),
      'createdByUserId': uid,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    // Add creator as participant
    await doc('${FirestorePaths.sessionParticipants(ref.id)}/$uid').set({
      'userId': uid,
      'attended': false,
      'joinedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return ref.id;
  }

  Future<String> inviteUserToSession({
    required String sessionId,
    required String invitedUserId,
  }) async {
    final uid = _uid();
    final ref = col(FirestorePaths.sessionInvites(sessionId)).doc();

    // Read session + inviter user in parallel (best effort)
    final sessionSnap = await doc('${FirestorePaths.sessions}/$sessionId').get();
    final inviterSnap = await db.collection('users').doc(uid).get();

    final sessionData = sessionSnap.data();
    final inviterData = inviterSnap.data();

    await ref.set({
      'sessionId': sessionId,
      'invitedUserId': invitedUserId,
      'invitedByUserId': uid,
      'status': InviteStatus.pending.name,
      'createdAt': FieldValue.serverTimestamp(),
      'respondedAt': null,

      // -------- snapshot fields for Home UI --------
      'sessionCategory': sessionData?['category'] ?? sessionData?['title'] ?? '',
      'sessionImageUrl': sessionData?['imageUrl'] ?? sessionData?['image'] ?? '',
      'sessionLocationText': sessionData?['location'] ?? sessionData?['locationText'] ?? '',
      'sessionDateTime': sessionData?['dateTime'] ?? sessionData?['scheduledAt'] ?? null,

      'invitedByName': inviterData?['displayName'] ?? '',
      'invitedByPhotoUrl': inviterData?['photoUrl'] ?? '',
    });

    return ref.id;
  }



  Future<void> acceptSessionInvite({
    required String sessionId,
    required String inviteId,
  }) async {
    final uid = _uid();
    final inviteRef = doc('${FirestorePaths.sessionInvites(sessionId)}/$inviteId');
    final participantRef = doc('${FirestorePaths.sessionParticipants(sessionId)}/$uid');

    await db.runTransaction((tx) async {
      final inv = await tx.get(inviteRef);
      if (!inv.exists) throw NotFoundException('Invite not found');
      final d = inv.data()!;
      if (d['invitedUserId'] != uid) throw PermissionException('Not your invite');
      if ((d['status'] as String?) != InviteStatus.pending.name) return;

      tx.update(inviteRef, {
        'status': InviteStatus.accepted.name,
        'respondedAt': FieldValue.serverTimestamp(),
      });

      tx.set(participantRef, SessionParticipant(
        id: uid,
        sessionId: sessionId,
        userId: uid,
        attended: false,
        joinedAt: DateTime.now(),
      ).toMap()..addAll({'joinedAt': FieldValue.serverTimestamp()}), SetOptions(merge: true));
    });
  }

  Future<void> declineSessionInvite({
    required String sessionId,
    required String inviteId,
  }) async {
    final uid = _uid();
    final inviteRef = doc('${FirestorePaths.sessionInvites(sessionId)}/$inviteId');

    await db.runTransaction((tx) async {
      final inv = await tx.get(inviteRef);
      if (!inv.exists) throw NotFoundException('Invite not found');
      final d = inv.data()!;
      if (d['invitedUserId'] != uid) throw PermissionException('Not your invite');
      if ((d['status'] as String?) != InviteStatus.pending.name) return;

      tx.update(inviteRef, {
        'status': InviteStatus.declined.name,
        'respondedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<List<SessionParticipant>> watchParticipants(String sessionId) {
    return col(FirestorePaths.sessionParticipants(sessionId))
        .orderBy('joinedAt', descending: false)
        .snapshots()
        .map((q) => q.docs.map((d) => SessionParticipant.fromDoc(d, sessionId: sessionId)).toList());
  }


  /// Pending (used by Home cards etc.)
  Stream<List<SessionInvite>> watchMySessionInvites({int limit = 50}) {
    final uid = _uid();
    return db
        .collectionGroup('invites')
        .where('invitedUserId', isEqualTo: uid)
        .where('status', isEqualTo: InviteStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((q) => q.docs.map(SessionInvite.fromDoc).toList());
  }

  /// NEW: Pending / Accepted / Declined for "View All" screen filters
  Stream<List<SessionInvite>> watchMySessionInvitesByStatus({
    required InviteStatus status,
    int limit = 50,
  }) {
    final uid = _uid();
    return db
        .collectionGroup('invites')
        .where('invitedUserId', isEqualTo: uid)
        .where('status', isEqualTo: status.name)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((q) => q.docs.map(SessionInvite.fromDoc).toList());
  }

}
