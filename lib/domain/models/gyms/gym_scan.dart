import '../../../data/doc.dart';
import '../common/geo.dart';
import '../common/firestore_model.dart';

enum ScanResult {
  allowed,
  denied,
  already_checked_in,
  subscription_inactive,
  gym_inactive,
}

ScanResult scanResultFrom(String v) {
  return ScanResult.values.firstWhere((e) => e.name == v, orElse: () => ScanResult.denied);
}

class GymScan implements FirestoreModel {
  @override
  final String id;

  final String userId;
  final String gymId;
  final String subscriptionId;

  final DateTime? scannedAt;
  final ScanResult result;

  final String deviceId;
  final GeoPoint? scanLocation;
  final String notes;

  const GymScan({
    required this.id,
    required this.userId,
    required this.gymId,
    this.subscriptionId = '',
    this.scannedAt,
    this.result = ScanResult.allowed,
    this.deviceId = '',
    this.scanLocation,
    this.notes = '',
  });

  static GymScan fromDoc(Doc doc) {
    final d = doc.data() ?? {};
    return GymScan(
      id: doc.id,
      userId: FirestoreModel.readString(d['userId']),
      gymId: FirestoreModel.readString(d['gymId']),
      subscriptionId: FirestoreModel.readString(d['subscriptionId']),
      scannedAt: FirestoreModel.readDate(d['scannedAt']),
      result: scanResultFrom(FirestoreModel.readString(d['result'], fallback: 'denied')),
      deviceId: FirestoreModel.readString(d['deviceId']),
      scanLocation: GeoPointX.fromAny(d['scanLocation']),
      notes: FirestoreModel.readString(d['notes']),
    );
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'gymId': gymId,
      'subscriptionId': subscriptionId,
      'scannedAt': FirestoreModel.ts(scannedAt),
      'result': result.name,
      'deviceId': deviceId,
      'scanLocation': scanLocation?.toJson(),
      'notes': notes,
    };
  }
}
