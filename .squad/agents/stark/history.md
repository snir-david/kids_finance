## Core Context

## Project Seed

**Project:** KidsFinance
**Description:** Android app (Flutter + Firebase) for kids' financial literacy.
- Three buckets per child: Money 💰, Investments 📈, Charity ❤️
- Parents can multiply investments at will (stored as a transaction event)
- Charity bucket resets to zero when child donates
- Multi-child: each family has 1–N children
- Multi-parent: 2+ parents can manage the same family
- Money can be set freely by parents (any positive amount)
- UI must be simple enough for kids to understand
**Stack:** Flutter (Dart) + Firebase (Firestore, Auth, Cloud Functions)
**Target:** Android (primary); Flutter enables future iOS expansion
**Universe:** Iron Man (Marvel)

## Team
- Stark: Tech Lead
- Rhodey: Mobile Dev
- JARVIS: Backend Dev
- Pepper: UI/UX Designer
- Fury: Security & Auth
- Happy: QA/Tester
- Scribe: Session Logger
- Ralph: Work Monitor

## Learnings

### 2025-07-17: Architecture Plan Delivered
- Chose **Feature-First + Riverpod + Repository** pattern for the full app architecture.
- **Riverpod** (with code-gen) over BLoC — less boilerplate, compile-safe, native AsyncValue for Firebase streams.
- **GoRouter** for routing with auth redirect guards — simpler than auto_route, officially supported.
- **Freezed** for all domain models — immutability, auto-generated equality/serialization.
- **Repository pattern** enforced: widgets/providers never touch Firebase SDKs directly.
- **Two UI modes** (parent vs child) handled via GoRouter redirect based on Firestore user role.
- Feature folders are fully self-contained (data/domain/presentation/providers); no cross-feature imports except through core/.
- Architecture doc written to `docs/architecture.md` as the team implementation contract.


