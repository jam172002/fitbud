import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/firestore_model.dart';

class Plan implements FirestoreModel {
  @override
  final String id;

  final String name;
  final String description;
  final double price;
  final String currency;
  final int durationDays;
  final List<String> features;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Plan({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currency,
    required this.durationDays,
    required this.features,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  static Plan fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};

    // Support both old and new keys (admin model already does this)
    final createdAtRaw = d['createdAt'];
    final updatedAtRaw = d['updatedAt'];

    return Plan(
      id: doc.id,
      name: FirestoreModel.readString(d['name']),
      description: FirestoreModel.readString(d['description']),
      price: _toDouble(d['price']),
      currency: FirestoreModel.readString(d['currency'], fallback: 'PKR'),
      durationDays: _toInt(d['durationDays'] ?? d['duration']),
      features: _toStringList(d['features'] ?? d['facilities']),
      isActive: FirestoreModel.readBool(d['isActive'], fallback: true),
      createdAt: createdAtRaw is Timestamp ? createdAtRaw.toDate() : FirestoreModel.readDate(createdAtRaw),
      updatedAt: updatedAtRaw is Timestamp ? updatedAtRaw.toDate() : FirestoreModel.readDate(updatedAtRaw),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    // In user app, you’ll mostly read. Still returning admin-compatible map is useful.
    return {
      'name': name.trim(),
      'description': description.trim(),
      'price': price,
      'currency': currency,
      'durationDays': durationDays,
      'features': features,
      'isActive': isActive,
      'createdAt': FirestoreModel.ts(createdAt),
      'updatedAt': FirestoreModel.ts(updatedAt),
    };
  }

  static double _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse('${v ?? ''}') ?? 0.0;
  }

  static int _toInt(dynamic v) {
    if (v is num) return v.toInt();
    return int.tryParse('${v ?? ''}') ?? 0;
  }

  static List<String> _toStringList(dynamic v) {
    if (v is List) return v.map((e) => e.toString()).toList();
    return <String>[];
  }
}
