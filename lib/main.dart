import 'package:fitbud/presentation/screens/gyms/controllers/gyms_user_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';

import 'app.dart';
import 'domain/repos/repo_provider.dart';
import 'firebase_options.dart';
import 'package:fitbud/presentation/screens/authentication/controllers/auth_controller.dart';
import 'package:fitbud/presentation/screens/authentication/controllers/location_controller.dart';
import 'package:fitbud/presentation/screens/subscription/plans_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Repo container
  final repos = Repos();
  Get.put<Repos>(repos, permanent: true);

  // Controllers (depend on repos)
  Get.put<GymsUserController>(
    GymsUserController(Get.find<Repos>().gymRepo),
    permanent: true,
  );

  Get.put(LocationController(), permanent: true);
  Get.put(PremiumPlanController());


  Get.put<AuthController>(
    AuthController(Get.find<Repos>()),
    permanent: true,
  );

  // IMPORTANT: seeds should not run in production builds
  // Keep them guarded or remove after testing.
  // await FirebaseSeed.seedAll();
  // await FirebaseSeedUsers.seedProfilesForExistingUids();
  // await FirebaseSeedUsers.seedAll();

  runApp(const MainApp());
}
