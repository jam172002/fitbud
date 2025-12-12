import 'package:fitbud/User-App/features/personalization/screens/chats/widget/dot.dart';
import 'package:flutter/material.dart';
import 'package:fitbud/utils/colors.dart';

class TypingIndicator extends StatelessWidget {
  final String? avatar;

  const TypingIndicator({super.key, this.avatar});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          CircleAvatar(
            radius: 10,
            backgroundImage: avatar != null ? AssetImage(avatar!) : null,
            child: avatar == null ? Icon(Icons.person, size: 12) : null,
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: XColors.secondaryBG,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Dot(),
                SizedBox(width: 4),
                Dot(delay: 100),
                SizedBox(width: 4),
                Dot(delay: 200),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
