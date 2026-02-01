import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitbud/presentation/screens/budy/controller/session_invites_controller.dart';
import 'package:fitbud/presentation/screens/scanning/controllers/scan_controller.dart';
import 'package:get/get.dart';

import 'domain/repos/repo_provider.dart';
import 'domain/repos/scans/scan_repo.dart';
import 'presentation/screens/home/home_controller.dart';
import 'presentation/screens/budy/controller/buddy_controller.dart';
import 'presentation/screens/authentication/controllers/location_controller.dart';
import 'presentation/screens/subscription/plans_controller.dart';
import 'presentation/screens/gyms/controllers/gyms_user_controller.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // Repos (ONE instance globally)
    if (!Get.isRegistered<Repos>()) {
      Get.put<Repos>(Repos(), permanent: true);
    }

    // Controllers that can exist globally
    Get.put<LocationController>(LocationController(), permanent: true);
    Get.put<PremiumPlanController>(PremiumPlanController(), permanent: true);

    // Session invites controller depends on repos
    Get.put<SessionInvitesController>(
      SessionInvitesController(Get.find<Repos>()),
      permanent: true,
    );

    // These can be lazy-created when first needed (prevents flash)
    Get.lazyPut<HomeController>(() => HomeController(), fenix: true);

    Get.lazyPut<BuddyController>(
          () => BuddyController(Get.find<Repos>()),
      fenix: true,
    );

    Get.lazyPut<GymsUserController>(
          () => GymsUserController(Get.find<Repos>().gymRepo),
      fenix: true,
    );

    Get.put<ScanRepo>(
      ScanRepo(
        FirebaseFirestore.instance,
        FirebaseAuth.instance,
        FirebaseFunctions.instance,
      ),
    );

    Get.put(ScanController(Get.find()));

  }
}
