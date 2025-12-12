import 'package:flutter/material.dart';
import 'buddy_finder_screen.dart';

class BuddyFinderSwiper extends StatelessWidget {
  const BuddyFinderSwiper({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView.builder(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          return const BuddyFinderScreen();
        },
      ),
    );
  }
}
