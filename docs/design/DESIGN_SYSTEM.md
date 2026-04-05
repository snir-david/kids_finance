# KidsFinance Design System & Screen Flow Specification

**Author:** Pepper (UI/UX Designer)  
**Version:** 1.0  
**Date:** 2026-04-05

---

## 1. Screen Inventory

### Kid Mode Screens

| Screen | Purpose |
|--------|---------|
| **Kid Login** | PIN entry for child to access their dashboard |
| **Kid Dashboard** | Main view showing all three buckets with big, clear numbers |
| **Bucket Detail: Money 💰** | Expanded view of Money bucket with recent transactions |
| **Bucket Detail: Investments 📈** | Expanded view showing investment growth history |
| **Bucket Detail: Charity ❤️** | Expanded view with donate button and giving history |
| **Donate Confirmation** | Confirmation dialog before resetting charity bucket |
| **Celebration Screen** | Full-screen animation for investment multiplies or donations |
| **Kid Settings** | Simple preferences (avatar, theme color) |

### Parent Mode Screens

| Screen | Purpose |
|--------|---------|
| **Parent Login** | Email/password authentication for parents |
| **Family Setup (First Launch)** | Onboarding flow to create family and add first child |
| **Parent Dashboard** | Overview of all children with quick bucket summaries |
| **Child Detail View** | Detailed view of one child's buckets with edit controls |
| **Add Money Modal** | Input dialog to set/add money to any bucket |
| **Multiply Investment** | Action screen to multiply a child's investment bucket |
| **Transaction History** | Chronological list of all bucket changes per child |
| **Manage Children** | Add/edit/remove children from the family |
| **Manage Parents** | Invite/remove co-parents to manage the family |
| **Parent Settings** | Account, notifications, family settings |

---

## 2. Navigation Flows

### Parent Journey

```
┌─────────────────────────────────────────────────────────────────────┐
│                         PARENT FLOW                                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  [First Launch]                                                      │
│       │                                                              │
│       ▼                                                              │
│  ┌─────────────┐    ┌──────────────┐    ┌─────────────────┐         │
│  │   Welcome   │───▶│ Create Acct  │───▶│  Family Setup   │         │
│  │   Screen    │    │  (Firebase)  │    │  (Name Family)  │         │
│  └─────────────┘    └──────────────┘    └────────┬────────┘         │
│                                                   │                  │
│                                                   ▼                  │
│                                         ┌─────────────────┐         │
│                                         │   Add Child     │         │
│                                         │ (Name, PIN, $)  │         │
│                                         └────────┬────────┘         │
│                                                   │                  │
│       ┌───────────────────────────────────────────┘                 │
│       │                                                              │
│       ▼                                                              │
│  ┌─────────────────┐                                                │
│  │ PARENT DASHBOARD │◀─────────────────────────────┐                │
│  │  (All Children)  │                               │                │
│  └────────┬─────────┘                               │                │
│           │                                         │                │
│     ┌─────┼─────────┬──────────────┐               │                │
│     ▼     ▼         ▼              ▼               │                │
│  [Child] [Manage] [History]    [Settings]         │                │
│  [Card]  [Kids]   [View]                          │                │
│     │                                              │                │
│     ▼                                              │                │
│  ┌─────────────────┐                               │                │
│  │  Child Detail   │                               │                │
│  │  (Edit Buckets) │                               │                │
│  └────────┬────────┘                               │                │
│           │                                         │                │
│     ┌─────┴──────────────┐                         │                │
│     ▼                    ▼                         │                │
│  [Add Money]    [Multiply Investment]             │                │
│     │                    │                         │                │
│     │                    ▼                         │                │
│     │           ┌────────────────┐                │                │
│     │           │  Celebration!  │────────────────┘                │
│     │           │  (Animation)   │                                  │
│     │           └────────────────┘                                  │
│     │                                                               │
│     └───────────────────────────────────────────────┘               │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### Child Journey

```
┌─────────────────────────────────────────────────────────────────────┐
│                          CHILD FLOW                                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  [Launch App]                                                        │
│       │                                                              │
│       ▼                                                              │
│  ┌─────────────┐                                                    │
│  │ Who's This? │  ◀── Select child avatar                           │
│  │ (Kid Select)│                                                    │
│  └──────┬──────┘                                                    │
│         │                                                            │
│         ▼                                                            │
│  ┌─────────────┐                                                    │
│  │  Enter PIN  │  ◀── Big number pad, 4 digits                      │
│  │  (4 digits) │                                                    │
│  └──────┬──────┘                                                    │
│         │                                                            │
│         ▼                                                            │
│  ┌─────────────────────────────────────────┐                        │
│  │          KID DASHBOARD                   │                        │
│  │  ┌─────────┐ ┌─────────┐ ┌─────────┐    │                        │
│  │  │  💰     │ │  📈     │ │  ❤️     │    │                        │
│  │  │ $42.00  │ │ $18.50  │ │ $7.25   │    │                        │
│  │  │  Money  │ │ Invest  │ │ Charity │    │                        │
│  │  └────┬────┘ └────┬────┘ └────┬────┘    │                        │
│  └───────│───────────│───────────│─────────┘                        │
│          │           │           │                                   │
│          ▼           ▼           ▼                                   │
│     ┌─────────┐ ┌─────────┐ ┌─────────┐                             │
│     │ Money   │ │ Invest  │ │ Charity │                             │
│     │ Detail  │ │ Detail  │ │ Detail  │                             │
│     │ (View)  │ │ (View)  │ │(+Donate)│                             │
│     └─────────┘ └─────────┘ └────┬────┘                             │
│                                   │                                  │
│                                   ▼                                  │
│                          ┌─────────────────┐                        │
│                          │ Donate Button!  │                        │
│                          │ "Give it all?"  │                        │
│                          └────────┬────────┘                        │
│                                   │                                  │
│                                   ▼                                  │
│                          ┌─────────────────┐                        │
│                          │  🎉 CELEBRATION │                        │
│                          │   "You Gave!"   │                        │
│                          │   (Animation)   │                        │
│                          └─────────────────┘                        │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 3. Kid Mode vs Parent Mode

