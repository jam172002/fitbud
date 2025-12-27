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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: XAppBar(title: widget.activity),
      body: SafeArea(
        child: FutureBuilder(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final users = (snap.data as List?) ?? [];
            if (users.isEmpty) {
              return const Center(child: Text('No buddies found'));
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final u = users[index];
                final invited = buddyC.busyUserIds.contains(u.id);

                return SpecificBuddyMatchCard(
                  avatar: (u.photoUrl?.isNotEmpty == true)
                      ? u.photoUrl!
                      : 'assets/images/buddy.jpg',
                  name: (u.displayName ?? 'User'),
                  location: (u.city ?? ''),
                  gender: (u.gender ?? ''),
                  age: _ageFromDob(u.dob)?.toString() ?? '',
                  isInvited: invited,
                  onInvite: () async {
                    await buddyC.inviteUser(u.id);

                    Get.dialog(
                      SimpleDialogWidget(
                        message:
                        "An invitation has been sent to the user to join as your buddy",
                        icon: LucideIcons.circle_check,
                        iconColor: XColors.primary,
                        buttonText: "Ok",
                        onOk: () {},
                      ),
                    );
                  },
                  onCardTap: () {
                    Get.to(
                          () => BuddyProfileScreen(
                            scenario: BuddyScenario.notBuddy,
                            buddyId: u.id,
                          ),
                    );
                  },
                );
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
