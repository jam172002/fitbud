import 'dart:typed_data';
import '../../../../utils/enums.dart';
import '../../../../domain/models/chat/message.dart';

class ChatSnapshot {
  final DateTime? clearedAt;
  final List<Message> msgsRaw;
  const ChatSnapshot({required this.clearedAt, required this.msgsRaw});
}

class PendingText {
  final String clientId;
  final String text;
  final DateTime localTime;
  const PendingText({
    required this.clientId,
    required this.text,
    required this.localTime,
  });
}

class PickedMedia {
  final Uint8List bytes;
  final String fileName;
  final String ext;
  final String mimeType;
  final MessageType type;
  final int fileSize;

  const PickedMedia({
    required this.bytes,
    required this.fileName,
    required this.ext,
    required this.mimeType,
    required this.type,
    required this.fileSize,
  });
}

class PendingMedia {
  final String clientId;
  final PickedMedia picked;
  final DateTime localTime;
  final String? uploadedUrl;

  const PendingMedia({
    required this.clientId,
    required this.picked,
    required this.localTime,
    this.uploadedUrl,
  });

  PendingMedia copyWithUrl(String url) => PendingMedia(
    clientId: clientId,
    picked: picked,
    localTime: localTime,
    uploadedUrl: url,
  );
}