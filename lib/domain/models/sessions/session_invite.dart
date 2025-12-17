import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/firestore_model.dart';

enum InviteStatus { pending, accepted, declined, cancelled }

InviteStatus inviteStatusFrom(String v) {
  return InviteStatus.values.firstWhere((e) => e.name == v, orElse: () => InviteStatus.pending);
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

  const SessionInvite({
    required this.id,
    required this.sessionId,
    required this.invitedUserId,
    required this.invitedByUserId,
    this.status = InviteStatus.pending,
    this.createdAt,
    this.respondedAt,
  });

  static SessionInvite fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return SessionInvite(
      id: doc.id,
      sessionId: FirestoreModel.readString(d['sessionId']),
      invitedUserId: FirestoreModel.readString(d['invitedUserId']),
      invitedByUserId: FirestoreModel.readString(d['invitedByUserId']),
      status: inviteStatusFrom(FirestoreModel.readString(d['status'], fallback: 'pending')),
      createdAt: FirestoreModel.readDate(d['createdAt']),
      respondedAt: FirestoreModel.readDate(d['respondedAt']),
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
    };
  }
}
