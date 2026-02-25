// lib/app.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app_binding.dart';
import 'notification_helper/my_notification.dart';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'presentation/screens/authentication/controllers/auth_controller.dart';
import 'presentation/screens/authentication/screens/user_login_screen.dart';
import 'presentation/screens/navigation/user_navigation.dart';
import 'presentation/screens/onboarding-screen/controllers/onboarding_controller.dart';
import 'presentation/screens/onboarding-screen/onboarding.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  Future<bool> _showOnboarding() async {
    final done = await OnBoardingController.isOnboardingDone();
    return !done;
  }

  Future<void> _initAfterFirstFrame() async {
    // Fire-and-forget init
    if (!kIsWeb) {
      await FirebaseAppCheck.instance.activate(
        androidProvider:
        kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      );

      // Ask permissions AFTER UI is shown
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();

      await MyNotification.initialize(flutterLocalNotificationsPlugin);
    } else {
      MyNotification.initializeWebMessaging();
    }

    // Update token if already logged in
    final authC = Get.find<AuthController>();
    final u = authC.authUser.value;
    if (u != null) {
      authC.updateUserDeviceToken();
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAfterFirstFrame();
    });

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      initialBinding: AppBinding(),
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF000000),
        fontFamily: 'Outfit',
      ),
      home: const _RootGate(),
    );
  }

}

class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final authC = Get.find<AuthController>();

    return FutureBuilder<bool>(
      future: OnBoardingController.isOnboardingDone().then((done) => !done),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.data == true) {
          return const XOnBoarding();
        }

        return Obx(() {
          final user = authC.authUser.value;
          return user == null
              ? const UserLoginScreen()
              : const UserNavigation();
        });
      },
    );
  }
}