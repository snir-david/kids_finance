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

