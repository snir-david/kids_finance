# KidsFinance

Android app (Flutter + Firebase) for kids' financial literacy.

## Current Status (Sprint 5 Complete)

### What's Working
- ✅ **Authentication:** Email/password login, Google Sign-In, forgot password
- ✅ **Family Management:** Create family, join via invite code, multi-parent support
- ✅ **Child Management:** Add/edit/archive children with emoji avatars
- ✅ **Three-Bucket System:** Money, Investment, Charity with full CRUD
- ✅ **Allowance Distribution:** Split funds across buckets with celebration animations
- ✅ **PIN Authentication:** 4-6 digit PIN with brute-force lockout (5 tries → 15min)
- ✅ **Offline Sync:** Hive queue with 24h TTL, conflict resolution dialog
- ✅ **Security:** JWT spoofing fix, 24h session expiry, Firestore rules hardening

### What Requires Configuration
- Firebase project with Authentication and Firestore enabled
- `google-services.json` in `android/app/`
- Run `flutterfire configure` to generate `lib/firebase_options.dart`

## Overview

Three buckets per child:
- 💰 **Money** - Spending money
- 📈 **Investments** - Money that grows when parents multiply it
- ❤️ **Charity** - Money for giving back (resets to zero on donation)

## Features

- Multi-child support: Each family can have 1–N children
- Multi-parent support: 2+ parents can manage the same family
- Parents control all bucket values
- Children have read-only access via PIN authentication
- Investment multiplier system (parent-controlled)
- Offline-first with automatic sync when connectivity returns
- Celebration animations for investments and donations

## Tech Stack

- **Flutter** (Dart) - Cross-platform UI framework
- **Firebase Auth** - Parent authentication
- **Cloud Firestore** - Real-time database
- **Cloud Functions** - Backend business logic
- **Riverpod** - State management
- **GoRouter** - Declarative routing
- **Hive** - Local offline queue storage

## Project Structure

```
lib/
├── main.dart                    # App entry point
├── app.dart                     # MaterialApp.router setup
├── core/                        # Shared utilities
│   ├── constants/              # App-wide constants
│   ├── errors/                 # Exception classes
│   ├── extensions/             # Dart extensions
│   ├── theme/                  # Themes (kid & parent modes)
│   ├── utils/                  # Helpers, formatters
│   └── widgets/                # Reusable widgets
├── routing/                     # GoRouter configuration
├── features/                    # Feature modules
│   ├── auth/                   # Authentication
│   ├── family/                 # Family management
│   ├── children/               # Child management
│   ├── buckets/                # Bucket system
│   └── transactions/           # Transaction history
```

## Getting Started

### Prerequisites

- Flutter SDK (3.3.0+)
- Android Studio or VS Code
- Firebase project setup

### Setup

1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Configure Firebase:
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure
   ```
4. Replace `android/app/google-services.json` with your Firebase config
5. Run the app:
   ```bash
   flutter run
   ```

See `lib/firebase_options.dart.example` for the expected configuration structure.

### Run

```bash
flutter run
```

## Development

No code generation is required — the project uses standard Riverpod providers and Equatable models.

### Architecture

See [docs/architecture.md](docs/architecture.md) for detailed architecture guide.

## Team

- **Stark** - Tech Lead (Architecture, project setup)
- **Rhodey** - Mobile Dev (Flutter UI implementation)
- **JARVIS** - Backend Dev (Cloud Functions, Firestore)
- **Pepper** - UI/UX Designer (Design system, animations)
- **Fury** - Security & Auth (Authentication, PIN system)
- **Happy** - QA/Tester (Testing strategy)

## License

Private project - All rights reserved
