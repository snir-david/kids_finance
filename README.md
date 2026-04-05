# KidsFinance

Android app (Flutter + Firebase) for kids' financial literacy.

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

## Tech Stack

- **Flutter** (Dart) - Cross-platform UI framework
- **Firebase Auth** - Parent authentication
- **Cloud Firestore** - Real-time database
- **Cloud Functions** - Backend business logic
- **Riverpod** - State management with code generation
- **GoRouter** - Declarative routing
- **Freezed** - Immutable data models

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
5. Run `flutter pub run build_runner build` to generate code

### Run

```bash
flutter run
```

## Development

### Code Generation

This project uses code generation for:
- Riverpod providers (`@riverpod`)
- Freezed models (`@freezed`)
- JSON serialization

Run code generation:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

Watch mode (auto-regenerate on file changes):
```bash
flutter pub run build_runner watch --delete-conflicting-outputs
```

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
