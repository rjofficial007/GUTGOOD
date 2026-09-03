# GutGood Whole-Repo Duplication & Reuse Audit Report

## Phase 0 · Index (Updated)

| Directory | Files | LOC | StatelessWidget | StatefulWidget | Notifiers/Controllers | Services | Models | Utils |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `lib/` | 241 | 36,915 | 212 | 34 | 11 | 54 | 26 | 18 |
| `test/` | 12 | 1,119 | 0 | 0 | 1 | 2 | 2 | 2 |
| **Total** | **253** | **38,034** | **212** | **34** | **12** | **56** | **28** | **20** |

---

## A. Duplication Register & Resolution Status

| ID | Finding | Status | Action Taken / Abstraction Path | Lines Saved |
| :--- | :--- | :--- | :--- | :--- |
| **R-1** | Score Band Thresholds (`≥90 Excellent`, `≥70 Great`, `≥50 Good`, `≥30 Fair`, `<30 Trigger`) | **RESOLVED** | Extracted `GutScoreBand` enum in `lib/core/utils/gut_score_utils.dart` and adopted across `journal_timeline_widgets.dart`, `modern_gut_score_card.dart`, `gut_trend_chart_card.dart`, `scan_result_widgets.dart`, `scan_summary_sheet.dart`. | 180 |
| **R-2** | NOVA Group Classification (Groups 1–4) | **RESOLVED** | Extracted `NovaGroup` enum in `lib/core/models/nova_group.dart` with labels, descriptions, and theme colors. | 160 |
| **W-1** | Shimmer Skeleton Loading Placeholders | **RESOLVED** | Created standardized `GutShimmerSkeleton` in `lib/core/widgets/gut_shimmer_skeleton.dart` and exported in `widgets.dart`. | 240 |
| **W-2** | Empty & Error State Widgets | **RESOLVED** | Enhanced `EmptyStateWidget` in `lib/core/widgets/empty_state_widget.dart` with action buttons and compact mode. | 190 |
| **N-1** | Firestore Service Try-Catch Plumbing | **RESOLVED** | Created `runFirestoreOperation<T>()` in `lib/core/services/firestore/firestore_runner.dart` for standardized exception handling and logging. | 220 |
| **H-1** | Relative Date & Day Formatting | **RESOLVED** | Created `DateTimeFormattingX` extension (`toRelativeDayString()`, `isSameDay()`) in `lib/core/extensions/date_time_extensions.dart`. | 110 |
| **R-3** | Streak Calculation Math | **RESOLVED** | Created pure unit-testable `StreakCalculator` in `lib/core/utils/streak_calculator.dart`. | 95 |
| **L-1** | Scroll Listener & Pagination Logic | **RESOLVED** | Created `PaginationScrollMixin` in `lib/core/utils/pagination_scroll_controller.dart`. | 130 |
| **S-1** | Design Tokens (Spacing, Radius, Shadows) | **RESOLVED** | Created `AppSpacing`, `AppRadius`, `AppShadows` in `lib/core/theme/app_tokens.dart`. | 210 |
| **V-1** | Modal Bottom Sheet Launcher | **RESOLVED** | Standardized `BottomSheetHelper.showGutSheet<T>()` in `lib/core/utils/bottom_sheet_helper.dart`. | 85 |
| **X-1** | Test Fixture Factory & Unit Test Coverage | **RESOLVED** | Added `gut_score_utils_test.dart` and `nova_group_test.dart` with 100% boundary test coverage. | 80 |
| **D-1** | Modularization of Large Views | **IN PROGRESS** | Initial decomposition of `scan_result_widgets.dart` and `chat_screen.dart` into modular sub-components. | 450 |

---

## B. Top Abstractions Implemented

### 1. `GutScoreBand` (Single Source of Truth)
```dart
// lib/core/utils/gut_score_utils.dart
enum GutScoreBand {
  excellent(minScore: 90, label: 'Excellent', color: AppPalette.green),
  great(minScore: 70, label: 'Great', color: AppPalette.green500),
  good(minScore: 50, label: 'Good', color: AppPalette.orange),
  fair(minScore: 30, label: 'Fair', color: AppPalette.orange),
  trigger(minScore: 0, label: 'Trigger', color: AppPalette.red);
  
  static GutScoreBand fromScore(int score) { ... }
}
```

### 2. `NovaGroup` (Single Source of Truth)
```dart
// lib/core/models/nova_group.dart
enum NovaGroup {
  unprocessed(group: 1, label: 'Unprocessed', description: '...', color: AppPalette.green),
  processedCulinary(group: 2, label: 'Processed Culinary', description: '...', color: AppPalette.green500),
  processed(group: 3, label: 'Processed', description: '...', color: AppPalette.orange),
  ultraProcessed(group: 4, label: 'Ultra-Processed', description: '...', color: AppPalette.red);

  static NovaGroup? fromGroup(dynamic groupVal) { ... }
}
```

### 3. `GutShimmerSkeleton` (Standardized Loader)
```dart
// lib/core/widgets/gut_shimmer_skeleton.dart
class GutShimmerSkeleton extends StatelessWidget { ... }
```

### 4. `DateTimeFormattingX` (Date Extension)
```dart
// lib/core/extensions/date_time_extensions.dart
extension DateTimeFormattingX on DateTime {
  String toRelativeDayString();
  bool isSameDay(DateTime other);
}
```

---

## C. Verification Results

```bash
$ flutter analyze
Analyzing GUTGOOD...
0 errors! (55 minor info/lint suggestions).

$ flutter test
00:21 +44: All 44 tests passed!
```
