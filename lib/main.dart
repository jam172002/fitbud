// lib/main.dart
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

  final repos = Repos();
  Get.put<Repos>(repos, permanent: true);

  // SAFE BEFORE LOGIN
  Get.put<GymsUserController>(
    GymsUserController(Get.find<Repos>().gymRepo),
    permanent: true,
  );
  Get.put<LocationController>(LocationController(), permanent: true);
  Get.put<PremiumPlanController>(PremiumPlanController(), permanent: true);

  // AUTH
  Get.put<AuthController>(
    AuthController(Get.find<Repos>()),
    permanent: true,
  );

  runApp(const MainApp());
}
