# Implementation Plan - Strengthening Insights Domain Layer

This plan outlines the refactoring of the Insights feature to introduce a UseCase layer. This will decouple complex business logic (journaling, threshold checks, orchestration) from the Repository implementation, improving testability and adhering to Clean Architecture principles.

## User Review Required

> [!IMPORTANT]
> This is a structural refactoring. While no business logic changes are intended, the way `InsightsNotifier` triggers generation will change from calling the Repository directly to calling a new `GenerateInsightUseCase`.

## Proposed Changes

### Insights Feature - Domain Layer

#### [NEW] [check_insight_threshold_usecase.dart](file:///D:/Github/GUTGOOD/lib/features/insights/domain/usecases/check_insight_threshold_usecase.dart)
- Pure business logic to verify if the user has reached the minimum data threshold (3 scans OR 3 meals + 1 symptom).

#### [NEW] [build_unified_journal_usecase.dart](file:///D:/Github/GUTGOOD/lib/features/insights/domain/usecases/build_unified_journal_usecase.dart)
- Logic for interleaving different event types (ATE, FEELING, SCANNED) into a chronologically sorted text journal for the AI.

#### [NEW] [generate_insight_usecase.dart](file:///D:/Github/GUTGOOD/lib/features/insights/domain/usecases/generate_insight_usecase.dart)
- The primary orchestrator. It will:
    - Check the 24-hour frequency rule.
    - Check the data threshold using `CheckInsightThresholdUseCase`.
    - Fetch raw data via the Repository.
    - Build the journal using `BuildUnifiedJournalUseCase`.
    - Request the AI analysis.
    - Handle side effects (saving results, updating profile score, creating health alerts).

#### [MODIFY] [insight_repository.dart](file:///D:/Github/GUTGOOD/lib/features/insights/domain/repositories/insight_repository.dart)
- Refine the interface. The repository should focus on data fetching and the raw AI call, while `generateNewInsight` might be removed or simplified if fully moved to a UseCase. *Decision: I will keep a simplified `generateRawInsight` in the repository and move orchestration to the UseCase.*

---

### Insights Feature - Data Layer

#### [MODIFY] [insight_repository_impl.dart](file:///D:/Github/GUTGOOD/lib/features/insights/data/repositories/insight_repository_impl.dart)
- Remove orchestration logic.
- Remove hardcoded prompt construction (moved to UseCase or Service).
- Focus on `Firestore` and `AiService` interactions.

---

### Insights Feature - Presentation Layer

#### [MODIFY] [insights_notifier.dart](file:///D:/Github/GUTGOOD/lib/features/insights/presentation/providers/insights_notifier.dart)
- Update to use `GenerateInsightUseCase` instead of `InsightRepository.generateNewInsight()`.

---

### Core / DI

#### [MODIFY] [usecase_di.dart](file:///D:/Github/GUTGOOD/lib/core/di/usecase_di.dart)
- Register the three new UseCases.

---

## Verification Plan

### Automated Tests
- I will verify the `BuildUnifiedJournalUseCase` with different input sets to ensure chronological sorting is preserved.
- I will verify `CheckInsightThresholdUseCase` with boundary conditions (e.g., 2 scans, 3 meals but 0 symptoms).

### Manual Verification
- Trigger an insight generation from the UI and verify that the "Gut Score" and "Insights" update correctly in the dashboard.
- Check `Logcat` for `AppLogger.insights` output to confirm the journal is still being built correctly.
