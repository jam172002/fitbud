import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/moderation/content_report.dart';
import '../repo_base.dart';
import '../repo_exceptions.dart';

class ModerationRepo extends RepoBase {
  ModerationRepo(super.db);

  // ---------------------------------------------------------------------
  // Reporting
  // ---------------------------------------------------------------------

  /// Report a user's profile/behavior in general (not tied to one message).
  Future<void> reportUser({
    required String targetUserId,
    required ReportReason reason,
    String details = '',
  }) {
    return _submitReport(
      targetType: ReportTargetType.user,
      targetUserId: targetUserId,
      targetKey: targetUserId,
      reason: reason,
      details: details,
    );
  }

  /// Report a specific chat message (and, implicitly, its author).
  Future<void> reportMessage({
    required String conversationId,
    required String messageId,
    required String authorUserId,
    required ReportReason reason,
    String details = '',
  }) {
    return _submitReport(
      targetType: ReportTargetType.message,
      targetUserId: authorUserId,
      targetKey: messageId,
      targetConversationId: conversationId,
      targetMessageId: messageId,
      reason: reason,
      details: details,
    );
  }

  Future<void> _submitReport({
    required ReportTargetType targetType,
    required String targetUserId,
    required String targetKey,
    required ReportReason reason,
    String details = '',
    String targetConversationId = '',
    String targetMessageId = '',
  }) async {
    final uid = requireUid();
    if (targetUserId.trim().isEmpty) {
      throw ValidationException('targetUserId is required.');
    }
    if (targetUserId == uid) {
      throw ValidationException('You cannot report yourself.');
    }

    // Deterministic id => re-reporting the same target updates the existing
    // report instead of creating duplicates. RLS only lets the reporter
    // write this exact id prefix.
    final id = ContentReport.idFor(
      reporterUserId: uid,
      targetType: targetType,
      targetKey: targetKey,
    );

    try {
      await db.from('reports').insert({
        'id': id,
        'reporter_user_id': uid,
        'target_type': targetType.name,
        'target_user_id': targetUserId,
        'target_conversation_id': targetConversationId,
        'target_message_id': targetMessageId,
        'reason': reason.name,
        'details': details,
        'status': ReportStatus.open.name,
      });
    } on PostgrestException catch (e) {
      if (e.code != '23505') rethrow; // already reported: just add the new detail
      await db.from('reports').update({
        'reason': reason.name,
        'details': details,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', id);
    }
  }

  /// Reports the current user has filed - not a moderation queue.
  Stream<List<ContentReport>> watchMyReports({int limit = 50}) {
    final uid = requireUid();
    return streamDocs('reports',
            eqColumn: 'reporter_user_id', eqValue: uid, orderBy: 'created_at', limit: limit)
        .map((l) => l.map((d) => ContentReport.fromMap(d.id, d.data())).toList());
  }

  // ---------------------------------------------------------------------
  // Blocking
  // ---------------------------------------------------------------------

  Future<void> blockUser(String targetUserId) async {
    final uid = requireUid();
    if (targetUserId.trim().isEmpty || targetUserId == uid) {
      throw ValidationException('Invalid user to block.');
    }
    await db.from('user_blocks').upsert({'user_id': uid, 'blocked_user_id': targetUserId});
  }

  Future<void> unblockUser(String targetUserId) async {
    final uid = requireUid();
    await db.from('user_blocks').delete().eq('user_id', uid).eq('blocked_user_id', targetUserId);
  }

  Stream<Set<String>> watchMyBlockedUserIds() {
    final uid = requireUid();
    return streamDocs(
      'user_blocks',
      pk: ['user_id', 'blocked_user_id'],
      idKey: 'blocked_user_id',
      eqColumn: 'user_id',
      eqValue: uid,
    ).map((l) => l.map((d) => d.id).toSet());
  }

  Future<bool> didIBlock(String targetUserId) async {
    final uid = requireUid();
    final row = await db
        .from('user_blocks')
        .select('blocked_user_id')
        .eq('user_id', uid)
        .eq('blocked_user_id', targetUserId)
        .maybeSingle();
    return row != null;
  }

  /// True if either side has blocked the other - a block must stop
  /// interaction in both directions, not just hide content from the blocker.
  Future<bool> isBlockedEitherWay(String otherUserId) async {
    requireUid();
    final r = await db.rpc('is_blocked_either_way', params: {'other': otherUserId});
    return r == true;
  }
}
