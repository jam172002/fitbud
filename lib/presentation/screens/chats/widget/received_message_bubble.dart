import 'package:flutter/material.dart';
import 'package:fitbud/utils/colors.dart';

class ReceivedMessage extends StatelessWidget {
  final String message;
  final String time;
  final String? senderName;
  final String? avatar;
  final bool isGroup;

  const ReceivedMessage({
    super.key,
    required this.message,
    required this.time,
    this.senderName,
    this.avatar,
    this.isGroup = true,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (senderName != null && isGroup)
            Row(
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundImage: avatar != null ? AssetImage(avatar!) : null,
                ),
                const SizedBox(width: 6),
                Text(
                  senderName!,
                  style: const TextStyle(
                    color: XColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          Container(
            margin: EdgeInsets.only(top: senderName != null ? 4 : 0),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: XColors.secondaryBG,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
            child: Text(
              message,
              style: const TextStyle(color: XColors.primaryText, fontSize: 14),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: const TextStyle(color: XColors.secondaryText, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
