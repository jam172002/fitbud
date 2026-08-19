import '../common/firestore_model.dart';

enum ReportTargetType { user, message }

ReportTargetType reportTargetTypeFrom(String v) {
  return ReportTargetType.values.firstWhere(
    (e) => e.name == v,
    orElse: () => ReportTargetType.user,
  );
}

enum ReportReason {
  harassment,
  threats,
  spam,
  sexualContent,
  illegalContent,
  impersonation,
  other,
}

ReportReason reportReasonFrom(String v) {
  return ReportReason.values.firstWhere(
    (e) => e.name == v,
    orElse: () => ReportReason.other,
  );
}

enum ReportStatus { open, reviewing, actioned, dismissed }

ReportStatus reportStatusFrom(String v) {
  return ReportStatus.values.firstWhere(
    (e) => e.name == v,
    orElse: () => ReportStatus.open,
  );
}

/// A report doc's id is deterministic: `${reporterUserId}_${targetType}_${targetKey}`
/// (targetKey = the reported userId, or the reported messageId). That makes
/// re-reporting the same target idempotent - the write just updates the
/// existing report instead of spawning duplicates - which doubles as a
/// simple, rule-enforceable abuse control without a separate rate limiter.
class ContentReport implements FirestoreModel {
  @override
  final String id;

  final String reporterUserId;
  final ReportTargetType targetType;
  final String targetUserId; // person being reported (author, in the message case)
  final String targetConversationId; // only for message reports
  final String targetMessageId; // only for message reports
  final ReportReason reason;
  final String details;
  final ReportStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? reviewedBy;
  final String? reviewNotes;

  const ContentReport({
    required this.id,
    required this.reporterUserId,
    required this.targetType,
    required this.targetUserId,
    this.targetConversationId = '',
    this.targetMessageId = '',
    this.reason = ReportReason.other,
    this.details = '',
    this.status = ReportStatus.open,
    this.createdAt,
    this.updatedAt,
    this.reviewedBy,
    this.reviewNotes,
  });

  static String idFor({
    required String reporterUserId,
    required ReportTargetType targetType,
    required String targetKey,
  }) => '${reporterUserId}_${targetType.name}_$targetKey';

  static ContentReport fromMap(String id, Map<String, dynamic> d) {
    return ContentReport(
      id: id,
      reporterUserId: FirestoreModel.readString(d['reporterUserId']),
      targetType: reportTargetTypeFrom(FirestoreModel.readString(d['targetType'], fallback: 'user')),
      targetUserId: FirestoreModel.readString(d['targetUserId']),
      targetConversationId: FirestoreModel.readString(d['targetConversationId']),
      targetMessageId: FirestoreModel.readString(d['targetMessageId']),
      reason: reportReasonFrom(FirestoreModel.readString(d['reason'], fallback: 'other')),
      details: FirestoreModel.readString(d['details']),
      status: reportStatusFrom(FirestoreModel.readString(d['status'], fallback: 'open')),
      createdAt: FirestoreModel.readDate(d['createdAt']),
      updatedAt: FirestoreModel.readDate(d['updatedAt']),
      reviewedBy: d['reviewedBy'] as String?,
      reviewNotes: d['reviewNotes'] as String?,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'reporterUserId': reporterUserId,
      'targetType': targetType.name,
      'targetUserId': targetUserId,
      'targetConversationId': targetConversationId,
      'targetMessageId': targetMessageId,
      'reason': reason.name,
      'details': details,
      'status': status.name,
    };
  }
}
