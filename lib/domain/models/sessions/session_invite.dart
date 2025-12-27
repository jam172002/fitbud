import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/firestore_model.dart';

enum InviteStatus { pending, accepted, declined, cancelled }

InviteStatus inviteStatusFrom(String v) {
  return InviteStatus.values.firstWhere(
        (e) => e.name == v,
    orElse: () => InviteStatus.pending,
  );
}

class SessionInvite implements FirestoreModel {
  @override
  final String id;

  final String sessionId;
  final String invitedUserId;
  final String invitedByUserId;
  final InviteStatus status;
  final DateTime? createdAt;
  final DateTime? respondedAt;

  /// ---- Optional snapshot fields for Home UI (NEW) ----
  final String? sessionCategory;
  final String? sessionImageUrl;
  final String? sessionLocationText;
  final DateTime? sessionDateTime;
  final String? invitedByName;
  final String? invitedByPhotoUrl;

  const SessionInvite({
    required this.id,
    required this.sessionId,
    required this.invitedUserId,
    required this.invitedByUserId,
    this.status = InviteStatus.pending,
    this.createdAt,
    this.respondedAt,
    this.sessionCategory,
    this.sessionImageUrl,
    this.sessionLocationText,
    this.sessionDateTime,
    this.invitedByName,
    this.invitedByPhotoUrl,
  });

  /// HomeSessionInviteCard expects "image"
  String get imageUrl => (sessionImageUrl ?? '').toString();

  static SessionInvite fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};

    return SessionInvite(
      id: doc.id,
      sessionId: FirestoreModel.readString(d['sessionId']),
      invitedUserId: FirestoreModel.readString(d['invitedUserId']),
      invitedByUserId: FirestoreModel.readString(d['invitedByUserId']),
      status: inviteStatusFrom(
        FirestoreModel.readString(d['status'], fallback: 'pending'),
      ),
      createdAt: FirestoreModel.readDate(d['createdAt']),
      respondedAt: FirestoreModel.readDate(d['respondedAt']),

      // NEW optional snapshot fields
      sessionCategory: FirestoreModel.readString(d['sessionCategory'], fallback: ''),
      sessionImageUrl: FirestoreModel.readString(d['sessionImageUrl'], fallback: ''),
      sessionLocationText: FirestoreModel.readString(d['sessionLocationText'], fallback: ''),
      sessionDateTime: FirestoreModel.readDate(d['sessionDateTime']),
      invitedByName: FirestoreModel.readString(d['invitedByName'], fallback: ''),
      invitedByPhotoUrl: FirestoreModel.readString(d['invitedByPhotoUrl'], fallback: ''),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'invitedUserId': invitedUserId,
      'invitedByUserId': invitedByUserId,
      'status': status.name,
      'createdAt': FirestoreModel.ts(createdAt),
      'respondedAt': FirestoreModel.ts(respondedAt),

      // snapshot fields (optional)
      if (sessionCategory != null) 'sessionCategory': sessionCategory,
      if (sessionImageUrl != null) 'sessionImageUrl': sessionImageUrl,
      if (sessionLocationText != null) 'sessionLocationText': sessionLocationText,
      if (sessionDateTime != null) 'sessionDateTime': FirestoreModel.ts(sessionDateTime),
      if (invitedByName != null) 'invitedByName': invitedByName,
      if (invitedByPhotoUrl != null) 'invitedByPhotoUrl': invitedByPhotoUrl,
    };
  }
}
