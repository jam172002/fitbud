import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/firestore_model.dart';

enum GymStatus { active, inactive, suspended }

GymStatus gymStatusFrom(String v) {
  return GymStatus.values.firstWhere(
        (e) => e.name == v,
    orElse: () => GymStatus.active,
  );
}

class Gym implements FirestoreModel {
  @override
  final String id;

  final String name;
  final String address;
  final GeoPoint? location; // optional (admin not using yet)
  final String city;
  final String phone;
  final String logoUrl;

  final GymStatus status;
  final String qrPublicId;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final int yearsOfService;
  final int members;
  final double rating;
  final String dayHours;
  final String nightHours;
  final List<String> equipments;
  final List<String> images;
  final int monthlyScans;
  final int totalScans;

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
    this.yearsOfService = 0,
    this.members = 0,
    this.rating = 0.0,
    this.dayHours = '',
    this.nightHours = '',
    this.equipments = const [],
    this.images = const [],
    this.monthlyScans = 0,
    this.totalScans = 0,
  });

  static Gym fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};

    // Backward compat (just in case)
    final logoUrl = FirestoreModel.readString(d['logoUrl']);
    final legacyLogo = FirestoreModel.readString(d['logo']);

    final images = (d['images'] is List)
        ? List<String>.from(d['images'])
        : (d['gallery'] is List ? List<String>.from(d['gallery']) : <String>[]);

    final equipments = (d['equipments'] is List)
        ? List<String>.from(d['equipments'])
        : (d['equipments'] is List ? List<String>.from(d['equipments']) : <String>[]);

    return Gym(
      id: doc.id,
      name: FirestoreModel.readString(d['name']),
      address: FirestoreModel.readString(d['address']),
      location: d['location'] is GeoPoint ? d['location'] as GeoPoint : null,
      city: FirestoreModel.readString(d['city']),
      phone: FirestoreModel.readString(d['phone']),
      logoUrl: logoUrl.isNotEmpty ? logoUrl : legacyLogo,

      status: gymStatusFrom(
        FirestoreModel.readString(d['status'], fallback: 'active'),
      ),
      qrPublicId: FirestoreModel.readString(d['qrPublicId']),
      createdAt: FirestoreModel.readDate(d['createdAt']),
      updatedAt: FirestoreModel.readDate(d['updatedAt']),

      yearsOfService: FirestoreModel.readInt(d['yearsOfService']),
      members: FirestoreModel.readInt(d['members']),
      rating: FirestoreModel.readDouble(d['rating']),
      dayHours: FirestoreModel.readString(d['dayHours']),
      nightHours: FirestoreModel.readString(d['nightHours']),
      equipments: equipments,
      images: images,
      monthlyScans: FirestoreModel.readInt(d['monthlyScans']),
      totalScans: FirestoreModel.readInt(d['totalScans']),
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
      'yearsOfService': yearsOfService,
      'members': members,
      'rating': rating,
      'dayHours': dayHours,
      'nightHours': nightHours,
      'equipments': equipments,
      'images': images,
      'monthlyScans': monthlyScans,
      'totalScans': totalScans,
    };
  }
}
