import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/firestore_model.dart';

enum GymStatus { active, inactive, suspended }

GymStatus gymStatusFrom(String v) {
  return GymStatus.values.firstWhere((e) => e.name == v, orElse: () => GymStatus.active);
}

class Gym implements FirestoreModel {
  @override
  final String id;

  final String name;
  final String address;
  final GeoPoint? location;
  final String city;
  final String phone;
  final String logoUrl;

  final GymStatus status;

  /// public part embedded in QR (safe)
  final String qrPublicId;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Gym({
    required this.id,
    this.name = '',
    this.address = '',
    this.location,
    this.city = '',
    this.phone = '',
    this.logoUrl = '',
    this.status = GymStatus.active,
    this.qrPublicId = '',
    this.createdAt,
    this.updatedAt,
  });

  static Gym fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Gym(
      id: doc.id,
      name: FirestoreModel.readString(d['name']),
      address: FirestoreModel.readString(d['address']),
      location: d['location'] is GeoPoint ? d['location'] as GeoPoint : null,
      city: FirestoreModel.readString(d['city']),
      phone: FirestoreModel.readString(d['phone']),
      logoUrl: FirestoreModel.readString(d['logoUrl']),
      status: gymStatusFrom(FirestoreModel.readString(d['status'], fallback: 'active')),
      qrPublicId: FirestoreModel.readString(d['qrPublicId']),
      createdAt: FirestoreModel.readDate(d['createdAt']),
      updatedAt: FirestoreModel.readDate(d['updatedAt']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'location': location,
      'city': city,
      'phone': phone,
      'logoUrl': logoUrl,
      'status': status.name,
      'qrPublicId': qrPublicId,
      'createdAt': FirestoreModel.ts(createdAt),
      'updatedAt': FirestoreModel.ts(updatedAt),
    };
  }
}
