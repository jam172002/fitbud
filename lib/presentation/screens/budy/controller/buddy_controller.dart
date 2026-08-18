// buddy_controller.dart
import 'dart:async';
import 'package:get/get.dart';
import '../../../../domain/models/auth/app_user.dart';
import '../../../../domain/models/buddies/buddy_request.dart';
import '../../../../domain/models/moderation/content_report.dart';
import '../../../../domain/repos/repo_provider.dart';

class BuddyRequestVM {
  final BuddyRequest req;
  final AppUser other;
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

  /// buddies (relationship)
  final RxSet<String> buddyIds = <String>{}.obs;

  /// Users the current user has blocked (their own block list only - see
  /// loadPerfectMatches/loadCategoryMatches for why the reverse direction
  /// isn't filtered out of discovery the same way).
  final RxSet<String> blockedUserIds = <String>{}.obs;

  // Streams we expose to UI
  final RxList<BuddyRequestVM> incoming = <BuddyRequestVM>[].obs;
  final RxList<BuddyRequestVM> outgoing = <BuddyRequestVM>[].obs;

  StreamSubscription? _subIn;
  StreamSubscription? _subOut;
  StreamSubscription? _subBuddies;
  StreamSubscription? _subBlocked;

  @override
  void onInit() {
    super.onInit();

    _subIn = repos.buddyRepo.watchIncomingRequests().listen(_hydrateIncoming);
    _subOut = repos.buddyRepo.watchOutgoingRequests().listen(_hydrateOutgoing);

    // ✅ NEW: keep buddy ids updated
    // Implement this in repo (recommended) as: Stream<List<String>> watchBuddyIds()
    _subBuddies = repos.buddyRepo.watchBuddyIds().listen((ids) {
      buddyIds.assignAll(ids);
    });

    _subBlocked = repos.moderationRepo.watchMyBlockedUserIds().listen((ids) {
      blockedUserIds.assignAll(ids);
    });
  }

  bool isBuddy(String userId) => buddyIds.contains(userId);
  bool isBlockedByMe(String userId) => blockedUserIds.contains(userId);

  // -------------------
  // Moderation
  // -------------------

  /// Ends the buddy relationship. Was previously a UI-only stub in
  /// BuddyProfileScreen - now actually removes the friendship doc.
  Future<void> removeBuddy(String userId) async {
    await repos.buddyRepo.removeFriendship(userId);
  }

  /// Blocks a user and severs any existing buddy relationship /
  /// outstanding request between them, since a block should stop
  /// interaction outright, not just future matching.
  Future<void> blockUser(String userId) async {
    await repos.moderationRepo.blockUser(userId);
    if (isBuddy(userId)) {
      await repos.buddyRepo.removeFriendship(userId);
    }
  }

  Future<void> unblockUser(String userId) async {
    await repos.moderationRepo.unblockUser(userId);
  }

  Future<void> reportUser(
    String userId, {
    required ReportReason reason,
    String details = '',
  }) async {
    await repos.moderationRepo.reportUser(
      targetUserId: userId,
      reason: reason,
      details: details,
    );
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
    } catch (_) {}
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
    // ✅ If already buddy, do nothing
    if (isBuddy(userId)) return;

    if (busyUserIds.contains(userId)) return;
    busyUserIds.add(userId);
    try {
      if (await repos.moderationRepo.isBlockedEitherWay(userId)) {
        throw Exception("You can't send a buddy request to this person.");
      }
      await repos.buddyRepo.sendBuddyRequest(toUserId: userId, message: message);
    } finally {
      busyUserIds.remove(userId);
    }
  }

  // -------------------
  // Discovery (one-shot)
  // -------------------
  Future<List<AppUser>> loadPerfectMatches({int limit = 20}) async {
    final users = await repos.buddyRepo.loadDiscoverUsers(limit: limit + blockedUserIds.length);
    return _excludeBlocked(users).take(limit).toList();
  }

  Future<List<AppUser>> loadCategoryMatches({
    required String activity,
    int limit = 20,
    String? city,
  }) async {
    final users = await repos.buddyRepo.loadDiscoverUsers(
      limit: limit + blockedUserIds.length,
      activity: activity,
      city: city,
    );
    return _excludeBlocked(users).take(limit).toList();
  }

  /// Filters out users the current user has blocked. Note: this only
  /// covers "I blocked them" - excluding "they blocked me" from a list
  /// query would need a denormalized reverse-lookup this schema doesn't
  /// have, so that direction is enforced at the point of interaction
  /// instead (ChatRepo.sendMessage, sendBuddyRequest - see
  /// ModerationRepo.isBlockedEitherWay).
  List<AppUser> _excludeBlocked(List<AppUser> users) {
    if (blockedUserIds.isEmpty) return users;
    return users.where((u) => !blockedUserIds.contains(u.id)).toList();
  }

  @override
  void onClose() {
    _subIn?.cancel();
    _subOut?.cancel();
    _subBuddies?.cancel();
    _subBlocked?.cancel();
    super.onClose();
  }
}