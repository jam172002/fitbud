import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class SingleChatCard extends StatelessWidget {
  final String chatName;
  final String? profilePic;
  final String time;
  final String lastMessage;
  final VoidCallback onTap;

  final bool isGroup;
  final bool unread;
  final String? lastSenderName;

  const SingleChatCard({
    super.key,
    required this.chatName,
    required this.time,
    required this.lastMessage,
    this.profilePic,
    this.isGroup = false,
    this.unread = false,
    this.lastSenderName,
    required this.onTap,
  });

  bool get hasValidImage =>
      profilePic != null && profilePic!.isNotEmpty && profilePic != "null";

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Row(
          children: [
            /// ------ PROFILE IMAGE WITH FALLBACK ICON ------
            CircleAvatar(
              radius: 30,
              backgroundColor: XColors.secondaryBG,
              backgroundImage: hasValidImage ? AssetImage(profilePic!) : null,
              child: !hasValidImage
                  ? Icon(
                      isGroup
                          ? LucideIcons
                                .users // group icon
                          : LucideIcons.user, // single user icon
                      size: 20,
                      color: XColors.bodyText.withValues(alpha: 0.7),
                    )
                  : null,
            ),

            const SizedBox(width: 12),

            /// TEXTS
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// NAME + TIME + UNREAD BADGE
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            chatName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: XColors.primaryText,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          if (unread) ...[
                            const SizedBox(width: 6),
                            Icon(
                              LucideIcons.message_square_dot,
                              color: XColors.primary,
                              size: 12,
                            ),
                          ],
                        ],
                      ),

                      Text(
                        time,
                        style: TextStyle(
                          color: XColors.bodyText.withValues(alpha: 0.5),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  /// LAST MESSAGE (with optional sender name)
                  RichText(
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    text: TextSpan(
                      children: [
                        if (isGroup && lastSenderName != null) ...[
                          TextSpan(
                            text: '${lastSenderName!}: ',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                        TextSpan(
                          text: lastMessage,
                          style: TextStyle(
                            color: XColors.bodyText.withValues(alpha: 0.7),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
