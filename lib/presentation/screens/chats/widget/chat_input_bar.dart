import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:fitbud/utils/colors.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onPickMedia;
  final bool isUploadingImage;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onPickMedia,
    this.isUploadingImage = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: XColors.primaryBG,
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: XColors.secondaryBG,
                borderRadius: BorderRadius.circular(22),
              ),
              child: TextField(
                controller: controller,
                cursorColor: XColors.primary,
                style: const TextStyle(color: XColors.primaryText),
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  hintText: "Type your message...",
                  hintStyle: TextStyle(
                    color: XColors.secondaryText,
                    fontSize: 13,
                  ),
                  border: InputBorder.none,
                  suffixIcon: GestureDetector(
                    onTap: onSend,
                    child: const Icon(
                      LucideIcons.send,
                      size: 20,
                      color: XColors.primary,
                    ),
                  ),
                ),
                onSubmitted: (_) => onSend(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: isUploadingImage ? null : onPickMedia,
            child: SizedBox(
              width: 28,
              height: 28,
              child: isUploadingImage
                  ? const CircularProgressIndicator(
                      color: XColors.primary,
                      strokeWidth: 2.5,
                    )
                  : const Icon(
                      Icons.image_outlined,
                      color: XColors.primary,
                      size: 26,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
