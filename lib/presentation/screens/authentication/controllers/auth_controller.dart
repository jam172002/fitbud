import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:get/get.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../data/supabase_config.dart';
import '../../../../domain/models/auth/app_user.dart';
import '../../../../domain/repos/repo_provider.dart';
import 'auth_result.dart';

class AuthController extends GetxController {
  AuthController(this._repos);

  final Repos _repos;
  Repos get repos => _repos;

  sb.GoTrueClient get _auth => _repos.db.auth;

  String? _lastPushedToken;
  DateTime? _lastTokenPushAt;

  // reactive state
  final RxBool isLoading = false.obs;
  final Rxn<sb.User> authUser = Rxn<sb.User>();
  final Rxn<AppUser> me = Rxn<AppUser>();

  StreamSubscription<sb.User?>? _authSub;
  StreamSubscription<AppUser?>? _meSub;

  @override
  void onInit() {
    super.onInit();

    // Restore an already-persisted session immediately (the auth stream also
    // replays it, but this avoids a login-screen flash on cold start).
    authUser.value = _auth.currentUser;

    // Observe Supabase auth state
    _authSub = _repos.authRepo.authState().listen((u) {
      authUser.value = u;

      // Stop previous profile stream
      _meSub?.cancel();
      _meSub = null;
      me.value = null;

      // If logged-in: start watching the user's profile row
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
  // PROFILE: force refresh once (optional helper)
  // ---------------------------------------------------------------------------
  Future<void> loadMe() async {
    final profile = await _repos.authRepo.getMeOnce();
    me.value = profile;
  }

  // ---------------------------------------------------------------------------
  // PROFILE UPDATE (generic)
  // ---------------------------------------------------------------------------
  Future<AuthResult> updateMeFields(Map<String, dynamic> fields) async {
    try {
      isLoading.value = true;
      await _repos.authRepo.updateMeFields(fields);
      await loadMe();
      return AuthResult.success('Profile updated');
    } catch (e) {
      return AuthResult.fail('Failed to update: $e', code: 'profile_update_failed');
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // COMPLETE PROFILE SETUP (used by ProfileDataGatheringScreen)
  // - Upload profile image
  // - Save activities, favourite, gym, about, photoUrl, isProfileComplete=true
  // ---------------------------------------------------------------------------
  Future<AuthResult> completeProfileSetup({
    required Uint8List imageBytes,
    required List<String> activities,
    required String favouriteActivity,
    required bool hasGym,
    required String gymName,
    required String about,
  }) async {
    try {
      isLoading.value = true;

      // 1) Upload image
      final photoUrl = await _repos.authRepo.uploadMyProfileImage(imageBytes);
      if (photoUrl.trim().isEmpty) {
        return AuthResult.fail('Image upload failed. Please try again.', code: 'upload_failed');
      }

      // 2) Save fields
      final payload = <String, dynamic>{
        'photoUrl': photoUrl,
        'activities': activities,
        'favouriteActivity': favouriteActivity,
        'hasGym': hasGym,
        'gymName': gymName,
        'about': about,
        'isProfileComplete': true,
      };

      await _repos.authRepo.updateMeFields(payload);
      await loadMe();

      return AuthResult.success('Profile setup completed');
    } catch (e) {
      return AuthResult.fail('Failed to complete profile: $e', code: 'profile_setup_failed');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateUserDeviceToken() async {
    if (kIsWeb) return;
    final u = authUser.value;
    if (u == null) return;

    // throttle: once per 12 hours
    if (_lastTokenPushAt != null) {
      final age = DateTime.now().difference(_lastTokenPushAt!);
      if (age.inHours < 12) return;
    }

    final fcm = FirebaseMessaging.instance;
    final token = await fcm.getToken();
    if (token == null || token.isEmpty) return;

    // avoid repeat writes in same session
    if (_lastPushedToken == token) return;

    // subscribe once per session (optional)
    await fcm.subscribeToTopic("chat");

    // supports multiple devices
    await _repos.authRepo.addFcmToken(token);

    _lastPushedToken = token;
    _lastTokenPushAt = DateTime.now();
  }

  // ---------------------------------------------------------------------------
  // SIGN UP (Email/Password)
  // Creates the auth user (a DB trigger creates the profile row), then fills
  // in the profile fields.
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

      final res = await _auth.signUp(
        email: email.trim(),
        password: password,
        data: {'display_name': name.trim()},
      );

      final uid = res.user?.id;
      if (uid == null) {
        return AuthResult.fail('Signup failed. Please try again.', code: 'no_uid');
      }

      // With "Confirm email" enabled there is no session yet - the user has
      // to confirm first.
      if (res.session == null) {
        return AuthResult.fail(
          'Check your inbox and confirm your email, then log in.',
          code: 'email_confirmation_required',
        );
      }

      final user = AppUser(
        id: uid,
        email: email.trim(),
        phone: phone.trim(),
        displayName: name.trim(),
        gender: gender,
        city: location,
        dob: dob,
        isActive: true,
      );

      await _repos.authRepo.upsertMe(user: user, merge: true);

      return AuthResult.success('Signup successful');
    } on sb.AuthException catch (e) {
      return AuthResult.fail(_mapAuthError(e), code: e.code ?? 'auth_error');
    } catch (e) {
      return AuthResult.fail('Unexpected error: $e', code: 'unexpected');
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // LOGIN (Email/Password)
  // - If email -> login with email/password
  // - If phone -> return controlled message (OTP phone login later)
  // ---------------------------------------------------------------------------
  Future<AuthResult> login({
    required String emailOrPhone,
    required String password,
  }) async {
    try {
      isLoading.value = true;

      final input = emailOrPhone.trim();

      final isEmail =
      RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(input);
      final isPhone = RegExp(r'^\+?\d{10,15}$').hasMatch(input);

      if (!isEmail && isPhone) {
        return AuthResult.fail(
          'Phone login is not enabled yet. Please login with email.',
          code: 'phone_not_supported',
        );
      }

      if (!isEmail) {
        return AuthResult.fail('Please enter a valid email.', code: 'invalid_email');
      }

      await _auth.signInWithPassword(email: input, password: password);

      return AuthResult.success('Login successful');
    } on sb.AuthException catch (e) {
      return AuthResult.fail(_mapAuthError(e), code: e.code ?? 'auth_error');
    } catch (e) {
      return AuthResult.fail('Unexpected error: $e', code: 'unexpected');
    } finally {
      isLoading.value = false;
    }
  }

  // ---------------------------------------------------------------------------
  // SOCIAL SIGN-IN (Google everywhere, Apple on iOS only)
  // ---------------------------------------------------------------------------

  /// Apple sign-in is only offered on iOS.
  bool get appleSignInAvailable =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Signs in with Google natively and exchanges the ID token with Supabase.
  Future<AuthResult> signInWithGoogle() async {
    try {
      isLoading.value = true;

      final google = GoogleSignIn(
        clientId: SupabaseConfig.googleIosClientId.isEmpty
            ? null
            : SupabaseConfig.googleIosClientId,
        serverClientId: SupabaseConfig.googleWebClientId.isEmpty
            ? null
            : SupabaseConfig.googleWebClientId,
      );
      final account = await google.signIn();
      if (account == null) {
        return AuthResult.fail('Sign-in cancelled.', code: 'cancelled');
      }
      final tokens = await account.authentication;
      final idToken = tokens.idToken;
      if (idToken == null) {
        return AuthResult.fail('Google did not return an ID token.', code: 'no_id_token');
      }

      await _auth.signInWithIdToken(
        provider: sb.OAuthProvider.google,
        idToken: idToken,
        accessToken: tokens.accessToken,
      );
      return AuthResult.success('Login successful');
    } on sb.AuthException catch (e) {
      return AuthResult.fail(_mapAuthError(e), code: e.code ?? 'auth_error');
    } catch (e) {
      return AuthResult.fail('Google sign-in failed: $e', code: 'google_failed');
    } finally {
      isLoading.value = false;
    }
  }

  /// Signs in with Apple (iOS) and exchanges the ID token with Supabase.
  Future<AuthResult> signInWithApple() async {
    if (!appleSignInAvailable) {
      return AuthResult.fail('Apple sign-in is only available on iOS.', code: 'unsupported');
    }
    try {
      isLoading.value = true;

      final rawNonce = _randomNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
        nonce: hashedNonce,
      );
      final idToken = credential.identityToken;
      if (idToken == null) {
        return AuthResult.fail('Apple did not return an identity token.', code: 'no_id_token');
      }

      await _auth.signInWithIdToken(
        provider: sb.OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );

      // Apple only sends the name on the very first authorization.
      final full = '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim();
      if (full.isNotEmpty) {
        await _repos.authRepo.updateMeFields({'displayName': full});
      }
      return AuthResult.success('Login successful');
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return AuthResult.fail('Sign-in cancelled.', code: 'cancelled');
      }
      return AuthResult.fail('Apple sign-in failed: ${e.message}', code: 'apple_failed');
    } on sb.AuthException catch (e) {
      return AuthResult.fail(_mapAuthError(e), code: e.code ?? 'auth_error');
    } catch (e) {
      return AuthResult.fail('Apple sign-in failed: $e', code: 'apple_failed');
    } finally {
      isLoading.value = false;
    }
  }

  String _randomNonce([int length = 32]) {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._';
    final rnd = Random.secure();
    return List.generate(length, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  /// Re-authenticates a Google/Apple account (used by sensitive flows such as
  /// account deletion).
  Future<AuthResult> reauthenticateWithOAuth() async {
    final providers =
        (authUser.value?.appMetadata['providers'] as List?)?.cast<String>() ?? const [];
    if (providers.contains('apple') && appleSignInAvailable) return signInWithApple();
    return signInWithGoogle();
  }

  // ---------------------------------------------------------------------------
  // FORGOT PASSWORD (Supabase email reset)
  // ---------------------------------------------------------------------------
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      isLoading.value = true;

      await _auth.resetPasswordForEmail(
        email.trim(),
        redirectTo: kIsWeb ? null : SupabaseConfig.authRedirect,
      );

      return AuthResult.success('Password reset email sent');
    } on sb.AuthException catch (e) {
      return AuthResult.fail(_mapAuthError(e), code: e.code ?? 'auth_error');
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
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _repos.authRepo.signOut();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  String _mapAuthError(sb.AuthException e) {
    switch (e.code) {
      case 'user_already_exists':
      case 'email_exists':
        return 'This email is already registered.';
      case 'validation_failed':
      case 'email_address_invalid':
        return 'Please enter a valid email address.';
      case 'weak_password':
        return 'Password is too weak.';
      case 'invalid_credentials':
        return 'Incorrect email or password.';
      case 'email_not_confirmed':
        return 'Please confirm your email first, then log in.';
      case 'over_request_rate_limit':
      case 'over_email_send_rate_limit':
        return 'Too many attempts. Please wait and try again.';
      default:
        return e.message.isNotEmpty ? e.message : 'Authentication error occurred.';
    }
  }
}
