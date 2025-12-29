import 'package:fitbud/utils/colors.dart';
import 'package:fitbud/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';

import '../../../common/widgets/interest_item_chip.dart';
import '../../../common/widgets/simple_dialog.dart';
import '../profile/buddy_profile_screen.dart';
import '../../../../domain/models/auth/app_user.dart';
import 'controller/buddy_controller.dart';

class BuddyFinderScreen extends StatelessWidget {
  final AppUser user;
  const BuddyFinderScreen({super.key, required this.user});

  BuddyController get buddyC => Get.find<BuddyController>();

  List<Widget> _interestChips(AppUser u) {
    final list = (u.activities ?? <String>[]);
    if (list.isEmpty) return [const InterestItem(title: 'Fitness')];
    return list.take(10).map((e) => InterestItem(title: e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final photo = (user.photoUrl?.isNotEmpty == true)
        ? user.photoUrl!
        : 'assets/images/buddy.jpg';

    return Scaffold(
      body: Stack(
        children: [
          SizedBox(
            width: screenWidth,
            height: screenHeight,
            child: photo.startsWith('http')
                ? Image.network(photo, fit: BoxFit.cover)
                : Image.asset(photo, fit: BoxFit.cover),
          ),
          Positioned(
            bottom: 0,
            child: Container(
              width: screenWidth,
              height: 600,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Obx(() {
                  final invited = buddyC.busyUserIds.contains(user.id);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              user.displayName ?? 'User',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: XColors.primaryText,
                                fontSize: 26,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          // View profile
                          GestureDetector(
                            onTap: () {
                              final buddyUserId = user.id;
                              if (buddyUserId.isEmpty) return;

                              Get.to(
                                    () => BuddyProfileScreen(
                                  buddyUserId: buddyUserId,
                                  scenario: BuddyScenario.notBuddy,
                                ),
                              );
                            },
                            child: Icon(
                              LucideIcons.user_round,
                              color: XColors.primary,
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Invite buddy
                          GestureDetector(
                            onTap: invited
                                ? null
                                : () async {
                              await buddyC.inviteUser(user.id);

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
                            },
                            child: Icon(
                              invited
                                  ? LucideIcons.circle_check
                                  : LucideIcons.circle_plus,
                              color: invited ? XColors.primary : Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.map_pin,
                            color: Colors.blueAccent,
                            size: 15,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              user.city ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: XColors.bodyText,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.venus,
                                color: Colors.lightGreen,
                                size: 15,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                user.gender ?? '',
                                style: TextStyle(
                                  color: XColors.bodyText,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.calendar_days,
                                color: Colors.amber,
                                size: 15,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _ageFromDob(user.dob) == null
                                    ? ''
                                    : '${_ageFromDob(user.dob)} years old',
                                style: TextStyle(
                                  color: XColors.bodyText,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.dumbbell,
                            color: Colors.pink,
                            size: 15,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              user.gymName ?? '',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: XColors.bodyText,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Interested in:',
                        style: TextStyle(color: XColors.primary),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _interestChips(user),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
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
