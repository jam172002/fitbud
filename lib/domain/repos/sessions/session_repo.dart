import '../../../data/doc.dart';
import '../../../domain/models/sessions/session.dart';
import '../../../domain/models/sessions/session_invite.dart';
import '../../../domain/models/sessions/session_participant.dart';
import '../repo_base.dart';

class SessionRepo extends RepoBase {
  SessionRepo(super.db);

  Stream<List<Session>> watchMySessions({int limit = 50}) {
    final uid = requireUid();
    return streamDocs('sessions',
            eqColumn: 'created_by_user_id', eqValue: uid, orderBy: 'created_at', limit: limit)
        .map((l) => l.map(Session.fromDoc).toList());
  }

  Future<String> createSession(Session session) async {
    final uid = requireUid();
    final row = DbRow.toRow(session.toMap(), drop: {'createdAt', 'updatedAt', 'createdByUserId'});
    final created = await db
        .from('sessions')
        .insert({...row, 'created_by_user_id': uid})
        .select('id')
        .single();
    final id = created['id'] as String;

    // Add creator as participant
    await db.from('session_participants').upsert({'session_id': id, 'user_id': uid, 'attended': false});
    return id;
  }

  /// Creates the invite (session/inviter snapshot fields are filled in
  /// server-side; a trigger notifies the invited user).
  Future<String> inviteUserToSession({
    required String sessionId,
    required String invitedUserId,
  }) async {
    final id = await db.rpc('create_session_invite', params: {
      'p_session_id': sessionId,
      'p_invited_user': invitedUserId,
    });
    return '$id';
  }

  Future<void> acceptSessionInvite({
    required String sessionId,
    required String inviteId,
  }) async {
    await db.rpc('accept_session_invite', params: {'invite_id': inviteId});
  }

  Future<void> declineSessionInvite({
    required String sessionId,
    required String inviteId,
  }) async {
    await db.rpc('decline_session_invite', params: {'invite_id': inviteId});
  }

  Stream<List<SessionParticipant>> watchParticipants(String sessionId) {
    return streamDocs(
      'session_participants',
      pk: ['session_id', 'user_id'],
      idKey: 'user_id',
      eqColumn: 'session_id',
      eqValue: sessionId,
    ).map((l) {
      final list = l.map((d) => SessionParticipant.fromDoc(d, sessionId: sessionId)).toList();
      list.sort((a, b) => (a.joinedAt ?? DateTime(0)).compareTo(b.joinedAt ?? DateTime(0)));
      return list;
    });
  }

  /// Pending (used by Home cards etc.)
  Stream<List<SessionInvite>> watchMySessionInvites({int limit = 50}) =>
      watchMySessionInvitesByStatus(status: InviteStatus.pending, limit: limit);

  /// Pending / Accepted / Declined for "View All" screen filters
  Stream<List<SessionInvite>> watchMySessionInvitesByStatus({
    required InviteStatus status,
    int limit = 50,
  }) {
    final uid = requireUid();
    return streamDocs(
      'session_invites',
      eqColumn: 'invited_user_id',
      eqValue: uid,
      orderBy: 'created_at',
      limit: limit,
      where: (r) => r['status'] == status.name,
    ).map((l) => l.map(SessionInvite.fromDoc).toList());
  }
}
