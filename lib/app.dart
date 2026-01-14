// lib/app.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_binding.dart';
import 'presentation/screens/navigation/user_navigation.dart';
import 'presentation/screens/authentication/screens/user_login_screen.dart';
import 'presentation/screens/onboarding-screen/onboarding.dart';
import 'presentation/screens/onboarding-screen/controllers/onboarding_controller.dart';
import 'presentation/screens/authentication/controllers/auth_controller.dart';

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
      initialBinding: AppBinding(), // ✅ all dependencies are ready before UI builds
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

          final showOnboarding = snap.data ?? true;
          if (showOnboarding) return const XOnBoarding();

          return Obx(() {
            final u = authC.authUser.value;
            if (u == null) return const UserLoginScreen();

            // ✅ HomeController is guaranteed available via binding
            return UserNavigation();
          });
        },
      ),
    );
  }
}
