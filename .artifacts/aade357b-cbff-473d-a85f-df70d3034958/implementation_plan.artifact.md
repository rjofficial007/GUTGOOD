# GutGood Streak System Audit & Production-Grade Optimization

This plan addresses the findings from the streak system audit, focusing on accuracy, timezone safety, and UI consistency.

## User Review Required

> [!IMPORTANT]
> The streak system relies on a **server-authoritative, forward-only** calculation.
> - **Time-Travel Protection**: Back-dated activities (synced after a newer activity exists in the record) will not increment the streak. This prevents confusing streak jumps or resets due to delayed offline synchronization.
> - **Lazy Reset**: The streak number in the database only resets to 1 (or 0) when the user performs a new activity. The UI will be updated to handle "Effective Streak" (showing 0 if the last activity was more than 1 day ago) to ensure the user sees their current state accurately.

> [!NOTE]
> **What counts as a streak?**
> The current system counts: Chat interactions, Food Scans, Meal Logs, and Symptom Logs.
> I will explicitly **exclude `system` usage types** (like background history summarization) from incrementing the streak to ensure it reflects actual user engagement.

## Proposed Changes

### [Backend] Firestore Cloud Functions

#### [MODIFY] [usage.ts](file:///D:/Github/GUTGOOD/functions/src/usage.ts)
- Update `checkAndConsume` to only call `calculateStreakUpdate` for `chat` and `scan` usage types.
- Add bounds checking to `calculateStreakUpdate` to prevent negative values.

---

### [Frontend] Core Models & Widgets

#### [MODIFY] [user_profile.dart](file:///D:/Github/GUTGOOD/lib/core/models/user_profile.dart)
- Add an `effectiveStreak` getter. This will return 0 if `lastActivityDate` is more than 1 day from `DateTime.now()` (local time), otherwise returns the stored `streak`.
- Add `isStreakActive` boolean getter for UI indicators.

#### [MODIFY] [streak_card.dart](file:///D:/Github/GUTGOOD/lib/core/widgets/streak_card.dart)
- Update the UI to display the `effectiveStreak`.
- Add a dedicated display for **Longest Streak** (Best) to the card.
- Synchronize the "Weekly Bubbles" logic with the `effectiveStreak` logic.

#### [MODIFY] [gut_snapshot_hero_card.dart](file:///D:/Github/GUTGOOD/lib/core/widgets/gut_snapshot_hero_card.dart)
- Use `effectiveStreak` for the displayed number.

#### [MODIFY] [profile_header.dart](file:///D:/Github/GUTGOOD/lib/core/widgets/profile_header.dart)
- Display `longestStreak` prominently in the profile header section.

---

### [Frontend] Lifecycle & Synchronization

#### [MODIFY] [profile_provider.dart](file:///D:/Github/GUTGOOD/lib/features/profile/presentation/providers/profile_provider.dart)
- Add a periodic check (or app-resume check) to notify listeners when a day rolls over, ensuring the "Effective Streak" resets in the UI even if the app stays open.

## Verification Plan

### Automated Tests
- **Unit Tests**: Create `streak_logic_test.dart` to verify `effectiveStreak` calculation across various date scenarios (leap years, month boundaries, timezone shifts).
- **Backend Tests**: Verify `calculateStreakUpdate` in `usage.test.ts` (if available) or create a mock transaction test.

### Manual Verification
1. **Activity Logic**: Log a meal -> Verify streak increments + celebration shows.
2. **Lazy Reset**: Set device clock forward 2 days -> Verify `StreakCard` shows 0, but performs a reset to 1 upon the next activity.
3. **Longest Streak**: Break a streak and start a new one -> Verify `Longest Streak` remains at the previous high until surpassed.
4. **Timezone Travel**: Change timezone while app is open -> Verify bubbles update to reflect the new local "Today".
