# KidsFinance

Android app (Flutter + Firebase) for kids' financial literacy.

## Current Status (Sprint 7D Complete)

### What's Working
- ✅ **Authentication:** Email/password login, forgot password
- ✅ **Family Management:** Create family, join via invite code, multi-parent support
- ✅ **Child Management:** Add/edit/archive children with emoji avatars; kids tap avatar to enter child mode (no PIN required)
- ✅ **Three-Bucket System:** Money, Investment, Charity with full CRUD
- ✅ **Allowance Distribution:** Split funds across buckets (default 70/20/10) with celebration animations
- ✅ **Savings Goals:** Named goals with progress bar, completion celebration, confetti
- ✅ **Achievement Badges:** 6 badge types awarded automatically; full badge grid screen
- ✅ **Multi-Currency:** ILS (default), USD, EUR, GBP — stored in SharedPreferences
- ✅ **Dark Theme:** System-aware toggle via Settings; full dark mode support
- ✅ **Hebrew Support:** Full RTL Hebrew localization across all screens
- ✅ **Offline Sync:** Hive queue with conflict resolution dialog
- ✅ **Security:** JWT spoofing fix, Firestore rules hardening, badge/goal rules deployed

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
- Parents control all bucket values; children have read-only access
- Savings goals with progress tracking and completion celebration
- Achievement badge system (6 types, auto-awarded)
- Multi-currency support: ILS, USD, EUR, GBP
- Dark theme + Hebrew RTL localization
- Investment multiplier system (parent-controlled)
- Offline-first with automatic sync when connectivity returns
- Celebration animations for investments, donations, and badge unlocks

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
│   ├── currency/               # CurrencyNotifier + CurrencyFormatter
│   ├── errors/                 # Exception classes
│   ├── extensions/             # Dart extensions
│   ├── l10n/                   # Manual AppLocalizations (EN + HE)
│   ├── offline/                # Hive offline queue + sync engine
│   ├── theme/                  # AppTheme (light/dark) + ThemeModeNotifier
│   └── widgets/                # Reusable widgets
├── routing/                     # GoRouter configuration
├── features/                    # Feature modules
│   ├── auth/                   # Parent auth + child picker
│   ├── badges/                 # BadgeShelf, BadgesScreen, BadgeEvaluationService
│   ├── buckets/                # Bucket system + action sheets
│   ├── children/               # Child management
│   ├── family/                 # Family management
│   ├── goals/                  # Savings goals
│   ├── settings/               # Theme, locale, currency settings
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
