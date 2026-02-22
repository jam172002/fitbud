import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/activities/activity.dart';
import '../firestore_paths.dart';
import '../firestore_repo_base.dart';

class ActivityRepo extends RepoBase {
  final FirebaseAuth auth;
  ActivityRepo(super.db, this.auth);

  // ---- Activities ----

  Stream<List<Activity>> watchActiveActivities() {
    return col(FirestorePaths.activities)
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((s) => s.docs.map(Activity.fromDoc).toList());
  }

  Future<void> createActivity(Activity activity) async {
    await col(FirestorePaths.activities)
        .doc(activity.id)
        .set(activity.toMap());
  }

  Future<void> updateActivity(String id, Map<String, dynamic> fields) async {
    await col(FirestorePaths.activities)
        .doc(id)
        .update({
      ...fields,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deactivateActivity(String id) async {
    await updateActivity(id, {'isActive': false});
  }
}
