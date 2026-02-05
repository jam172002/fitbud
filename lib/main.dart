// lib/main.dart
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
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
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

import 'notification_helper/my_notification.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );


  FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);

  await FirebaseAppCheck.instance.activate(
    androidProvider:
    kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
  );

  await Permission.notification.isDenied.then((value) {
    if (value) {
      Permission.notification.request();
    }
  });

  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
      AndroidFlutterLocalNotificationsPlugin>()
      ?.requestNotificationsPermission();

  await MyNotification.initialize(flutterLocalNotificationsPlugin);


  final repos = Repos();
  Get.put<Repos>(repos, permanent: true);
  Get.put<AuthController>(
    AuthController(Get.find<Repos>()),
    permanent: true,
  );
  Get.put<GymsUserController>(
    GymsUserController(Get.find<Repos>().gymRepo),
    permanent: true,
  );

  Get.put<LocationController>(LocationController(), permanent: true);
  Get.put<PremiumPlanController>(PremiumPlanController(), permanent: true);



  runApp(const MainApp());
}


