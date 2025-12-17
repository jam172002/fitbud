import 'package:fitbud/User-App/common/widgets/section_heading.dart';
import 'package:fitbud/User-App/common/widgets/simple_dialog.dart';
import 'package:fitbud/User-App/features/personalization/screens/profile/buddy_profile_screen.dart';
import 'package:fitbud/User-App/features/personalization/screens/profile/transactions_screen.dart';
import 'package:fitbud/User-App/features/personalization/screens/profile/user_profile_details_screen.dart';
import 'package:fitbud/User-App/features/service/controllers/plans_controller.dart';
import 'package:fitbud/User-App/features/service/screens/home/linked_screens/all_buddy_requests_screen.dart';
import 'package:fitbud/User-App/features/service/screens/home/linked_screens/all_session_invites_screen.dart';
import 'package:fitbud/User-App/features/service/screens/home/linked_screens/premium_plans_screen.dart';
import 'package:fitbud/utils/colors.dart';
import 'package:fitbud/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';

class ProfileScreen extends StatelessWidget {
  ProfileScreen({super.key});

  final PremiumPlanController planController = Get.find();

  final List<Map<String, String>> recentBuddies = List.generate(
    10,
    (index) => {
      'name': 'Buddy ${index + 1}',
      'avatar': 'https://i.pravatar.cc/150?img=${index + 1}',
    },
  );

  void checkPremiumAndProceed(VoidCallback onAllowed) {
    if (planController.hasPremium) {
      onAllowed();
    } else {
      Get.dialog(
        SimpleDialogWidget(
          message: "Please purchase a premium plan to access Buddy Requests.",
          icon: Icons.lock_outline,
          iconColor: XColors.primary,
          buttonText: "Ok",
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            /// ================= Profile Header =================
            GestureDetector(
              onTap: () {
                Get.to(() => UserProfileDetailsScreen());
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      backgroundImage: AssetImage('assets/images/buddy.jpg'),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Muhammad Sufyan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'sufyan@email.com',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            /// ================= Recent Buddies =================
            XHeading(
              title: 'Recent Buddies',
              actionText: '',
              onActionTap: () {},
              sidePadding: 0,
            ),
            const SizedBox(height: 16),
            recentBuddies.isEmpty
                ? const Center(
                    child: Text(
                      'No recent buddies to show',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  )
                : SizedBox(
                    height: 70,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: recentBuddies.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final buddy = recentBuddies[index];
                        return GestureDetector(
                          onTap: () {
                            Get.to(
                              () => BuddyProfileScreen(
                                scenario: BuddyScenario.existingBuddy,
                              ),
                            );
                          },
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundImage: NetworkImage(buddy['avatar']!),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                buddy['name']!,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

            const SizedBox(height: 24),

            /// ================= Action Tiles =================
            _ProfileTile(
              icon: LucideIcons.user_round_plus,
              title: 'Buddy Requests',
              subtitle: 'Checkout the requests you received',
              onTap: () {
                checkPremiumAndProceed(() {
                  Get.to(() => AllBuddyRequestsScreen());
                });
              },
            ),

            const SizedBox(height: 12),
            _ProfileTile(
              icon: LucideIcons.calendar_arrow_down,
              title: 'Session Invites',
              subtitle: 'See all the session invites',
              onTap: () {
                Get.to(() => AllSessionInvitesScreen());
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
                Get.to(() => PremiumPlanScreen());
              },
            ),

            const SizedBox(height: 12),
            _ProfileTile(
              icon: LucideIcons.bolt,
              title: 'Settings',
              subtitle: 'App preferences & security',
              onTap: () {
                // Navigate to Settings Screen
              },
            ),
          ],
        ),
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
