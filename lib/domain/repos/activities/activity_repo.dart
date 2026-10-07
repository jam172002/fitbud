import '../../../data/doc.dart';
import '../../models/activities/activity.dart';
import '../repo_base.dart';

class ActivityRepo extends RepoBase {
  ActivityRepo(super.db);

  Stream<List<Activity>> watchActiveActivities() {
    return streamDocs('activities', where: (r) => r['is_active'] == true)
        .map((l) => (l.map(Activity.fromDoc).toList())..sort((a, b) => a.order.compareTo(b.order)));
  }

  Future<void> createActivity(Activity activity) async {
    await db.from('activities').upsert({'id': activity.id, ...DbRow.toRow(activity.toMap())});
  }

  Future<void> updateActivity(String id, Map<String, dynamic> fields) async {
    await db.from('activities').update(DbRow.toRow(fields, drop: {'updatedAt'})).eq('id', id);
  }

  Future<void> deactivateActivity(String id) async {
    await updateActivity(id, {'isActive': false});
  }
}
