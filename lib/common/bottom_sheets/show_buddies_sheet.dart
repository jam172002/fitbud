import 'package:fitbud/domain/models/auth/app_user.dart';
import 'package:fitbud/domain/repos/repo_provider.dart';
import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';

import '../../presentation/screens/chats/chat_screen.dart';

void showBuddiesSheet(BuildContext context, List<AppUser> buddies) {
  final repos = Get.find<Repos>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: XColors.secondaryBG,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) {
      return DraggableScrollableSheet(
        expand: false,
        maxChildSize: 0.85,
        minChildSize: 0.4,
        initialChildSize: 0.6,
        builder: (_, controller) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 45,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: XColors.primary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
                Text(
                  "My Buddies",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: XColors.primaryText,
                  ),
                ),
                const SizedBox(height: 16),

                Expanded(
                  child: GridView.builder(
                    controller: controller,
                    padding: const EdgeInsets.only(bottom: 24),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      mainAxisExtent: 120,
                    ),
                    itemCount: buddies.length,
                    itemBuilder: (_, index) {
                      final u = buddies[index];
                      final name = (u.displayName ?? '').trim().isEmpty ? 'Buddy' : (u.displayName ?? '');
                      final pic = (u.photoUrl ?? '').trim();

                      return GestureDetector(
                        onTap: () async {
                          Navigator.pop(context); // close sheet
                          final convId = await repos.chatRepo.getOrCreateDirectConversation(otherUserId: u.id);
                          Get.to(() => ChatScreen(
                            conversationId: convId,
                            isGroup: false,
                            directOtherUserId: u.id,
                            directTitle: name,
                          ));
                        },
                        child: Column(
                          children: [
                            Container(
                              height: 70,
                              width: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: XColors.primary.withOpacity(0.15),
                                image: pic.isNotEmpty
                                    ? DecorationImage(
                                  fit: BoxFit.cover,
                                  image: NetworkImage(pic),
                                )
                                    : null,
                              ),
                              child: pic.isEmpty
                                  ? Icon(
                                LucideIcons.user,
                                color: XColors.primary,
                                size: 28,
                              )
                                  : null,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: XColors.primaryText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
