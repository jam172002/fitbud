import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;
  final bool isActive;
  final DateTime? createdAt;

  const Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.isActive,
    required this.createdAt,
  });

  static Product fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    final createdAtRaw = d['createdAt'];
    return Product(
      id: doc.id,
      title: (d['title'] ?? '').toString(),
      description: (d['description'] ?? '').toString(),
      price: (d['price'] is num) ? (d['price'] as num).toDouble() : double.tryParse('${d['price'] ?? 0}') ?? 0,
      imageUrl: (d['imageUrl'] ?? d['image'] ?? '').toString(),
      isActive: (d['isActive'] ?? true) == true,
      createdAt: createdAtRaw is Timestamp ? createdAtRaw.toDate() : null,
    );
  }
}
