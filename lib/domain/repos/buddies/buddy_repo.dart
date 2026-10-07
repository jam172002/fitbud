// lib/domain/repos/buddies/buddy_repo.dart
import '../../models/auth/app_user.dart';
import '../../models/buddies/buddy_request.dart';
import '../../models/buddies/friendship.dart';
import '../repo_base.dart';
import '../repo_exceptions.dart';

class BuddyRepo extends RepoBase {
  BuddyRepo(super.db);

  // -----------------------------
  // Buddy Requests
  // -----------------------------

  Stream<List<BuddyRequest>> watchIncomingRequests() {
    final uid = requireUid();
    return streamDocs('buddy_requests',
            eqColumn: 'to_user_id', eqValue: uid, orderBy: 'created_at')
        .map((l) => l.map(BuddyRequest.fromDoc).toList());
  }

  Stream<List<BuddyRequest>> watchOutgoingRequests() {
    final uid = requireUid();
    return streamDocs('buddy_requests',
            eqColumn: 'from_user_id', eqValue: uid, orderBy: 'created_at')
        .map((l) => l.map(BuddyRequest.fromDoc).toList());
  }

  Future<String> sendBuddyRequest({
    required String toUserId,
    String message = '',
  }) async {
    final uid = requireUid();
    if (toUserId == uid) {
      throw ValidationException('Cannot send request to yourself');
    }

    // Block if already buddies
    final friendship = await db
        .from('friendships')
        .select('id')
        .contains('user_ids', [uid, toUserId])
        .limit(1);
    if (friendship.isNotEmpty) {
      throw ValidationException('You are already buddies');
    }

    // Either side blocked the other?
    final blocked = await db.rpc('is_blocked_either_way', params: {'other': toUserId});
    if (blocked == true) throw PermissionException('Cannot send request');

    // If reverse pending exists, do NOT create duplicate
    final reversePending = await db
        .from('buddy_requests')
        .select('id')
        .eq('from_user_id', toUserId)
        .eq('to_user_id', uid)
        .eq('status', BuddyRequestStatus.pending.name)
        .limit(1);
    if (reversePending.isNotEmpty) {
      throw ValidationException('This user has already sent you a request');
    }

    // Find any prior request from me -> them (pending/rejected/cancelled)
    final existingAny = await db
        .from('buddy_requests')
        .select()
        .eq('from_user_id', uid)
        .eq('to_user_id', toUserId)
        .order('created_at', ascending: false)
        .limit(5);

    if (existingAny.isNotEmpty) {
      final first = existingAny.first;
      final id = first['id'] as String;
      final status = (first['status'] as String?) ?? BuddyRequestStatus.pending.name;

      if (status == BuddyRequestStatus.pending.name) return id;

      // If rejected/cancelled, re-open to pending (so sender can send again)
      if (status == BuddyRequestStatus.rejected.name ||
          status == BuddyRequestStatus.cancelled.name) {
        await db.from('buddy_requests').update({
          'status': BuddyRequestStatus.pending.name,
          'message': message,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'responded_at': null,
        }).eq('id', id);
        return id;
      }

      if (status == BuddyRequestStatus.accepted.name) {
        throw ValidationException('You are already buddies');
      }
      if (status == BuddyRequestStatus.blocked.name) {
        throw PermissionException('Cannot send request');
      }
    }

    final row = await db
        .from('buddy_requests')
        .insert({
          'from_user_id': uid,
          'to_user_id': toUserId,
          'status': BuddyRequestStatus.pending.name,
          'message': message,
        })
        .select('id')
        .single();
    return row['id'] as String;
  }

