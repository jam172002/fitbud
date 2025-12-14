import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/firestore_model.dart';

enum NotificationType {
  buddy_request,
  buddy_accepted,
  group_invite,
  session_invite,
  message,
  subscription,
  payout,
}

NotificationType notificationTypeFrom(String v) {
  return NotificationType.values.firstWhere(
        (e) => e.name == v,
    orElse: () => NotificationType.message,
  );
}

class AppNotification implements FirestoreModel {
  @override
  final String id;

  final String userId;
  final NotificationType type;
  final String title;
  final String body;
  final Map<String, dynamic> data;
  final bool isRead;
  final DateTime? createdAt;

  const AppNotification({
    required this.id,
    required this.userId,
    this.type = NotificationType.message,
    this.title = '',
    this.body = '',
    this.data = const {},
    this.isRead = false,
    this.createdAt,
  });

  static AppNotification fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppNotification(
      id: doc.id,
      userId: FirestoreModel.readString(d['userId']),
      type: notificationTypeFrom(FirestoreModel.readString(d['type'], fallback: 'message')),
      title: FirestoreModel.readString(d['title']),
      body: FirestoreModel.readString(d['body']),
      data: FirestoreModel.readMap(d['data']),
      isRead: FirestoreModel.readBool(d['isRead']),
      createdAt: FirestoreModel.readDate(d['createdAt']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.name,
      'title': title,
      'body': body,
      'data': data,
      'isRead': isRead,
      'createdAt': FirestoreModel.ts(createdAt),
    };
  }
}
