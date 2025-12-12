import 'package:fitbud/User-App/common/appbar/common_appbar.dart';
import 'package:fitbud/User-App/features/service/screens/home/widgets/buddy_match_card.dart';
import 'package:fitbud/User-App/common/widgets/simple_dialog.dart';
import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';

class AllPerfectMatchScreen extends StatefulWidget {
  const AllPerfectMatchScreen({super.key});

  @override
  State<AllPerfectMatchScreen> createState() => _AllPerfectMatchScreenState();
}

class _AllPerfectMatchScreenState extends State<AllPerfectMatchScreen> {
  // Keep track of which buddies are invited
  final List<bool> _invitedBuddies = List.generate(12, (_) => false);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const XAppBar(title: 'Perfect Matches'),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 12,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: BuddyMatchCard(
                name: 'Ali Haider',
                location: 'DHA Bahawalpur, Pakistan',
                interest: 'GYM',
                sport: 'Cricket',
                avatar: 'assets/images/buddy.jpg',
                isInvited: _invitedBuddies[index],
                onInvite: () {
                  if (_invitedBuddies[index]) return; // already invited
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
              ),
            );
          },
        ),
      ),
    );
  }
}
