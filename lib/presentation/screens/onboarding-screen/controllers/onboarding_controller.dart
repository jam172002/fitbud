// ----------------------------
// controllers/onboarding_controller.dart
// ----------------------------
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../authentication/screens/user_login_screen.dart';

class OnBoardingController extends GetxController {
  static OnBoardingController get instance => Get.find<OnBoardingController>();

  static const String _kOnboardingDoneKey = 'onboarding_done';
  static const int pageCount = 3;
  static const int lastPageIndex = pageCount - 1;

  final PageController pageController = PageController();
  final RxInt currentPageIndex = 0.obs;

  void updatePageIndicator(int index) => currentPageIndex.value = index;

  Future<void> dotNavigationClick(int index) async {
    currentPageIndex.value = index;
    await pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingDoneKey, true);

    // Replace stack so user can't go back to onboarding
    Get.offAll(() => const UserLoginScreen());
  }

  Future<void> nextPage() async {
    if (currentPageIndex.value >= lastPageIndex) {
      await _completeOnboarding();
      return;
    }

    final next = currentPageIndex.value + 1;
    await pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> skipPage() async {
    currentPageIndex.value = lastPageIndex;
    await pageController.animateToPage(
      lastPageIndex,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  static Future<bool> isOnboardingDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kOnboardingDoneKey) ?? false;
  }
}
