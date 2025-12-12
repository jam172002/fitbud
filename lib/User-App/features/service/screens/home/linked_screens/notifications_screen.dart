import 'package:fitbud/User-App/common/appbar/common_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fitbud/utils/colors.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Mutable notification list
  List<Map<String, dynamic>> notifications = [
    {
      'icon': LucideIcons.bell,
      'title': 'New Session Invitation',
      'subtitle': 'Ali Haider invited you to a gym session.',
      'time': '2h ago',
      'isRead': false,
    },
    {
      'icon': Iconsax.message_text,
      'title': 'Message from Sufyan',
      'subtitle': 'Hey! Are you joining today’s workout?',
      'time': '3h ago',
      'isRead': true,
    },
    {
      'icon': Iconsax.user_add,
      'title': 'Buddy Request',
      'subtitle': 'Fatima sent you a buddy request.',
      'time': '5h ago',
      'isRead': false,
    },
    {
      'icon': Iconsax.trash,
      'title': 'Reminder',
      'subtitle': 'Don’t forget to log your workout today.',
      'time': '1d ago',
      'isRead': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Sort unread on top
    notifications.sort((a, b) {
      if (a['isRead'] == b['isRead']) return 0;
      if (a['isRead'] == false) return -1;
      return 1;
    });

    return Scaffold(
      backgroundColor: XColors.primaryBG,
      appBar: XAppBar(title: 'Notifications'),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: notifications.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) {
          final item = notifications[index];
          return GestureDetector(
            onTap: () {
              if (!item['isRead']) {
                setState(() {
                  notifications[index]['isRead'] = true;
                });
              }
            },
            child: _NotificationTile(
              icon: item['icon'],
              title: item['title'],
              subtitle: item['subtitle'],
              time: item['time'],
              isRead: item['isRead'],
            ),
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
    super.key,
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
