import 'dart:io';

import 'package:fitbud/User-App/common/appbar/common_appbar.dart';
import 'package:fitbud/User-App/common/bottom_sheets/session_invite_sheet.dart';
import 'package:fitbud/User-App/common/widgets/simple_dialog.dart';
import 'package:fitbud/User-App/common/widgets/two_buttons_dialog.dart';
import 'package:fitbud/User-App/features/personalization/screens/chats/chat_screen.dart';
import 'package:fitbud/User-App/features/personalization/screens/chats/widget/full_screen_media.dart';
import 'package:fitbud/utils/colors.dart';
import 'package:fitbud/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:iconsax/iconsax.dart';
import 'dart:math';
import 'package:path_provider/path_provider.dart';

class BuddyProfileScreen extends StatelessWidget {
  final BuddyScenario scenario;
  const BuddyProfileScreen({super.key, required this.scenario});

  // List of all possible activities
  List<String> get allActivities => [
    "Cricket",
    "Football",
    "Badminton",
    "Gym",
    "Running",
    "Swimming",
    "Cycling",
    "Yoga",
    "Hiking",
    "Tennis",
    "Boxing",
    "Chess",
    "Walking",
    "Table Tennis",
    "Basketball",
    "Volleyball",
    "Snooker",
    "Skating",
    "Crossfit",
    "Meditation",
  ];

  // Generate 15 random unique activities
  List<String> getRandomActivities() {
    final list = List<String>.from(allActivities);
    list.shuffle(Random());
    return list.take(15).toList();
  }

