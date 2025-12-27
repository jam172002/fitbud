import 'dart:async';

import 'package:get/get.dart';
import '../../../../domain/models/auth/app_user.dart';
import '../../../../domain/models/buddies/buddy_request.dart';
import '../../../../domain/repos/repo_provider.dart';

class BuddyRequestVM {
  final BuddyRequest req;
  final AppUser other; // sender or receiver user object
  final bool isIncoming;

  BuddyRequestVM({
    required this.req,
    required this.other,
    required this.isIncoming,
  });
}

class BuddyController extends GetxController {
  BuddyController(this.repos);

  final Repos repos;

  final RxBool isBusy = false.obs;

  /// for button-level loading
  final RxSet<String> busyRequestIds = <String>{}.obs;
  final RxSet<String> busyUserIds = <String>{}.obs;

  // Streams we expose to UI
  final RxList<BuddyRequestVM> incoming = <BuddyRequestVM>[].obs;
  final RxList<BuddyRequestVM> outgoing = <BuddyRequestVM>[].obs;

  StreamSubscription? _subIn;
  StreamSubscription? _subOut;

  @override
  void onInit() {
    super.onInit();
    _subIn = repos.buddyRepo.watchIncomingRequests().listen(_hydrateIncoming);
    _subOut = repos.buddyRepo.watchOutgoingRequests().listen(_hydrateOutgoing);
  }

  Future<void> _hydrateIncoming(List<BuddyRequest> list) async {
    try {
      final ids = list.map((e) => e.fromUserId).toSet().toList();
      final map = await repos.buddyRepo.loadUsersMapByIds(ids);

      final out = <BuddyRequestVM>[];
      for (final r in list) {
        final u = map[r.fromUserId];
        if (u == null) continue;
        out.add(BuddyRequestVM(req: r, other: u, isIncoming: true));
      }
      incoming.value = out;
    } catch (_) {
      // don't crash UI
    }
  }

  Future<void> _hydrateOutgoing(List<BuddyRequest> list) async {
    try {
      final ids = list.map((e) => e.toUserId).toSet().toList();
      final map = await repos.buddyRepo.loadUsersMapByIds(ids);

      final out = <BuddyRequestVM>[];
      for (final r in list) {
        final u = map[r.toUserId];
        if (u == null) continue;
        out.add(BuddyRequestVM(req: r, other: u, isIncoming: false));
      }
      outgoing.value = out;
    } catch (_) {}
  }

  // -------------------
  // Actions
  // -------------------

  Future<void> acceptRequest(String requestId) async {
    if (busyRequestIds.contains(requestId)) return;
    busyRequestIds.add(requestId);

    try {
      await repos.buddyRepo.acceptBuddyRequest(requestId: requestId);
    } finally {
      busyRequestIds.remove(requestId);
    }
  }

  Future<void> rejectRequest(String requestId) async {
    if (busyRequestIds.contains(requestId)) return;
    busyRequestIds.add(requestId);

    try {
      await repos.buddyRepo.declineBuddyRequest(requestId);
    } finally {
      busyRequestIds.remove(requestId);
    }
  }

  Future<void> cancelRequest(String requestId) async {
    if (busyRequestIds.contains(requestId)) return;
    busyRequestIds.add(requestId);

    try {
      await repos.buddyRepo.cancelBuddyRequest(requestId);
    } finally {
      busyRequestIds.remove(requestId);
    }
  }

  Future<void> inviteUser(String userId, {String message = ''}) async {
    if (busyUserIds.contains(userId)) return;
    busyUserIds.add(userId);

    try {
      await repos.buddyRepo.sendBuddyRequest(toUserId: userId, message: message);
    } finally {
      busyUserIds.remove(userId);
    }
  }

  // -------------------
  // Discovery (one-shot)
  // -------------------

  Future<List<AppUser>> loadPerfectMatches({int limit = 20}) async {
    // You can replace this logic later with real matching algorithm.
    // For now it loads active users excluding me, limited.
    return repos.buddyRepo.loadDiscoverUsers(limit: limit);
  }

  Future<List<AppUser>> loadCategoryMatches({
    required String activity,
    int limit = 20,
    String? city,
  }) async {
    return repos.buddyRepo.loadDiscoverUsers(
      limit: limit,
      activity: activity,
      city: city,
    );
  }

  @override
  void onClose() {
    _subIn?.cancel();
    _subOut?.cancel();
    super.onClose();
  }
}
