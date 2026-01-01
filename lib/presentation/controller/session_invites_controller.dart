import 'package:get/get.dart';
import '../../../../domain/models/sessions/session_invite.dart';
import '../../../../domain/repos/repo_provider.dart';

class SessionInvitesController extends GetxController {
  final Repos repos = Get.find<Repos>();

  /// inviteId values that are being processed to disable UI taps
  final RxSet<String> busyInviteIds = <String>{}.obs;

  Stream<List<SessionInvite>> watchInvitesByUiFilter(String uiFilter, {int limit = 50}) {
    // UI: Pending / Accepted / Rejected
    // Model: pending / accepted / declined
    final status = switch (uiFilter) {
      'Accepted' => InviteStatus.accepted,
      'Rejected' => InviteStatus.declined,
      _ => InviteStatus.pending,
    };

    return repos.sessionRepo.watchMySessionInvitesByStatus(status: status, limit: limit);
  }

  Future<void> accept(SessionInvite inv) async {
    if (busyInviteIds.contains(inv.id)) return;
    busyInviteIds.add(inv.id);
    try {
      await repos.sessionRepo.acceptSessionInvite(sessionId: inv.sessionId, inviteId: inv.id);
    } finally {
      busyInviteIds.remove(inv.id);
    }
  }

  Future<void> decline(SessionInvite inv) async {
    if (busyInviteIds.contains(inv.id)) return;
    busyInviteIds.add(inv.id);
    try {
      await repos.sessionRepo.declineSessionInvite(sessionId: inv.sessionId, inviteId: inv.id);
    } finally {
      busyInviteIds.remove(inv.id);
    }
  }
}
