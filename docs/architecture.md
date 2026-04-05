# KidsFinance — Flutter Architecture Guide

**Author:** Stark (Tech Lead)
**Date:** 2025-07-17
**Status:** Active — all agents implement against this spec.

---

## 1. Folder Structure

```
lib/
├── main.dart                       # App entry point: Firebase init, provider scope, router
├── app.dart                        # MaterialApp.router widget, theme config
│
├── core/                           # Shared infrastructure — NOT features
│   ├── constants/                  # App-wide constants (colors, strings, durations)
│   ├── errors/                     # Custom exception classes, failure types
│   ├── extensions/                 # Dart extension methods (DateTime, String, etc.)
│   ├── theme/                      # ThemeData, text styles, kid-friendly color palette
│   ├── utils/                      # Formatters (currency), validators, helpers
│   └── widgets/                    # Reusable widgets (BucketCard, AvatarBadge, LoadingIndicator)
│
├── routing/                        # GoRouter config, route names, auth redirect logic
│   ├── app_router.dart
│   └── route_names.dart
│
├── features/                       # Feature-first modules — each is self-contained
│   ├── auth/                       # Login, registration, auth state
│   │   ├── data/                   # AuthRepository, Firebase Auth calls
│   │   ├── domain/                 # AppUser model, auth enums
│   │   ├── presentation/          # LoginScreen, RegisterScreen, widgets
│   │   └── providers/             # authStateProvider, currentUserProvider
│   │
│   ├── family/                     # Family creation, joining, multi-parent management
│   │   ├── data/                   # FamilyRepository (Firestore)
│   │   ├── domain/                 # Family model, Parent model
│   │   ├── presentation/          # FamilySetupScreen, AddChildScreen
│   │   └── providers/             # familyProvider, childrenProvider
│   │
│   ├── dashboard/                  # Parent dashboard: overview of all children
│   │   ├── presentation/          # DashboardScreen, ChildSummaryCard
│   │   └── providers/             # dashboardProvider (aggregates child data)
│   │
│   ├── child_view/                 # Kid-facing view: their own buckets
│   │   ├── presentation/          # ChildHomeScreen, BucketDetailScreen
│   │   └── providers/             # childBucketsProvider
│   │
│   ├── buckets/                    # Core domain: Money 💰, Investments 📈, Charity ❤️
│   │   ├── data/                   # BucketRepository (Firestore reads/writes)
│   │   ├── domain/                 # Bucket model, BucketType enum, Transaction model
│   │   ├── presentation/          # BucketCard, TransactionHistoryList
│   │   └── providers/             # bucketProviders, transactionProviders
│   │
│   ├── transactions/               # Parent actions: set money, multiply, donate
│   │   ├── data/                   # TransactionRepository
│   │   ├── domain/                 # Transaction model, TransactionType enum
│   │   ├── presentation/          # SetMoneySheet, MultiplySheet, DonateSheet
│   │   └── providers/             # transactionFormProviders
│   │
│   └── settings/                   # App settings, profile, logout
│       ├── presentation/          # SettingsScreen
│       └── providers/
│
├── services/                       # Thin wrappers around Firebase SDKs
│   ├── firebase_service.dart       # Firebase.initializeApp helper
│   └── crashlytics_service.dart    # Error reporting wrapper
│
test/
├── unit/                           # Pure Dart tests (models, repositories, providers)
├── widget/                         # Widget tests with WidgetTester
├── integration/                    # Integration tests (flutter_test + Firebase emulator)
├── mocks/                          # Shared mock classes (MockFirestore, etc.)
└── fixtures/                       # JSON fixtures for Firestore data
```

### Key rules:
- **Feature folders are self-contained.** Each has its own `data/`, `domain/`, `presentation/`, `providers/`.
- **Nothing in `features/` imports from another feature's `data/` or `providers/`.** Cross-feature communication goes through shared providers or core models.
- **`core/`** is the only shared import across features.
- **`services/`** wraps external SDKs so they can be mocked in tests.

---

## 2. Package Selection

