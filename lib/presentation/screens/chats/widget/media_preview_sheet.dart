import 'package:flutter/material.dart';
import '../../../../domain/models/chat/chat_models.dart';
import '../../../../domain/models/chat/message.dart';
import '../../../../utils/colors.dart';

Future<bool?> showMediaPreviewSheet(BuildContext context, PickedMedia picked) {
  return showModalBottomSheet<bool>(
    context: context,
    backgroundColor: XColors.secondaryBG,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _MediaPreviewSheet(picked: picked),
  );
}

class _MediaPreviewSheet extends StatelessWidget {
  final PickedMedia picked;
  const _MediaPreviewSheet({required this.picked});

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  IconData _typeIcon(MessageType t) {
    switch (t) {
      case MessageType.video:
        return Icons.videocam_rounded;
      case MessageType.audio:
        return Icons.headset_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = picked.type == MessageType.image
        ? 'Photo'
        : picked.type == MessageType.video
        ? 'Video'
        : picked.type == MessageType.audio
        ? 'Audio'
        : 'File';

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
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
          const SizedBox(height: 16),
          Text(
            'Send $title',
            style: const TextStyle(
              color: XColors.primaryText,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          if (picked.type == MessageType.image)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                picked.bytes,
                height: 260,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: XColors.primaryBG,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: XColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(_typeIcon(picked.type), color: XColors.primary, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          picked.fileName,
                          style: const TextStyle(
                            color: XColors.primaryText,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatSize(picked.fileSize),
                          style: const TextStyle(color: XColors.secondaryText, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel', style: TextStyle(color: XColors.secondaryText)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: XColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Send', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}