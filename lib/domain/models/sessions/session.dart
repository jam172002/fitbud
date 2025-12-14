import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/firestore_model.dart';

enum SessionType { gym, game, other }
enum SessionStatus { draft, scheduled, active, completed, cancelled }

SessionType sessionTypeFrom(String v) {
  return SessionType.values.firstWhere((e) => e.name == v, orElse: () => SessionType.gym);
}

SessionStatus sessionStatusFrom(String v) {
  return SessionStatus.values.firstWhere((e) => e.name == v, orElse: () => SessionStatus.scheduled);
}

class Session implements FirestoreModel {
  @override
  final String id;

  final SessionType type;
  final String title;
  final String description;

  final String createdByUserId;

  final DateTime? startAt;
  final DateTime? endAt;

  final GeoPoint? location;
  final String locationName;

  final String gymId; // optional
  final SessionStatus status;

  final bool isGroupSession;
  final String groupId; // optional

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Session({
    required this.id,
    this.type = SessionType.gym,
    this.title = '',
    this.description = '',
    this.createdByUserId = '',
    this.startAt,
    this.endAt,
    this.location,
    this.locationName = '',
    this.gymId = '',
    this.status = SessionStatus.scheduled,
    this.isGroupSession = false,
    this.groupId = '',
    this.createdAt,
    this.updatedAt,
  });

  static Session fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return Session(
      id: doc.id,
      type: sessionTypeFrom(FirestoreModel.readString(d['type'], fallback: 'gym')),
      title: FirestoreModel.readString(d['title']),
      description: FirestoreModel.readString(d['description']),
      createdByUserId: FirestoreModel.readString(d['createdByUserId']),
      startAt: FirestoreModel.readDate(d['startAt']),
      endAt: FirestoreModel.readDate(d['endAt']),
      location: d['location'] is GeoPoint ? d['location'] as GeoPoint : null,
      locationName: FirestoreModel.readString(d['locationName']),
      gymId: FirestoreModel.readString(d['gymId']),
      status: sessionStatusFrom(FirestoreModel.readString(d['status'], fallback: 'scheduled')),
      isGroupSession: FirestoreModel.readBool(d['isGroupSession']),
      groupId: FirestoreModel.readString(d['groupId']),
      createdAt: FirestoreModel.readDate(d['createdAt']),
      updatedAt: FirestoreModel.readDate(d['updatedAt']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'type': type.name,
      'title': title,
      'description': description,
      'createdByUserId': createdByUserId,
      'startAt': FirestoreModel.ts(startAt),
      'endAt': FirestoreModel.ts(endAt),
      'location': location,
      'locationName': locationName,
      'gymId': gymId,
      'status': status.name,
      'isGroupSession': isGroupSession,
      'groupId': groupId,
      'createdAt': FirestoreModel.ts(createdAt),
      'updatedAt': FirestoreModel.ts(updatedAt),
    };
  }
}
