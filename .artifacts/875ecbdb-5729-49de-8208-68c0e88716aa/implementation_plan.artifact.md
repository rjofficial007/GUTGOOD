# Replace Insight Bottom Sheets with Full Screens

Transform the `InsightDetailSheet` into a full-page `InsightDetailScreen` to provide a more immersive "Report" experience. This screen will feature a prominent hero section at the top, mimicking the `GutSnapshotHeroCard` style, followed by the detailed analysis dashboards.

## User Review Required

> [!IMPORTANT]
> I will replace the `InsightDetailSheet` (currently a bottom sheet shown in History) with a full screen.
>
> **Hero Section**: The top of the new screen will look like the `GutSnapshotHeroCard` but with the specific historical data from the selected insight.

## Proposed Changes

### Features: Insights (Pages)

#### [NEW] [insight_detail_screen.dart](file:///D:/Github/GUTGOOD/lib/features/insights/presentation/pages/insight_detail_screen.dart)
- Create a new screen that replicates the logic of `InsightDetailSheet` but in a full Scaffold.
- **Top Section**: A large, card-styled hero containing the `GutScoreGauge`, `GutTrendSparkline`, and score difference, matching the `GutSnapshotHeroCard` aesthetic.
- **Dashboard Sections**: Staggered animated cards for **Trends**, **Stats**, and **Reactions**.

#### [MODIFY] [app_router.dart](file:///D:/Github/GUTGOOD/lib/core/router/app_router.dart)
- Register the `/insight-detail` route.
- Pass the `AIInsight` object via `extra`.

#### [MODIFY] [insights_history_screen.dart](file:///D:/Github/GUTGOOD/lib/features/insights/presentation/pages/insights_history_screen.dart)
- Update `_showInsightDetail` to use `context.push('/insight-detail', extra: insight)` instead of `showModalBottomSheet`.

### Cleanup

#### [DELETE] [insight_detail_sheet.dart](file:///D:/Github/GUTGOOD/lib/features/insights/presentation/widgets/insight_detail_sheet.dart)
- Once the screen is functional, the sheet widget will be removed.

## Verification Plan

### Manual Verification
- Navigate to **Insight History**.
- Tap on an historical insight.
- Verify that it opens as a full-page report instead of a bottom sheet.
- Confirm the top "Snapshot" area matches the requested high-fidelity style.
- Check that all staggered animations work correctly in the new screen context.
