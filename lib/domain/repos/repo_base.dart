import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/doc.dart';
import 'repo_exceptions.dart';

/// Shared plumbing for the Supabase-backed repositories.
class RepoBase {
  final SupabaseClient db;
  RepoBase(this.db);

  /// Signed-in user id (throws if signed out).
  String requireUid() {
    final u = db.auth.currentUser;
    if (u == null) throw PermissionException('User is not signed in');
    return u.id;
  }

  /// Realtime stream of a table, mapped to [Doc]s.
  ///
  /// Supabase streams support a single server-side `eq` filter plus order /
  /// limit; any extra condition goes in [where] and is applied client-side.
  /// RLS already scopes what the user can receive.
  Stream<List<Doc>> streamDocs(
    String table, {
    List<String> pk = const ['id'],
    String idKey = 'id',
    String? eqColumn,
    Object? eqValue,
    String? orderBy,
    bool ascending = false,
    int? limit,
    bool Function(Map<String, dynamic> row)? where,
  }) {
    dynamic b = db.from(table).stream(primaryKey: pk);
    if (eqColumn != null) b = b.eq(eqColumn, eqValue);
    if (orderBy != null) b = b.order(orderBy, ascending: ascending);
    if (limit != null) b = b.limit(limit);
    return (b as Stream<List<Map<String, dynamic>>>).map((rows) {
      final filtered = where == null ? rows : rows.where(where);
      return filtered.map((r) => Doc.fromRow(r, idKey: idKey)).toList();
    });
  }

  List<Doc> docs(List<dynamic> rows, {String idKey = 'id'}) => rows
      .map((r) => Doc.fromRow(Map<String, dynamic>.from(r as Map), idKey: idKey))
      .toList();

  Doc docOf(dynamic row, {String idKey = 'id'}) =>
      Doc.fromRow(Map<String, dynamic>.from(row as Map), idKey: idKey);
}
