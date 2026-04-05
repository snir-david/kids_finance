---
updated_at: 2026-04-05T20:33:27Z
focus_area: Architecture planning complete — ready for implementation
active_issues: []
---

# What We're Focused On

Architecture phase complete. Five specialist agents delivered comprehensive specifications:
- **Stark:** Flutter architecture with Riverpod + Repository pattern
- **JARVIS:** Firestore data model with Cloud Functions
- **Pepper:** Design system with dual-mode UI and celebration animations
- **Fury:** Two-tier auth (parent Firebase, child PIN) + COPPA compliance
- **Happy:** Master test plan with 60+ cases and permission boundary tests

**Team Status:** Ready for implementation phase. Architectural direction approved.

**Open Questions for Squad Consensus:**
1. Multiply by zero behavior (allow / reject >0 / reject ≥1?)
2. Offline conflict resolution (last-write-wins / user prompt / CRDT?)
3. Offline queue retention (indefinite / 30 mins / 24 hrs?)
4. Child spending limits (full parent control / parent-set limits?)
5. Child auth (PIN only / add biometric?)

**Next Milestone:** Squad decision review on open questions. Begin implementation on approved foundations.
