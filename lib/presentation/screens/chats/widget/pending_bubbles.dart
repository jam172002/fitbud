import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../domain/models/chat/chat_models.dart';
import '../../../../domain/models/chat/message.dart';
import '../../../../utils/colors.dart';
import 'sent_message_bubble.dart';

class PendingSentBubble extends StatelessWidget {
  final String message;
  final String time;

  const PendingSentBubble({super.key, required this.message, required this.time});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SentMessage(message: message, time: time),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Iconsax.clock, size: 14, color: XColors.secondaryText),
            ],
          ),
        ],
      ),
    );
  }
}

class PendingMediaBubble extends StatelessWidget {
  final PendingMedia pending;
  const PendingMediaBubble({super.key, required this.pending});

  IconData _typeIcon(MessageType t) {
    switch (t) {
      case MessageType.video:
        return Icons.videocam_rounded;
      case MessageType.audio:
        return Icons.headset_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isImage = pending.picked.type == MessageType.image;

    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
            child: Stack(
              children: [
                if (isImage)
                  Image.memory(pending.picked.bytes, height: 200, width: 200, fit: BoxFit.cover)
                else
                  Container(
                    height: 72,
                    width: 220,
                    color: XColors.secondaryBG,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Icon(_typeIcon(pending.picked.type), color: XColors.primary, size: 30),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            pending.picked.fileName,
                            style: const TextStyle(color: XColors.primaryText, fontSize: 12),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.4),
                    child: const Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Iconsax.clock, size: 12, color: XColors.secondaryText),
              SizedBox(width: 3),
              Text('Sending…', style: TextStyle(color: XColors.secondaryText, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}