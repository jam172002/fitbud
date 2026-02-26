import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../domain/models/chat/chat_models.dart';
import '../../../../utils/chat_utils.dart';
import '../../../../utils/colors.dart';
import '../../../../utils/enums.dart';
import '../../../../domain/models/chat/message.dart';
import '../controller/chat_controller.dart';
import 'pending_bubbles.dart';
import 'typing_indicator.dart';
import 'full_screen_media.dart';
import 'received_message_bubble.dart';
import 'sent_message_bubble.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ChatMessageList extends StatelessWidget {
  final ChatController controller;
  final List<Message> firestoreMessages;

  const ChatMessageList({
    super.key,
    required this.controller,
    required this.firestoreMessages,
  });

  @override
  Widget build(BuildContext context) {
    final uid = controller.uid;

    // IMPORTANT: minimize rebuild work
    final combined = <dynamic>[
      ...controller.pendingMedias,
      ...controller.pendingTexts,
      ...firestoreMessages,
    ];

    if (combined.isEmpty) {
      return Center(
        child: Text(
          'No messages yet.',
          style: TextStyle(color: XColors.bodyText.withValues(alpha: .7), fontSize: 13),
        ),
      );
    }

    return Obx(() {
      final typing = controller.isTyping.value;

      return ListView.builder(
        controller: controller.scrollController,
        padding: const EdgeInsets.all(16),
        reverse: true,
        itemCount: combined.length + (typing ? 1 : 0) + 1,
        itemBuilder: (_, index) {
          if (index == combined.length + (typing ? 1 : 0)) {
            return const SizedBox(height: 8);
          }

          if (typing && index == combined.length) {
            return const TypingIndicator(avatar: 'assets/images/buddy.jpg');
          }

          final item = combined[index];

          if (item is PendingMedia) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: PendingMediaBubble(pending: item),
            );
          }

          if (item is PendingText) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: PendingSentBubble(
                message: item.text,
                time: ChatUtils.timeLabel(item.localTime),
              ),
            );
          }

          final m = item as Message;
          final isSent = m.senderUserId == uid;
          final time = ChatUtils.timeLabel(m.createdAt);

          if (m.type == MessageType.image && m.mediaUrl.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: _ImageBubble(
                url: m.mediaUrl,
                time: time,
                isSent: isSent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenMedia(path: m.mediaUrl, isVideo: false, isAsset: false),
                    ),
                  );
                },
              ),
            );
          }

          final displayText = m.type == MessageType.text
              ? m.text
              : (m.text.isNotEmpty ? m.text : '[${m.type.name}]');

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: isSent
                ? SentMessage(message: displayText, time: time)
                : ReceivedMessage(
              message: displayText,
              time: time,
              senderName: 'User',
              avatar: 'assets/images/buddy.jpg',
              isGroup: controller.isGroup,
            ),
          );
        },
      );
    });
  }
}

class _ImageBubble extends StatelessWidget {
  final String url;
  final String time;
  final bool isSent;
  final VoidCallback onTap;

  const _ImageBubble({
    required this.url,
    required this.time,
    required this.isSent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSent ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: isSent ? const Radius.circular(16) : const Radius.circular(4),
                bottomRight: isSent ? const Radius.circular(4) : const Radius.circular(16),
              ),
              child: CachedNetworkImage(
                imageUrl: url,
                height: 200,
                width: 200,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 200,
                  width: 200,
                  color: XColors.secondaryBG,
                  child: const Center(
                    child: CircularProgressIndicator(color: XColors.primary, strokeWidth: 2),
                  ),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 200,
                  width: 200,
                  color: XColors.secondaryBG,
                  child: const Center(
                    child: Icon(Icons.broken_image_outlined, color: Colors.grey, size: 40),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(time, style: const TextStyle(color: XColors.secondaryText, fontSize: 10)),
        ],
      ),
    );
  }
}