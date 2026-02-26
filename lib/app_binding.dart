// lib/app_binding.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import 'domain/repos/repo_provider.dart';
import 'domain/repos/scans/scan_repo.dart';

import 'presentation/screens/authentication/controllers/auth_controller.dart';
import 'presentation/screens/authentication/controllers/location_controller.dart';
import 'presentation/screens/budy/controller/buddy_controller.dart';
import 'presentation/screens/budy/controller/session_invites_controller.dart';
import 'presentation/screens/gyms/controllers/gyms_user_controller.dart';
import 'presentation/screens/home/home_controller.dart';
import 'presentation/screens/scanning/controllers/scan_controller.dart';
import 'presentation/screens/subscription/plans_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // Repos: ONE global instance
    Get.put<Repos>(Repos(), permanent: true);

    //  Auth controller should be global (used everywhere)
    Get.put<AuthController>(
      AuthController(Get.find<Repos>()),
      permanent: true,
    );

    //  Light/global controllers
    Get.put<LocationController>(LocationController(), permanent: true);
    Get.put<PremiumPlanController>(PremiumPlanController(), permanent: true);

    //  Heavy or screen-based controllers -> lazy
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);

    Get.lazyPut<BuddyController>(
          () => BuddyController(Get.find<Repos>()),
      fenix: true,
    );

    Get.lazyPut<GymsUserController>(
          () => GymsUserController(Get.find<Repos>().gymRepo),
      fenix: true,
    );

    Get.lazyPut<SessionInvitesController>(
          () => SessionInvitesController(Get.find<Repos>()),
      fenix: true,
    );

    //  Scan repo is okay global (used in multiple scan screens)
    Get.put<ScanRepo>(
      ScanRepo(
        FirebaseFirestore.instance,
        FirebaseAuth.instance,
        FirebaseFunctions.instance,
      ),
      permanent: true,
    );

    Get.lazyPut<ScanController>(() => ScanController(Get.find()), fenix: true);
  }
}