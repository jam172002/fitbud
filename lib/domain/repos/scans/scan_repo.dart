import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/cupertino.dart';
import '../../../domain/models/gyms/gym_scan.dart';
import '../../../utils/qr_parser.dart';
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

  Future<Map<String, dynamic>> validateAndCreateScan({
    required String qrPayload,
    GeoPoint? scanLocation,
    String deviceId = '',
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('AUTH USER: ${user?.uid}');

    _uid();

    final gymId = extractGymId(qrPayload);
    if (gymId == null || gymId.isEmpty) {
      throw Exception('Invalid QR code — could not read gym ID.');
    }

    final clientScanId =
        '${user!.uid}_${gymId}_${DateTime.now().millisecondsSinceEpoch}';

    final callable = functions.httpsCallable('scanGym');
    final res = await callable.call(<String, dynamic>{
      'gymId': gymId,
      'clientScanId': clientScanId,
      'deviceId': deviceId,
    });
    return Map<String, dynamic>.from(res.data as Map);
  }

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
    _uid();

    final callable = functions.httpsCallable('scanGym');
    final res = await callable.call(<String, dynamic>{
      'gymId': gymId,
      'clientScanId': clientCheckinId,
      'deviceId': deviceId,
    });

    return Map<String, dynamic>.from(res.data as Map);
  }
}