### pubspec.yaml dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| **flutter_riverpod** | ^2.6.x | State management. Compile-safe, testable, handles async Firebase streams natively. |
| **riverpod_annotation** | ^2.6.x | Code-gen for providers — less boilerplate, clearer intent. |
| **go_router** | ^14.x | Declarative routing with auth redirect guards. Deep-link ready. |
| **firebase_core** | ^3.x | Firebase initialization. |
| **firebase_auth** | ^5.x | Email/password auth + Google Sign-In for parents. |
| **cloud_firestore** | ^5.x | Real-time Firestore for buckets, transactions, families. |
| **firebase_crashlytics** | ^4.x | Crash reporting. |
| **freezed** | ^2.5.x | Immutable data classes with `copyWith`, `==`, JSON serialization. |
| **freezed_annotation** | ^2.4.x | Annotations for freezed. |
| **json_annotation** | ^4.9.x | JSON serialization annotations. |
| **google_fonts** | ^6.x | Kid-friendly typography (e.g., Nunito, Fredoka). |
| **flutter_animate** | ^4.x | Simple, declarative animations for kid-appealing UI. |
| **intl** | ^0.19.x | Currency and number formatting. |
| **flutter_svg** | ^2.x | SVG icons and illustrations. |

### dev_dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| **build_runner** | ^2.4.x | Code generation (freezed, riverpod_generator, json_serializable). |
| **riverpod_generator** | ^2.6.x | Code-gen for Riverpod providers. |
| **json_serializable** | ^6.8.x | JSON serialization code-gen. |
| **flutter_test** | sdk | Widget and unit testing. |
| **mockito** | ^5.4.x | Mocking for unit tests. |
| **riverpod_lint** | ^2.6.x | Lint rules specific to Riverpod usage. |
| **flutter_lints** | latest | Standard Dart/Flutter lint rules. |
| **fake_cloud_firestore** | ^3.x | In-memory Firestore for unit tests — no emulator needed for fast tests. |

### Why NOT these:
- **BLoC**: Too much boilerplate for a small team and simple app. Riverpod is lighter.
- **Provider (vanilla)**: Riverpod supersedes it with better testability and no BuildContext dependency.
- **auto_route**: GoRouter is simpler, officially supported, sufficient for our needs.
- **GetX**: Too magic, too hard to test, too opinionated.

---

## 3. Architecture Pattern

### Pattern: Feature-First + Riverpod + Repository

```
┌─────────────────────────────────────────────────────┐
│                    PRESENTATION                      │
│   Widgets / Screens (StatelessWidget + ConsumerWidget)│
│   ─ reads providers via ref.watch()                  │
│   ─ triggers actions via ref.read().method()         │
└────────────────────────┬────────────────────────────┘
                         │ ref.watch / ref.read
┌────────────────────────▼────────────────────────────┐
│                     PROVIDERS                        │
│   Riverpod providers (StateNotifier / AsyncNotifier)  │
│   ─ holds UI state                                   │
│   ─ calls repository methods                         │
│   ─ transforms data for the UI                       │
└────────────────────────┬────────────────────────────┘
                         │ method calls
┌────────────────────────▼────────────────────────────┐
│                    REPOSITORY                        │
│   Plain Dart classes                                 │
│   ─ single source of truth for data access           │
│   ─ wraps Firestore / Auth SDK calls                 │
│   ─ returns domain models (never raw Firebase types) │
└────────────────────────┬────────────────────────────┘
                         │ SDK calls
┌────────────────────────▼────────────────────────────┐
│                  FIREBASE / EXTERNAL                 │
│   Firestore, Firebase Auth, Cloud Functions          │
└─────────────────────────────────────────────────────┘
```

### Data flow example: Loading a child's buckets

1. **ChildHomeScreen** calls `ref.watch(childBucketsProvider(childId))`
2. **childBucketsProvider** is an `AsyncNotifierProvider` that calls `BucketRepository.getBuckets(childId)`
3. **BucketRepository.getBuckets()** queries Firestore `families/{familyId}/children/{childId}/buckets` and maps snapshots → `Bucket` model list
4. Provider emits `AsyncValue<List<Bucket>>` → widget renders `AsyncValue.when(data:, loading:, error:)`

### Data flow example: Parent multiplies investment

