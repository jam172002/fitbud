import '../../../data/doc.dart';
import '../common/firestore_model.dart';

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
  factory AppUser.fromDoc(Doc doc) {
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
          ? FirestoreModel.readDate(d['premiumUntil'])
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
      dob: FirestoreModel.readDate(d['dob']),

      isActive: d['isActive'],
      createdAt: FirestoreModel.readDate(d['createdAt']),
      updatedAt: FirestoreModel.readDate(d['updatedAt']),
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
      'premiumUntil': FirestoreModel.ts(premiumUntil),
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
      'dob': FirestoreModel.ts(dob),

      'isActive': isActive,
      'createdAt': FirestoreModel.ts(createdAt),
      'updatedAt': FirestoreModel.ts(updatedAt),
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
