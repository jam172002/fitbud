import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../utils/colors.dart';
import 'controllers/checkin_outbox_controller.dart';

class CheckinStatusSheet extends StatelessWidget {
  final String clientCheckinId;
  final String? gymId;

  const CheckinStatusSheet({
    super.key,
    required this.clientCheckinId,
    this.gymId,
  });

  @override
  Widget build(BuildContext context) {
    final outbox = Get.find<CheckinOutboxController>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: XColors.secondaryBG,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Obx(() {
        // Prefer clientId, but fallback to latest by gym if needed
        final item = outbox.itemsById[clientCheckinId] ??
            (gymId == null ? null : outbox.latestForGym(gymId!));

        if (item == null) {
          return const Text(
            'No check-in record found.',
            style: TextStyle(color: XColors.primaryText),
          );
        }

        final status = item.status;
        final attempts = item.attempts;
        final err = (item.lastError ?? '').trim();

        String title;
        String subtitle;

        switch (status) {
          case 'pending':
            title = 'Queued';
            subtitle = 'Saved locally. It will sync when internet is available.';
            break;
          case 'sending':
            title = 'Sending…';
            subtitle = 'Trying to confirm with server.';
            break;
          case 'confirmed':
            title = 'Confirmed';
            subtitle = 'Attendance recorded on server.';
            break;
          case 'failed':
            title = 'Not confirmed yet';
            subtitle = 'Network/server issue. Auto-retry will happen.';
            break;
          default:
            title = 'Status: $status';
            subtitle = 'Working…';
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: XColors.primaryText,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: const TextStyle(color: XColors.primaryText),
            ),
            const SizedBox(height: 8),
            Text(
              'Attempts: $attempts',
              style: const TextStyle(color: XColors.primaryText, fontSize: 12),
            ),
            if (err.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                err,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => outbox.flush(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: XColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Retry now',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: XColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(color: XColors.primaryText),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      }),
    );
  }
}
