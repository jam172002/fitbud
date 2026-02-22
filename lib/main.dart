// lib/main.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:fitbud/notification_helper/my_notification.dart';
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
import 'package:flutter/foundation.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Enable Firestore offline persistence so data loads from cache instantly
  // on repeat visits — major speed improvement on slow connections.
  if (kIsWeb) {
    try {
      await FirebaseFirestore.instance.enablePersistence(
        const PersistenceSettings(synchronizeTabs: true),
      );
    } catch (_) {}
  } else {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  }

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);
  }

  if (!kIsWeb) {
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
    );
  }

  if (!kIsWeb) {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  if (!kIsWeb) {
    await MyNotification.initialize(flutterLocalNotificationsPlugin);
  } else {
    MyNotification.initializeWebMessaging();
  }

  final repos = Repos();
  Get.put<Repos>(repos, permanent: true);

  final authController = AuthController(Get.find<Repos>());
  Get.put<AuthController>(authController, permanent: true);

  Get.put<GymsUserController>(
    GymsUserController(Get.find<Repos>().gymRepo),
    permanent: true,
  );

  Get.put<LocationController>(LocationController(), permanent: true);
  Get.put<PremiumPlanController>(PremiumPlanController(), permanent: true);

  // Store the subscription so it can be cancelled if needed.
  // ignore: unused_local_variable
  final _authListen = authController.authUser.listen((user) {
    if (user != null) {
      authController.updateUserDeviceToken();
    }
  });

  runApp(const MainApp());
}
