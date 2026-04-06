# Core Widget Library

This directory contains the foundational UI components for KidsFinance, implementing dual-mode design (Kid Mode vs Parent Mode) with Material 3 styling.

## Widgets

### BucketCard
Display a financial bucket (Money/Investment/Charity) with balance.
- **Kid Mode:** Large emoji (64px), gradient background, animated entry
- **Parent Mode:** Compact layout, bordered card, horizontal layout
- **Colors:** Semantic bucket colors (green/blue/pink)
- **Usage:** Dashboard bucket displays, bucket selection

### PinInputWidget
4-digit PIN entry with visual feedback and numpad.
- **Features:** Dot indicators, 3×4 numpad, error display, lock state
- **Touch Targets:** 70dp buttons (exceeds Kid Mode 64dp minimum)
- **Usage:** Child login screen

### ChildAvatar
Emoji-based avatar with configurable size.
- **Sizes:** Small (40dp), Medium (56dp), Large (80dp)
- **Features:** Selection state, name display, tap handling
- **Usage:** Child selection, profile headers, lists

### LoadingOverlay
Centered loading indicator with optional message.
- **Usage:** Data fetch states, async operations

### ErrorDisplay
Error state display with retry capability.
- **Features:** Error icon, message text, optional retry button
- **Usage:** Error boundaries, failed data loads

### AmountInputDialog
Numeric input dialog for money amounts or multipliers.
- **Modes:** Currency ($) or Multiplier (×)
- **Validation:** Real-time with error messages
- **Usage:** Parent actions (Set Money, Multiply Investment)

## Usage

Import all widgets via the barrel export:

```dart
import 'package:kids_finance/core/widgets/widgets.dart';
```

Or import individually:

```dart
import 'package:kids_finance/core/widgets/bucket_card.dart';
```

## Design Principles

1. **Dual Mode:** All user-facing widgets adapt to Kid vs Parent mode
2. **Accessibility:** 64dp touch targets (Kid), 48dp (Parent), colorblind-safe palette
3. **Material 3:** Follows Material Design 3 guidelines
4. **No Business Logic:** Widgets receive data, don't fetch it
5. **Const Constructors:** Use const where possible for performance

## Dependencies

- `flutter_animate`: Animations (BucketCard)
- `intl`: Currency formatting
- `google_fonts`: Nunito (Kid) / Inter (Parent) fonts

## Quality

- ✅ Zero flutter analyze issues
- ✅ Colorblind accessible (tested)
- ✅ Touch target compliant
- ✅ Material 3 compliant

## Next Steps

- Add widget tests (Rhodey)
- Implement celebration animations (Pepper)
- Integrate into screens (Stark)