1. **MultiplySheet** calls `ref.read(transactionProvider.notifier).multiplyInvestment(childId, multiplier)`
2. **TransactionNotifier** calls `TransactionRepository.addTransaction(...)` with type `TransactionType.multiply`
3. **TransactionRepository** writes to Firestore `families/{fId}/children/{cId}/transactions/{txId}`
4. A **Cloud Function** (JARVIS's domain) triggers on write, recalculates the investment bucket balance, and updates `buckets/investments`
5. The bucket provider is listening to the Firestore stream → UI auto-updates

---

## 4. Key Architectural Decisions

### ADR-001: Feature-First Folder Organization
**Decision:** Organize code by feature, not by layer.
**Rationale:** Each feature (auth, buckets, family) is a self-contained module. This keeps related code together, makes navigation easier, and supports parallel development — Rhodey can work on `child_view/` while JARVIS works on `buckets/data/` without merge conflicts.

### ADR-002: Riverpod for State Management
**Decision:** Use `flutter_riverpod` with code generation (`riverpod_generator`).
**Rationale:** Compile-time safety, no `BuildContext` needed for providers, first-class `AsyncValue` for Firebase streams, excellent testability via `ProviderContainer` overrides. Code-gen reduces boilerplate.

### ADR-003: Repository Pattern for Data Access
**Decision:** All Firebase access goes through Repository classes. Widgets and providers never import Firebase SDKs directly.
**Rationale:** Testability (mock the repository, not Firestore), single place to handle errors and data mapping, easy to swap data source if needed.

### ADR-004: Freezed for Domain Models
**Decision:** All domain models (Bucket, Transaction, Family, AppUser) use `freezed` for immutability and `json_serializable` for Firestore serialization.
**Rationale:** Eliminates hand-written `==`, `hashCode`, `copyWith`, `toJson`, `fromJson`. Reduces bugs, enforces immutability.

### ADR-005: GoRouter with Auth Redirect
**Decision:** Use `go_router` with a `redirect` callback that checks auth state.
**Rationale:** If user is not authenticated → redirect to `/login`. If authenticated but no family → redirect to `/family-setup`. Otherwise → `/dashboard` (parent) or `/home` (child). Simple, declarative, no manual navigation guards.

### ADR-006: Two UI Modes — Parent & Child
**Decision:** The app has two distinct navigation trees: parent mode (dashboard, manage children, settings) and child mode (my buckets, simple view). Mode is determined by user role stored in Firestore.
**Rationale:** Kids see a drastically simpler UI. Parents see management tools. Sharing one app keeps the family connected. GoRouter's redirect handles mode switching.

---

## 5. App Entry Point Sketch

### main.dart

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // 1. Ensure Flutter binding is ready
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Run app inside ProviderScope (Riverpod root)
  runApp(
    const ProviderScope(
      child: KidsFinanceApp(),
    ),
  );
}
```

### app.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'routing/app_router.dart';

class KidsFinanceApp extends ConsumerWidget {
  const KidsFinanceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'KidsFinance',
      theme: AppTheme.light,    // kid-friendly colors and large tap targets
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

### routing/app_router.dart (sketch)

```dart
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../features/auth/providers/auth_providers.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isOnLogin = state.matchedLocation == '/login';

      if (!isLoggedIn && !isOnLogin) return '/login';
      if (isLoggedIn && isOnLogin) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login',      builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register',   builder: (_, __) => const RegisterScreen()),
      GoRoute(path: '/family-setup', builder: (_, __) => const FamilySetupScreen()),
      GoRoute(path: '/dashboard',  builder: (_, __) => const DashboardScreen()),
      GoRoute(path: '/child/:id',  builder: (_, state) =>
        ChildHomeScreen(childId: state.pathParameters['id']!)),
      GoRoute(path: '/settings',   builder: (_, __) => const SettingsScreen()),
    ],
  );
}
```

### Bootstrap Flow

```
main() → Firebase.initializeApp()
       → ProviderScope(child: KidsFinanceApp())
           → MaterialApp.router(routerConfig: appRouterProvider)
               → GoRouter.redirect checks authStateProvider
                   → Not logged in? → /login
                   → Logged in, no family? → /family-setup
                   → Logged in, has family? → /dashboard (parent) or /child/:id (child)
```

---

## 6. Conventions for All Agents

| Rule | Details |
|------|---------|
| **File naming** | `snake_case.dart` — always. |
| **Class naming** | `PascalCase` — models, widgets, providers. |
| **Provider naming** | `camelCaseProvider` — e.g., `childBucketsProvider`. |
| **Imports** | Relative within a feature, package imports across features. |
| **No business logic in widgets** | Widgets call providers. Providers call repositories. Period. |
| **Error handling** | Repositories catch Firebase exceptions and throw typed `AppException` subclasses. Providers expose errors via `AsyncValue.error`. |
| **Testing** | Every repository gets unit tests. Every provider gets unit tests. Critical screens get widget tests. |

---

*This document is the implementation contract. All agents build against this spec. Questions or proposed changes go through Stark.*
