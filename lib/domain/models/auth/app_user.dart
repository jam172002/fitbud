import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;

  final String? displayName;
  final String? email;
  final String? phone;
  final String? photoUrl;

  final List<String>? activities;
  final String? favouriteActivity;

  final bool? hasGym;
  final String? gymName;

  final String? about;
  final bool? isProfileComplete;

  final String? city;
  final String? gender;
  final DateTime? dob;

  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AppUser({
    required this.id,
    this.displayName,
    this.email,
    this.phone,
    this.photoUrl,
    this.activities,
    this.favouriteActivity,
    this.hasGym,
    this.gymName,
    this.about,
    this.isProfileComplete,
    this.city,
    this.gender,
    this.dob,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  // -----------------------
  // Firestore → Model
  // -----------------------
  factory AppUser.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    return AppUser(
      id: doc.id,
      displayName: d['displayName'],
      email: d['email'],
      phone: d['phone'],
      photoUrl: d['photoUrl'],

      activities: (d['activities'] as List?)?.cast<String>(),
      favouriteActivity: d['favouriteActivity'],

      hasGym: d['hasGym'],
      gymName: d['gymName'],

      about: d['about'],
      isProfileComplete: d['isProfileComplete'],

      city: d['city'],
      gender: d['gender'],
      dob: d['dob'] != null
          ? (d['dob'] as Timestamp).toDate()
          : null,

      isActive: d['isActive'],
      createdAt: d['createdAt'] != null
          ? (d['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: d['updatedAt'] != null
          ? (d['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  // -----------------------
  // Model → Firestore
  // -----------------------
  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'email': email,
      'phone': phone,
      'photoUrl': photoUrl,

      'activities': activities,
      'favouriteActivity': favouriteActivity,

      'hasGym': hasGym,
      'gymName': gymName,

      'about': about,
      'isProfileComplete': isProfileComplete,

      'city': city,
      'gender': gender,
      'dob': dob != null ? Timestamp.fromDate(dob!) : null,

      'isActive': isActive,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }
}
