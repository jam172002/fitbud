import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fitbud/utils/colors.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

class SentMedia extends StatelessWidget {
  final File file;
  final bool isVideo;
  final String time;
  final VoidCallback onTap;

  const SentMedia({
    super.key,
    required this.file,
    required this.isVideo,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
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
                        Positioned.fill(
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
