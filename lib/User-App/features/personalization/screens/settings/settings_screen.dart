import 'package:fitbud/User-App/common/appbar/common_appbar.dart';
import 'package:fitbud/User-App/common/widgets/two_buttons_dialog.dart';
import 'package:fitbud/User-App/features/personalization/screens/settings/about_app_screen.dart';
import 'package:fitbud/User-App/features/personalization/screens/settings/notification_settings_screen.dart';
import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  void _showConfirmationDialog({
    required BuildContext context,
    required String message,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onConfirm,
  }) {
    Get.dialog(
      XButtonsConfirmationDialog(
        message: message,
        icon: icon,
        iconColor: iconColor,
        confirmText: 'Yes',
        cancelText: 'No',
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const XAppBar(title: 'Settings'),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        children: [
          _SettingsTile(
            icon: LucideIcons.bell,
            title: 'Notifications Settings',
            subtitle: 'Manage your notifications preferences',
            onTap: () {
              Get.to(() => NotificationSettingsScreen());
            },
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: LucideIcons.info,
            title: 'About',
            subtitle: 'App information & version',
            onTap: () {
              Get.to(() => AboutAppScreen());
            },
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: LucideIcons.trash,
            title: 'Delete Account',
            subtitle: 'Permanently delete your account',
            onTap: () {
              _showConfirmationDialog(
                context: context,
                message:
                    'Are you sure you want to delete your account? This action cannot be undone.',
                icon: LucideIcons.trash,
                iconColor: Colors.redAccent,
                onConfirm: () {
                  // Handle account deletion
                },
              );
            },
          ),
          const SizedBox(height: 12),
          _SettingsTile(
            icon: LucideIcons.log_out,
            title: 'Logout',
            subtitle: 'Sign out from the app',
            iconColor: Colors.redAccent,
            titleColor: Colors.redAccent,
            onTap: () {
              _showConfirmationDialog(
                context: context,
                message: 'Are you sure you want to logout?',
                icon: LucideIcons.log_out,
                iconColor: Colors.redAccent,
                onConfirm: () {
                  // Handle logout
                },
              );
            },
          ),
        ],
      ),
    );
  }
}

/// ================= Reusable Settings Tile =================
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: XColors.secondaryBG.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                color: (iconColor ?? XColors.primary).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: iconColor ?? XColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: titleColor ?? XColors.primaryText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: XColors.bodyText.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}
