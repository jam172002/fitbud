import '../domain/models/common/geo.dart';

/// Lightweight stand-in for a Firestore document snapshot: an id plus a
/// camelCase field map. Models keep their `fromDoc(Doc)` factories; repos
/// build a [Doc] from each Postgres row.
class Doc {
  final String id;
  final Map<String, dynamic> _data;
  const Doc(this.id, this._data);

  Map<String, dynamic> data() => _data;
  bool get exists => true;

  /// Build from a Postgres row (snake_case) - [idKey] is the column that
  /// identifies the row (defaults to `id`).
  factory Doc.fromRow(Map<String, dynamic> row, {String idKey = 'id'}) {
    final m = DbRow.toCamel(row);
    return Doc('${row[idKey] ?? ''}', m);
  }
}

/// snake_case <-> camelCase conversion for row maps (top level only; jsonb
/// payloads such as notification `data` are left untouched).
class DbRow {
  static String camel(String s) {
    if (!s.contains('_')) return s;
    final parts = s.split('_');
    return parts.first +
        parts.skip(1).map((p) => p.isEmpty ? p : p[0].toUpperCase() + p.substring(1)).join();
  }

  static String snake(String s) =>
      s.replaceAllMapped(RegExp(r'[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

  static Map<String, dynamic> toCamel(Map<String, dynamic> row) =>
      {for (final e in row.entries) camel(e.key): e.value};

  /// Model map -> row map: snake_case keys, DateTime -> ISO-8601, GeoPoint-like
  /// values -> {lat,lng}, `id` dropped, and keys listed in [drop] removed.
  static Map<String, dynamic> toRow(Map<String, dynamic> m, {Set<String> drop = const {}}) {
    final out = <String, dynamic>{};
    m.forEach((k, v) {
      if (k == 'id' || drop.contains(k)) return;
      out[snake(k)] = encode(v);
    });
    return out;
  }

  static dynamic encode(dynamic v) {
    if (v is DateTime) return v.toUtc().toIso8601String();
    if (v is List) return v.map(encode).toList();
    if (v is Map) return v.map((k, x) => MapEntry('$k', encode(x)));
    if (v is GeoPoint) return v.toJson();
    return v;
  }
}
