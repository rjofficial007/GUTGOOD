# Update Primary Goal and Watch List Cards to SuperCard Style

The goal is to update the UI/UX of the "Primary Goal" and "Watch List" cards in the Insight Dashboard to match the aesthetic of the `SuperCard` components (dark gradients, radius 22, thin borders, specific typography).

## Proposed Changes

### Core Widgets

#### [MODIFY] [super_card.dart](file:///D:/Github/GUTGOOD/lib/core/widgets/super_card.dart)
- Add `SuperPhysicalGoalCard` which implements the high-polish style seen in other SuperCards.
- It will feature a dark gradient background, radius 22, a subtle background icon, and specific typography for title and subtitle.

### Insights Feature

#### [MODIFY] [insight_dashboard_view.dart](file:///D:/Github/GUTGOOD/lib/features/insights/presentation/widgets/insight_dashboard_view.dart)
- Replace `PhysicalGoalCard` usage with `SuperPhysicalGoalCard`.
- Remove the local `PhysicalGoalCard` class definition as it's no longer used and its logic is now in `super_card.dart`.

## Verification Plan

### Manual Verification
- Inspect the Insight Dashboard to ensure the "PRIMARY GOAL" and "WATCH LIST" cards now match the "SUPER GUT SCORE" and "AUTOPILOT RECAP" cards in terms of border radius, background, and overall feel.
- Verify that the colors (Blue for Primary Goal, Pink for Watch List) are correctly applied as accents.
