import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'buddy_finder_screen.dart';
import 'controller/buddy_controller.dart';

class BuddyFinderSwiper extends StatefulWidget {
  const BuddyFinderSwiper({super.key});

  @override
  State<BuddyFinderSwiper> createState() => _BuddyFinderSwiperState();
}

class _BuddyFinderSwiperState extends State<BuddyFinderSwiper> {
  BuddyController get buddyC => Get.find<BuddyController>();

  Future<List<dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    _future = buddyC.loadPerfectMatches(limit: 50);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final users = (snap.data as List?) ?? [];
          if (users.isEmpty) {
            return const Center(child: Text('No users found'));
          }

          return PageView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: users.length,
            itemBuilder: (context, index) {
              return BuddyFinderScreen(user: users[index]);
            },
          );
        },
      ),
    );
  }
}
