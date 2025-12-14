import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/firestore_model.dart';

enum BuddyRequestStatus { pending, accepted, rejected, cancelled, blocked }

BuddyRequestStatus buddyRequestStatusFrom(String v) {
  return BuddyRequestStatus.values.firstWhere(
        (e) => e.name == v,
    orElse: () => BuddyRequestStatus.pending,
  );
}

class BuddyRequest implements FirestoreModel {
  @override
  final String id;

  final String fromUserId;
  final String toUserId;
  final BuddyRequestStatus status;
  final String message;
  final DateTime? createdAt;
  final DateTime? respondedAt;

  const BuddyRequest({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    this.status = BuddyRequestStatus.pending,
    this.message = '',
    this.createdAt,
    this.respondedAt,
  });

  static BuddyRequest fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return BuddyRequest(
      id: doc.id,
      fromUserId: FirestoreModel.readString(d['fromUserId']),
      toUserId: FirestoreModel.readString(d['toUserId']),
      status: buddyRequestStatusFrom(FirestoreModel.readString(d['status'], fallback: 'pending')),
      message: FirestoreModel.readString(d['message']),
      createdAt: FirestoreModel.readDate(d['createdAt']),
      respondedAt: FirestoreModel.readDate(d['respondedAt']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'status': status.name,
      'message': message,
      'createdAt': FirestoreModel.ts(createdAt),
      'respondedAt': FirestoreModel.ts(respondedAt),
    };
  }
}
