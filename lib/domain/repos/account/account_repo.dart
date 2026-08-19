import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
/// reauth check, which the callable also enforces server-side).
class ReauthRequiredException extends RepoException {
  ReauthRequiredException() : super('reauth_required', 'Please sign in again to confirm this.');
}

class AccountRepo {
  final FirebaseAuth auth;
  final FirebaseFunctions functions;
  AccountRepo(this.auth, this.functions);

  /// True if the current Firebase session is recent enough that Firebase
  /// Auth itself won't demand reauthentication for a sensitive operation.
  /// Used to decide, client-side, whether to prompt for the password before
  /// even attempting deletion (a nicer flow than always calling the backend
  /// first and reacting to a rejection).
  bool needsReauth({Duration maxAge = const Duration(minutes: 15)}) {
    final user = auth.currentUser;
    if (user == null) return true;
    final signedInAt = user.metadata.lastSignInTime;
    if (signedInAt == null) return true;
    return DateTime.now().difference(signedInAt) > maxAge;
  }

  /// Re-enters the user's password against their current email to refresh
  /// the session's sign-in recency. Email/password is the only auth method
  /// this app supports (see AuthController) so that's the only credential
  /// type handled here.
  Future<void> reauthenticateWithPassword(String password) async {
    final user = auth.currentUser;
    final email = user?.email;
    if (user == null || email == null || email.isEmpty) {
      throw PermissionException('No signed-in email/password account to reauthenticate.');
    }
    final cred = EmailAuthProvider.credential(email: email, password: password);
    await user.reauthenticateWithCredential(cred);
  }

  /// Calls the trusted backend deletion workflow. Safe to call more than
  /// once - the Cloud Function is idempotent (see functions/src/accountDeletion.ts).
  Future<void> requestDeletion({String requestedVia = 'app'}) async {
    try {
      final callable = functions.httpsCallable(
        'requestAccountDeletion',
        options: HttpsCallableOptions(timeout: const Duration(minutes: 9)),
      );
      await callable.call({'requestedVia': requestedVia});
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'failed-precondition' && e.message == 'REAUTH_REQUIRED') {
        throw ReauthRequiredException();
      }
      rethrow;
    }
  }

  Future<AccountDeletionStatus> getDeletionStatus() async {
    final callable = functions.httpsCallable('getAccountDeletionStatus');
    final result = await callable.call<Map<String, dynamic>>();
    final status = (result.data['status'] as String?) ?? 'none';
    return _statusFrom(status);
  }
}
