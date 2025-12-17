import 'package:fitbud/User-App/features/service/controllers/location_controller.dart';
import 'package:fitbud/User-App/features/service/controllers/plans_controller.dart';
import 'package:fitbud/app.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  /// Global controllers
  Get.put(LocationController(), permanent: true);
  Get.put(PremiumPlanController(), permanent: true);

  runApp(const MainApp());
}
