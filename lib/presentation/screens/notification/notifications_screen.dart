import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fitbud/utils/colors.dart';
import 'package:get/get.dart';

import '../../../common/appbar/common_appbar.dart';
import '../../../domain/models/notifications/app_notification.dart';
import '../../../domain/repos/repo_provider.dart';

/// Reads from `users/{uid}/notifications` via NotificationRepo - the same
/// path the buddy-request/session-invite/new-message Cloud Functions
/// actually write to (functions/src/index.ts). This screen used to query a
/// separate top-level `notifications` collection that nothing ever wrote to
/// server-side, so server-generated notifications never showed up here even
/// though the accompanying push notification still arrived. Fixed.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  Repos get repos => Get.find<Repos>();

  IconData _iconFor(NotificationType type) {
    switch (type) {
      case NotificationType.session_invite:
        return LucideIcons.calendar;
      case NotificationType.buddy_request:
        return Iconsax.user_add;
      case NotificationType.buddy_accepted:
        return Iconsax.tick_circle;
      case NotificationType.group_invite:
        return Iconsax.people;
      case NotificationType.message:
        return Iconsax.message_text;
      case NotificationType.subscription:
        return Iconsax.crown;
      case NotificationType.payout:
        return Iconsax.wallet;
    }
  }

  String _timeAgo(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: XColors.primaryBG,
      appBar: const XAppBar(title: 'Notifications'),
      body: StreamBuilder<List<AppNotification>>(
        stream: repos.notificationRepo.watchMyNotifications(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Failed to load notifications.',
                style: TextStyle(color: XColors.bodyText.withValues(alpha: .7)),
              ),
            );
          }

          final items = snapshot.data ?? const <AppNotification>[];
          if (items.isEmpty) {
            return const Center(child: Text('No notifications yet'));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, index) {
              final n = items[index];
              return GestureDetector(
                onTap: () {
                  if (!n.isRead) repos.notificationRepo.markRead(n.id);
                },
                child: _NotificationTile(
                  icon: _iconFor(n.type),
                  title: n.title,
                  subtitle: n.body,
                  time: _timeAgo(n.createdAt),
                  isRead: n.isRead,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final bool isRead;

  const _NotificationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    this.isRead = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRead
            ? XColors.secondaryBG
            : XColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isRead
                  ? XColors.secondaryBG
                  : XColors.primary.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 20,
              color: isRead ? XColors.primaryText : XColors.primary,
            ),
          ),
          const SizedBox(width: 12),

          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: XColors.primaryText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: XColors.bodyText.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Time
          Text(
            time,
            style: TextStyle(
              color: XColors.bodyText.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
