import '../../../domain/models/notifications/app_notification.dart';
import '../repo_base.dart';

class NotificationRepo extends RepoBase {
  NotificationRepo(super.db);

  Stream<List<AppNotification>> watchMyNotifications({int limit = 50}) {
    final uid = requireUid();
    return streamDocs('notifications',
            eqColumn: 'user_id', eqValue: uid, orderBy: 'created_at', limit: limit)
        .map((l) => l.map(AppNotification.fromDoc).toList());
  }

  Future<void> markRead(String notificationId) async {
    final uid = requireUid();
    await db
        .from('notifications')
        .update({'is_read': true})
        .eq('id', notificationId)
        .eq('user_id', uid);
  }

  Future<void> markAllRead() async {
    final uid = requireUid();
    await db
        .from('notifications')
        .update({'is_read': true})
        .eq('user_id', uid)
        .eq('is_read', false);
  }
}
