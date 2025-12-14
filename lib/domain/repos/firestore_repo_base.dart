import 'package:cloud_firestore/cloud_firestore.dart';

class RepoBase {
  final FirebaseFirestore db;
  RepoBase(this.db);

  CollectionReference<Map<String, dynamic>> col(String path) => db.collection(path);
  DocumentReference<Map<String, dynamic>> doc(String path) => db.doc(path);

  /// Simple "page after" helper for queries ordered by a field.
  Query<Map<String, dynamic>> applyPaging({
    required Query<Map<String, dynamic>> q,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
    int limit = 30,
  }) {
    var query = q.limit(limit);
    if (startAfter != null) query = query.startAfterDocument(startAfter);
    return query;
  }
}
