# FitBud - Flutter Fitness App

## Project Overview
FitBud is a Flutter-based fitness app that supports gym management, workout sessions, user authentication, and fitness buddy matching. It uses Firebase as the backend.

## Architecture
- **Framework**: Flutter 3.41.2 (Dart 3.11.0)
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
- **Script**: `run_web.sh` - Uses Flutter 3.41.2 installed at `/home/runner/flutter`
- **Command**: `bash run_web.sh`
- **Port**: 5000 (web-server mode)
- **Host**: 0.0.0.0

## Flutter Installation
Flutter 3.41.2 is installed manually at `/home/runner/flutter/` (not via Nix).
The Nix module `dart-3.10` is also installed, but Flutter uses its own bundled Dart 3.11.0.

The Nix `flutter` package (3.32.0 with Dart 3.8.0) was also installed via nix packages, but the project requires Dart ^3.8.0 (updated from ^3.10.0 to match package constraints).

## Notes
- The app requires Firebase configuration to run properly
- Firebase App Check is configured for Android in production, debug mode in debug builds
- The app has web support but is primarily designed for mobile (Android/iOS)
- Cloud Functions are in TypeScript under `functions/`
