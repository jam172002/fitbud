// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'app.dart';
import 'notification_helper/my_notification.dart';

// Only needed for background handler registration
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register background handler ASAP (must be top-level function in your file)
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);
  }

  runApp(const MainApp());
}