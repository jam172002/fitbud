import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/firestore_model.dart';
import 'conversation.dart';

class UserConversationIndex implements FirestoreModel {
  @override
  final String id; // conversationId (doc id)

  final String conversationId;
  final ConversationType type; // direct/group (stored for fast UI)
  final String title; // group title (or empty for direct)
  final String lastMessagePreview;
  final DateTime? lastMessageAt;
  final int unreadCount;

  const UserConversationIndex({
    required this.id,
    required this.conversationId,
    required this.type,
    required this.title,
    required this.lastMessagePreview,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  static UserConversationIndex fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return UserConversationIndex(
      id: doc.id,
      conversationId: FirestoreModel.readString(d['conversationId'], fallback: doc.id),
      type: conversationTypeFrom(FirestoreModel.readString(d['type'], fallback: 'direct')),
      title: FirestoreModel.readString(d['title']),
      lastMessagePreview: FirestoreModel.readString(d['lastMessagePreview']),
      lastMessageAt: FirestoreModel.readDate(d['lastMessageAt']),
      unreadCount: FirestoreModel.readInt(d['unreadCount']),
    );
  }

  @override
  Map<String, dynamic> toMap() => {
    'conversationId': conversationId,
    'type': type.name,
    'title': title,
    'lastMessagePreview': lastMessagePreview,
    'lastMessageAt': FirestoreModel.ts(lastMessageAt),
    'unreadCount': unreadCount,
  };
}
