import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Central override point for the Firebase SDK instances the app talks to.
///
/// In a normal run these just forward to the live Firebase singletons, so
/// nothing changes. `lib/main_mock.dart` overwrites [db]/[auth] with
/// in-memory fakes *before* `runApp`, and every repo/controller that reads
/// through here (instead of grabbing `FirebaseFirestore.instance` etc.
/// directly) transparently starts operating on local dummy data.
class FirebaseInstances {
  static FirebaseFirestore db = FirebaseFirestore.instance;
  static FirebaseAuth auth = FirebaseAuth.instance;
  static FirebaseStorage storage = FirebaseStorage.instance;
  static FirebaseFunctions functions = FirebaseFunctions.instance;
}
