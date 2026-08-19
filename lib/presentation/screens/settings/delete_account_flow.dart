import 'package:fitbud/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../common/widgets/simple_dialog.dart';
import '../../../common/widgets/two_buttons_dialog.dart';
import '../../../domain/repos/account/account_repo.dart';
import '../../../domain/repos/repo_provider.dart';
import '../authentication/controllers/auth_controller.dart';
import '../authentication/screens/user_login_screen.dart';

/// Entry point for Settings > Delete Account. Handles the full flow end to
/// end: warning, reauthentication if the session isn't recent enough,
/// calling the trusted backend deletion function, and cleaning up
/// afterward - no data is ever deleted from the client directly.
Future<void> showDeleteAccountFlow(BuildContext context) async {
  Get.dialog(
    XButtonsConfirmationDialog(
      message:
          'This permanently deletes your FitBud account: your profile, '
          'buddies, chat messages you sent, sessions, gym check-in history, '
          'and notifications. This cannot be undone.\n\n'
          'Are you sure you want to continue?',
      icon: LucideIcons.triangle_alert,
      iconColor: Colors.redAccent,
      confirmText: 'Delete My Account',
      cancelText: 'Cancel',
      onConfirm: _beginDeletion,
    ),
  );
}

Future<void> _beginDeletion() async {
  final accountRepo = Get.find<Repos>().accountRepo;

  if (accountRepo.needsReauth()) {
    final password = await _promptPassword();
    if (password == null) return; // user cancelled
    try {
      await accountRepo.reauthenticateWithPassword(password);
    } catch (e) {
      _showError('Could not verify your password. ${_friendly(e)}');
      return;
    }
  }

  await _runDeletion();
}

Future<void> _runDeletion() async {
  Get.dialog(
    const _DeletionProgressDialog(),
    barrierDismissible: false,
  );

  final repos = Get.find<Repos>();
  try {
    await repos.accountRepo.requestDeletion(requestedVia: 'app');
    Get.back(); // close progress dialog
    await _handleDeletionSuccess();
  } on ReauthRequiredException {
    Get.back();
    final password = await _promptPassword();
    if (password == null) return;
    try {
      await repos.accountRepo.reauthenticateWithPassword(password);
      await _runDeletion();
    } catch (e) {
      _showError('Could not verify your password. ${_friendly(e)}');
    }
  } catch (e) {
    Get.back(); // close progress dialog
    _showRetryableError(e);
  }
}

Future<void> _handleDeletionSuccess() async {
  // Clear locally cached preferences (notification toggles etc.) - the
  // account itself is already gone server-side.
  try {
    await GetStorage().erase();
  } catch (_) {
    // Non-fatal: local prefs are convenience state, not account data.
  }

  try {
    await Get.find<AuthController>().logout();
  } catch (_) {
    // The Auth user was already deleted server-side; signOut() locally is
    // best-effort cleanup and should not block navigating away.
  }

  // Explicitly reset navigation (in addition to _RootGate's own reactive
  // rebuild on auth-state change) so there's no path back to an
  // authenticated screen, e.g. via the back button.
  Get.offAll(() => const UserLoginScreen());

  Get.dialog(
    SimpleDialogWidget(
      message: 'Your account has been deleted.',
      icon: LucideIcons.circle_check,
      iconColor: XColors.primary,
      buttonText: 'Ok',
      onOk: () => Get.back(),
    ),
  );
}

void _showRetryableError(Object e) {
  Get.dialog(
    XButtonsConfirmationDialog(
      message:
          "We couldn't complete account deletion. ${_friendly(e)}\n\n"
          'You can try again - nothing was left partially deleted.',
      icon: LucideIcons.circle_x,
      iconColor: XColors.danger,
      confirmText: 'Try Again',
      cancelText: 'Cancel',
      onConfirm: _runDeletion,
    ),
  );
}

void _showError(String message) {
  Get.dialog(
    SimpleDialogWidget(
      message: message,
      icon: LucideIcons.circle_x,
      iconColor: XColors.danger,
      buttonText: 'Ok',
      onOk: () => Get.back(),
    ),
  );
}

String _friendly(Object e) {
  final s = e.toString();
  return s.startsWith('Exception: ') ? s.substring(11) : s;
}

/// Simple password re-entry sheet. Email/password is the only credential
/// type this app supports (see AuthController), so that's all this handles.
Future<String?> _promptPassword() {
  final controller = TextEditingController();
  return Get.dialog<String?>(
    Dialog(
      backgroundColor: XColors.secondaryBG,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Confirm your password',
              style: TextStyle(
                color: XColors.primaryText,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'For your security, deleting your account requires signing in again.',
              style: TextStyle(color: XColors.bodyText, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              style: const TextStyle(color: XColors.primaryText),
              decoration: const InputDecoration(
                hintText: 'Password',
                hintStyle: TextStyle(color: XColors.bodyText),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Get.back(result: null),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Get.back(result: controller.text),
                    style: ElevatedButton.styleFrom(backgroundColor: XColors.danger),
                    child: const Text('Confirm'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _DeletionProgressDialog extends StatelessWidget {
  const _DeletionProgressDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: XColors.secondaryBG,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: const Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: XColors.primary),
            SizedBox(height: 16),
            Text(
              'Deleting your account…',
              style: TextStyle(color: XColors.bodyText, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
