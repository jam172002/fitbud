import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/firestore_model.dart';

class SessionParticipant implements FirestoreModel {
  @override
  final String id; // uid

  final String sessionId;
  final String userId;
  final bool attended;
  final DateTime? joinedAt;

  const SessionParticipant({
    required this.id,
    required this.sessionId,
    required this.userId,
    this.attended = false,
    this.joinedAt,
  });

  static SessionParticipant fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc, {
        required String sessionId,
      }) {
    final d = doc.data() ?? {};
    return SessionParticipant(
      id: doc.id,
      sessionId: sessionId,
      userId: FirestoreModel.readString(d['userId']),
      attended: FirestoreModel.readBool(d['attended']),
      joinedAt: FirestoreModel.readDate(d['joinedAt']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'attended': attended,
      'joinedAt': FirestoreModel.ts(joinedAt),
    };
  }
}
