
import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:get_storage/get_storage.dart';

import '../../../common/appbar/common_appbar.dart';

class NotificationSettingsScreen extends StatelessWidget {
  NotificationSettingsScreen({super.key});

  // GetStorage instance for persistence
  final box = GetStorage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const XAppBar(title: 'Notification Settings'),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          _NotificationTile(
            key: const ValueKey('new_session'),
            title: 'New Session Invites',
            subtitle: 'Get notified when a new session is available',
            box: box,
            storageKey: 'new_session',
          ),
          const SizedBox(height: 12),
          _NotificationTile(
            key: const ValueKey('buddy_requests'),
            title: 'Buddy Requests',
            subtitle: 'Be alerted when someone sends you a buddy request',
            box: box,
            storageKey: 'buddy_requests',
          ),
          const SizedBox(height: 12),
          _NotificationTile(
            key: const ValueKey('new_messages'),
            title: 'New Messages',
            subtitle: 'Receive notifications for new messages',
            box: box,
            storageKey: 'new_messages',
          ),
          const SizedBox(height: 12),
          _NotificationTile(
            key: const ValueKey('reminder'),
            title: 'Reminder',
            subtitle: 'Get reminders for upcoming sessions',
            box: box,
            storageKey: 'reminder',
          ),
        ],
      ),
    );
  }
}

/// ================= Reusable Notification Tile =================
class _NotificationTile extends StatefulWidget {
  final String title;
  final String subtitle;
  final GetStorage box;
  final String storageKey;

  const _NotificationTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.box,
    required this.storageKey,
  });

  @override
  State<_NotificationTile> createState() => _NotificationTileState();
}

class _NotificationTileState extends State<_NotificationTile> {
  late bool isEnabled;

  @override
  void initState() {
    super.initState();
    // Load the saved value or default to true
    isEnabled = widget.box.read(widget.storageKey) ?? true;
  }

  void _toggleSwitch(bool value) {
    setState(() {
      isEnabled = value;
    });
    widget.box.write(widget.storageKey, value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: XColors.secondaryBG.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: XColors.primaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: XColors.bodyText.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.8, // reduce switch size
            child: Switch(
              value: isEnabled,
              activeColor: XColors.primary,
              onChanged: _toggleSwitch,
            ),
          ),
        ],
      ),
    );
  }
}
