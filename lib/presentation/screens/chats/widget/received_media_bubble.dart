import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fitbud/utils/colors.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class ReceivedMedia extends StatelessWidget {
  final File file;
  final bool isVideo;
  final String time;
  final String? senderName;
  final String? avatar;
  final bool showSender; // To replace `widget.isGroup`
  final VoidCallback onTap;

  const ReceivedMedia({
    super.key,
    required this.file,
    required this.isVideo,
    required this.time,
    this.senderName,
    this.avatar,
    required this.showSender,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (senderName != null && showSender)
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
                    color: Colors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          SizedBox(height: senderName != null && showSender ? 4 : 0),
          GestureDetector(
            onTap: onTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: isVideo
                  ? Stack(
                      children: [
                        Image.file(
                          file,
                          height: 180,
                          width: 160,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          height: 180,
                          width: 160,
                          color: Colors.black26,
                        ),
                        const Positioned.fill(
                          child: Center(
                            child: Icon(
                              LucideIcons.play,
                              size: 42,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Image.file(
                      file,
                      height: 180,
                      width: 160,
                      fit: BoxFit.cover,
                    ),
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
