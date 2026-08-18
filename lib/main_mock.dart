// lib/main_mock.dart
//
// Local-data preview entry point. Runs the exact same app UI as lib/main.dart,
// but backed entirely by an in-memory Firestore + a signed-in mock user
// pre-loaded with dummy data (buddies, gyms, chats, notifications, plans...),
// so you can see every screen without touching the real Firebase backend.
//
// Run with:
//   flutter run -t lib/main_mock.dart
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'domain/repos/repo_provider.dart';
import 'firebase_instances.dart';
import 'firebase_options.dart';
import 'mock/dummy_data.dart';
import 'presentation/screens/authentication/controllers/auth_controller.dart';
import 'presentation/screens/authentication/controllers/location_controller.dart';
import 'presentation/screens/gyms/controllers/gyms_user_controller.dart';
import 'presentation/screens/subscription/plans_controller.dart';

const _meUid = 'demo_user';
const _meName = 'Ahmed Raza';
const _meEmail = 'demo@fitbud.app';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Still needed so FirebaseStorage/FirebaseFunctions/FirebaseMessaging (used
  // elsewhere in the app) have a default Firebase app to attach to. This does
  // not require network access and does not touch your Firestore data.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Skip onboarding + go straight past the login screen.
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues({'onboarding_done': true});

  final fakeDb = FakeFirebaseFirestore();
  final mockAuth = MockFirebaseAuth(
    mockUser: MockUser(
      uid: _meUid,
      email: _meEmail,
      displayName: _meName,
      isAnonymous: false,
    ),
    signedIn: true,
  );

  // Every repo/controller built after this point (including the ones
  // AppBinding creates during GetMaterialApp init) will use these fakes.
  FirebaseInstances.db = fakeDb;
  FirebaseInstances.auth = mockAuth;

  await seedDummyData(fakeDb, meUid: _meUid, meName: _meName, meEmail: _meEmail);

  final repos = Repos(db: fakeDb, auth: mockAuth);
  Get.put<Repos>(repos, permanent: true);
  Get.put<AuthController>(AuthController(Get.find<Repos>()), permanent: true);
  Get.put<GymsUserController>(
    GymsUserController(Get.find<Repos>().gymRepo),
    permanent: true,
  );
  Get.put<LocationController>(LocationController(), permanent: true);
  Get.put<PremiumPlanController>(PremiumPlanController(), permanent: true);

  runApp(const MainApp());
}
