# Offline-First Reliable Streak System

Simplify and centralize the GutGood streak tracking to be offline-first, reliable, and based strictly on active calendar days.

## User Review Required

> [!IMPORTANT]
> The streak source of truth is moving from Server-Authoritative to **Local-First with Cloud Sync**. This ensures users see their streak increase immediately even without internet.

## Proposed Changes

### Centralized Streak Service

#### [NEW] [streak_service.dart](file:///D:/Github/GUTGOOD/lib/core/services/streak_service.dart)
- Create a `StreakService` that handles local calculation and persistence using `SharedPreferences`.
- Implement the "one credit per calendar day" logic.
- Support merging remote Firestore data without overwriting "newer" local activity.

### Repositories (Activity Triggers)

#### [MODIFY] [chat_repository_impl.dart](file:///D:/Github/GUTGOOD/lib/features/chat/data/repositories/chat_repository_impl.dart)
- Call `streakService.markActivityToday()` when a user message is saved.

#### [MODIFY] [scanner_repository_impl.dart](file:///D:/Github/GUTGOOD/lib/features/scanner/data/repositories/scanner_repository_impl.dart)
- Call `streakService.markActivityToday()` when a scan result is saved.

#### [MODIFY] [log_repository_impl.dart](file:///D:/Github/GUTGOOD/lib/features/logs/data/repositories/log_repository_impl.dart)
- Call `streakService.markActivityToday()` when a meal or symptom is logged.

### State Management & UI

#### [MODIFY] [profile_provider.dart](file:///D:/Github/GUTGOOD/lib/features/profile/presentation/providers/profile_provider.dart)
- Inject `StreakService`.
- Forward cloud profile updates to `streakService.syncWithRemote()`.
- Expose local streak state to the UI for zero-latency feedback.

#### [MODIFY] [user_profile.dart](file:///D:/Github/GUTGOOD/lib/core/models/user_profile.dart)
- Preserve existing fields but ensure they are used as sync targets.

---

## Verification Plan

### Automated Tests
- Create `test/core/services/streak_service_test.dart` covering:
    - First use.
    - Same-day multiple activities.
    - Consecutive day increment.
    - Missed day reset.
    - Offline usage (local persistence).
    - Syncing higher remote streak.

### Manual Verification
1. **Activity Check**: Send a chat message -> Observe 🔥 1.
2. **Persistence**: Restart app -> Observe 🔥 1 remains.
3. **Offline**: Disable internet -> Log a meal -> Observe streak increment (if it's a new day).
4. **Day Roll**: Change system clock forward 1 day -> Scan food -> Observe streak increment.
5. **Missed Day**: Change system clock forward 2 days -> Chat -> Observe streak reset to 1.
