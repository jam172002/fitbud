import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/route_manager.dart';

class XAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final bool showBackIcon;

  const XAppBar({
    super.key,
    required this.title,
    this.showBackIcon = true,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: showBackIcon
          ? IconButton(
              icon: const Icon(
                LucideIcons.chevron_left,
                color: XColors.primary,
                size: 20,
              ),
              onPressed: () => Get.back(),
            )
          : Text(''),
      centerTitle: true,
      title: Text(
        title,
        style: const TextStyle(
          color: XColors.primaryText,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),

      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
