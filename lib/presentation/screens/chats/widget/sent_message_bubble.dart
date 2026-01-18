import 'package:flutter/material.dart';
import 'package:fitbud/utils/colors.dart';
import 'package:iconsax/iconsax.dart';

class SentMessage extends StatelessWidget {
  final String message;
  final String time;

  /// NEW (optional) status flags — default values keep old behavior.
  /// If all are false, it behaves like your current widget (time only).
  final bool isPending; // clock
  final bool isSent; // single tick (optional)
  final bool isDelivered; // double tick
  final bool isRead; // double tick (blue)

  const SentMessage({
    super.key,
    required this.message,
    required this.time,
    this.isPending = false,
    this.isSent = true,
    this.isDelivered = false,
    this.isRead = false,
  });

  IconData _statusIcon() {
    if (isPending) return Iconsax.clock;
    if (isRead) return Iconsax.tick_square; // use any double-tick icon you prefer
    if (isDelivered) return Iconsax.tick_square;
    if (isSent) return Iconsax.tick_circle;
    return Iconsax.tick_circle;
  }

  Color _statusColor() {
    if (isRead) return Colors.blue;
    return XColors.secondaryText;
  }

  bool get _showStatusIcon {
    // If caller wants WhatsApp-like visuals (pending/delivered/read), show icon.
    // If nothing is specified, show nothing (keeps old UI).
    return isPending || isDelivered || isRead || isSent == false ? true : false;
  }

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

          // NEW: time + status on same row (WhatsApp-like)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                time,
                style: const TextStyle(color: XColors.secondaryText, fontSize: 10),
              ),
              if (_showStatusIcon) ...[
                const SizedBox(width: 6),
                Icon(
                  _statusIcon(),
                  size: 14,
                  color: _statusColor(),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
