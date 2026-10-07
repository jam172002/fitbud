import '../../../domain/models/common/geo.dart';
import '../../../domain/models/gyms/gym_scan.dart';
import '../../../data/doc.dart';
import '../../../utils/qr_parser.dart';
import '../repo_base.dart';

class ScanRepo extends RepoBase {
  ScanRepo(super.db);

  /// Maps a scans row to the [GymScan] model (`status: accepted` => allowed).
  static GymScan scanFromRow(Map<String, dynamic> row) {
    final doc = Doc.fromRow(row);
    final d = Map<String, dynamic>.from(doc.data())
      ..['result'] = row['status'] == 'accepted' ? 'allowed' : 'denied';
    return GymScan.fromDoc(Doc(doc.id, d));
  }

  Stream<List<GymScan>> watchMyScanHistory({int limit = 100}) {
    final uid = requireUid();
    return db
        .from('scans')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('scanned_at', ascending: false)
        .limit(limit)
        .map((rows) => rows.map(scanFromRow).toList());
  }

  /// Raw camelCase scan maps (`scannedAt` as DateTime) for the history
  /// screens; optionally limited to one gym.
  Stream<List<Map<String, dynamic>>> watchScanMaps({String? gymId, int limit = 500}) {
    final uid = requireUid();
    return db
        .from('scans')
        .stream(primaryKey: ['id'])
        .eq('user_id', uid)
        .order('scanned_at', ascending: false)
        .limit(limit)
        .map((rows) => rows
            .where((r) => gymId == null || r['gym_id'] == gymId)
            .map((r) {
              final m = DbRow.toCamel(r);
              m['scannedAt'] = DateTime.tryParse('${r['scanned_at']}')?.toLocal();
              return m;
            })
            .toList());
  }

  Future<Map<String, dynamic>> _scanGym({
    required String gymId,
    required String clientScanId,
    required String deviceId,
  }) async {
    final res = await db.rpc('scan_gym', params: {
      'p_gym_id': gymId,
      'p_client_scan_id': clientScanId,
      'p_device_id': deviceId,
    });
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> validateAndCreateScan({
    required String qrPayload,
    GeoPoint? scanLocation,
    String deviceId = '',
  }) async {
    final uid = requireUid();

    final gymId = extractGymId(qrPayload);
    if (gymId == null || gymId.isEmpty) {
      throw Exception('Invalid QR code — could not read gym ID.');
    }

    final clientScanId = '${uid}_${gymId}_${DateTime.now().millisecondsSinceEpoch}';
    return _scanGym(gymId: gymId, clientScanId: clientScanId, deviceId: deviceId);
  }

  Future<Map<String, dynamic>> checkInToGym({
    required String gymId,
    required String clientCheckinId,
    String deviceId = '',
  }) async {
    requireUid();
    return _scanGym(gymId: gymId, clientScanId: clientCheckinId, deviceId: deviceId);
  }
}
