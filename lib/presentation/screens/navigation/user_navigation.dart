import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:salomon_bottom_bar/salomon_bottom_bar.dart';

import '../chats/inbox_screen.dart';
import '../gyms/gyms_screen.dart';
import '../home/home.dart';
import '../profile/profile_screen.dart';

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
