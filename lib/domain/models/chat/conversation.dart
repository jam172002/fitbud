import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/firestore_model.dart';

enum ConversationType { direct, group }

ConversationType conversationTypeFrom(String v) {
  return ConversationType.values.firstWhere((e) => e.name == v, orElse: () => ConversationType.direct);
}

class Conversation implements FirestoreModel {
  @override
  final String id;

  final ConversationType type;
  final String title; // optional for group
  final String groupId; // empty if direct
  final String createdByUserId;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final String lastMessageId;
  final String lastMessagePreview;
  final DateTime? lastMessageAt;

  const Conversation({
    required this.id,
    this.type = ConversationType.direct,
    this.title = '',
    this.groupId = '',
    this.createdByUserId = '',
    this.createdAt,
    this.updatedAt,
    this.lastMessageId = '',
    this.lastMessagePreview = '',
    this.lastMessageAt,
  });

  static Conversation fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Conversation(
      id: doc.id,
      type: conversationTypeFrom(FirestoreModel.readString(d['type'], fallback: 'direct')),
      title: FirestoreModel.readString(d['title']),
      groupId: FirestoreModel.readString(d['groupId']),
      createdByUserId: FirestoreModel.readString(d['createdByUserId']),
      createdAt: FirestoreModel.readDate(d['createdAt']),
      updatedAt: FirestoreModel.readDate(d['updatedAt']),
      lastMessageId: FirestoreModel.readString(d['lastMessageId']),
      lastMessagePreview: FirestoreModel.readString(d['lastMessagePreview']),
      lastMessageAt: FirestoreModel.readDate(d['lastMessageAt']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'title': title,
      'groupId': groupId,
      'createdByUserId': createdByUserId,
      'createdAt': FirestoreModel.ts(createdAt),
      'updatedAt': FirestoreModel.ts(updatedAt),
      'lastMessageId': lastMessageId,
      'lastMessagePreview': lastMessagePreview,
      'lastMessageAt': FirestoreModel.ts(lastMessageAt),
    };
  }
}