### Visual Differences

| Aspect | Kid Mode | Parent Mode |
|--------|----------|-------------|
| **Colors** | Bright, playful, high saturation | Calmer, professional, lower saturation |
| **Typography** | Large (32-64px numbers), rounded fonts | Standard (16-24px), clean sans-serif |
| **Icons** | Big emoji-style, animated | Material icons, static |
| **Information density** | Low (3 buckets visible max) | Higher (tables, lists, multiple children) |
| **Touch targets** | 64px minimum | 48px minimum |
| **Animations** | Frequent, celebratory | Subtle, functional |
| **Navigation** | Tap buckets directly | Bottom nav + lists |

### Functional Differences

| Capability | Kid Mode | Parent Mode |
|------------|----------|-------------|
| View buckets | ✅ Own only | ✅ All children |
| Edit bucket amounts | ❌ | ✅ |
| Trigger investment multiply | ❌ | ✅ |
| Donate charity bucket | ✅ | ✅ (on behalf) |
| View transaction history | ✅ Simple | ✅ Detailed |
| Manage family members | ❌ | ✅ |
| Change settings | Avatar only | Full settings |

### Mode Switching

```
┌────────────────────────────────────────────────────────────────┐
│                      MODE SWITCHING                             │
├────────────────────────────────────────────────────────────────┤
│                                                                 │
│  App Launch                                                     │
│      │                                                          │
│      ▼                                                          │
│  ┌──────────────────────────────────────┐                      │
│  │         "WHO'S HERE?"                 │                      │
│  │                                       │                      │
│  │   👧 Emma    👦 Jake    👨 Parent    │                      │
│  │                                       │                      │
│  └──────────────────────────────────────┘                      │
│                                                                 │
│  Kid tap → PIN entry → Kid Dashboard                           │
│  Parent tap → Email/Pass → Parent Dashboard                    │
│                                                                 │
│  ─────────────────────────────────────────────────             │
│                                                                 │
│  From Kid Dashboard:                                            │
│    • Swipe down / tap gear icon → "Are you a parent?"          │
│    • Parent confirms with password → switches to Parent Mode   │
│                                                                 │
│  From Parent Dashboard:                                         │
│    • Tap child avatar → "View as [Child]" option               │
│    • Enters Kid Mode preview (no PIN needed, parent override)  │
│                                                                 │
└────────────────────────────────────────────────────────────────┘
```

