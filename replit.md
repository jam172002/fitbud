# FitBud - Flutter Fitness App

## Project Overview
FitBud is a Flutter-based fitness app that supports gym management, workout sessions, user authentication, and fitness buddy matching. It uses Firebase as the backend. The app runs on both mobile (iOS/Android) and web.

## Architecture
- **Framework**: Flutter 3.32.0 (Dart 3.8.0) via Nix
- **Backend**: Firebase (Firestore, Auth, Storage, Functions, App Check, Messaging)
- **State Management**: GetX (get package)
- **Local Storage**: Hive, GetStorage, SharedPreferences

## Project Structure
- `lib/main.dart` - App entry point, Firebase initialization
- `lib/app.dart` - Root widget, onboarding/auth routing
- `lib/app_binding.dart` - GetX dependency injection
- `lib/firebase_options.dart` - Firebase configuration (project: fitbud-46f70)
- `lib/presentation/` - UI screens and controllers
- `lib/domain/` - Domain models and repository interfaces
- `lib/common/` - Shared widgets and utilities
- `assets/` - Images, icons, fonts (Outfit font family)
- `functions/` - Firebase Cloud Functions (TypeScript)
- `web/` - Flutter web configuration

## Running the App
- **Script**: `run_web.sh` - Uses the Nix Flutter (3.32.0 / Dart 3.8.0)
- **Command**: `bash run_web.sh`
- **Port**: 5000 (web-server mode)
- **Host**: 0.0.0.0

## Flutter / Dart Notes
- Flutter 3.32.0 (Dart 3.8.0) is provided by the Nix environment.
- `shared_preferences` is pinned to `">=2.2.0 <2.5.4"` because 2.5.4+ requires Dart ^3.9.0.

## Notification System
Push notifications are handled end-to-end:
- **Server-side (Cloud Functions)**: `functions/src/index.ts` triggers FCM + Firestore writes on events:
  - `onBuddyRequestCreated` — notifies recipient when a buddy request is sent
  - `onBuddyRequestUpdated` — notifies sender when their request is accepted
  - `onSessionInviteCreated` — notifies invited user when a session invite arrives
  - `onSessionInviteUpdated` — notifies inviter when their session invite is accepted
  - `onNewMessage` — notifies all conversation participants on a new chat message
- **Client-side (Flutter)**: `lib/notification_helper/my_notification.dart`
  - Foreground messages: local notification on mobile, FCM listener on web
  - Background messages: `myBackgroundMessageHandler` (mobile only)
  - Tap on notification: navigates to NotificationsScreen
- **FCM token** is stored in `users/{uid}.fcmTokens` and refreshed on every login
- **Notification history** stored in `users/{uid}/notifications` subcollection
- **Deploy functions**: Run `firebase deploy --only functions` from the `functions/` directory

## Profile Tab
- Privacy & Security screen: `lib/presentation/screens/profile/privacy_security_screen.dart`
- Terms & Conditions screen: `lib/presentation/screens/profile/terms_conditions_screen.dart`
- Both screens use numbered sections with the app dark/green theme

## Signup
- Terms & Conditions checkbox is required before account creation
- Checkbox links to both the Terms & Conditions and Privacy Policy screens in-app

## Notes
- The app requires Firebase configuration to run properly
- Firebase App Check is configured for Android in production, debug mode in debug builds
- The app has web support but is primarily designed for mobile (Android/iOS)
- Cloud Functions are in TypeScript under `functions/` — build with `npx tsc` in that directory