  @override
  Widget build(BuildContext context) {
    final randomActivities = getRandomActivities();

    return Scaffold(
      appBar: XAppBar(
        title: '',
        actions: [
          if (scenario == BuddyScenario.notBuddy) _NotBuddyButton(),

          if (scenario == BuddyScenario.requestReceived)
            _RequestActionButtons(),

          if (scenario == BuddyScenario.existingBuddy) _ExistingBuddyDropdown(),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //? Header (Profile picture + Name)
              SizedBox(
                width: double.infinity,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FullScreenMedia(
                              path: "assets/images/buddy.jpg",
                              isVideo: false,
                              isAsset: true,
                            ),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        backgroundImage: const AssetImage(
                          'assets/images/buddy.jpg',
                        ),
                        backgroundColor: XColors.secondaryBG,
                        radius: 45,
                      ),
                    ),

                    const SizedBox(height: 16),
                    Text(
                      'Ali Haider',
                      style: TextStyle(
                        color: XColors.primaryText,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              //? Details Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  children: [
                    //? Age - Gender - Favourite Row (Centered)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.calendar_days,
                              color: Colors.amber,
                              size: 11,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '25 years old',
                              style: TextStyle(
                                color: XColors.bodyText,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(width: 22),

                        Row(
                          children: [
                            const Icon(
                              LucideIcons.venus,
                              color: Colors.lightGreen,
                              size: 11,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Male',
                              style: TextStyle(
                                color: XColors.bodyText,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(width: 22),

                        Row(
                          children: [
                            const Icon(
                              LucideIcons.heart,
                              color: Colors.pink,
                              size: 11,
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              'Badminton',
                              style: TextStyle(
                                color: XColors.bodyText,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    //? Gym joined
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.dumbbell,
                          color: Colors.deepPurple,
                          size: 11,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          '360 GYM Commercial Area Bahawalpur',
                          style: TextStyle(
                            color: XColors.bodyText,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    //? Location
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          LucideIcons.map_pin,
                          color: Colors.blue,
                          size: 11,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Model Town A, Bahawalpur',
                          style: TextStyle(
                            color: XColors.bodyText,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              //? Interests Section (Random list)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Interests",
                      style: TextStyle(
                        color: XColors.bodyText,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: randomActivities
                          .map((item) => BuddyProfileInterestItem(label: item))
                          .toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              //? About Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About',
                      style: TextStyle(
                        color: XColors.bodyText,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'But I must explain to you how all this mistaken idea of denouncing pleasure and praising pain was born and I will give you a complete account of the system, and expound the actual teachings of the great explorer of the truth, the master-builder of human happiness.\nNo one rejects, dislikes, or avoids pleasure itself, because it is pleasure, but because those who do not know how to pursue pleasure rationally encounter consequences that are extremely painful.\nNor again is there anyone who loves or pursues or desires to obtain pain of itself, because it is pain, but because occasionally circumstances occur in which toil and pain can procure him some great pleasure.',
                      textAlign: TextAlign.justify,
                      style: TextStyle(
                        fontSize: 12,
                        color: XColors.bodyText.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

//                REUSABLE INTEREST ITEM WIDGET

class BuddyProfileInterestItem extends StatelessWidget {
  final String label;

  const BuddyProfileInterestItem({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: XColors.primary.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: const TextStyle(color: XColors.bodyText, fontSize: 11),
      ),
    );
  }
}

/// Scenario 1: Not a buddy yet
class _NotBuddyButton extends StatefulWidget {
  @override
  State<_NotBuddyButton> createState() => _NotBuddyButtonState();
}

class _NotBuddyButtonState extends State<_NotBuddyButton> {
  bool _isInvited = false;

  void _handleInvite() {
    if (_isInvited) return;
    setState(() => _isInvited = true);

    Get.dialog(
      SimpleDialogWidget(
        message: "Invitation sent to the user.",
        icon: LucideIcons.circle_check,
        iconColor: XColors.primary,
        buttonText: "Ok",
        onOk: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        _isInvited ? LucideIcons.circle_check : LucideIcons.circle_plus,
        color: _isInvited ? XColors.primary : Colors.blue,
      ),
      onPressed: _handleInvite,
    );
  }
}

/// Scenario 2: Request received (accept/reject)
class _RequestActionButtons extends StatelessWidget {
  void _acceptRequest() {
    // Add accept logic
    print("Request accepted");
  }

  void _rejectRequest() {
    // Add reject logic
    print("Request rejected");
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(LucideIcons.circle_check, color: XColors.primary),
          onPressed: _acceptRequest,
        ),
        IconButton(
          icon: Icon(LucideIcons.circle_x, color: XColors.danger),
          onPressed: _rejectRequest,
        ),
      ],
    );
  }
}

/// Scenario 3: Existing buddy dropdown
class _ExistingBuddyDropdown extends StatelessWidget {
  void _createSession(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,

      backgroundColor: Colors.transparent,
      builder: (_) => const SessionInviteSheet(),
    );
  }

  void _startChat(BuildContext context) =>
      Get.to(() => ChatScreen(isGroup: false));
  void _removeBuddy(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => XButtonsConfirmationDialog(
        message: "Are you sure you want to remove this buddy?",
        icon: Iconsax.user_remove,
        iconColor: Colors.red,
        confirmText: "Remove",
        cancelText: "Cancel",
        onConfirm: () {
          // Add your remove buddy logic here
          print("Buddy removed");
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(LucideIcons.ellipsis_vertical, color: XColors.primaryText),
      color: XColors.secondaryBG,
      onSelected: (value) {
        switch (value) {
          case 'create_session':
            _createSession(context);
            break;

          case 'chat':
            _startChat(context);
            break;
          case 'remove_buddy':
            _removeBuddy(context);
            break;
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'create_session',
          child: Text(
            "Create Session",
            style: TextStyle(color: XColors.bodyText),
          ),
        ),
        PopupMenuItem(
          value: 'chat',
          child: Text("Chat", style: TextStyle(color: XColors.bodyText)),
        ),
        PopupMenuItem(
          value: 'remove_buddy',
          child: Text(
            "Remove from Buddies",
            style: TextStyle(color: Colors.red),
          ),
        ),
      ],
    );
  }
}
