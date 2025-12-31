// lib/app.dart
import 'package:fitbud/presentation/screens/authentication/controllers/location_controller.dart';
import 'package:fitbud/presentation/screens/gyms/controllers/gyms_user_controller.dart';
import 'package:fitbud/presentation/screens/subscription/plans_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:fitbud/presentation/screens/navigation/user_navigation.dart';
import 'package:fitbud/presentation/screens/authentication/screens/user_login_screen.dart';
import 'package:fitbud/presentation/screens/onboarding-screen/onboarding.dart';
import 'package:fitbud/presentation/screens/onboarding-screen/controllers/onboarding_controller.dart';
import 'package:fitbud/presentation/screens/authentication/controllers/auth_controller.dart';
import 'package:fitbud/presentation/screens/home/home_controller.dart';
import 'package:fitbud/presentation/screens/budy/controller/buddy_controller.dart';

import 'domain/repos/repo_provider.dart';

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
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final showOnboarding = snap.data ?? true;
          if (showOnboarding) return const XOnBoarding();

          return Obx(() {
            final u = authC.authUser.value;

            if (u == null) {
              // Ensure signed-out controllers are removed
              if (Get.isRegistered<HomeController>()) {
                Get.delete<HomeController>(force: true);
              }
              if (Get.isRegistered<BuddyController>()) {
                Get.delete<BuddyController>(force: true);
              }
              return const UserLoginScreen();
            }

            // Signed in → create controllers that require uid()
            if (!Get.isRegistered<HomeController>()) {
              Get.put<HomeController>(HomeController(), permanent: true);
            }
            if (!Get.isRegistered<BuddyController>()) {
              Get.put<BuddyController>(BuddyController(Get.find<Repos>()), permanent: true);
            }


            // Repo container
            final repos = Repos();
            Get.put<Repos>(repos, permanent: true);
            Get.put(HomeController());
            Get.put(BuddyController(Get.find<Repos>()), permanent: true);

            // Controllers (depend on repos)
            Get.put<GymsUserController>(
              GymsUserController(Get.find<Repos>().gymRepo),
              permanent: true,
            );

            Get.put(LocationController(), permanent: true);
            Get.put(PremiumPlanController());

            return UserNavigation();
          });
        },
      ),
    );
  }
}
