// ----------------------------
// widgets/onboarding_skip.dart
// Improvement: await async skip
// ----------------------------
import 'package:flutter/material.dart';
import 'package:fitbud/utils/colors.dart';

import '../controllers/onboarding_controller.dart';

class OnBoardingSkip extends StatelessWidget {
  const OnBoardingSkip({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: kToolbarHeight,
      right: 16,
      child: TextButton(
        onPressed: () => OnBoardingController.instance.skipPage(),
        style: TextButton.styleFrom(
          splashFactory: NoSplash.splashFactory,
          overlayColor: Colors.transparent,
          foregroundColor: XColors.primaryText,
        ),
        child: const Text('Skip'),
      ),
    );
  }
}
