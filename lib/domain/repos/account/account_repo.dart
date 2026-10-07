import 'package:supabase_flutter/supabase_flutter.dart';

import '../repo_exceptions.dart';

enum AccountDeletionStatus { none, pending, inProgress, completed, failed }

AccountDeletionStatus _statusFrom(String v) {
  switch (v) {
    case 'in_progress':
      return AccountDeletionStatus.inProgress;
    case 'completed':
      return AccountDeletionStatus.completed;
    case 'failed':
      return AccountDeletionStatus.failed;
    case 'pending':
      return AccountDeletionStatus.pending;
    default:
      return AccountDeletionStatus.none;
  }
}

/// Thrown by [AccountRepo.requestDeletion] when the backend requires a more
/// recent sign-in than the current session has (mirrors the client-side
/// check, which the edge function also enforces server-side).
class ReauthRequiredException extends RepoException {
  ReauthRequiredException() : super('reauth_required', 'Please sign in again to confirm this.');
}

class AccountRepo {
  final SupabaseClient db;
  AccountRepo(this.db);

  GoTrueClient get auth => db.auth;

  /// True if the current session is older than [maxAge], i.e. the user
  /// should confirm their identity again before deleting the account. Asks
  /// the database how old the session is (works for email, Google and Apple
  /// sign-ins alike); if it can't tell, it errs on the side of asking.
  Future<bool> needsReauth({Duration maxAge = const Duration(minutes: 15)}) async {
    if (auth.currentUser == null) return true;
    try {
      final age = await db.rpc('session_age_minutes');
      if (age is num) return age > maxAge.inMinutes;
    } catch (_) {}
    return true;
  }

  /// True when the account has an email/password identity, i.e. it can be
  /// reauthenticated with a password (otherwise sign in with Google/Apple
  /// again).
  bool get canReauthWithPassword {
    final u = auth.currentUser;
    if (u == null) return false;
    final providers = (u.appMetadata['providers'] as List?)?.cast<String>() ?? const [];
    return providers.contains('email');
  }

  /// Re-enters the user's password against their current email, which opens
  /// a fresh session and so refreshes the sign-in recency.
  Future<void> reauthenticateWithPassword(String password) async {
    final email = auth.currentUser?.email;
    if (email == null || email.isEmpty) {
      throw PermissionException('No signed-in email/password account to reauthenticate.');
    }
    await auth.signInWithPassword(email: email, password: password);
  }

  /// Calls the trusted backend deletion workflow. Safe to call more than
  /// once - the edge function is idempotent (see supabase/functions/delete-account).
  Future<void> requestDeletion({String requestedVia = 'app'}) async {
    try {
      await db.functions.invoke('delete-account', body: {'requestedVia': requestedVia});
    } on FunctionException catch (e) {
      final details = e.details;
      final msg = details is Map ? '${details['message'] ?? details['error'] ?? ''}' : '$details';
      if (e.status == 412 || msg == 'REAUTH_REQUIRED') throw ReauthRequiredException();
      rethrow;
    }
  }

  Future<AccountDeletionStatus> getDeletionStatus() async {
    final uid = auth.currentUser?.id;
    if (uid == null) return AccountDeletionStatus.none;
    final row = await db.from('account_deletions').select('status').eq('user_id', uid).maybeSingle();
    return _statusFrom((row?['status'] as String?) ?? 'none');
  }
}
