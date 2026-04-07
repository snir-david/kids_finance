---
updated_at: 2026-04-07T08:08:09Z
focus_area: Sprint 5B COMPLETE — Offline sync, conflict resolution, TTL queue. Sprint 5C (security polish) is next.
active_issues: []
---

# What We're Focused On

## ✅ SPRINT 5B COMPLETE

### Deliverables (Parallel Delivery by 3 Agents)

**JARVIS — Backend Infrastructure:**
- Offline queue: Hive-based with 24-hour TTL (warn at 23h, purge at 24h)
- ConnectivityService: Real-time online/offline status via connectivity_plus
- SyncEngine: Auto-sync on reconnect, conflict detection for bucket balances (setMoney, distribute, multiply, donate)
- Conflict resolution: User prompt (useLocal vs useServer) for balance ops; last-write-wins for non-balance ops
- Repository integration: BucketRepository and ChildRepository offline-aware
- Code quality: flutter analyze 0 errors, 15 files modified/created
- No code generation dependencies (Riverpod 3 compatible)

**Happy — Test Suite:**
- 29 anticipatory tests across 6 files
- Comprehensive edge case coverage (TTL boundary at 23h59m, conflict detection, resolution paths)
- Offline repository behavior (online regression tests)
- Conflict resolution dialog interaction tests
- TTL expiry warning lifecycle tests
- Tests serve as executable specification for JARVIS and Rhodey

**Rhodey — UI Components:**
- OfflineStatusBanner: 4-state animated banner (online, offline, expiring, syncing) at top of home screens
- ConflictResolutionDialog: Forced user choice, one-at-a-time resolution (useLocal vs useServer)
- TTL Expiry Warning: App lifecycle observer, one-time SnackBar per session when ops > 23h old
- Integration: parent_home_screen.dart and child_home_screen.dart fully wired
- Code quality: flutter analyze 0 errors, Material 3 design compliant

### Status
- ✅ Hive-based offline queue with 24h TTL (warn → purge lifecycle)
- ✅ Real-time connectivity tracking via Riverpod providers
- ✅ Conflict detection scoped to bucket balances only
- ✅ User prompt conflict resolution (no silent data loss)
- ✅ OfflineStatusBanner integrated on all home screens
- ✅ ConflictResolutionDialog enforces choice (barrierDismissible: false)
- ✅ TTL expiry warning prevents silent operation loss
- ✅ 0 lint issues, 29 new tests (200 total), all architecture patterns maintained

### Commits
- TBD (pending final commit)

---

## 🚀 SPRINT 5C QUEUED (Security Polish)

**Focus Area:** Security audit, offline conflict analytics, TTL retention policy  
**Timeline:** 1–2 day sprint  
**Key Tasks:**
- Audit log enhancements for offline operations
- Conflict resolution analytics and reporting
- TTL retention vs purge optimization
- Device-level encryption for offline queue (optional)

**Next Milestone:** Integration testing (Happy) + Sprint 5C planning

