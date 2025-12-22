import 'package:fitbud/tools/firebase_seed.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app.dart';
import 'domain/repos/repo_provider.dart';
import 'firebase_options.dart';
import 'package:fitbud/presentation/screens/authentication/controllers/auth_controller.dart';
import 'package:fitbud/User-App/features/service/controllers/location_controller.dart';
import 'package:fitbud/User-App/features/service/controllers/plans_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Create repositories container
  final repos = Repos();

  // Register global dependencies
  Get.put<Repos>(repos, permanent: true);

  Get.put(LocationController(), permanent: true);
  Get.put(PremiumPlanController(), permanent: true);

  // AuthController requires Repos
  Get.put<AuthController>(AuthController(Get.find<Repos>()), permanent: true);
  // 🚨 RUN ONLY ONCE
  //await FirebaseSeed.seedAll();

  runApp(const MainApp());
}
