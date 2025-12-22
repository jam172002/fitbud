import 'package:cloud_firestore/cloud_firestore.dart';

class Activity {
  final String id;
  final String name;
  final int order;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Activity({
    required this.id,
    required this.name,
    required this.order,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  // -----------------------
  // Firestore deserialization
  // -----------------------
  factory Activity.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Activity(
      id: doc.id,
      name: data['name'] as String,
      order: (data['order'] ?? 0) as int,
      isActive: (data['isActive'] ?? true) as bool,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  // -----------------------
  // Firestore serialization
  // -----------------------
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'order': order,
      'isActive': isActive,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // -----------------------
  // Copy helper
  // -----------------------
  Activity copyWith({
    String? name,
    int? order,
    bool? isActive,
  }) {
    return Activity(
      id: id,
      name: name ?? this.name,
      order: order ?? this.order,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
