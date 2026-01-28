import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:iconsax/iconsax.dart';
import 'package:fitbud/utils/colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../common/appbar/common_appbar.dart';

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
  IconData _getIcon(String? type) {
    switch (type) {
      case "session_invite":
        return LucideIcons.calendar;
      case "buddy_request":
        return Iconsax.user_add;
      case "buddy_accept":
        return Iconsax.tick_circle;
      case "message":
        return Iconsax.message_text;
      default:
        return LucideIcons.bell;
    }
  }

  String _timeAgo(Timestamp timestamp) {
    final date = timestamp.toDate();
    final diff = DateTime.now().difference(date);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: XColors.primaryBG,
      appBar: XAppBar(title: 'Notifications'),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("notifications")
            .where("userId", isEqualTo: currentUserId)
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No notifications yet"),
            );
          }

          final docs = snapshot.data!.docs;

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, index) {
              final data = docs[index].data() as Map<String, dynamic>;

              return GestureDetector(
                onTap: () async {
                  if (data['isRead'] == false) {
                    await docs[index].reference.update({
                      'isRead': true,
                    });
                  }
                },
                child: _NotificationTile(
                  icon: _getIcon(data['type']),
                  title: data['title'] ?? '',
                  subtitle: data['body'] ?? '',
                  time: _timeAgo(data['createdAt']),
                  isRead: data['isRead'] ?? true,
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
