import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../authentication/screens/user_login_screen.dart';

class OnBoardingController extends GetxController {
  static OnBoardingController get instance => Get.find();

  // Page Controller
  final pageController = PageController();

  // Current page index
  Rx<int> currentPageIndex = 0.obs;

  // Update page index when scrolling
  void updatePageIndicator(int index) {
    currentPageIndex.value = index;
  }

  // Jump to selected dot page
  void dotNavigationClick(int index) {
    currentPageIndex.value = index;
    pageController.jumpToPage(index);
  }

  // Go to next page
  void nextPage() {
    if (currentPageIndex.value == 2) {
      Get.to(() => UserLoginScreen());
    } else {
      int page = currentPageIndex.value + 1;
      pageController.jumpToPage(page);
    }
  }

  // Skip to the last page
  void skipPage() {
    currentPageIndex.value = 2;
    pageController.jumpToPage(2);
  }
}
