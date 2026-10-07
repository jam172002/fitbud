import '../../../data/doc.dart';
import '../common/firestore_model.dart';

class Activity {
  final String id;
  final String name;
  final int order;
  final bool isActive;
  final String iconUrl;
  final String imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Activity({
    required this.id,
    required this.name,
    required this.order,
    required this.isActive,
    this.iconUrl = '',
    this.imageUrl = '',
    this.createdAt,
    this.updatedAt,
  });

  // -----------------------
  // Firestore deserialization
  // -----------------------
  factory Activity.fromDoc(Doc doc) {
    final data = doc.data()!;
    return Activity(
      id: doc.id,
      name: data['name'] as String,
      order: (data['order'] ?? 0) as int,
      isActive: (data['isActive'] ?? true) as bool,
      iconUrl: (data['iconUrl'] ?? '') as String,
      imageUrl: (data['imageUrl'] ?? '') as String,
      createdAt: FirestoreModel.readDate(data['createdAt']),
      updatedAt: FirestoreModel.readDate(data['updatedAt']),
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
      'iconUrl': iconUrl,
      'imageUrl': imageUrl,
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
