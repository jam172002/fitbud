import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fitbud/utils/colors.dart';

class ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onPickMedia;

  const ChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onPickMedia,
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
                style: TextStyle(color: XColors.primaryText),
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
                    child: Icon(
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
            onTap: onPickMedia,
            child: const Icon(Iconsax.gallery, color: Colors.blue),
          ),
        ],
      ),
    );
  }
}