**Security:** Parent mode requires Firebase Auth (email/password). Kid mode uses local 4-digit PIN per child stored securely in device keychain.

---

## 4. Design System Tokens

### Color Palette

```dart
// === PRIMARY PALETTE ===
static const Color primary = Color(0xFF6366F1);        // Indigo - trust, growth
static const Color primaryDark = Color(0xFF4F46E5);    // Darker indigo
static const Color primaryLight = Color(0xFFA5B4FC);   // Light indigo

// === SURFACE COLORS ===
static const Color background = Color(0xFFFAFAFC);     // Near white
static const Color surface = Color(0xFFFFFFFF);        // Pure white cards
static const Color surfaceKid = Color(0xFFFFF7ED);     // Warm cream for kid mode

// === BUCKET COLORS (THE HERO COLORS) ===
// Money 💰
static const Color bucketMoney = Color(0xFF22C55E);          // Green
static const Color bucketMoneyLight = Color(0xFFDCFCE7);     // Light green bg
static const Color bucketMoneyDark = Color(0xFF166534);      // Dark green text

// Investments 📈  
static const Color bucketInvest = Color(0xFF3B82F6);         // Blue
static const Color bucketInvestLight = Color(0xFFDBEAFE);    // Light blue bg
static const Color bucketInvestDark = Color(0xFF1E40AF);     // Dark blue text

// Charity ❤️
static const Color bucketCharity = Color(0xFFEC4899);        // Pink
static const Color bucketCharityLight = Color(0xFFFCE7F3);   // Light pink bg
static const Color bucketCharityDark = Color(0xFF9D174D);    // Dark pink text

// === SEMANTIC COLORS ===
static const Color success = Color(0xFF22C55E);        // Green
static const Color warning = Color(0xFFF59E0B);        // Amber
static const Color error = Color(0xFFEF4444);          // Red
static const Color info = Color(0xFF3B82F6);           // Blue

// === TEXT COLORS ===
static const Color textPrimary = Color(0xFF1F2937);    // Near black
static const Color textSecondary = Color(0xFF6B7280);  // Gray
static const Color textMuted = Color(0xFF9CA3AF);      // Light gray
static const Color textOnColor = Color(0xFFFFFFFF);    // White on colored bg

// === KID MODE ACCENT ===
static const Color kidAccent = Color(0xFFFFB800);      // Bright yellow/gold
static const Color kidBackground = Color(0xFFFFF7ED);  // Warm cream
```

### Typography Scale

```dart
// === KID MODE TYPOGRAPHY (Large, Rounded) ===
// Font Family: 'Nunito' (rounded, friendly, highly readable)

// Bucket amounts - THE HERO
static const TextStyle kidBucketAmount = TextStyle(
  fontFamily: 'Nunito',
  fontSize: 48,              // LARGE for visibility
  fontWeight: FontWeight.w800,
  height: 1.1,
);

// Bucket labels
static const TextStyle kidBucketLabel = TextStyle(
  fontFamily: 'Nunito',
  fontSize: 18,
  fontWeight: FontWeight.w600,
  height: 1.3,
);

// Headings (greetings, screens)
static const TextStyle kidHeadingLarge = TextStyle(
  fontFamily: 'Nunito',
  fontSize: 32,
  fontWeight: FontWeight.w700,
  height: 1.2,
);

static const TextStyle kidHeadingMedium = TextStyle(
  fontFamily: 'Nunito',
  fontSize: 24,
  fontWeight: FontWeight.w700,
  height: 1.2,
);

// Body text (simple explanations)
static const TextStyle kidBody = TextStyle(
  fontFamily: 'Nunito',
  fontSize: 18,
  fontWeight: FontWeight.w500,
  height: 1.5,
);

// === PARENT MODE TYPOGRAPHY (Clean, Professional) ===
// Font Family: 'Inter' (modern, readable, professional)

static const TextStyle parentHeadingLarge = TextStyle(
  fontFamily: 'Inter',
  fontSize: 24,
  fontWeight: FontWeight.w600,
  height: 1.3,
);

static const TextStyle parentHeadingMedium = TextStyle(
  fontFamily: 'Inter',
  fontSize: 20,
  fontWeight: FontWeight.w600,
  height: 1.3,
);

static const TextStyle parentBody = TextStyle(
  fontFamily: 'Inter',
  fontSize: 16,
  fontWeight: FontWeight.w400,
  height: 1.5,
);

static const TextStyle parentBodySmall = TextStyle(
  fontFamily: 'Inter',
  fontSize: 14,
  fontWeight: FontWeight.w400,
  height: 1.5,
);

static const TextStyle parentLabel = TextStyle(
  fontFamily: 'Inter',
  fontSize: 12,
  fontWeight: FontWeight.w500,
  letterSpacing: 0.5,
  height: 1.4,
);

// Amount in parent mode (smaller than kid mode)
static const TextStyle parentAmount = TextStyle(
  fontFamily: 'Inter',
  fontSize: 28,
  fontWeight: FontWeight.w700,
  height: 1.2,
);
```

