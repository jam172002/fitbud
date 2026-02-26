import 'package:fitbud/presentation/screens/profile/privacy_security_screen.dart';
import 'package:fitbud/presentation/screens/profile/transactions_screen.dart';
import 'package:fitbud/presentation/screens/profile/user_profile_details_screen.dart';
import 'package:fitbud/utils/colors.dart';
import 'package:fitbud/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

import '../subscription/plans_controller.dart';
import '../../../common/widgets/section_heading.dart';
import '../../../domain/models/auth/app_user.dart';
import '../../../domain/repos/repo_provider.dart';
import '../budy/all_buddy_requests_screen.dart';
import '../budy/all_session_invites_screen.dart';
import '../settings/settings_screen.dart';
import '../subscription/premium_plans_screen.dart';
import 'buddy_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final PremiumPlanController planController = Get.find();
  final Repos repos = Get.find<Repos>();

  void checkPremiumAndProceed(VoidCallback onAllowed) {
    // premium gate currently disabled in your code
    onAllowed();
  }

  ImageProvider _avatarProvider(String? url) {
    final u = (url ?? '').trim();
    if (u.isEmpty || u == 'null') {
      return const AssetImage('assets/images/buddy.jpg');
    }
    if (u.startsWith('http://') || u.startsWith('https://')) {
      return NetworkImage(u);
    }
    return AssetImage(u);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            /// ================= Profile Header (REAL) =================
            StreamBuilder<AppUser?>(
              stream: repos.authRepo.watchMe(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 70,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final me = snap.data;

                if (me == null) {
                  return GestureDetector(
                    onTap: () => Get.to(() => UserProfileDetailsScreen()),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: AssetImage('assets/images/buddy.jpg'),
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Profile not found',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final name = (me.displayName ?? '').trim().isEmpty
                    ? 'User'
                    : (me.displayName ?? '');
                final email = (me.email ?? '').trim();

                return GestureDetector(
                  onTap: () => Get.to(() => UserProfileDetailsScreen()),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundImage: _avatarProvider(me.photoUrl),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                email.isEmpty ? ' ' : email,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 22),

            /// ================= Recent Buddies (REAL) =================
            XHeading(
              title: 'Recent Buddies',
              actionText: '',
              onActionTap: () {},
              sidePadding: 0,
            ),
            const SizedBox(height: 16),

            StreamBuilder<List<AppUser>>(
              stream: repos.buddyRepo.watchMyBuddiesUsers(limit: 10),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 70);
                }

                final recent = snap.data ?? [];

                // ✅ If recent exists → show it
                if (recent.isNotEmpty) {
                  return _BuddiesRow(
                    buddies: recent,
                    avatarProvider: _avatarProvider,
                  );
                }

                // ✅ Otherwise fallback once (past buddies)
                return FutureBuilder<List<AppUser>>(
                  future: repos.buddyRepo.loadAnyBuddies(limit: 10),
                  builder: (context, fb) {
                    if (fb.connectionState == ConnectionState.waiting) {
                      return const SizedBox(height: 70);
                    }
                    final buddies = fb.data ?? [];
                    if (buddies.isEmpty) {
                      return const _ClosedEmptyState();
                    }
                    return _BuddiesRow(
                      buddies: buddies,
                      avatarProvider: _avatarProvider,
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 24),

            /// ================= Action Tiles =================
            _ProfileTile(
              icon: LucideIcons.user_round_plus,
              title: 'Buddy Requests',
              subtitle: 'Checkout the requests you received',
              onTap: () {
                checkPremiumAndProceed(() {
                  Get.to(() => const AllBuddyRequestsScreen());
                });
              },
            ),
            const SizedBox(height: 12),

            _ProfileTile(
              icon: LucideIcons.calendar_arrow_down,
              title: 'Session Invites',
              subtitle: 'See all the session invites',
              onTap: () {
                Get.to(() => const AllSessionInvitesScreen());
              },
            ),
            const SizedBox(height: 12),

            _ProfileTile(
              icon: LucideIcons.dollar_sign,
              title: 'Transactions',
              subtitle: 'View transactions history',
              onTap: () {
                Get.to(() => TransactionsScreen());
              },
            ),
            const SizedBox(height: 12),

            _ProfileTile(
              icon: LucideIcons.award,
              title: 'Subscriptions & Plans',
              subtitle: 'View all the premium plans',
              onTap: () {
                Get.to(() => const PremiumPlanScreen());
              },
            ),
            const SizedBox(height: 12),

            _ProfileTile(
              icon: LucideIcons.bolt,
              title: 'Settings',
              subtitle: 'View all app settings',
              onTap: () {
                Get.to(() => SettingsScreen());
              },
            ),
            const SizedBox(height: 12),

            _ProfileTile(
              icon: Icons.lock_outline_rounded,
              title: 'Privacy & Security',
              subtitle: 'Data policy and security practices',
              onTap: () {
                Get.to(() => const PrivacySecurityScreen());
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

/// ================= Recent Buddies Row =================
class _BuddiesRow extends StatelessWidget {
  final List<AppUser> buddies;
  final ImageProvider Function(String? url) avatarProvider;

  const _BuddiesRow({
    required this.buddies,
    required this.avatarProvider,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 70,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: buddies.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final u = buddies[index];
          final name =
          (u.displayName ?? '').trim().isEmpty ? 'Buddy' : (u.displayName ?? '');

          return GestureDetector(
            onTap: () {
              final buddyUserId = (u.id).toString();
              if (buddyUserId.isEmpty) return;

              Get.to(
                    () => BuddyProfileScreen(
                  buddyUserId: buddyUserId,
                  scenario: BuddyScenario.existingBuddy,
                ),
              );
            },
            child: Column(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: avatarProvider(u.photoUrl),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 60,
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// ================= Closed Empty State =================
class _ClosedEmptyState extends StatelessWidget {
  const _ClosedEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: XColors.secondaryBG.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Iconsax.user_add, color: XColors.primary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'No buddies yet. Send requests to start chatting.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// ================= Reusable Tile =================
class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
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
                color: XColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 20, color: XColors.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: XColors.primaryText,
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
