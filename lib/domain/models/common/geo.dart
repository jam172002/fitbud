import 'package:cloud_firestore/cloud_firestore.dart';

class GeoPointX {
  static GeoPoint? fromAny(dynamic v) {
    if (v == null) return null;
    if (v is GeoPoint) return v;
    // Allow {lat,lng} maps
    if (v is Map) {
      final m = Map<String, dynamic>.from(v);
      final lat = m['lat'];
      final lng = m['lng'];
      if (lat is num && lng is num) return GeoPoint(lat.toDouble(), lng.toDouble());
    }
    return null;
  }

  static Map<String, dynamic>? toJson(GeoPoint? gp) {
    if (gp == null) return null;
    return {'lat': gp.latitude, 'lng': gp.longitude};
  }
}
