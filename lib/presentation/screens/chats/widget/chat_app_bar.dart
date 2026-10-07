import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:iconsax/iconsax.dart';

import '../../../../utils/colors.dart';
import '../../../../domain/models/auth/app_user.dart';
import '../controller/chat_controller.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final ChatController controller;
  const ChatAppBar({super.key, required this.controller});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: XColors.primaryBG,
      elevation: 0,
      title: Text(
        controller.isGroup ? controller.groupName : (controller.directTitle.isEmpty ? "Chat" : controller.directTitle),
        style: const TextStyle(color: XColors.primaryText, fontSize: 16, fontWeight: FontWeight.w600),
      ),
      leading: controller.isGroup
          ? null
          : Padding(
        padding: const EdgeInsets.only(left: 16),
        child: FutureBuilder<AppUser?>(
          future: controller.loadDirectOtherUser(),
          builder: (_, snap) {
            final u = snap.data;
            final provider = (u?.photoUrl?.trim().isNotEmpty == true)
                ? NetworkImage(u!.photoUrl!)
                : const AssetImage('assets/images/buddy.jpg') as ImageProvider;
            return CircleAvatar(radius: 18, backgroundImage: provider);
          },
        ),
      ),
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(LucideIcons.ellipsis_vertical, color: XColors.primaryText),
          color: XColors.secondaryBG,
          onSelected: (v) {
            if (v == 'delete_chat') controller.deleteChat();
          },
          itemBuilder: (_) => const [
            PopupMenuItem(
              value: 'delete_chat',
              child: Row(
                children: [
                  Icon(Iconsax.trash, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text("Delete Chat", style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}