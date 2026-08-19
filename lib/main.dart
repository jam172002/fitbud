// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'notification_helper/my_notification.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await initAppCheck();
  // Register background handler ASAP (must be top-level function in your file)
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);
  }

  runApp(const MainApp());
}




Future<void> initAppCheck() async {
  if (kIsWeb) {
    // Web: use ReCaptcha v3 (needs site key in Firebase console)
    await FirebaseAppCheck.instance.activate(
      webProvider: ReCaptchaV3Provider('YOUR_RECAPTCHA_SITE_KEY'),
    );
    return;
  }

  if (kDebugMode) {
    //  Debug provider for local/dev builds
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.debug,
      appleProvider: AppleProvider.debug,
    );
  } else {
    //  Production provider
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.deviceCheck, // or appAttest if set
    );
  }
}