import 'package:flutter/material.dart';
import '../../../../domain/models/chat/message.dart';
import '../../../../utils/colors.dart';
import '../../../../utils/enums.dart';

Future<MessageType?> showAttachmentSheet(BuildContext context) {
  return showModalBottomSheet<MessageType>(
    context: context,
    backgroundColor: XColors.secondaryBG,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: XColors.secondaryText.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _AttachOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Photo',
                  color: Colors.purple,
                  onTap: () => Navigator.pop(ctx, MessageType.image),
                ),
                _AttachOption(
                  icon: Icons.videocam_rounded,
                  label: 'Video',
                  color: Colors.red,
                  onTap: () => Navigator.pop(ctx, MessageType.video),
                ),
                _AttachOption(
                  icon: Icons.insert_drive_file_rounded,
                  label: 'Document',
                  color: Colors.blue,
                  onTap: () => Navigator.pop(ctx, MessageType.file),
                ),
                _AttachOption(
                  icon: Icons.headset_rounded,
                  label: 'Audio',
                  color: Colors.orange,
                  onTap: () => Navigator.pop(ctx, MessageType.audio),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      );
    },
  );
}

class _AttachOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _AttachOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: XColors.primaryText, fontSize: 12)),
        ],
      ),
    );
  }
}