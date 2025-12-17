import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/firestore_model.dart';

class ConversationParticipant implements FirestoreModel {
  @override
  final String id; // usually uid

  final String conversationId;
  final String userId;
  final DateTime? joinedAt;
  final DateTime? lastReadAt;
  final bool isMuted;
  final DateTime? mutedUntil;

  const ConversationParticipant({
    required this.id,
    required this.conversationId,
    required this.userId,
    this.joinedAt,
    this.lastReadAt,
    this.isMuted = false,
    this.mutedUntil,
  });

  static ConversationParticipant fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc, {
        required String conversationId,
      }) {
    final d = doc.data() ?? {};
    return ConversationParticipant(
      id: doc.id,
      conversationId: conversationId,
      userId: FirestoreModel.readString(d['userId']),
      joinedAt: FirestoreModel.readDate(d['joinedAt']),
      lastReadAt: FirestoreModel.readDate(d['lastReadAt']),
      isMuted: FirestoreModel.readBool(d['isMuted']),
      mutedUntil: FirestoreModel.readDate(d['mutedUntil']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'joinedAt': FirestoreModel.ts(joinedAt),
      'lastReadAt': FirestoreModel.ts(lastReadAt),
      'isMuted': isMuted,
      'mutedUntil': FirestoreModel.ts(mutedUntil),
    };
  }
}
