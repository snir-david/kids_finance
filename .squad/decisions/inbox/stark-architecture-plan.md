# Architecture Plan — Team Decisions

**From:** Stark (Tech Lead)
**Date:** 2025-07-17
**Type:** Architecture — requires all agents to follow

---

## Decisions for Team Adoption

### 1. Feature-First + Riverpod + Repository Pattern
All code lives in `lib/features/{name}/` with `data/`, `domain/`, `presentation/`, `providers/` sub-folders. No cross-feature imports of data or providers. Shared code goes in `lib/core/`.

### 2. Riverpod with Code Generation
Use `flutter_riverpod` + `riverpod_generator` for state management. All providers use `@riverpod` annotations and code-gen. No vanilla Provider, no BLoC, no GetX.

### 3. Repository Pattern Enforced
All Firebase access goes through Repository classes in `data/`. Widgets and providers **never** import Firebase SDKs directly. Repositories return domain models, never raw Firestore types.

### 4. Freezed for Domain Models
All models (Bucket, Transaction, Family, AppUser) use `freezed` + `json_serializable`. No hand-written `==`, `hashCode`, `copyWith`, `toJson`, `fromJson`.

### 5. GoRouter with Auth Redirect
Navigation uses `go_router` with a redirect callback checking `authStateProvider`. Routes: `/login`, `/register`, `/family-setup`, `/dashboard`, `/child/:id`, `/settings`.

### 6. Two UI Modes
Parent mode: dashboard, manage children, settings. Child mode: simple bucket view. Mode determined by user role in Firestore, enforced by GoRouter redirect.

---

## Impact by Agent

| Agent | What This Means for You |
|-------|------------------------|
| **Rhodey** (Mobile Dev) | Build screens in `features/*/presentation/`. Use `ConsumerWidget` + `ref.watch()`. Never import Firebase directly. |
| **JARVIS** (Backend) | Build repositories in `features/*/data/`. Write Cloud Functions for transaction triggers. Return Freezed models from repos. |
| **Pepper** (UI/UX) | Design within the two-mode constraint (parent vs child). Theme lives in `core/theme/`. Use kid-friendly fonts (google_fonts). |
| **Fury** (Security) | Auth lives in `features/auth/`. Use Firebase Auth via `AuthRepository`. Firestore security rules enforce family-scoped access. |
| **Happy** (QA) | Tests go in `test/unit/`, `test/widget/`, `test/integration/`. Mock repositories with Mockito. Use `fake_cloud_firestore` for data tests. |

---

**Full architecture document:** `docs/architecture.md`
