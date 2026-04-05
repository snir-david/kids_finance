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

### Test Strategy & Coverage (2026-04-05)

**Key Decisions:**

1. **Critical Path First** — Defined P0 tests (30+) as the minimum gate before any release. These cover auth, bucket operations, investment multiplier, charity reset, and permission boundaries. P1/P2 tests provide depth but aren't blockers.

2. **Permission Model is Non-Negotiable** — Dedicated 8 explicit "boundary tests" (SEC-*) to prevent privilege escalation. Child isolation and parent-only actions are security-critical and tested in both happy path and adversarial scenarios.

3. **Edge Cases Over Generic Coverage** — Instead of just testing happy paths, identified tricky edge cases:
   - Multiply by zero, multiply by one (edge math)
   - Concurrent parent edits (race conditions)
   - Offline queue + sync conflict resolution
   - Rapid back-to-back updates
   - Family isolation under stress

4. **Firebase Emulator is Essential** — Integration tests require local Firebase (Firestore + Auth + Functions) to run fast and deterministically. Cloud Functions must be tested separately (Jest) to catch permission bugs before they reach production.

5. **Offline-First Architecture** — App must work offline with local edits queuing and syncing on reconnect. This adds complexity (conflict resolution) but is critical for mobile reliability. Included 4 P1 offline tests.

6. **Multi-Parent is Hard** — Concurrent edits by Parent A and B on the same child's bucket can race. Last-write-wins is simple but may lose data. Alternative: operational transform or CRDT. Decision deferred to Stark (tech lead) after MVP.

7. **Audit Trail Everywhere** — Every bucket operation (set money, multiply, reset) must create an immutable transaction entry with timestamp, actor (parent/child ID), and values. Enables debugging, compliance, and parent accountability.

8. **Kid UX is Non-Functional Testing** — Can't automate "is this fun for a 7-year-old?" Design & manual QA (Pepper, QA team) must validate the UX alongside functional tests.

**Test Infrastructure Decisions:**

- **Firebase Emulator locally** for unit/integration tests (fast, deterministic)
- **Cloud Functions Jest tests** separate from UI tests (isolation)
- **60+ test cases** organized into 9 categories + edge cases
- **80% code coverage minimum** on critical paths
- **Definition of Done includes manual QA** (not just automated tests)

**Open Questions for Squad:**

1. What's the policy on multiply by zero? Should it be rejected, error, or mathematically valid (→$0)?
2. Offline conflict resolution: last-write-wins, user prompt, or CRDT?
3. How long should offline queue persist? (e.g., max age before discarding stale changes)
4. Should child accounts have spending limits, or pure parent control?