### Spacing Scale

```dart
// === SPACING TOKENS (8px base grid) ===
class Spacing {
  static const double xs = 4;     // Tight gaps
  static const double sm = 8;     // Small gaps
  static const double md = 16;    // Standard gaps
  static const double lg = 24;    // Section gaps
  static const double xl = 32;    // Large section gaps
  static const double xxl = 48;   // Screen padding (kid mode)
  static const double xxxl = 64;  // Hero spacing
}

// === KID MODE SPECIFIC ===
class KidSpacing {
  static const double screenPadding = 24;
  static const double bucketGap = 16;
  static const double cardPadding = 24;
  static const double touchTargetMin = 64;  // Larger for kids
}

// === PARENT MODE SPECIFIC ===
class ParentSpacing {
  static const double screenPadding = 16;
  static const double cardPadding = 16;
  static const double listItemHeight = 72;
  static const double touchTargetMin = 48;  // Standard Material
}
```

### Border Radius / Shape System

```dart
// === BORDER RADIUS TOKENS ===
class Radii {
  static const double none = 0;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double full = 999;  // Pill shape
}

// === SHAPE SYSTEM ===

// Kid Mode: Rounded, playful
class KidShapes {
  static const RoundedRectangleBorder bucketCard = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(24)),
  );
  static const RoundedRectangleBorder button = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(16)),
  );
  static const CircleBorder avatar = CircleBorder();
}

// Parent Mode: Subtle curves
class ParentShapes {
  static const RoundedRectangleBorder card = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );
  static const RoundedRectangleBorder button = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(8)),
  );
  static const RoundedRectangleBorder chip = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(16)),
  );
}

// === ELEVATION ===
class Elevation {
  static const double none = 0;
  static const double card = 2;
  static const double raised = 4;
  static const double modal = 8;
  static const double overlay = 16;
}
```

---

## 5. Key Screen Wireframes

### Kid Dashboard

```
┌─────────────────────────────────────────────────────────────┐
│                                                     ⚙️      │
│                                                             │
│              👋 Hi Emma!                                    │
│                                                             │
│   ┌───────────────────────────────────────────────────┐    │
│   │                                                   │    │
│   │            💰                                     │    │
│   │                                                   │    │
│   │          $42.00                                   │    │
│   │                                                   │    │
│   │          My Money                                 │    │
│   │                                                   │    │
│   └───────────────────────────────────────────────────┘    │
│                                                             │
│   ┌──────────────────────┐  ┌──────────────────────┐       │
│   │                      │  │                      │       │
│   │        📈            │  │         ❤️           │       │
│   │                      │  │                      │       │
│   │      $18.50          │  │       $7.25          │       │
│   │                      │  │                      │       │
│   │    Investments       │  │      Charity         │       │
│   │                      │  │                      │       │
│   └──────────────────────┘  └──────────────────────┘       │
│                                                             │
│                                                             │
│                                                             │
│                        🏠                                   │
│                       Home                                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘

NOTES:
- Money bucket is LARGEST (most common interaction)
- Investment and Charity side-by-side below
- Tapping any bucket opens detail view
- Emoji icons serve as visual anchors (no reading needed)
- Numbers are HUGE (48px+) for easy reading
- Warm cream background, rounded cards
- Single bottom icon = home anchor (no complex nav)
```

### Parent Dashboard

