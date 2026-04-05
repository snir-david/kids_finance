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

### 2026-04-05: Design System v1.0 Complete
- Created comprehensive design system spec in `docs/design/DESIGN_SYSTEM.md`
- **Key decisions made:**
  - Dual-mode UI: Kid Mode (playful, large targets, emoji-driven) vs Parent Mode (clean, professional, data-dense)
  - Three-bucket layout always visible: Money 💰, Investments 📈, Charity ❤️
  - Typography: Nunito for kids (rounded, friendly), Inter for parents (modern, clean)
  - Color system: Green for money, Blue for investments, Pink for charity — consistent visual anchors
  - Touch targets: 64px minimum for kids, 48px for parents
  - Mode switching via "Who's Here?" selector at launch; parents use Firebase Auth, kids use 4-digit PIN
  - Celebration animations are essential UX — investment multiply, donation, and money-added moments
  - Reduced motion support required for accessibility
- **Implementation phased:** Core screens → Actions → Celebrations → Management
- **Fonts chosen:** Nunito (Google Fonts, rounded) for kid mode, Inter for parent mode


