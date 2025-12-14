import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/firestore_model.dart';

class Plan implements FirestoreModel {
  @override
  final String id;

  final String name;
  final double price;
  final String currency;
  final String billingPeriod; // monthly/yearly
  final int maxScansPerDay;
  final int maxScansPerMonth;
  final bool allowAnyAffiliatedGym;
  final DateTime? createdAt;
  final bool isActive;

  const Plan({
    required this.id,
    this.name = '',
    this.price = 0,
    this.currency = 'PKR',
    this.billingPeriod = 'monthly',
    this.maxScansPerDay = 1,
    this.maxScansPerMonth = 30,
    this.allowAnyAffiliatedGym = true,
    this.createdAt,
    this.isActive = true,
  });

  static Plan fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Plan(
      id: doc.id,
      name: FirestoreModel.readString(d['name']),
      price: FirestoreModel.readDouble(d['price']),
      currency: FirestoreModel.readString(d['currency'], fallback: 'PKR'),
      billingPeriod: FirestoreModel.readString(d['billingPeriod'], fallback: 'monthly'),
      maxScansPerDay: FirestoreModel.readInt(d['maxScansPerDay'], fallback: 1),
      maxScansPerMonth: FirestoreModel.readInt(d['maxScansPerMonth'], fallback: 30),
      allowAnyAffiliatedGym: FirestoreModel.readBool(d['allowAnyAffiliatedGym'], fallback: true),
      createdAt: FirestoreModel.readDate(d['createdAt']),
      isActive: FirestoreModel.readBool(d['isActive'], fallback: true),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'currency': currency,
      'billingPeriod': billingPeriod,
      'maxScansPerDay': maxScansPerDay,
      'maxScansPerMonth': maxScansPerMonth,
      'allowAnyAffiliatedGym': allowAnyAffiliatedGym,
      'createdAt': FirestoreModel.ts(createdAt),
      'isActive': isActive,
    };
  }
}
