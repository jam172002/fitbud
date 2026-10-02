/// Minimal lat/lng value (replaces Firestore's GeoPoint). Stored in Postgres
/// as jsonb `{"lat":..,"lng":..}`.
class GeoPoint {
  final double latitude;
  final double longitude;
  const GeoPoint(this.latitude, this.longitude);

  Map<String, dynamic> toJson() => {'lat': latitude, 'lng': longitude};

  @override
  String toString() => 'GeoPoint($latitude, $longitude)';
}

class GeoPointX {
  static GeoPoint? fromAny(dynamic v) {
    if (v == null) return null;
    if (v is GeoPoint) return v;
    if (v is Map) {
      final m = Map<String, dynamic>.from(v);
      final lat = m['lat'] ?? m['latitude'];
      final lng = m['lng'] ?? m['longitude'];
      if (lat is num && lng is num) return GeoPoint(lat.toDouble(), lng.toDouble());
    }
    return null;
  }

  static Map<String, dynamic>? toJson(GeoPoint? gp) => gp?.toJson();
}
