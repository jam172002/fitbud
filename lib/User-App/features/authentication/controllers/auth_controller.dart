import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

import '../../../../domain/models/auth/app_user.dart';
import '../../../../domain/repos/repo_provider.dart';
import '../controllers/auth_result.dart';

class AuthController extends GetxController {
  AuthController(this._repos);

  final Repos _repos;

  // reactive state
  final RxBool isLoading = false.obs;
  final Rxn<User> authUser = Rxn<User>();
  final Rxn<AppUser> me = Rxn<AppUser>();

  StreamSubscription<User?>? _authSub;
  StreamSubscription<AppUser?>? _meSub;

  @override
  void onInit() {
    super.onInit();

    // Observe FirebaseAuth state
    _authSub = _repos.authRepo.authState().listen((u) {
      authUser.value = u;

      // Stop previous profile stream
      _meSub?.cancel();
      _meSub = null;
      me.value = null;

      // If logged-in: start watching user profile doc
      if (u != null) {
        _meSub = _repos.authRepo.watchMe().listen((profile) {
          me.value = profile;
        });
      }
    });
  }

  @override
  void onClose() {
    _authSub?.cancel();
    _meSub?.cancel();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // SIGN UP (Email/Password)
  // Creates Auth user + creates Firestore AppUser document.
  // ---------------------------------------------------------------------------
  Future<AuthResult> signUpWithEmail({
    required String name,
    required String email,
    required String phone,
    required String password,
    required DateTime dob,
    required String gender,
    required String location, // store as city for now
  }) async {
    try {
      isLoading.value = true;

      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = cred.user?.uid;
      if (uid == null) {
        return AuthResult.fail('Signup failed. Please try again.', code: 'no_uid');
      }

      // Optional: update displayName in Auth
      await cred.user!.updateDisplayName(name.trim());

      // Create user profile doc in Firestore
      final user = AppUser(
        id: uid,
        email: email.trim(),
        phone: phone.trim(),
        displayName: name.trim(),
        gender: gender,
        city: location,
        dob: dob,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
      );

      await _repos.authRepo.upsertMe(user: user, merge: true);

      return AuthResult.success('Signup successful');
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(_mapAuthError(e), code: e.code);
    } catch (e) {
      return AuthResult.fail('Unexpected error: $e', code: 'unexpected');
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // LOGIN (Email/Password)
  // Your UI accepts email OR phone. For now:
  // - If email -> login with email/password
  // - If phone -> return a controlled message (OTP phone login can be added later)
  // ---------------------------------------------------------------------------
  Future<AuthResult> login({
    required String emailOrPhone,
    required String password,
  }) async {
    try {
      isLoading.value = true;

      final input = emailOrPhone.trim();

      final isEmail = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(input);
      final isPhone = RegExp(r'^\+?\d{10,15}$').hasMatch(input);

      if (!isEmail && isPhone) {
        // Your UI shows phone option, but Firebase phone auth requires OTP flow.
        return AuthResult.fail(
          'Phone login is not enabled yet. Please login with email.',
          code: 'phone_not_supported',
        );
      }

      if (!isEmail) {
        return AuthResult.fail('Please enter a valid email.', code: 'invalid_email');
      }

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: input,
        password: password,
      );

      return AuthResult.success('Login successful');
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(_mapAuthError(e), code: e.code);
    } catch (e) {
      return AuthResult.fail('Unexpected error: $e', code: 'unexpected');
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // FORGOT PASSWORD (Firebase email reset)
  // Your EnterEmailScreen currently navigates to VerifyCodeScreen (mock).
  // In production, Firebase reset email is enough (no OTP screen needed).
  // ---------------------------------------------------------------------------
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      isLoading.value = true;

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email.trim());

      return AuthResult.success('Password reset email sent');
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(_mapAuthError(e), code: e.code);
    } catch (e) {
      return AuthResult.fail('Unexpected error: $e', code: 'unexpected');
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // LOGOUT
  // ---------------------------------------------------------------------------
  Future<void> logout() async {
    await _repos.authRepo.signOut();
  }

  // ---------------------------------------------------------------------------
  // UPDATE PROFILE (for Profile editing screens later)
  // ---------------------------------------------------------------------------
  Future<AuthResult> updateProfileFields(Map<String, dynamic> fields) async {
    try {
      isLoading.value = true;
      await _repos.authRepo.updateMeFields(fields);
      return AuthResult.success('Profile updated');
    } catch (e) {
      return AuthResult.fail('Failed to update: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-credential':
        return 'Invalid credentials. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      default:
        return e.message ?? 'Authentication error occurred.';
    }
  }
}
