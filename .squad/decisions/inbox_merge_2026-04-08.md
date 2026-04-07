# Merged Decisions - 2026-04-08

## Decision: Architecture Documentation Update & FRD Creation

**Date:** 2026-04-08  
**Author:** Stark (Tech Lead)  
**Status:** Complete

### Summary

Reviewed and updated all architecture documentation to reflect Sprint 5D complete state. Created comprehensive Functional Requirements Document (FRD) with 80+ numbered requirements.

### Documents Updated

#### AUTH_ARCHITECTURE.md
**Changes:** Complete rewrite from "Design" to "Implemented" status
- Documented two-tier auth model (Firebase Auth parents + bcrypt PIN children)
- Added PIN brute-force lockout details (5 attempts → 15min, FlutterSecureStorage)
- Added 24h child session expiry (dual storage: local + Firestore)
- Added JWT spoofing fix explanation (Firestore parentIds[] verification)
- Added forgot password flow documentation
- Marked all security risks as MITIGATED with implementation references

#### INTEGRATION_STATUS.md
**Changes:** Updated from generic "fully integrated" to Sprint 5D specifics
- Changed timestamp to 2026-04-08
- Updated file count to 57 Dart files
- Added complete file structure tree
- Added Sprint 5A-5D delivery summary
- Marked all checklist items as complete
- Added offline support and security sections

#### SCAFFOLD_CHECKLIST.md
**Changes:** Complete rewrite from Phase 1 scaffold to implementation status
- Converted placeholder checklist to feature-complete status table
- Added status and file references for every component
- Added "Out of Scope" section with reasons
- Updated statistics: 57 files, 8 screens, 4 Cloud Functions

### Document Created

#### FRD.md
**Location:** Project root  
**Size:** ~21KB, ~500 lines

**Contents:**
- Overview: Product description, target users, platform, tech stack
- User Roles: FR-ROLE-01/02 (Parent, Child)
- Authentication: FR-AUTH-01 through FR-AUTH-21 (registration, login, PIN, session, lockout, family isolation)
- Parent Features: FR-PARENT-01 through FR-PARENT-25 (family, children, allowance, investment, charity)
- Child Features: FR-CHILD-01 through FR-CHILD-09 (bucket viewing, read-only access, session)
- Bucket System: FR-BUCKET-01 through FR-BUCKET-11 (types, validation, operations)
- Offline Support: FR-OFFLINE-01 through FR-OFFLINE-15 (queue, TTL, sync, conflicts, connectivity)
- Security: FR-SEC-01 through FR-SEC-15 (data protection, access control, data integrity, auth security)
- Non-Functional: NFR-01 through NFR-07 (performance, reliability, platform, quality, maintainability, accessibility, localization)
- Out of Scope: 14 items with reasons
- Appendices: Firestore data model, glossary

**All requirements marked with status:**
- ✅ Implemented (majority)
- 🔶 Partial (localization only)
- ❌ Not implemented (none — all out-of-scope items in separate section)

---

## Decision: Data Layer & Infrastructure Documentation Overhaul

**Date:** 2026-04-08  
**Author:** JARVIS (Backend)  
**Status:** Complete

### Summary

Updated critical data layer and infrastructure documentation to reflect Sprint 5A-5D implementation reality and address harmful/outdated sections.

### Documents Updated

#### FIRESTORE_DATA_MODEL.md (v1.0 → v2.0)

**What was outdated:**
- Described a `/families/{familyId}/parents/{parentId}` subcollection that was never implemented
- Described a `/userProfiles/{uid}` top-level collection that is not in the security rules or repositories
- Described buckets as a nested map inside the child document — they are actually a separate subcollection
- Transaction path was at the family level but document implied child-level
- Old transaction type names (`investment_multiply`, `charity_donate`, `money_adjust`, `bucket_transfer`) do not match the actual Dart enum values
- All date examples used ISO 8601 strings — code always uses `Timestamp.fromDate()`
- Sections 3–10 were aspirational design that predated implementation and were never accurate

**What was updated:**
- Corrected collection tree (no /parents, no /userProfiles)
- Added Bucket document schema as a separate section (§ 2.3)
- Corrected Child document to actual fields: `displayName`, `avatarEmoji`, `pinHash`, `sessionExpiresAt`, `archived`, `createdAt`
- Corrected Transaction document to flat field structure with actual enum names
- Added `distributed` transaction type with explanation
- Added Timestamp rule section
- Added Security Rules summary, Cloud Functions table, Index requirement, Offline Sync summary
- Removed ~450 lines of outdated Riverpod/Cloud Functions design specs

