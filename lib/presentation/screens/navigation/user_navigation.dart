import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:get/get.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

import '../../../common/widgets/simple_dialog.dart';
import '../authentication/controllers/auth_controller.dart';
import '../authentication/screens/profile_setup_screens/profile_data_gathering_screen.dart';
import '../chats/inbox_screen.dart';
import '../gyms/gyms_screen.dart';
import '../home/home.dart';
import '../profile/profile_tab.dart';

class UserNavigation extends StatefulWidget {
  const UserNavigation({super.key});

  @override
  State<UserNavigation> createState() => _UserNavigationState();
}

class _UserNavigationState extends State<UserNavigation> {
  int _currentIndex = 0;

  // ------------- Screens here ---------------- //
  final List<Widget> _screens = [
    HomeScreen(),
    GymsScreen(),
    InboxScreen(),
    ProfileScreen(),
  ];
  // ----------------------------------------------------- //

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _promptProfileIfNeeded());
  }

  Future<void> _promptProfileIfNeeded() async {
    final authC = Get.find<AuthController>();
    try {
      await authC.loadMe();
    } catch (_) {
      return;
    }
    final me = authC.me.value;
    // No profile row yet (e.g. fetch failed) -> don't nag.
    if (!mounted || me == null || me.isProfileComplete == true) return;

    Get.dialog(
      SimpleDialogWidget(
        icon: LucideIcons.shield_alert,
        iconColor: XColors.warning,
        message:
            'Your profile is incomplete. Please complete your profile to get the best out of Fitbud.',
        onOk: () => Get.to(() => ProfileDataGatheringScreen()),
      ),
      barrierDismissible: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],

      bottomNavigationBar: SalomonBottomBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        unselectedItemColor: XColors.bodyText,
        items: [
          SalomonBottomBarItem(
            icon: const Icon(LucideIcons.house),
            title: const Text("Home"),
            selectedColor: XColors.primary,
          ),
          SalomonBottomBarItem(
            icon: const Icon(LucideIcons.dumbbell),
            title: const Text("Gyms"),
            selectedColor: XColors.primary,
          ),
          SalomonBottomBarItem(
            icon: const Icon(LucideIcons.message_circle),
            title: const Text("Chats"),
            selectedColor: XColors.primary,
          ),
          SalomonBottomBarItem(
            icon: const Icon(LucideIcons.user),
            title: const Text("Profile"),
            selectedColor: XColors.primary,
          ),
        ],
      ),
    );
  }
}
