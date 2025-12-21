// ----------------------------
// widgets/onboarding_arrow_button.dart
// Improvement: "Get Started" on last page
// ----------------------------
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import 'package:fitbud/utils/colors.dart';
import '../controllers/onboarding_controller.dart';

class OnBoardingArrowButton extends StatelessWidget {
  const OnBoardingArrowButton({super.key});

  @override
  Widget build(BuildContext context) {
    final c = OnBoardingController.instance;

    return Positioned(
      right: 16,
      bottom: kBottomNavigationBarHeight - 25,
      child: Obx(() {
        final isLast = c.currentPageIndex.value == OnBoardingController.lastPageIndex;

        return ElevatedButton(
          onPressed: () => c.nextPage(),
          style: ElevatedButton.styleFrom(
            backgroundColor: XColors.primary,
            shape: isLast
                ? RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))
                : const CircleBorder(),
            padding: isLast
                ? const EdgeInsets.symmetric(horizontal: 18, vertical: 12)
                : const EdgeInsets.all(14),
          ),
          child: isLast
              ? const Text(
            'Get Started',
            style: TextStyle(color: Colors.white, fontSize: 14),
          )
              : const Icon(
            LucideIcons.chevron_right,
            color: Colors.white,
          ),
        );
      }),
    );
  }
}
