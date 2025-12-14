import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/firestore_model.dart';

class Friendship implements FirestoreModel {
  @override
  final String id;

  final String userAId;
  final String userBId;
  final DateTime? createdAt;

  final bool isBlocked;
  final String blockedByUserId;

  const Friendship({
    required this.id,
    required this.userAId,
    required this.userBId,
    this.createdAt,
    this.isBlocked = false,
    this.blockedByUserId = '',
  });

  static Friendship fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Friendship(
      id: doc.id,
      userAId: FirestoreModel.readString(d['userAId']),
      userBId: FirestoreModel.readString(d['userBId']),
      createdAt: FirestoreModel.readDate(d['createdAt']),
      isBlocked: FirestoreModel.readBool(d['isBlocked']),
      blockedByUserId: FirestoreModel.readString(d['blockedByUserId']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'userAId': userAId,
      'userBId': userBId,
      'createdAt': FirestoreModel.ts(createdAt),
      'isBlocked': isBlocked,
      'blockedByUserId': blockedByUserId,
    };
  }
}
