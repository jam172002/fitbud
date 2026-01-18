import 'package:cloud_firestore/cloud_firestore.dart';

class UserAddress {
  final String id;

  final String? label;   // Home / Work
  final String? city;
  final String? line1;   // main street/area
  final String? line2;   // optional extra
  final double? lat;
  final double? lng;

  final bool isDefault;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserAddress({
    required this.id,
    this.label,
    this.city,
    this.line1,
    this.line2,
    this.lat,
    this.lng,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  String get title => (city ?? '').trim().isNotEmpty ? city!.trim() : (label ?? 'Saved Address');
  String get subtitle {
    final parts = <String>[];
    final l1 = (line1 ?? '').trim();
    final l2 = (line2 ?? '').trim();
    if (l1.isNotEmpty) parts.add(l1);
    if (l2.isNotEmpty) parts.add(l2);
    return parts.isNotEmpty ? parts.join(', ') : '—';
  }

  factory UserAddress.fromDoc(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};

    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    return UserAddress(
      id: doc.id,
      label: d['label'],
      city: d['city'],
      line1: d['line1'],
      line2: d['line2'],
      lat: _toDouble(d['lat']),
      lng: _toDouble(d['lng']),
      isDefault: (d['isDefault'] ?? false) == true,
      createdAt: d['createdAt'] != null ? (d['createdAt'] as Timestamp).toDate() : null,
      updatedAt: d['updatedAt'] != null ? (d['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'label': label,
      'city': city,
      'line1': line1,
      'line2': line2,
      'lat': lat,
      'lng': lng,
      'isDefault': isDefault,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}
