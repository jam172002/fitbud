import 'package:cloud_firestore/cloud_firestore.dart';
import '../common/firestore_model.dart';

class DeviceToken implements FirestoreModel {
  @override
  final String id; // tokenId

  final String platform; // android/ios/web
  final String token;
  final DateTime? createdAt;
  final DateTime? lastSeenAt;

  const DeviceToken({
    required this.id,
    this.platform = '',
    this.token = '',
    this.createdAt,
    this.lastSeenAt,
  });

  static DeviceToken fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return DeviceToken(
      id: doc.id,
      platform: FirestoreModel.readString(d['platform']),
      token: FirestoreModel.readString(d['token']),
      createdAt: FirestoreModel.readDate(d['createdAt']),
      lastSeenAt: FirestoreModel.readDate(d['lastSeenAt']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'platform': platform,
      'token': token,
      'createdAt': FirestoreModel.ts(createdAt),
      'lastSeenAt': FirestoreModel.ts(lastSeenAt),
    };
  }
}
