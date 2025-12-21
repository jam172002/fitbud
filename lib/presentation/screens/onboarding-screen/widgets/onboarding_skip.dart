import '../controllers/onboarding_controller.dart';
import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';

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
