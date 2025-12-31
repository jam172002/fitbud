import 'package:cloud_firestore/cloud_firestore.dart';
import 'repo_exceptions.dart';

class RepoBase {
  final FirebaseFirestore db;
  RepoBase(this.db);

  String _sanitizePath(String path) {
    final p = path.trim();

    if (p.isEmpty) {
      throw RepoException('Invalid path: empty', 'invalid_path');
    }
    if (p.contains('//')) {
      throw RepoException('Invalid path: "$p"', 'invalid_path');
    }
    // Also block paths starting/ending with "/"
    if (p.startsWith('/') || p.endsWith('/')) {
      throw RepoException('Invalid path: "$p"', 'invalid_path');
    }
    return p;
  }

  CollectionReference<Map<String, dynamic>> col(String path) =>
      db.collection(_sanitizePath(path));

  DocumentReference<Map<String, dynamic>> doc(String path) =>
      db.doc(_sanitizePath(path));

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
