import 'package:fitbud/Onboarding/controllers/onboarding_controller.dart';
import 'package:fitbud/Onboarding/screens/onboarding-screen/widgets/onboarding_arrow_button.dart';
import 'package:fitbud/Onboarding/screens/onboarding-screen/widgets/onboarding_dots.dart';
import 'package:fitbud/Onboarding/screens/onboarding-screen/widgets/onboarding_page.dart';
import 'package:fitbud/Onboarding/screens/onboarding-screen/widgets/onboarding_skip.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class XOnBoarding extends StatelessWidget {
  const XOnBoarding({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OnBoardingController());
    return Scaffold(
      body: Stack(
        children: [
          /// Horizontal scrollable pages
          PageView(
            controller: controller.pageController,
            onPageChanged: controller.updatePageIndicator,
            children: [
              OnBoardingPage(
                image: 'assets/images/OB1.png',
                title: 'Find Perfect Fitness Match',
                subtitle:
                    'Discover gym and sports buddies who share your energy, goals, and vibe so you never train alone again.',
              ),
              OnBoardingPage(
                image: "assets/images/OB2.png",
                title: 'Build Your Workout Crew',
                subtitle:
                    'Create groups, plan sessions, and stay consistent together. Fitness feels better when you move as a team.',
              ),
              OnBoardingPage(
                image: "assets/images/OB3.png",
                title: 'Unlock Premium Gym Access',
                subtitle:
                    'Explore verified gyms, grab memberships, and train anywhere with ease all inside the app.',
              ),
            ],
          ),

          /// Skip button
          const OnBoardingSkip(),

          /// Dot Navigation
          const OnBoardingDotNavigation(),

          /// Arrow Button
          const OnBoardingArrowButton(),
        ],
      ),
    );
  }
}
