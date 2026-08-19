import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/moderation/content_report.dart';
import '../firestore_paths.dart';
import '../firestore_repo_base.dart';
import '../repo_exceptions.dart';

class ModerationRepo extends RepoBase {
  final FirebaseAuth auth;
  ModerationRepo(super.db, this.auth);

  String _uid() {
    final u = auth.currentUser;
    if (u == null) throw PermissionException('User is not signed in');
    return u.uid;
  }

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
    final uid = _uid();
    if (targetUserId.trim().isEmpty) {
      throw ValidationException('targetUserId is required.');
    }
    if (targetUserId == uid) {
      throw ValidationException('You cannot report yourself.');
    }

    final id = ContentReport.idFor(
      reporterUserId: uid,
      targetType: targetType,
      targetKey: targetKey,
    );

    // Deterministic doc id => re-reporting the same target updates the
    // existing report instead of creating duplicates. Firestore rules only
    // allow the reporter to write this exact id (see firestore.rules).
    await doc('${FirestorePaths.reports}/$id').set({
      'reporterUserId': uid,
      'targetType': targetType.name,
      'targetUserId': targetUserId,
      'targetConversationId': targetConversationId,
      'targetMessageId': targetMessageId,
      'reason': reason.name,
      'details': details,
      'status': ReportStatus.open.name,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Reports the current user has filed (for their own reference / "you
  /// already reported this" checks) - not a moderation queue.
  Stream<List<ContentReport>> watchMyReports({int limit = 50}) {
    final uid = _uid();
    return col(FirestorePaths.reports)
        .where('reporterUserId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((q) => q.docs.map((d) => ContentReport.fromMap(d.id, d.data())).toList());
  }

  // ---------------------------------------------------------------------
  // Blocking
  // ---------------------------------------------------------------------

  Future<void> blockUser(String targetUserId) async {
    final uid = _uid();
    if (targetUserId.trim().isEmpty || targetUserId == uid) {
      throw ValidationException('Invalid user to block.');
    }
    await doc('${FirestorePaths.userBlocks(uid)}/$targetUserId').set({
      'blockedUserId': targetUserId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> unblockUser(String targetUserId) async {
    final uid = _uid();
    await doc('${FirestorePaths.userBlocks(uid)}/$targetUserId').delete();
  }

  Stream<Set<String>> watchMyBlockedUserIds() {
    final uid = _uid();
    return col(FirestorePaths.userBlocks(uid))
        .snapshots()
        .map((q) => q.docs.map((d) => d.id).toSet());
  }

  Future<bool> didIBlock(String targetUserId) async {
    final uid = _uid();
    final snap = await doc('${FirestorePaths.userBlocks(uid)}/$targetUserId').get();
    return snap.exists;
  }

  /// True if either side has blocked the other - the check chat sends and
  /// buddy actions should use, since a block must stop interaction in both
  /// directions, not just hide content from the blocker.
  Future<bool> isBlockedEitherWay(String otherUserId) async {
    final uid = _uid();
    final results = await Future.wait([
      doc('${FirestorePaths.userBlocks(uid)}/$otherUserId').get(),
      doc('${FirestorePaths.userBlocks(otherUserId)}/$uid').get(),
    ]);
    return results.any((s) => s.exists);
  }
}