```
┌─────────────────────────────────────────────────────────────┐
│  KidsFinance                                       👤       │
│  ─────────────────────────────────────────────────────      │
│                                                             │
│  Your Family: The Smiths                                    │
│                                                             │
│  ┌───────────────────────────────────────────────────┐     │
│  │ 👧 Emma                                      ▶    │     │
│  │    ─────────────────────────────────────────      │     │
│  │    💰 $42.00    📈 $18.50    ❤️ $7.25            │     │
│  │         ▲ +$5 today                               │     │
│  └───────────────────────────────────────────────────┘     │
│                                                             │
│  ┌───────────────────────────────────────────────────┐     │
│  │ 👦 Jake                                      ▶    │     │
│  │    ─────────────────────────────────────────      │     │
│  │    💰 $28.75    📈 $12.00    ❤️ $3.50            │     │
│  │                                                   │     │
│  └───────────────────────────────────────────────────┘     │
│                                                             │
│  ┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐     │
│                                                             │
│  │              + Add Another Child                  │     │
│                                                             │
│  └ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┘     │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│   🏠        👨‍👩‍👧‍👦        📜        ⚙️                        │
│  Home      Family     History   Settings                   │
└─────────────────────────────────────────────────────────────┘

NOTES:
- Clean white background
- Each child is a tappable card
- All three buckets visible at a glance per child
- Activity indicator shows recent changes
- Bottom navigation for main sections
- Tapping child card → Child Detail View
```

### Investment Multiply Screen

```
┌─────────────────────────────────────────────────────────────┐
│  ←  Multiply Investment                                     │
│  ─────────────────────────────────────────────────────      │
│                                                             │
│              👧 Emma's Investments                          │
│                                                             │
│                      📈                                     │
│                                                             │
│                   Current                                   │
│                  ─────────                                  │
│                   $18.50                                    │
│                                                             │
│  ┌───────────────────────────────────────────────────┐     │
│  │                                                   │     │
│  │    Multiply by:                                   │     │
│  │                                                   │     │
│  │    ○ 1.5x  →  $27.75                             │     │
│  │    ● 2x    →  $37.00   ✨ DOUBLE!                │     │
│  │    ○ 3x    →  $55.50                             │     │
│  │    ○ Custom: [____]                              │     │
│  │                                                   │     │
│  └───────────────────────────────────────────────────┘     │
│                                                             │
│  ┌───────────────────────────────────────────────────┐     │
│  │                                                   │     │
│  │  "Emma did great this week! Multiplying her      │     │
│  │   investment teaches the power of growth."       │     │
│  │                                                   │     │
│  │   [  Optional note for Emma  ]                   │     │
│  │                                                   │     │
│  └───────────────────────────────────────────────────┘     │
│                                                             │
│  ┌───────────────────────────────────────────────────┐     │
│  │                                                   │     │
│  │             🚀 MULTIPLY NOW                       │     │
│  │                                                   │     │
│  └───────────────────────────────────────────────────┘     │
│                                                             │
└─────────────────────────────────────────────────────────────┘

NOTES:
- Shows current investment amount prominently
- Radio buttons for quick multiplier selection
- Live preview of new amount
- Optional note field (shows in kid's celebration)
- Big, satisfying "Multiply Now" button
- Parent sees educational message
```

### Charity Donate Screen (Kid Action)

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                                                             │
│                          ❤️                                 │
│                                                             │
│                   Your Charity                              │
│                   ────────────                              │
│                                                             │
│                      $7.25                                  │
│                                                             │
│                                                             │
│   ┌───────────────────────────────────────────────────┐    │
│   │                                                   │    │
│   │   🎁 Ready to give your charity money?           │    │
│   │                                                   │    │
│   │   When you donate, this money goes to help       │    │
│   │   people who need it!                            │    │
│   │                                                   │    │
│   │           ───────────────────────                │    │
│   │                                                   │    │
│   │   You've donated 2 times before.                 │    │
│   │   Total given: $15.50 🌟                         │    │
│   │                                                   │    │
│   └───────────────────────────────────────────────────┘    │
│                                                             │
│                                                             │
│   ┌───────────────────────────────────────────────────┐    │
│   │                                                   │    │
│   │              💝 DONATE ALL $7.25                  │    │
│   │                                                   │    │
│   └───────────────────────────────────────────────────┘    │
│                                                             │
│                                                             │
│                    Maybe Later                              │
│                                                             │
└─────────────────────────────────────────────────────────────┘

