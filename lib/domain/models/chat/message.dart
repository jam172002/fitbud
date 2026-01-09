import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/firestore_model.dart';

enum MessageType { text, image, video, audio, file, location, system }
enum DeliveryState { sent, delivered, read }

MessageType messageTypeFrom(String v) {
  return MessageType.values.firstWhere((e) => e.name == v, orElse: () => MessageType.text);
}

DeliveryState deliveryStateFrom(String v) {
  return DeliveryState.values.firstWhere((e) => e.name == v, orElse: () => DeliveryState.sent);
}

class Message implements FirestoreModel {
  @override
  final String id;

  final String conversationId;
  final String senderUserId;
  final MessageType type;

  final String text;

  final String mediaUrl;
  final String thumbnailUrl;

  final double? lat;
  final double? lng;

  final String replyToMessageId;

  final DateTime? createdAt;
  final bool isDeleted;
  final DeliveryState deliveryState;

  final String clientMessageId;
  final DateTime? clientCreatedAt;

  const Message({
    required this.id,
    required this.conversationId,
    required this.senderUserId,
    this.type = MessageType.text,
    this.text = '',
    this.mediaUrl = '',
    this.thumbnailUrl = '',
    this.lat,
    this.lng,
    this.replyToMessageId = '',
    this.createdAt,
    this.clientMessageId = '',
    this.clientCreatedAt,
    this.isDeleted = false,
    this.deliveryState = DeliveryState.sent,
  });

  static Message fromDoc(DocumentSnapshot<Map<String, dynamic>> doc, {required String conversationId}) {
    final d = doc.data() ?? {};
    return Message(
      id: doc.id,
      conversationId: conversationId,
      senderUserId: FirestoreModel.readString(d['senderUserId']),
      type: messageTypeFrom(FirestoreModel.readString(d['type'], fallback: 'text')),
      text: FirestoreModel.readString(d['text']),
      mediaUrl: FirestoreModel.readString(d['mediaUrl']),
      thumbnailUrl: FirestoreModel.readString(d['thumbnailUrl']),
      lat: (d['lat'] is num) ? (d['lat'] as num).toDouble() : null,
      lng: (d['lng'] is num) ? (d['lng'] as num).toDouble() : null,
      replyToMessageId: FirestoreModel.readString(d['replyToMessageId']),
      createdAt: FirestoreModel.readDate(d['createdAt']),
      clientMessageId: FirestoreModel.readString(d['clientMessageId']),
      clientCreatedAt: FirestoreModel.readDate(d['clientCreatedAt']),
      isDeleted: FirestoreModel.readBool(d['isDeleted']),
      deliveryState: deliveryStateFrom(FirestoreModel.readString(d['deliveryState'], fallback: 'sent')),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'senderUserId': senderUserId,
      'type': type.name,
      'text': text,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'lat': lat,
      'lng': lng,
      'replyToMessageId': replyToMessageId,
      'createdAt': FirestoreModel.ts(createdAt),
      'clientMessageId': clientMessageId,
      'clientCreatedAt': FirestoreModel.ts(clientCreatedAt),
      'isDeleted': isDeleted,
      'deliveryState': deliveryState.name,
    };
  }
}
