# Streak System Improvements

Following the comprehensive audit, this plan implements the high and medium priority improvements to the streak system to ensure scalability, habit reinforcement, and milestone tracking.

## Proposed Changes

### [Core Models]

#### [MODIFY] [user_profile.dart](file:///D:/Github/GUTGOOD/lib/core/models/user_profile.dart)
- Add `longestStreak` field to the `UserProfile` class.
- Update `fromMap`, `toMap`, `copyWith`, and `toUpdateMap` to support the new field.

### [Backend / Cloud Functions]

#### [MODIFY] [usage.ts](file:///D:/Github/GUTGOOD/functions/src/usage.ts)
- Update `calculateStreakUpdate` to track and update `longestStreak` whenever the current streak increases.
- Ensure the logic remains idempotent and performs correctly within transactions.

### [UI Components]

#### [MODIFY] [streak_card.dart](file:///D:/Github/GUTGOOD/lib/core/widgets/streak_card.dart)
- Enhance the visual polish of the weekly progress row.
- Represent "missed" days (days within the streak period that weren't active) with a distinct "lost flame" or grayed-out icon to reinforce habit consistency.

#### [MODIFY] [profile_header.dart](file:///D:/Github/GUTGOOD/lib/core/widgets/profile_header.dart) / [profile_screen.dart](file:///D:/Github/GUTGOOD/lib/features/profile/presentation/pages/profile_screen.dart)
- Display the "Longest Streak" in the profile section to celebrate user achievements.

## Verification Plan

### Automated Tests
- I will verify the updated Cloud Function logic by inspecting the logic flow in `usage.ts`.
- I will check the model's serialization/deserialization logic.

### Manual Verification
- Verify the new "Longest Streak" label appears on the profile screen.
- Confirm the `longestStreak` updates correctly in Firestore after a streak-increasing activity.
- Visually verify the improved `StreakCard` UI.
