import 'dart:convert';

String? extractGymId(String raw) {
  final v = raw.trim();
  if (v.isEmpty) return null;

  // JSON payload
  if (v.startsWith('{') && v.endsWith('}')) {
    try {
      final obj = jsonDecode(v);
      if (obj is Map && obj['gymId'] != null) return obj['gymId'].toString().trim();
    } catch (_) {}
  }

  // Deep link
  if (v.startsWith('fitbud://')) {
    try {
      final uri = Uri.parse(v);
      final gymId = uri.queryParameters['gymId'];
      if (gymId != null && gymId.trim().isNotEmpty) return gymId.trim();
    } catch (_) {}
  }

  // Plain gymId
  return v;
}
