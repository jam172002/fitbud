import 'package:fitbud/utils/colors.dart';
import 'package:fitbud/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';

import '../../../common/widgets/interest_item_chip.dart';
import '../../../common/widgets/simple_dialog.dart';
import '../profile/buddy_profile_screen.dart';

class BuddyFinderScreen extends StatefulWidget {
  const BuddyFinderScreen({super.key});

  @override
  State<BuddyFinderScreen> createState() => _BuddyFinderScreenState();
}

class _BuddyFinderScreenState extends State<BuddyFinderScreen> {
  bool _isInvited = false;

  // --------------- Random Interest List ---------------- //
  final List<String> allInterests = [
    "Cricket",
    "Gym",
    "Running",
    "Swimming",
    "Yoga",
    "Football",
    "Cycling",
    "Boxing",
    "Walking",
    "Badminton",
    "Cardio",
    "Zumba",
    "Powerlifting",
    "Crossfit",
    "HIIT",
  ];

  List<Widget> _buildRandomInterests() {
    allInterests.shuffle();
    return allInterests.take(10).map((e) => InterestItem(title: e)).toList();
  }
  // ------------------------------------------------------ //

  void _handleInvite() {
    if (_isInvited) return;

    setState(() => _isInvited = true);

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
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          //? User Image
          SizedBox(
            width: screenWidth,
            height: screenHeight,
            child: Image.asset('assets/images/buddy.jpg', fit: BoxFit.cover),
          ),

          //? Details Section
          Positioned(
            bottom: 0,
            child: Container(
              width: screenWidth,
              height: 600,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        //? Name
                        Text(
                          'Muhammad Sufyan',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: XColors.primaryText,
                            fontSize: 26,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Spacer(),

                        //? Profile Icon
                        GestureDetector(
                          onTap: () {
                            Get.to(
                              () => BuddyProfileScreen(
                                scenario: BuddyScenario.notBuddy,
                              ),
                            );
                          },
                          child: Icon(
                            LucideIcons.user_round,
                            color: XColors.primary,
                          ),
                        ),
                        SizedBox(width: 16),

                        //? Invite Button
                        GestureDetector(
                          onTap: _handleInvite,
                          child: Icon(
                            _isInvited
                                ? LucideIcons.circle_check
                                : LucideIcons.circle_plus,
                            color: _isInvited ? XColors.primary : Colors.blue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 2),

                    //? Location
                    Row(
                      children: [
                        Icon(
                          LucideIcons.map_pin,
                          color: Colors.blueAccent,
                          size: 15,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Block C, DHA Bahawalpur, Pakistan.',
                          style: TextStyle(
                            color: XColors.bodyText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),

                    //? Gender + Age
                    Row(
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.venus,
                              color: Colors.lightGreen,
                              size: 15,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Male',
                              style: TextStyle(
                                color: XColors.bodyText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(width: 16),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.calendar_days,
                              color: Colors.amber,
                              size: 15,
                            ),
                            SizedBox(width: 4),
                            Text(
                              '23 years old',
                              style: TextStyle(
                                color: XColors.bodyText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 4),

                    //? Gym
                    Row(
                      children: [
                        Icon(
                          LucideIcons.dumbbell,
                          color: Colors.pink,
                          size: 15,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Fitness 360 Commercial Area Branch',
                          style: TextStyle(
                            color: XColors.bodyText,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    //? Interested in section
                    Text(
                      'Interested in:',
                      style: TextStyle(color: XColors.primary),
                    ),
                    SizedBox(height: 4),

                    //? 10 Random wrapped Interest items
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _buildRandomInterests(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
