import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/doc.dart';
import '../../../data/supabase_config.dart';
import '../../models/auth/app_user.dart';
import '../../models/auth/user_address.dart';
import '../../models/auth/user_settings.dart';
import '../repo_base.dart';
import '../repo_exceptions.dart';

class AuthRepo extends RepoBase {
  AuthRepo(super.db);

  GoTrueClient get auth => db.auth;

  final Map<String, AppUser> _userCache = {};
  final Map<String, DateTime> _userCacheTime = {};
  static const _userCacheTtl = Duration(minutes: 5);

  /// Emits the signed-in user (or null) - once per identity change, not on
  /// every token refresh.
  Stream<User?> authState() => auth.onAuthStateChange
      .map((s) => s.session?.user)
      .distinct((a, b) => a?.id == b?.id);

  Future<void> signOut() => auth.signOut();

  // ---- Profile (profiles/{uid}) ----

  Stream<AppUser?> watchMe() {
    final uid = requireUid();
    return streamDocs('profiles', eqColumn: 'id', eqValue: uid)
        .map((l) => l.isEmpty ? null : AppUser.fromDoc(l.first));
  }

  Future<AppUser> getUser(String uid) async {
    final cached = _userCache[uid];
    final cachedAt = _userCacheTime[uid];
    if (cached != null && cachedAt != null && DateTime.now().difference(cachedAt) < _userCacheTtl) {
      return cached;
    }
    final row = await db.from('profiles').select().eq('id', uid).maybeSingle();
    if (row == null) throw NotFoundException('User not found');
    final user = AppUser.fromDoc(docOf(row));
    _userCache[uid] = user;
    _userCacheTime[uid] = DateTime.now();
    return user;
  }

  void invalidateUserCache(String uid) {
    _userCache.remove(uid);
    _userCacheTime.remove(uid);
  }

  static const _serverManaged = {
    'isPremium', 'premiumUntil', 'activePlanId', 'activeSubscriptionId', 'createdAt', 'updatedAt',
  };

  Future<void> upsertMe({required AppUser user, bool merge = true}) async {
    final uid = requireUid();
    if (user.id != uid) throw PermissionException('Cannot write another user profile');
    final row = DbRow.toRow(user.toMap(), drop: _serverManaged)..removeWhere((_, v) => v == null);
    await db.from('profiles').upsert({'id': uid, ...row});
  }

  Future<void> updateMeFields(Map<String, dynamic> fields) async {
    final uid = requireUid();
    final row = DbRow.toRow(fields, drop: {'updatedAt', 'fcmTokens'});
    if (row.isEmpty) return;
    await db.from('profiles').update(row).eq('id', uid);
    invalidateUserCache(uid);
  }

  /// Adds an FCM token to my profile (multi-device).
  Future<void> addFcmToken(String token) async {
    final uid = requireUid();
    final row = await db.from('profiles').select('fcm_tokens').eq('id', uid).maybeSingle();
    final tokens = <String>{...((row?['fcm_tokens'] as List?)?.cast<String>() ?? const [])};
    if (tokens.add(token)) {
      await db.from('profiles').update({'fcm_tokens': tokens.toList()}).eq('id', uid);
    }
  }

  // ---- Settings ----

  Stream<UserSettings?> watchMySettings() {
    final uid = requireUid();
    return streamDocs('user_settings', pk: ['user_id'], idKey: 'user_id', eqColumn: 'user_id', eqValue: uid)
        .map((l) => l.isEmpty ? null : UserSettings.fromDoc(l.first));
  }

  Future<void> upsertMySettings(UserSettings settings) async {
    final uid = requireUid();
    await db.from('user_settings').upsert({
      'user_id': uid,
      ...DbRow.toRow(settings.toMap(), drop: {'updatedAt'}),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<AppUser?> getMeOnce() async {
    final uid = requireUid();
    final row = await db.from('profiles').select().eq('id', uid).maybeSingle();
    return row == null ? null : AppUser.fromDoc(docOf(row));
  }

  /// Uploads profile image bytes and returns its public URL.
  Future<String> uploadMyProfileImage(Uint8List bytes) async {
    final uid = requireUid();
    final path = 'users/$uid/profile.jpg';
    final bucket = db.storage.from(SupabaseConfig.profileBucket);
    await bucket.uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
    );
    // cache-bust: the object path never changes
    return '${bucket.getPublicUrl(path)}?v=${DateTime.now().millisecondsSinceEpoch}';
  }

  // ---- Addresses ----

  List<UserAddress> _sortAddresses(List<Doc> l) {
    final out = l.map(UserAddress.fromDoc).toList();
    out.sort((a, b) {
      if (a.isDefault != b.isDefault) return a.isDefault ? -1 : 1;
      final au = a.updatedAt?.millisecondsSinceEpoch ?? 0;
      final bu = b.updatedAt?.millisecondsSinceEpoch ?? 0;
      return bu.compareTo(au);
    });
    return out;
  }

  Stream<List<UserAddress>> watchMyAddresses({int limit = 50}) {
    final uid = requireUid();
    return streamDocs('user_addresses', eqColumn: 'user_id', eqValue: uid, limit: limit)
        .map(_sortAddresses);
  }

  Future<List<UserAddress>> getMyAddressesOnce({int limit = 50}) async {
    final uid = requireUid();
    final rows = await db.from('user_addresses').select().eq('user_id', uid).limit(limit);
    return _sortAddresses(docs(rows));
  }

  Future<String> addAddressEnforceMax2({
    required UserAddress address,
    bool makeDefaultIfFirst = true,
  }) async {
    final id = await db.rpc('add_address_enforce_max2', params: {
      'p_label': address.label ?? '',
      'p_city': address.city ?? '',
      'p_lat': address.lat,
      'p_lng': address.lng,
      'p_is_default': address.isDefault,
      'p_make_default_if_first': makeDefaultIfFirst,
    });
    return '$id';
  }

  Stream<String?> watchSelectedAddressId() => watchMySettings().map((s) => s?.selectedAddressId);

  Future<void> setSelectedAddressId(String addressId) async {
    final uid = requireUid();
    await db.from('user_settings').upsert({
      'user_id': uid,
      'selected_address_id': addressId,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> setDefaultAddress(String addressId) async {
    await db.rpc('set_default_address', params: {'address_id': addressId});
  }
}