CONFIRMATION DIALOG (after tap):
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│                          ❤️                                 │
│                                                             │
│                   Are you sure?                             │
│                                                             │
│        You're about to donate all $7.25!                   │
│        This will reset your charity bucket.                 │
│                                                             │
│   ┌────────────────────┐   ┌────────────────────┐          │
│   │     Go Back        │   │   💝 Yes, Donate!  │          │
│   └────────────────────┘   └────────────────────┘          │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 6. Animation Moments

### 1. Investment Multiply Celebration 🚀

**Trigger:** Parent multiplies a child's investment bucket  
**Duration:** 3-4 seconds  
**Seen by:** Child (next time they open app or immediately if viewing)

```
ANIMATION SEQUENCE:

Frame 1 (0.0s - 0.3s): ANTICIPATION
┌─────────────────────────────┐
│                             │
│           📈                │
│         $18.50              │
│                             │
│     (number wiggles)        │
│                             │
└─────────────────────────────┘
- Slight scale pulse on amount
- Subtle glow begins around number

Frame 2 (0.3s - 1.2s): THE MULTIPLY
┌─────────────────────────────┐
│      ✨  ✨  ✨  ✨          │
│   ✨                 ✨     │
│        📈  → → →  📈📈     │
│   ✨   $18.50               │
│           ↓                 │
│   ✨   $37.00!  ✨          │
│      ✨  ✨  ✨  ✨          │
└─────────────────────────────┘
- Number rapidly counts up ($18.50 → $37.00)
- Stars/sparkles burst outward
- Icon duplicates and merges
- Screen briefly flashes gold

Frame 3 (1.2s - 2.5s): CELEBRATION
┌─────────────────────────────┐
│   🎉  🌟  ✨  🎉  🌟       │
│                             │
│     YOUR INVESTMENT         │
│       DOUBLED! 🚀           │
│                             │
│        $37.00               │
│                             │
│   (confetti raining down)   │
│                             │
│   🎉  🌟  ✨  🎉  🌟       │
└─────────────────────────────┘
- Confetti particles rain from top
- "DOUBLED!" text bounces in
- Haptic feedback (medium impact)

Frame 4 (2.5s - 3.5s): PARENT MESSAGE
┌─────────────────────────────┐
│                             │
│        $37.00  📈           │
│                             │
│   ┌─────────────────────┐   │
│   │  💬 From Mom:       │   │
│   │  "Great job saving  │   │
│   │   this week!"       │   │
│   └─────────────────────┘   │
│                             │
│      [ Awesome! ]           │
│                             │
└─────────────────────────────┘
- Message card fades in from bottom
- Dismiss button appears
- Tapping dismisses to updated dashboard
```

**Implementation Notes:**
- Use `flutter_animate` for sequencing
- Confetti via `confetti` package
- Count-up animation via `AnimatedSwitcher` with custom tween
- Store "unseen celebration" flag in Firestore, show on next child login

---

### 2. Charity Donation Celebration 💝

**Trigger:** Child confirms donation of their charity bucket  
**Duration:** 4-5 seconds  
**Seen by:** Child (immediately) and Parent (notification)

```
ANIMATION SEQUENCE:

Frame 1 (0.0s - 0.5s): THE GIVING
┌─────────────────────────────┐
│                             │
│           ❤️                │
│         $7.25               │
│           │                 │
│           │                 │
│           ▼                 │
│          🌍                 │
│                             │
└─────────────────────────────┘
- Heart icon floats upward
- Money amount shrinks and follows heart
- Globe/world icon appears at bottom

Frame 2 (0.5s - 1.5s): HEARTS BURST
┌─────────────────────────────┐
│   ❤️ 💕 💗 ❤️ 💕 💗 ❤️     │
│  💕                    💗   │
│ 💗       🌟 🌟 🌟      💕   │
│  ❤️                   ❤️   │
│         💝                  │
│  💕      YOU GAVE!    💗    │
│ 💗                    💕    │
│   ❤️ 💕 💗 ❤️ 💕 💗 ❤️     │
└─────────────────────────────┘
- Multiple hearts burst outward from center
- Background briefly turns soft pink
- "YOU GAVE!" bounces in with scale animation

Frame 3 (1.5s - 3.0s): IMPACT VISUALIZATION
┌─────────────────────────────┐
│                             │
│      🌟 You helped! 🌟      │
│                             │
│   ┌─────────────────────┐   │
│   │  😊  😊  😊  😊  😊  │   │
│   │                     │   │
│   │  5 smiles created!  │   │
│   └─────────────────────┘   │
│                             │
│    Your total giving:       │
│       $22.75 🏆             │
│                             │
└─────────────────────────────┘
- Smiley faces pop in one by one
- Count equals rough "impact" (amount / $1.50)
- Running total of all donations shown
- Trophy icon if milestone reached

Frame 4 (3.0s - 4.5s): RESOLUTION
┌─────────────────────────────┐
│                             │
│     🌟 AMAZING GIVER 🌟     │
│                             │
│           ❤️                │
│         $0.00               │
│      Ready to grow!         │
│                             │
│                             │
│      [ Back Home ]          │
│                             │
└─────────────────────────────┘
- Charity bucket shows $0.00 (reset)
- Encouraging message about growing it again
- Haptic feedback (success pattern)
- Dismiss returns to dashboard
```

