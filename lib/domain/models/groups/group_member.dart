import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/firestore_model.dart';

enum GroupRole { owner, admin, member }

GroupRole groupRoleFrom(String v) {
  return GroupRole.values.firstWhere((e) => e.name == v, orElse: () => GroupRole.member);
}

class GroupMember implements FirestoreModel {
  @override
  final String id; // could be uid

  final String groupId;
  final String userId;
  final GroupRole role;
  final DateTime? joinedAt;
  final bool isMuted;
  final DateTime? mutedUntil;

  const GroupMember({
    required this.id,
    required this.groupId,
    required this.userId,
    this.role = GroupRole.member,
    this.joinedAt,
    this.isMuted = false,
    this.mutedUntil,
  });

  static GroupMember fromDoc(DocumentSnapshot<Map<String, dynamic>> doc, {required String groupId}) {
    final d = doc.data() ?? {};
    return GroupMember(
      id: doc.id,
      groupId: groupId,
      userId: FirestoreModel.readString(d['userId']),
      role: groupRoleFrom(FirestoreModel.readString(d['role'], fallback: 'member')),
      joinedAt: FirestoreModel.readDate(d['joinedAt']),
      isMuted: FirestoreModel.readBool(d['isMuted']),
      mutedUntil: FirestoreModel.readDate(d['mutedUntil']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'role': role.name,
      'joinedAt': FirestoreModel.ts(joinedAt),
      'isMuted': isMuted,
      'mutedUntil': FirestoreModel.ts(mutedUntil),
    };
  }
}
