import 'package:flutter/material.dart';
import 'package:fitbud/utils/colors.dart';

class SentMessage extends StatelessWidget {
  final String message;
  final String time;

  const SentMessage({super.key, required this.message, required this.time});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: XColors.primary.withValues(alpha: 0.7),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
            ),
            child: Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: TextStyle(color: XColors.secondaryText, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