**Implementation Notes:**
- Heart particles via `particles_flutter` or custom painter
- Sound effect: gentle "ding" or chime
- Transaction logged to Firestore with timestamp
- Parent gets push notification: "Emma donated $7.25! 💝"

---

### 3. New Money Added Celebration 💰

**Trigger:** Parent adds money to a child's Money bucket  
**Duration:** 2-3 seconds  
**Seen by:** Child (next open or immediately)

```
ANIMATION SEQUENCE:

Frame 1 (0.0s - 0.3s): COIN DROP ANTICIPATION
┌─────────────────────────────┐
│           🪙                │
│            ↓                │
│                             │
│           💰                │
│         $42.00              │
│                             │
└─────────────────────────────┘
- Coin icon drops from top
- Slight bounce physics

Frame 2 (0.3s - 1.0s): COIN SPLASH
┌─────────────────────────────┐
│                             │
│     ✨  💰  ✨               │
│        CLINK!               │
│                             │
│    $42.00 → $52.00         │
│         +$10.00             │
│                             │
│     ✨      ✨               │
└─────────────────────────────┘
- Coin "splashes" into bucket
- Amount counts up smoothly
- Green "+$10.00" shows increment
- Small sparkle burst

Frame 3 (1.0s - 2.0s): SETTLED
┌─────────────────────────────┐
│                             │
│           💰                │
│                             │
│        $52.00               │
│                             │
│     💬 "Allowance day!"     │
│                             │
│                             │
└─────────────────────────────┘
- Final amount settles with slight bounce
- Optional parent note fades in
- Auto-dismisses after 2s or on tap
```

**Implementation Notes:**
- Simpler than investment multiply (happens more frequently)
- Coin physics via `spring_animation` 
- Sound: satisfying "coin clink"
- Less intrusive — doesn't take over full screen

---

## 7. Accessibility Considerations

### Touch Targets
- Kid mode: Minimum 64x64dp (larger fingers, less precision)
- Parent mode: Minimum 48x48dp (Material standard)

### Color Contrast
- All text meets WCAG AA (4.5:1 for normal, 3:1 for large)
- Bucket colors chosen to be distinguishable for colorblind users
- Icons + text labels always paired (not color-only meaning)

### Text Scaling
- All text respects system font scaling
- Layout remains functional up to 200% text scale
- Numbers in buckets use `FittedBox` to scale down if needed

### Motion
- Respect `MediaQuery.disableAnimations`
- Provide reduced motion alternative for celebrations
- Animations under 5 seconds (prevent vestibular triggers)

---

## 8. Implementation Priority

### Phase 1: Core Screens
1. Kid Login (PIN entry)
2. Kid Dashboard (3 buckets)
3. Parent Login (Firebase Auth)
4. Parent Dashboard (child list)
5. Child Detail View (parent editing)

### Phase 2: Actions
6. Add Money modal
7. Multiply Investment screen
8. Charity Donate flow

### Phase 3: Celebrations
9. Investment multiply animation
10. Donation celebration animation
11. Money added animation

### Phase 4: Management
12. Family setup onboarding
13. Manage children
14. Manage parents
15. Transaction history
16. Settings screens

---

*This specification is the authoritative design reference for the KidsFinance app. All implementation should follow these patterns, tokens, and flows.*
