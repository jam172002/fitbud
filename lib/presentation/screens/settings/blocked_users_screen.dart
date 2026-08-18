import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';

import '../../../common/appbar/common_appbar.dart';
import '../../../domain/models/auth/app_user.dart';
import '../../../domain/repos/repo_provider.dart';

/// Reachable from Settings. Blocking someone removes them from discovery
/// and (if applicable) your buddy list, so without a dedicated screen like
/// this there'd be no way back to a blocked profile to unblock them.
class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({super.key});

  Repos get repos => Get.find<Repos>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: XColors.primaryBG,
      appBar: const XAppBar(title: 'Blocked Users'),
      body: StreamBuilder<Set<String>>(
        stream: repos.moderationRepo.watchMyBlockedUserIds(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final ids = (snap.data ?? const <String>{}).toList();
          if (ids.isEmpty) {
            return Center(
              child: Text(
                "You haven't blocked anyone.",
                style: TextStyle(color: XColors.bodyText.withValues(alpha: .7)),
              ),
            );
          }

          return FutureBuilder<Map<String, AppUser>>(
            future: repos.buddyRepo.loadUsersMapByIds(ids),
            builder: (context, userSnap) {
              if (!userSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final users = userSnap.data!;
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: ids.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final id = ids[i];
                  final u = users[id];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: XColors.secondaryBG.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: XColors.secondaryBG,
                          backgroundImage: (u?.photoUrl != null && u!.photoUrl!.startsWith('http'))
                              ? NetworkImage(u.photoUrl!)
                              : const AssetImage('assets/images/buddy.jpg') as ImageProvider,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            u?.displayName ?? 'Deleted User',
                            style: const TextStyle(color: XColors.primaryText, fontSize: 14),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => repos.moderationRepo.unblockUser(id),
                          icon: const Icon(LucideIcons.circle_x, size: 16, color: XColors.danger),
                          label: const Text('Unblock', style: TextStyle(color: XColors.danger)),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
