import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/firestore_model.dart';

class Friendship implements FirestoreModel {
  @override
  final String id;

  final String userAId;
  final String userBId;

  /// IMPORTANT: Needed for arrayContains query
  final List<String> userIds;

  final DateTime? createdAt;

  final bool isBlocked;
  final String blockedByUserId;

  const Friendship({
    required this.id,
    required this.userAId,
    required this.userBId,
    required this.userIds,
    this.createdAt,
    this.isBlocked = false,
    this.blockedByUserId = '',
  });

  static Friendship fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final a = FirestoreModel.readString(d['userAId']);
    final b = FirestoreModel.readString(d['userBId']);

    // Backward compatible: if old docs don't have userIds, compute it.
    final rawIds = (d['userIds'] is List) ? List.from(d['userIds']) : null;
    final ids = rawIds
        ?.map((e) => e.toString())
        .where((e) => e.trim().isNotEmpty)
        .toList();

    return Friendship(
      id: doc.id,
      userAId: a,
      userBId: b,
      userIds: (ids != null && ids.length == 2) ? ids : <String>[a, b],
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
      'userIds': userIds,
      'createdAt': FirestoreModel.ts(createdAt),
      'isBlocked': isBlocked,
      'blockedByUserId': blockedByUserId,
    };
  }
}
