import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';

import 'package:fitbud/app.dart';
import 'package:fitbud/User-App/features/service/controllers/location_controller.dart';
import 'package:fitbud/User-App/features/authentication/controllers/auth_controller.dart';

import 'domain/repos/repo_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Core singletons (permanent)
  Get.put<Repos>(Repos(), permanent: true);

  // Controllers (permanent)
  Get.put<AuthController>(AuthController(Get.find<Repos>()), permanent: true);
  Get.put<LocationController>(LocationController(), permanent: true);

  runApp(const MainApp());
}