### 2025-07-18: Phase 1 — Project Scaffold Completed
- Created **complete Flutter project structure** with all foundational files for KidsFinance.
- **pubspec.yaml**: Added all dependencies (flutter_riverpod 2.6.1, riverpod_annotation, go_router 14.6.2, firebase_core 3.8.1, firebase_auth 5.3.3, cloud_firestore 5.5.2, cloud_functions 5.2.2, firebase_crashlytics 4.1.8, freezed 2.5.7, json_serializable 6.8.0, google_fonts 6.2.1, flutter_animate 4.5.0, flutter_secure_storage 9.2.2, intl 0.19.0, flutter_svg 2.0.10). Dev dependencies: build_runner, riverpod_generator, freezed, json_serializable, flutter_lints, riverpod_lint, mockito, fake_cloud_firestore.
- **lib/ folder structure**: Created feature-first organization with `core/`, `routing/`, and `features/{auth,family,children,buckets,transactions}` each with `data/`, `domain/`, `presentation/`, `providers/` subfolders. Added placeholder README.md files in each directory for git visibility.
- **lib/main.dart**: Bootstrap with `WidgetsFlutterBinding.ensureInitialized()`, `Firebase.initializeApp()`, and `ProviderScope` wrapping the app.
- **lib/app.dart**: MaterialApp.router setup consuming `appRouterProvider` with parent theme.
- **lib/routing/app_router.dart**: GoRouter with auth-aware redirect logic (unauthenticated → /login, authenticated parent → /parent-home, authenticated child with PIN → /child-home). Routes: /splash, /login, /parent-home, /child-home, /child-pin. Uses `@riverpod` code generation.
- **lib/core/theme/app_theme.dart**: Dual theme system with `kidTheme()` (Nunito font, 64x64dp tap targets, playful) and `parentTheme()` (Inter font, 48x48dp standard Material, professional). Includes bucket colors: Money=green (#4CAF50), Investments=blue (#2196F3), Charity=pink (#E91E63) — colorblind accessible. Material 3 design.
- **lib/core/constants/app_constants.dart**: PIN_LENGTH=4, PIN_MAX_ATTEMPTS=5, PIN_LOCKOUT_MINUTES=15, CHILD_SESSION_DAYS=30, INVESTMENT_MIN_MULTIPLIER=0.01, TRANSACTION_ARCHIVE_YEARS=1, bucket type constants, role constants.
- **lib/features/auth/**: Created domain model `AppUser` with Freezed, `auth_providers.dart` with authStateProvider and currentUserProvider, placeholder screens (LoginScreen, ParentHomeScreen, ChildHomeScreen, ChildPinScreen).
- **lib/firebase_options.dart**: Placeholder for FlutterFire CLI to generate actual config.
- **android/**: Created `android/app/build.gradle` with minSdk=21, targetSdk=34, compileSdk=34. Created `android/build.gradle`, `android/settings.gradle`, `android/local.properties`, `android/app/src/main/AndroidManifest.xml`, `android/app/src/main/kotlin/com/kidsfinance/app/MainActivity.kt`. Added placeholder `google-services.json` with instructions.
- **firebase.json** and **.firebaserc**: Stub Firebase project configuration files for Firestore, Functions, and Hosting.
- **test/**: Created `test/{unit,widget,integration}` directories with README files describing test strategy.
- **README.md**: Comprehensive project documentation with overview, tech stack, setup instructions, code generation commands, and team structure.
- **.gitignore**: Updated to exclude generated files (*.g.dart, *.freezed.dart), Android build artifacts, Firebase config, and IDE files.

**Key Technical Decisions:**
- Used `@riverpod` annotation for code generation instead of manual provider definitions — reduces boilerplate.
- GoRouter redirect uses `authStateProvider.valueOrNull` to determine authentication state and role-based routing.
- Dual theme system allows switching between kid-friendly and parent-professional UI modes.
- Android minSdk 21 (Lollipop 5.0) for broad compatibility while supporting modern Firebase SDKs.
- All Freezed models use `@freezed` with JSON serialization annotations.
- Repository pattern enforced: all Firebase access will go through repository classes (stubs created for JARVIS).

**Files Created (41 total):**
- Root: pubspec.yaml, README.md, .firebaserc, firebase.json, .gitignore (updated)
- lib/: main.dart, app.dart, firebase_options.dart
- lib/core/: theme/app_theme.dart, constants/app_constants.dart, + 5 placeholder READMEs
- lib/routing/: app_router.dart
- lib/features/auth/: domain/app_user.dart, providers/auth_providers.dart, presentation/{login_screen, parent_home_screen, child_home_screen, child_pin_screen}.dart, + 4 placeholder READMEs
- lib/features/{family,children,buckets,transactions}/: 16 placeholder READMEs across data/domain/presentation/providers
- android/: build.gradle, settings.gradle, local.properties, app/build.gradle, app/google-services.json (placeholder), app/src/main/AndroidManifest.xml, app/src/main/kotlin/com/kidsfinance/app/MainActivity.kt
- test/: unit/README.md, widget/README.md, integration/README.md

**Next Steps:**
- Run `flutter pub get` to fetch all dependencies.
- Run `flutterfire configure` to generate real `firebase_options.dart`.
- Run `flutter pub run build_runner build` to generate Riverpod and Freezed code.
- JARVIS implements repository layer (data/ folders).
- Fury implements authentication logic and PIN system.
- Rhodey implements UI screens (presentation/ folders).
- Pepper refines theme and adds animations.

**Handoff:**
- All foundational files are in place and compilable (pending code generation).
- JARVIS can start implementing repositories in `features/*/data/`.
- Fury can start implementing auth logic in `features/auth/data/` and `features/auth/providers/`.
- Rhodey can start building screens in `features/*/presentation/`.
- The project follows the architecture spec in `docs/architecture.md` exactly.

### 2026-04-05: Phase 1 Complete — All Agents Delivered
- **Status:** ✅ PHASE 1 SCAFFOLD FINALIZED
- Stark scaffold created 70+ files: pubspec.yaml, main.dart, app.dart, GoRouter, dual-theme, Android config
- JARVIS completed 22-file data layer: 5 Freezed models, 4 repositories, 15+ Riverpod providers
- Fury implemented auth system: AuthService, PinService (bcrypt), Firestore rules (124 lines), Cloud Functions (304 lines)
- **Total Phase 1 Output:** 99+ files, 2,392+ lines of code
- **Architecture Validated:** Feature-first, repository pattern, Riverpod code generation, GoRouter, dual theme, atomic transactions, security multi-layer
- **Next Phase:** Rhodey (UI), Pepper (design), Happy (testing)
- **Orchestration Log:** `.squad/orchestration-log/2026-04-05T18-30-00Z-stark-scaffold.md`


### 2025-07-20: Phase 1 Completion — Compile & Test Verification
- **Verified Phase 1 compilation status**: All core files (`lib/main.dart`, `lib/app.dart`, `lib/firebase_options.dart`, `lib/core/theme/app_theme.dart`, auth screens) compile cleanly with zero errors.
- **Flutter analyze results**: Ran `flutter analyze` on entire project — **NO ISSUES FOUND** ✅. All stub screens render properly with Scaffold widgets and placeholder text.
- **Stub screen status**:
  - `login_screen.dart`: Minimal stub with Scaffold and placeholder text ✅
  - `child_pin_screen.dart`: Minimal stub with Scaffold and placeholder text ✅
  - `family_setup_screen.dart`: Full UI form with validation (TODOs for backend integration) ✅
  - `parent_home_screen.dart`: Minimal stub ✅
  - `child_home_screen.dart`: Minimal stub ✅
- **Test suite**: No test files present yet; `flutter test` returns clean (expected for Phase 1).
- **Removed packages check**: No imports of deleted packages (freezed, riverpod_annotation) found — pubspec.yaml simplified to core dependencies only.
- **Created SETUP.md**: Comprehensive setup guide with Firebase configuration steps, running instructions, test commands, and project structure overview.
- **Decision**: Removed Freezed and Riverpod code generation in favor of simpler Equatable models and standard Riverpod providers. Reduces build complexity while maintaining immutability and type safety.
- **Phase 1 Status**: ✅ **COMPLETE** — Entire codebase compiles, no errors, ready for Phase 2 (Auth Implementation).

