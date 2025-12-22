import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class SingleChatCard extends StatelessWidget {
  final String chatName;
  final String? profilePic; // can be URL or asset
  final String time;
  final String lastMessage;
  final VoidCallback onTap;

  final bool isGroup;
  final int unreadCount;
  final String? lastSenderName;

  const SingleChatCard({
    super.key,
    required this.chatName,
    required this.time,
    required this.lastMessage,
    this.profilePic,
    this.isGroup = false,
    this.unreadCount = 0,
    this.lastSenderName,
    required this.onTap,
  });

  bool get hasValidImage =>
      profilePic != null && profilePic!.trim().isNotEmpty && profilePic != "null";

  ImageProvider? _provider() {
    if (!hasValidImage) return null;
    final p = profilePic!.trim();
    final isUrl = p.startsWith('http://') || p.startsWith('https://');
    return isUrl ? NetworkImage(p) : AssetImage(p);
  }

  @override
  Widget build(BuildContext context) {
    final unread = unreadCount > 0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: XColors.secondaryBG,
              backgroundImage: _provider(),
              child: _provider() == null
                  ? Icon(
                isGroup ? LucideIcons.users : LucideIcons.user,
                size: 20,
                color: XColors.bodyText.withOpacity(0.7),
              )
                  : null,
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + time + unread
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                chatName,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: XColors.primaryText,
                                  fontSize: 14,
                                  fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (unread) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: XColors.primary.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  unreadCount > 99 ? '99+' : '$unreadCount',
                                  style: const TextStyle(
                                    color: XColors.primary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        time,
                        style: TextStyle(
                          color: XColors.bodyText.withOpacity(0.5),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  RichText(
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                    text: TextSpan(
                      children: [
                        if (isGroup && lastSenderName != null && lastSenderName!.trim().isNotEmpty) ...[
                          TextSpan(
                            text: '${lastSenderName!}: ',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.blue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        TextSpan(
                          text: lastMessage,
                          style: TextStyle(
                            color: XColors.bodyText.withOpacity(0.7),
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
