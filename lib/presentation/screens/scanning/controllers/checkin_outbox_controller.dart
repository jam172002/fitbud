import 'dart:async';
import 'package:get/get.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../../data/local/checkin_outbox_item.dart';
import '../../../../domain/repos/repo_provider.dart';
import '../../../../domain/repos/scans/scan_repo.dart';
import '../../../../utils/device_id.dart';

class CheckinOutboxController extends GetxController {
  static const boxName = 'checkin_outbox';

  late final ScanRepo repo;
  late Box<CheckinOutboxItem> _box;

  Timer? _timer;
  final RxBool syncing = false.obs;

  // ✅ ADDED: Observable mirror of Hive for UI
  final RxMap<String, CheckinOutboxItem> itemsById =
      <String, CheckinOutboxItem>{}.obs;

  // ✅ ADDED: Optional helper list (latest first) for UI screens
  List<CheckinOutboxItem> get itemsSorted {
    final list = itemsById.values.toList();
    list.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
    return list;
  }

  // ✅ ADDED: Keep memory cache in sync with Hive
  void _rebuildCache() {
    final map = <String, CheckinOutboxItem>{};
    for (final e in _box.values) {
      map[e.clientCheckinId] = e;
    }
    itemsById.assignAll(map);
  }

  @override
  Future<void> onInit() async {
    super.onInit();

    // ✅ Repo is guaranteed because Repos is registered in main() before this controller
    repo = Get.find<Repos>().scanRepo;

    _box = await Hive.openBox<CheckinOutboxItem>(boxName);

    // ✅ ADDED: Build initial cache
    _rebuildCache();

    // ✅ ADDED: Watch changes and update cache
    _box.watch().listen((_) {
      _rebuildCache();
    });

    // Flush once on start (do not await to avoid blocking init, but safe)
    scheduleMicrotask(() => flush());

    // Periodic flush
    _timer = Timer.periodic(const Duration(seconds: 20), (_) {
      flush();
    });
  }

  @override
  void onClose() {
    _timer?.cancel();
    super.onClose();
  }

  String newClientCheckinId() => const Uuid().v4();

  // ✅ KEEP: Your existing method remains untouched (API stays same)
  Future<void> enqueueAndSend({required String gymId}) async {
    final clientId = newClientCheckinId();
    final item = CheckinOutboxItem(
      clientCheckinId: clientId,
      gymId: gymId,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
      status: 'pending',
    );
    await _box.put(clientId, item);

    // ✅ ADDED: Keep cache updated immediately (even before watch event)
    itemsById[clientId] = item;

    // Immediate send attempt (best UX)
    await _send(item);

    // ✅ ADDED: Refresh cache after send
    _rebuildCache();
  }

  // ✅ ADDED: New method that returns id (without changing existing code usage)
  Future<String> enqueueAndSendWithId({required String gymId}) async {
    final clientId = newClientCheckinId();
    final item = CheckinOutboxItem(
      clientCheckinId: clientId,
      gymId: gymId,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
      status: 'pending',
    );
    await _box.put(clientId, item);

    // update cache immediately
    itemsById[clientId] = item;

    await _send(item);
    _rebuildCache();
    return clientId;
  }

  // ✅ ADDED: Get latest item for a gym (handy fallback)
  CheckinOutboxItem? latestForGym(String gymId) {
    final list = _box.values.where((e) => e.gymId == gymId).toList();
    if (list.isEmpty) return null;
    list.sort((a, b) => b.createdAtMs.compareTo(a.createdAtMs));
    return list.first;
  }

  Future<void> flush() async {
    if (syncing.value) return;
    syncing.value = true;

    try {
      final items = _box.values
          .where((e) => e.status == 'pending' || e.status == 'failed')
          .toList();

      for (final item in items) {
        if (item.attempts >= 10) continue; // basic backoff cap
        await _send(item);
      }

      // ✅ ADDED: Refresh cache after flush
      _rebuildCache();
    } finally {
      syncing.value = false;
    }
  }

  Future<void> _send(CheckinOutboxItem item) async {
    if (item.status == 'confirmed') return;

    item.status = 'sending';
    item.attempts += 1;
    await item.save();

    // ✅ ADDED: Refresh cache for UI immediately
    itemsById[item.clientCheckinId] = item;

    final deviceId = await DeviceId.get();

    try {
      final res = await repo.checkInToGym(
        gymId: item.gymId,
        clientCheckinId: item.clientCheckinId,
        deviceId: deviceId,
      );

      final ok = res['ok'] == true;
      if (ok) {
        item.status = 'confirmed';
        item.lastError = '';
      } else {
        item.status = 'failed';
        item.lastError =
            (res['message'] ?? res['result'] ?? 'Failed').toString();
      }
      await item.save();

      // ✅ ADDED: Refresh cache after result
      itemsById[item.clientCheckinId] = item;
    } catch (e) {
      // network/timeout -> keep failed and retry later
      item.status = 'failed';
      item.lastError = e.toString();
      await item.save();

      // ✅ ADDED: Refresh cache after error
      itemsById[item.clientCheckinId] = item;
    }
  }
}
