import 'package:firebase_auth/firebase_auth.dart';
import '../../../domain/models/notifications/app_notification.dart';
import '../firestore_paths.dart';
import '../firestore_repo_base.dart';
import '../repo_exceptions.dart';

class NotificationRepo extends RepoBase {
  final FirebaseAuth auth;
  NotificationRepo(super.db, this.auth);

  String _uid() {
    final u = auth.currentUser;
    if (u == null) throw PermissionException('User is not signed in');
    return u.uid;
  }

  Stream<List<AppNotification>> watchMyNotifications({int limit = 50}) {
    final uid = _uid();
    // Prefer subcollection per user
    return col(FirestorePaths.userNotifications(uid))
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((q) => q.docs.map(AppNotification.fromDoc).toList());
  }

  Future<void> markRead(String notificationId) async {
    final uid = _uid();
    await doc('${FirestorePaths.userNotifications(uid)}/$notificationId')
        .update({'isRead': true});
  }

  Future<void> markAllRead() async {
    final uid = _uid();
    final q = await col(FirestorePaths.userNotifications(uid))
        .where('isRead', isEqualTo: false)
        .limit(200)
        .get();
    final batch = db.batch();
    for (final d in q.docs) {
      batch.update(d.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
