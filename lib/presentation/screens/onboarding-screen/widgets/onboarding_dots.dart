// ----------------------------
// widgets/onboarding_dots.dart
// Improvement: use controller method that is async-friendly
// ----------------------------
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'package:fitbud/utils/colors.dart';
import '../controllers/onboarding_controller.dart';

class OnBoardingDotNavigation extends StatelessWidget {
  const OnBoardingDotNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final c = OnBoardingController.instance;

    return Positioned(
      bottom: kBottomNavigationBarHeight,
      left: 16,
      child: SmoothPageIndicator(
        controller: c.pageController,
        count: OnBoardingController.pageCount,
        onDotClicked: (i) => c.dotNavigationClick(i),
        effect: ExpandingDotsEffect(
          activeDotColor: XColors.primary,
          dotHeight: 6,
        ),
      ),
    );
  }
}
