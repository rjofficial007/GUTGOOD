# Use PatternGrid in Insights Screen

This plan details the steps to make `_PatternGrid` public and reusable, and then integrate it into the `InsightsScreen` (specifically within the `InsightBentoFeed` or as a standalone section) to provide a more visual and data-dense representation of detected patterns.

## User Review Required

> [!IMPORTANT]
> The `_PatternGrid` and `_PatternCard` widgets use a different visual style (mini charts, specific background tones) compared to the standard `BentoCard` used in the rest of the Insights feed. This will add visual variety but may slightly deviate from the strict "Bento" card layout currently in place.

## Proposed Changes

### Insights Feature

#### [NEW] [pattern_grid.dart](file:///D:/Github/GUTGOOD/lib/features/insights/presentation/widgets/pattern_grid.dart)
Create a new file to house the `PatternGrid` and its supporting widgets (`PatternCard`, `MiniChart`, and painters). This makes them accessible across the `insights` feature.

#### [MODIFY] [patterns_screen.dart](file:///D:/Github/GUTGOOD/lib/features/insights/presentation/pages/patterns_screen.dart)
- Remove the private implementations of `_PatternGrid`, `_PatternCard`, `_MiniChart`, `_BarPainter`, and `_LinePainter`.
- Import and use the new `PatternGrid` widget.

#### [MODIFY] [insight_bento_feed.dart](file:///D:/Github/GUTGOOD/lib/features/insights/presentation/widgets/bento/insight_bento_feed.dart)
- Import `pattern_grid.dart`.
- Refactor the `_tiles` method to replace (or augment) the current pattern `BentoCard` tiles with a single `BentoTile` containing the `PatternGrid`. This will allow showing more patterns in a compact grid with mini-charts directly in the main feed.

## Verification Plan

### Manual Verification
- Open the **Insights** tab and verify the patterns are now displayed using the `PatternGrid` style (with mini charts).
- Tap on a pattern in the grid to ensure it still navigates correctly to the pattern detail screen.
- Open the **Patterns** screen (via the "See All" button or direct navigation) and verify it still looks and functions as before.
