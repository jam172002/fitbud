
import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../controllers/onboarding_controller.dart';

class OnBoardingArrowButton extends StatelessWidget {
  const OnBoardingArrowButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: kBottomNavigationBarHeight - 25,
      child: ElevatedButton(
        onPressed: () => OnBoardingController.instance.nextPage(),
        style: ElevatedButton.styleFrom(
          shape: const CircleBorder(),
          backgroundColor: XColors.primary,
        ),
        child: const Icon(
          LucideIcons.chevron_right,
          color: XColors.primaryText,
        ),
      ),
    );
  }
}