  Future<void> cancelBuddyRequest(String requestId) async {
    final uid = requireUid();
    await db
        .from('buddy_requests')
        .update({
          'status': BuddyRequestStatus.cancelled.name,
          'responded_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', requestId)
        .eq('from_user_id', uid)
        .eq('status', BuddyRequestStatus.pending.name);
  }

  Future<void> declineBuddyRequest(String requestId) async {
    final uid = requireUid();
    await db
        .from('buddy_requests')
        .update({
          'status': BuddyRequestStatus.rejected.name,
          'responded_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', requestId)
        .eq('to_user_id', uid)
        .eq('status', BuddyRequestStatus.pending.name);
  }

  /// Receiver cleanup: remove a rejected request row from their rejected list.
  Future<void> deleteRejectedIncomingRequest(String requestId) async {
    final uid = requireUid();
    await db
        .from('buddy_requests')
        .delete()
        .eq('id', requestId)
        .eq('to_user_id', uid)
        .eq('status', BuddyRequestStatus.rejected.name);
  }

  /// Accept request: marks it accepted and creates the friendship (atomic,
  /// server-side; also notifies the sender).
  Future<void> acceptBuddyRequest({required String requestId}) async {
    await db.rpc('accept_buddy_request', params: {'request_id': requestId});
  }

  // -----------------------------
  // Friendships
  // -----------------------------

  /// Ends a buddy relationship ("Remove from Buddies" and blocking).
  Future<void> removeFriendship(String otherUserId) async {
    await db.rpc('remove_friendship', params: {'other': otherUserId});
  }

  /// RLS only returns friendships the signed-in user is part of.
  Stream<List<Friendship>> watchMyFriendships({int limit = 200}) {
    return streamDocs('friendships', limit: limit)
        .map((l) => l.map(Friendship.fromDoc).toList());
  }

  List<String> _otherIds(String uid, Friendship f) {
    if (f.userAId == uid) return [f.userBId];
    if (f.userBId == uid) return [f.userAId];
    return f.userIds.where((e) => e != uid).toList();
  }

  Stream<List<AppUser>> watchMyBuddiesUsers({int limit = 200}) {
    final uid = requireUid();
    return watchMyFriendships(limit: limit).asyncMap((items) async {
      final otherIds = <String>{};
      for (final f in items) {
        if (f.isBlocked) continue;
        otherIds.addAll(_otherIds(uid, f));
      }
      final ids = otherIds.toList();
      if (ids.isEmpty) return <AppUser>[];

      final rows = await db.from('profiles').select().inFilter('id', ids);
      final out = docs(rows).map(AppUser.fromDoc).toList();
      out.sort((a, b) => (a.displayName ?? '').compareTo(b.displayName ?? ''));
      return out;
    });
  }

  // -----------------------------
  // Users discovery helpers
  // -----------------------------

  Future<List<AppUser>> loadDiscoverUsers({
    int limit = 30,
    String? activity,
    String? city,
    bool premiumOnly = true,
  }) async {
    final uid = requireUid();

    var q = db.from('profiles').select().eq('is_active', true);
    if (premiumOnly) q = q.eq('is_premium', true);
    if (city != null && city.trim().isNotEmpty) q = q.eq('city', city.trim());
    if (activity != null && activity.trim().isNotEmpty) {
      q = q.contains('activities', [activity.trim()]);
    }

    final rows = await q.limit(limit + 10);
    final users = docs(rows).map(AppUser.fromDoc).toList();
    users.removeWhere((u) => u.id == uid);
    return users.take(limit).toList();
  }

  Future<Map<String, AppUser>> loadUsersMapByIds(List<String> ids) async {
    final map = <String, AppUser>{};
    if (ids.isEmpty) return map;

    for (var i = 0; i < ids.length; i += 100) {
      final chunk = ids.sublist(i, (i + 100).clamp(0, ids.length));
      final rows = await db.from('profiles').select().inFilter('id', chunk);
      for (final d in docs(rows)) {
        final u = AppUser.fromDoc(d);
        map[u.id] = u;
      }
    }
    return map;
  }

  Future<List<AppUser>> loadAnyBuddies({int limit = 10}) async {
    final uid = requireUid();

    final rows = await db.from('friendships').select().limit(limit);
    if (rows.isEmpty) return [];

    final friendships = docs(rows).map(Friendship.fromDoc).toList();
    final otherUserIds = <String>[];
    for (final f in friendships) {
      if (f.isBlocked) continue;
      otherUserIds.addAll(_otherIds(uid, f));
    }
    if (otherUserIds.isEmpty) return [];

    final usersRows = await db
        .from('profiles')
        .select()
        .inFilter('id', otherUserIds.take(10).toList());
    return docs(usersRows).map(AppUser.fromDoc).toList();
  }

  Stream<List<String>> watchBuddyIds({int limit = 200}) {
    final uid = requireUid();
    return watchMyFriendships(limit: limit).map((items) {
      final out = <String>[];
      for (final f in items) {
        if (f.isBlocked) continue;
        out.addAll(_otherIds(uid, f));
      }
      return out.toSet().toList()..sort();
    });
  }
}
