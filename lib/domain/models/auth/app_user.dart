import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/firestore_model.dart';
import '../common/geo.dart';

class AppUser implements FirestoreModel {
  @override
  final String id; // uid

  final String email;
  final String phone;
  final String displayName;
  final String photoUrl;
  final String bio;
  final DateTime? dob;
  final String gender;
  final String city;
  final GeoPoint? lastKnownLocation;

  final List<String> interests;
  final List<String> goals;

  final int buddyCount;
  final int groupCount;

  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  const AppUser({
    required this.id,
    this.email = '',
    this.phone = '',
    this.displayName = '',
    this.photoUrl = '',
    this.bio = '',
    this.dob,
    this.gender = '',
    this.city = '',
    this.lastKnownLocation,
    this.interests = const [],
    this.goals = const [],
    this.buddyCount = 0,
    this.groupCount = 0,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  AppUser copyWith({
    String? email,
    String? phone,
    String? displayName,
    String? photoUrl,
    String? bio,
    DateTime? dob,
    String? gender,
    String? city,
    GeoPoint? lastKnownLocation,
    List<String>? interests,
    List<String>? goals,
    int? buddyCount,
    int? groupCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return AppUser(
      id: id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      bio: bio ?? this.bio,
      dob: dob ?? this.dob,
      gender: gender ?? this.gender,
      city: city ?? this.city,
      lastKnownLocation: lastKnownLocation ?? this.lastKnownLocation,
      interests: interests ?? this.interests,
      goals: goals ?? this.goals,
      buddyCount: buddyCount ?? this.buddyCount,
      groupCount: groupCount ?? this.groupCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  static AppUser fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return AppUser(
      id: doc.id,
      email: FirestoreModel.readString(d['email']),
      phone: FirestoreModel.readString(d['phone']),
      displayName: FirestoreModel.readString(d['displayName']),
      photoUrl: FirestoreModel.readString(d['photoUrl']),
      bio: FirestoreModel.readString(d['bio']),
      dob: FirestoreModel.readDate(d['dob']),
      gender: FirestoreModel.readString(d['gender']),
      city: FirestoreModel.readString(d['city']),
      lastKnownLocation: GeoPointX.fromAny(d['lastKnownLocation']),
      interests: FirestoreModel.readStringList(d['interests']),
      goals: FirestoreModel.readStringList(d['goals']),
      buddyCount: FirestoreModel.readInt(d['buddyCount']),
      groupCount: FirestoreModel.readInt(d['groupCount']),
      createdAt: FirestoreModel.readDate(d['createdAt']),
      updatedAt: FirestoreModel.readDate(d['updatedAt']),
      isActive: FirestoreModel.readBool(d['isActive'], fallback: true),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'phone': phone,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'bio': bio,
      'dob': FirestoreModel.ts(dob),
      'gender': gender,
      'city': city,
      'lastKnownLocation': lastKnownLocation,
      'interests': interests,
      'goals': goals,
      'buddyCount': buddyCount,
      'groupCount': groupCount,
      'createdAt': FirestoreModel.ts(createdAt),
      'updatedAt': FirestoreModel.ts(updatedAt),
      'isActive': isActive,
    };
  }
}
