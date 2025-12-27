import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  final String id;

  final String? displayName;
  final String? email;
  final String? phone;
  final String? photoUrl;

  // Premium
  final bool isPremium; // stored field
  final DateTime? premiumUntil; // stored field (recommended)
  final String? activePlanId; // stored field (recommended)
  final String? activeSubscriptionId; // stored field (recommended)

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

    this.isPremium = false,
    this.premiumUntil,
    this.activePlanId,
    this.activeSubscriptionId,

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

  /// Main getter for access gating in ProfileScreen and elsewhere
  bool get hasPremiumAccess {
    final until = premiumUntil;
    return isPremium == true || (until != null && until.isAfter(DateTime.now()));
  }

  // -----------------------
  // Firestore → Model
  // -----------------------
  factory AppUser.fromDoc(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};

    return AppUser(
      id: doc.id,
      displayName: d['displayName'],
      email: d['email'],
      phone: d['phone'],
      photoUrl: d['photoUrl'],

      // Premium fields
      isPremium: (d['isPremium'] ?? false) == true,
      premiumUntil: d['premiumUntil'] != null
          ? (d['premiumUntil'] as Timestamp).toDate()
          : null,
      activePlanId: d['activePlanId'],
      activeSubscriptionId: d['activeSubscriptionId'],

      activities: (d['activities'] as List?)?.cast<String>(),
      favouriteActivity: d['favouriteActivity'],

      hasGym: d['hasGym'],
      gymName: d['gymName'],

      about: d['about'],
      isProfileComplete: d['isProfileComplete'],

      city: d['city'],
      gender: d['gender'],
      dob: d['dob'] != null ? (d['dob'] as Timestamp).toDate() : null,

      isActive: d['isActive'],
      createdAt: d['createdAt'] != null ? (d['createdAt'] as Timestamp).toDate() : null,
      updatedAt: d['updatedAt'] != null ? (d['updatedAt'] as Timestamp).toDate() : null,
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

      'isPremium': isPremium,
      'premiumUntil': premiumUntil != null ? Timestamp.fromDate(premiumUntil!) : null,
      'activePlanId': activePlanId,
      'activeSubscriptionId': activeSubscriptionId,

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

  AppUser copyWith({
    String? displayName,
    String? email,
    String? phone,
    String? photoUrl,
    bool? isPremium,
    DateTime? premiumUntil,
    String? activePlanId,
    String? activeSubscriptionId,
    List<String>? activities,
    String? favouriteActivity,
    bool? hasGym,
    String? gymName,
    String? about,
    bool? isProfileComplete,
    String? city,
    String? gender,
    DateTime? dob,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppUser(
      id: id,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl ?? this.photoUrl,

      isPremium: isPremium ?? this.isPremium,
      premiumUntil: premiumUntil ?? this.premiumUntil,
      activePlanId: activePlanId ?? this.activePlanId,
      activeSubscriptionId: activeSubscriptionId ?? this.activeSubscriptionId,

      activities: activities ?? this.activities,
      favouriteActivity: favouriteActivity ?? this.favouriteActivity,
      hasGym: hasGym ?? this.hasGym,
      gymName: gymName ?? this.gymName,
      about: about ?? this.about,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      city: city ?? this.city,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
