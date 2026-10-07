import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';

import '../../../common/appbar/common_appbar.dart';
import '../../../common/widgets/simple_dialog.dart';
import '../../../common/widgets/specific_buddy_match_card.dart';
import '../profile/buddy_profile_screen.dart';
import 'package:fitbud/utils/enums.dart';

import 'controller/buddy_controller.dart';

class SpecificCatagoryBuddiesMatchScreen extends StatefulWidget {
  final String activity;
  const SpecificCatagoryBuddiesMatchScreen({super.key, required this.activity});

  @override
  State<SpecificCatagoryBuddiesMatchScreen> createState() =>
      _SpecificCatagoryBuddiesMatchScreenState();
}

class _SpecificCatagoryBuddiesMatchScreenState
    extends State<SpecificCatagoryBuddiesMatchScreen> {
  BuddyController get buddyC => Get.find<BuddyController>();

  Future<List<dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = buddyC.loadCategoryMatches(activity: widget.activity, limit: 30);
  }

  String _avatarOf(dynamic u) {
    final v = (u.photoUrl ?? '').toString().trim();
    return v.isNotEmpty ? v : 'assets/images/buddy.jpg';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: XAppBar(title: widget.activity),
      body: SafeArea(
        child: FutureBuilder<List<dynamic>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final users = snap.data ?? [];
            if (users.isEmpty) {
              return const Center(child: Text('No buddies found'));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final u = users[index];
                final String buddyUserId = (u.id ?? '').toString();

                // ✅ Wrap ONLY the card in Obx (correct GetX usage)
                return Obx(() {
                  final bool invited = buddyC.busyUserIds.contains(buddyUserId);
                  final bool isBuddy = buddyC.buddyIds.contains(buddyUserId);

                  return SpecificBuddyMatchCard(
                    avatar: _avatarOf(u),
                    name: (u.displayName ?? 'User'),
                    location: (u.city ?? ''),
                    gender: (u.gender ?? ''),
                    age: _ageFromDob(u.dob)?.toString() ?? '',
                    isInvited: invited,

                    // ✅ Hide action button if already buddy
                    onInvite: isBuddy
                        ? null
                        : () {
                      if (invited) return;
                      if (buddyUserId.isEmpty) return;

                      buddyC.inviteUser(buddyUserId).then((_) {
                        Get.dialog(
                          SimpleDialogWidget(
                            message:
                            "An invitation has been sent to the user to join as your buddy",
                            icon: LucideIcons.circle_check,
                            iconColor: XColors.primary,
                            buttonText: "Ok",
                            onOk: () => Get.back(),
                          ),
                        );
                      }).catchError((e) {
                        Get.dialog(
                          SimpleDialogWidget(
                            message: e.toString(),
                            icon: LucideIcons.circle_x,
                            iconColor: XColors.danger,
                            buttonText: "Ok",
                            onOk: () => Get.back(),
                          ),
                        );
                      });
                    },

                    onCardTap: () {
                      if (buddyUserId.isEmpty) return;

                      Get.to(
                            () => BuddyProfileScreen(
                          buddyUserId: buddyUserId,
                          scenario: isBuddy
                              ? BuddyScenario.buddy
                              : BuddyScenario.notBuddy,
                        ),
                      );
                    },
                  );
                });
              },
            );
          },
        ),
      ),
    );
  }

  int? _ageFromDob(DateTime? dob) {
    if (dob == null) return null;
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age;
  }
}