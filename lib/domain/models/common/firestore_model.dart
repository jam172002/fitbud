/// Base contract for Postgres-backed models (kept under its original name so
/// every model keeps compiling unchanged).
abstract class FirestoreModel {
  String get id;

  /// Serialize to Firestore map (no id).
  Map<String, dynamic> toMap();

  /// Helper: DateTime? -> ISO-8601 string (UTC) for writes.
  static String? ts(DateTime? dt) => dt?.toUtc().toIso8601String();

  /// Helper: read a timestamp (ISO string / DateTime) as local DateTime.
  static DateTime? readDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v.toLocal();
    if (v is String) return DateTime.tryParse(v)?.toLocal();
    return null;
  }

  /// Helper: read int safely
  static int readInt(dynamic v, {int fallback = 0}) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return fallback;
  }

  /// Helper: read double safely
  static double readDouble(dynamic v, {double fallback = 0}) {
    if (v is double) return v;
    if (v is num) return v.toDouble();
    return fallback;
  }

  /// Helper: read bool safely
  static bool readBool(dynamic v, {bool fallback = false}) {
    if (v is bool) return v;
    return fallback;
  }

  /// Helper: read string safely
  static String readString(dynamic v, {String fallback = ''}) {
    if (v is String) return v;
    return fallback;
  }

  /// Helper: read list<string> safely
  static List<String> readStringList(dynamic v) {
    if (v is List) {
      return v.whereType<String>().toList();
    }
    return const [];
  }

  /// Helper: read Map safely
  static Map<String, dynamic> readMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return Map<String, dynamic>.from(v);
    return <String, dynamic>{};
  }
}
