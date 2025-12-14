import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/firestore_model.dart';
import 'message.dart';

class MessageReceipt implements FirestoreModel {
  @override
  final String id; // userId or receiptId

  final String messageId;
  final String userId;
  final DeliveryState state;
  final DateTime? updatedAt;

  const MessageReceipt({
    required this.id,
    required this.messageId,
    required this.userId,
    this.state = DeliveryState.sent,
    this.updatedAt,
  });

  static MessageReceipt fromDoc(DocumentSnapshot<Map<String, dynamic>> doc, {required String messageId}) {
    final d = doc.data() ?? {};
    return MessageReceipt(
      id: doc.id,
      messageId: messageId,
      userId: FirestoreModel.readString(d['userId']),
      state: deliveryStateFrom(FirestoreModel.readString(d['state'], fallback: 'sent')),
      updatedAt: FirestoreModel.readDate(d['updatedAt']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'state': state.name,
      'updatedAt': FirestoreModel.ts(updatedAt),
    };
  }
}
