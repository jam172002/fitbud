// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'data/supabase_config.dart';
import 'firebase_options.dart';
import 'notification_helper/my_notification.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Backend: Supabase (auth, database, realtime, storage, edge functions).
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  // Firebase is used ONLY to receive push notifications (FCM). Everything
  // else lives in Supabase. A push-setup failure must never stop the app.
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    if (!kIsWeb) {
      // Must be registered ASAP and be a top-level function.
      FirebaseMessaging.onBackgroundMessage(myBackgroundMessageHandler);
    }
  } catch (e) {
    debugPrint('FCM init skipped: $e');
  }

  runApp(const MainApp());
}
