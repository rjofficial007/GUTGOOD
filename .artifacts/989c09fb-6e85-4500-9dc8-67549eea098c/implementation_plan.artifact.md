# Implementation Plan - Standardize Insight Screens UI/UX

This plan aims to standardize the UI/UX across all insight-related screens to match the style established in `insights_screen.dart`.

## User Review Required

> [!IMPORTANT]
> This will change the background colors and layout structures of several screens to ensure consistency. The "Bento-style" cards and `GutSliverAppBar` will be the primary components used.

## Proposed Changes

### [Insights Feature]

#### [MODIFY] [weekly_recap_screen.dart](file:///D:/Github/GUTGOOD/lib/features/insights/presentation/pages/weekly_recap_screen.dart)
- Update `Scaffold` background to `context.appColorScheme.cardBackground`.
- Standardize padding and section spacing.
- Ensure consistent use of `DashboardEntrance` animations.
- Use `context.appColorScheme` instead of `Theme.of(context).colorScheme` where appropriate.

#### [MODIFY] [insights_history_screen.dart](file:///D:/Github/GUTGOOD/lib/features/insights/presentation/pages/insights_history_screen.dart)
- Update `_HistoryEmpty` to match the visual style of `_NoInsightsState` from `insights_screen.dart` (centered circle icon, specific typography).
- Ensure consistent sliver structure and padding.

#### [MODIFY] [pattern_detail_screen.dart](file:///D:/Github/GUTGOOD/lib/features/insights/presentation/pages/pattern_detail_screen.dart)
- Minor style tweaks to ensure it perfectly aligns with the `insights_screen.dart` color palette and spacing.
- Ensure `GutSliverAppBar` is used correctly.

#### [MODIFY] [smart_insight_detail_screen.dart](file:///D:/Github/GUTGOOD/lib/features/insights/presentation/pages/smart_insight_detail_screen.dart)
- Consistency pass for background colors and spacing.

## Verification Plan

### Automated Tests
- Run existing UI tests for insights (if any).
- Check for overflow issues on smaller screens.

### Manual Verification
- Manually navigate through all insight screens (Live Insights, History, Weekly Recap, Pattern Details, Smart Insight Details) on the device to verify visual consistency.
- Verify that animations (`DashboardEntrance`) feel cohesive.
