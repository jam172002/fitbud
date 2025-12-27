import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';

import '../../../common/appbar/common_appbar.dart';
import '../../../common/widgets/buddy_match_card.dart';
import '../../../common/widgets/simple_dialog.dart';
import 'controller/buddy_controller.dart';

class AllPerfectMatchScreen extends StatefulWidget {
  const AllPerfectMatchScreen({super.key});

  @override
  State<AllPerfectMatchScreen> createState() => _AllPerfectMatchScreenState();
}

class _AllPerfectMatchScreenState extends State<AllPerfectMatchScreen> {
  BuddyController get buddyC => Get.find<BuddyController>();

  Future<List<dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = buddyC.loadPerfectMatches(limit: 30);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const XAppBar(title: 'Perfect Matches'),
      body: SafeArea(
        child: FutureBuilder(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final users = (snap.data as List?) ?? [];

            if (users.isEmpty) {
              return const Center(child: Text('No matches found'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: users.length,
              itemBuilder: (context, index) {
                final u = users[index];
                final invited = buddyC.busyUserIds.contains(u.id);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: BuddyMatchCard(
                    name: (u.displayName ?? 'User'),
                    location: (u.city ?? ''),
                    interest: (u.favouriteActivity ?? ''),
                    sport: (u.favouriteActivity ?? ''),
                    avatar: (u.photoUrl?.isNotEmpty == true)
                        ? u.photoUrl!
                        : 'assets/images/buddy.jpg',
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
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
