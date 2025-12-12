import 'package:fitbud/User-App/common/appbar/common_appbar.dart';
import 'package:fitbud/User-App/common/widgets/simple_dialog.dart';
import 'package:fitbud/User-App/features/personalization/screens/profile/buddy_profile_screen.dart';
import 'package:fitbud/User-App/features/service/screens/home/widgets/specific_buddy_match_card.dart';
import 'package:fitbud/utils/colors.dart';
import 'package:fitbud/utils/enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';

class SpecificCatagoryBuddiesMatchScreen extends StatefulWidget {
  const SpecificCatagoryBuddiesMatchScreen({super.key});

  @override
  State<SpecificCatagoryBuddiesMatchScreen> createState() =>
      _SpecificCatagoryBuddiesMatchScreenState();
}

class _SpecificCatagoryBuddiesMatchScreenState
    extends State<SpecificCatagoryBuddiesMatchScreen> {
  // Track invite status for each buddy
  final List<bool> _invitedBuddies = List.generate(12, (_) => false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const XAppBar(title: 'Badminton'),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: 12,
          separatorBuilder: (context, index) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            return SpecificBuddyMatchCard(
              avatar: 'assets/images/buddy.jpg',
              name: 'Waseem Abbas $index',
              location: 'Model Town A, Bahawalpur',
              gender: 'Male',
              age: '25',
              isInvited: _invitedBuddies[index],
              onInvite: () {
                if (_invitedBuddies[index]) return;
                setState(() {
                  _invitedBuddies[index] = true;
                });

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
                  () => BuddyProfileScreen(scenario: BuddyScenario.notBuddy),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