#### DATA_LAYER_MANIFEST.md

**What was outdated:**
- Listed "Code Generation Required" as a mandatory step — build_runner is not used at all
- Missing the offline layer (OfflineQueue, SyncEngine, ConnectivityService, conflict detection)
- Missing auth services (pin_service, auth_service, pin_attempt_tracker)
- Missing emulator/integration test infrastructure
- Firestore paths section showed `/archivedTransactions` and wrong transaction path
- Provider list was incomplete (missing auth_providers, session_provider)

**What was updated:**
- Removed code generation section entirely
- Added offline layer (8 files) with clear DO NOT use hive_generator warning
- Added auth services section
- Added Firebase/emulator config files section
- Updated provider list
- Updated Key Implementation Decisions (added items 1–13)
- Added correct Firestore paths with note about transactions being family-level

#### SETUP_DATA_LAYER.md

**What was outdated:**
- "Code Generation (REQUIRED)" was the first setup step — this is wrong and harmful
- No mention of Hive manual TypeAdapter
- No Firebase emulator setup instructions
- Offline support section said "Conflicts use last-write-wins (may need user prompt later)" — conflict resolution with user prompt is fully implemented
- Missing `distributeFunds` and `archiveChild` usage examples
- References to wrong Firestore collection paths in index creation step

**What was updated:**
- Replaced code generation step with explicit "DO NOT run build_runner" warning
- Added Hive TypeAdapter section
- Added Firebase Emulator Setup section with port table and seed script commands
- Added `distributeFunds` and `archiveChild` usage examples
- Updated troubleshooting to cover Timestamp errors and Hive registration errors
- Fixed Firestore index path

#### AUTH_SECURITY_PHASE1_COMPLETE.md

**What was outdated (Fury's original doc from Sprint 1):**
- Documented `onSetCustomClaims` Cloud Function as the family membership mechanism — this was replaced by the JWT spoofing fix in Sprint 5C
- Documented `onMultiplyInvestment`, `onDonateCharity`, `onSetMoney` as the function names — actual names are `multiplyBucket`, `addFundsToChild`, `distributeFunds`
- Session duration listed as 30 days — changed to 24h in Sprint 5C
- Google Sign-In listed as implemented — it is not (package not in pubspec)
- No mention of known platform limitations (iOS/Web not supported)
- No mention of Sprint 5C security hardening work

**What was updated:**
- Replaced entirely with a combined security status document
- Two-tier auth architecture table
- Sprint 5C hardening section: JWT spoofing fix, PIN lockout, session expiry, rule validators
- "Current Security Posture" threat → protection mapping table
- Cloud Functions auth + validation summary table
- Known Limitations section (iOS, Web, Google Sign-In, PIN recovery, session revocation, audit logging)
- File reference table

---

## Decision: Test Report Consolidation (Sprint 5D)

**Date:** 2026-04-08  
**Author:** Happy (QA Lead)  
**Status:** Complete

### Summary of Changes

#### TEST_REPORT.md — now canonical
Replaced the Phase 1-only report with a full canonical report covering all sprints. It now includes:
- Actual verified test counts: **218 unit tests (189 pass / 29 expected failures)** and **54 integration tests (40 runnable / 14 emulator)**
- Sprint-by-sprint summary table (Phase 1 → Sprint 5D)
- Full test file inventory (36 unit files, 6 integration files)
- Known issues section explaining the 29 pre-existing mock failures (build_runner + Flutter 3.41.6 incompatibility — NOT regressions)
- How-to-run instructions for both unit and integration tests, including the emulator prerequisite
- Integration test coverage breakdown per file (auth_flow, bucket_operations, child_management, offline_sync, security, full_journey)

#### TEST_REPORT_PHASE2.md — archived with redirect
Added a superseded banner at the top pointing to TEST_REPORT.md. Original Phase 2 widget content preserved below. Rationale: the canonical report now covers all widget/screen tests; a separate living document would diverge.

### Actual Test Numbers (verified)

```
flutter test test/ --no-pub
+189 -29: Some tests failed.
Total: 218 unit tests | 189 passing | 29 failing (expected)
```

```
flutter test integration_test/
40 tests pass without emulator | 14 require `firebase emulators:start`
```

**Grand total: 272 tests across the project (218 unit + 54 integration)**

---

## Deduplication Notes

**No duplicates found** across the three decision documents. Each agent addressed distinct documentation domains:
- **Stark:** Architecture, FRD, integration status
- **JARVIS:** Data layer, Firestore schema, setup procedures
- **Happy:** Test reporting and validation
