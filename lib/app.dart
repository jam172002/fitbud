import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fitbud/presentation/screens/navigation/user_navigation.dart';
import 'package:fitbud/presentation/screens/authentication/screens/user_login_screen.dart';
import 'package:fitbud/presentation/screens/onboarding-screen/onboarding.dart';
import 'package:fitbud/presentation/screens/onboarding-screen/controllers/onboarding_controller.dart';
import 'package:fitbud/presentation/screens/authentication/controllers/auth_controller.dart';

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  Future<bool> _showOnboarding() async {
    final done = await OnBoardingController.isOnboardingDone();
    return !done;
  }

  @override
  Widget build(BuildContext context) {
    final authC = Get.find<AuthController>();

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF000000),
        fontFamily: 'Outfit',
      ),
      home: FutureBuilder<bool>(
        future: _showOnboarding(),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          // 1) Onboarding first
          final showOnboarding = snap.data ?? true;
          if (showOnboarding) return const XOnBoarding();

          // 2) Then auth
          return Obx(() {
            final u = authC.authUser.value;
            return (u == null) ? const UserLoginScreen() : UserNavigation();
          });
        },
      ),
    );
  }
}
