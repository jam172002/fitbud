import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/firestore_model.dart';

enum GroupInviteStatus { pending, accepted, declined, cancelled }

GroupInviteStatus groupInviteStatusFrom(String v) {
  return GroupInviteStatus.values.firstWhere(
        (e) => e.name == v,
    orElse: () => GroupInviteStatus.pending,
  );
}

class GroupInvite implements FirestoreModel {
  @override
  final String id;

  final String groupId;
  final String invitedUserId;
  final String invitedByUserId;
  final GroupInviteStatus status;
  final DateTime? createdAt;
  final DateTime? respondedAt;

  const GroupInvite({
    required this.id,
    required this.groupId,
    required this.invitedUserId,
    required this.invitedByUserId,
    this.status = GroupInviteStatus.pending,
    this.createdAt,
    this.respondedAt,
  });

  static GroupInvite fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return GroupInvite(
      id: doc.id,
      groupId: FirestoreModel.readString(d['groupId']),
      invitedUserId: FirestoreModel.readString(d['invitedUserId']),
      invitedByUserId: FirestoreModel.readString(d['invitedByUserId']),
      status: groupInviteStatusFrom(FirestoreModel.readString(d['status'], fallback: 'pending')),
      createdAt: FirestoreModel.readDate(d['createdAt']),
      respondedAt: FirestoreModel.readDate(d['respondedAt']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'invitedUserId': invitedUserId,
      'invitedByUserId': invitedByUserId,
      'status': status.name,
      'createdAt': FirestoreModel.ts(createdAt),
      'respondedAt': FirestoreModel.ts(respondedAt),
    };
  }
}
