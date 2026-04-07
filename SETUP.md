# KidsFinance Setup Guide

## Prerequisites
- Flutter 3.41+ with Dart 3.11+
- Android Studio or VS Code with Flutter extension
- Firebase project

## Firebase Setup (Required before running)

### Initial Configuration
1. Create a Firebase project at https://console.firebase.google.com/
2. Add an Android app with package name `com.example.kids_finance`
3. Download `google-services.json` and place it in `android/app/`
4. Install FlutterFire CLI:
   ```bash
   dart pub global activate flutterfire_cli
   ```
5. Run FlutterFire configuration:
   ```bash
   flutterfire configure
   ```
   This will replace `lib/firebase_options.dart` with real Firebase values.

### Enable Firebase Services
In the Firebase Console, enable:
- **Authentication** → Email/Password and Google Sign-In
- **Firestore Database** → Create database in production mode
- **Cloud Functions** → Set up billing (required for callable functions)
- **Crashlytics** (optional but recommended)

## Running the App

### Install Dependencies
```bash
flutter pub get
```

### Run on Android Emulator or Device
```bash
flutter run
```

### Run in Debug Mode
```bash
flutter run --debug
```

### Run in Release Mode
```bash
flutter run --release
```

## Running Tests

### Run All Unit Tests
```bash
flutter test
```

### Run Tests with Coverage
```bash
flutter test --coverage
```

### Run Integration Tests
```bash
flutter test integration_test/
```

## Project Structure

```
lib/
├── main.dart                  # App entry point
├── app.dart                   # Root app widget
├── firebase_options.dart      # Firebase configuration (generated)
├── core/
│   └── theme/
│       └── app_theme.dart    # Parent & Kid themes
├── features/
│   ├── auth/                 # Authentication feature
│   ├── buckets/              # Three-bucket system (Money, Investments, Charity)
│   └── transactions/         # Transaction tracking
├── routing/
│   └── app_router.dart       # GoRouter configuration
└── shared/                   # Shared widgets & utilities
```

For detailed architecture information, see:
- `docs/ARCHITECTURE.md` - Full system architecture
- `AUTH_ARCHITECTURE.md` - Authentication design
- `FIRESTORE_DATA_MODEL.md` - Database schema
- `DATA_LAYER_MANIFEST.md` - Data layer implementation guide

## Development Notes

### Sprint 5 (Complete) ✅
- **5A:** Allowance distribution, celebration animations, kids screen, edit child, soft-delete, forgot password
- **5B:** Offline sync (Hive queue 24h TTL, SyncEngine, ConflictResolution dialog, OfflineStatusBanner)
- **5C:** JWT spoofing fix, PIN brute-force lockout (5→15min), 24h session expiry, Cloud Function hardening, Firestore rules tightening

### Previous Phases (Complete) ✅
- Phase 1-4: Core infrastructure, authentication, family management, bucket system, multi-parent support

## Troubleshooting

### Firebase not initialized
Make sure you've run `flutterfire configure` and the `google-services.json` file is present in `android/app/`.

### Build errors
```bash
flutter clean
flutter pub get
flutter run
```

### Test failures
Ensure all Firebase services are properly configured. Some tests may require Firebase emulator setup.

## Support

For issues or questions, refer to the documentation in the `docs/` directory.
