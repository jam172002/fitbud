import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../domain/models/gyms/gym_scan.dart';
import '../firestore_paths.dart';
import '../firestore_repo_base.dart';
import '../repo_exceptions.dart';

class ScanRepo extends RepoBase {
  final FirebaseAuth auth;
  final FirebaseFunctions functions;

  ScanRepo(super.db, this.auth, this.functions);

  String _uid() {
    final u = auth.currentUser;
    if (u == null) throw PermissionException('User is not signed in');
    return u.uid;
  }

  Stream<List<GymScan>> watchMyScanHistory({int limit = 100}) {
    final uid = _uid();
    return col(FirestorePaths.scans)
        .where('userId', isEqualTo: uid)
        .orderBy('scannedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((q) => q.docs.map(GymScan.fromDoc).toList());
  }


  /// SECURE FLOW (Recommended):
  /// Calls Cloud Function validateGymScan which:
  /// - validates subscription + plan limits
  /// - checks gym active
  /// - checks cooldown / anti-fraud
  /// - writes GymScan doc server-side
  ///
  /// Expected callable response:
  /// { scanId: string, result: string, message: string }
  Future<Map<String, dynamic>> validateAndCreateScan({
    required String qrPayload,      // scanned string (contains gym public id + token/version etc.)
    GeoPoint? scanLocation,
    String deviceId = '',
  }) async {
    final uid = _uid();
    final callable = functions.httpsCallable('validateGymScan');
    final res = await callable.call(<String, dynamic>{
      'userId': uid,
      'qrPayload': qrPayload,
      'scanLocation': scanLocation == null ? null : {
        'lat': scanLocation.latitude,
        'lng': scanLocation.longitude,
      },
      'deviceId': deviceId,
    });
    return Map<String, dynamic>.from(res.data as Map);
  }

  /// TESTING-ONLY: client writes a scan directly.
  /// Only use if your rules allow it.
  Future<String> createScanClientWrite({
    required String gymId,
    required ScanResult result,
    String subscriptionId = '',
    GeoPoint? scanLocation,
    String deviceId = '',
    String notes = '',
  }) async {
    final uid = _uid();
    final ref = col(FirestorePaths.scans).doc();
    await ref.set({
      'userId': uid,
      'gymId': gymId,
      'subscriptionId': subscriptionId,
      'scannedAt': FieldValue.serverTimestamp(),
      'result': result.name,
      'deviceId': deviceId,
      'scanLocation': scanLocation,
      'notes': notes,
    });
    return ref.id;
  }

  Future<Map<String, dynamic>> checkInToGym({
    required String gymId,
    required String clientCheckinId,
    String deviceId = '',
  }) async {
    _uid(); // ensures signed in

    final callable = functions.httpsCallable('checkInToGym');
    final res = await callable.call(<String, dynamic>{
      'gymId': gymId,
      'clientCheckinId': clientCheckinId,
      'deviceId': deviceId,
    });

    return Map<String, dynamic>.from(res.data as Map);
  }

}
