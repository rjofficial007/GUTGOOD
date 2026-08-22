Act as a **Principal Flutter Engineer, Product Engineer, and Gamification Systems Architect** with experience building production-grade habit, wellness, fitness, and health applications.

You are joining the existing **GutGood Flutter codebase**.

Your task is to **completely review, reverse-engineer, test, and improve the existing Streak feature and all of its functionality**.

Do not assume the current implementation is correct.

Do not blindly rewrite the feature.

First understand exactly how the current streak system works, identify every problem and edge case, then implement production-grade fixes while preserving the intended product behavior.

The goal is to make GutGood's streak system:

**Accurate → Reliable → Consistent → Timezone-safe → Persistent → Scalable → Maintainable → User-friendly**

---

# 1. Reverse-Engineer the Existing Streak System

First inspect the complete codebase and locate everything related to streaks.

Search for:

- Streak models
- Streak services
- Streak repositories
- Streak providers/notifiers/controllers
- Streak UI
- Streak cards
- Streak counters
- Calendar/history UI
- Daily activity tracking
- Meal logging
- Chat activity
- Food scanning
- Insight activity
- User activity
- Local storage
- Firebase/database persistence
- API calls
- Date/time utilities
- Notification/reminder logic
- Background jobs
- App lifecycle handling

Do not rely only on filenames.

Trace the actual data flow.

---

# 2. Understand What Actually Counts Toward a Streak

Determine the current business rule.

Answer:

**What exact user action makes a day "active"?**

For example, does a streak count when the user:

- Logs a meal?
- Logs any food?
- Completes a daily goal?
- Uses Chat?
- Scans food?
- Records symptoms?
- Opens the app?
- Performs any GutGood activity?
- Completes a specific health action?

Do not invent a new rule.

Identify the existing intended rule from the codebase and product behavior.

If the implementation is inconsistent or ambiguous, clearly report it before changing it.

---

# 3. Define the Streak Data Model

Audit what data is currently stored.

Determine whether the system tracks:

- Current streak
- Longest streak
- Last active date
- First active date
- Total active days
- Streak start date
- Streak end date
- Daily activity
- Activity timestamps
- Missed days
- Streak history
- User ID
- Timezone
- Streak freeze, if supported
- Grace period, if supported

Identify whether the current model contains unnecessary or duplicated information.

Prefer a clear source of truth.

---

# 4. Single Source of Truth

The streak calculation must have **one authoritative source of truth**.

Avoid situations where:

```text id="xw7v0d"
UI calculates streak
+
Provider calculates streak
+
Repository calculates streak
+
Database stores another streak value
```

and all four can disagree.

Determine where streak state should be calculated and stored.

If the backend exists, determine whether streak calculations should be authoritative there.

If the current application is local-only, ensure the local persistence layer remains the source of truth.

Do not introduce unnecessary duplication.

---

# 5. Daily Activity Logic

Audit how the system determines whether a user was active on a given day.

The logic should correctly handle:

```text id="k6z8p5"
Activity today
Activity yesterday
Activity 2 days ago
No activity
Multiple activities on the same day
```

Multiple activities on the same day should normally count as **one active day**, unless the existing product explicitly defines otherwise.

For example:

```text id="5f7m0j"
Monday:
08:00 meal logged
12:00 meal logged
18:00 symptom logged
21:00 chat used

Result:
1 active day
```

Do not accidentally calculate:

```text
4-day streak
```

from four activities on the same calendar day.

---

# 6. Consecutive-Day Calculation

Review the algorithm used to calculate the streak.

It must correctly distinguish:

### Example 1

```text id="2t0e7n"
Monday  ✓
Tuesday ✓
Wednesday ✓
```

Current streak:

**3 days**

### Example 2

```text id="9u4s8d"
Monday  ✓
Tuesday ✓
Wednesday ✗
Thursday ✓
```

Current streak:

**1 day**

unless the existing product explicitly supports a grace/streak-freeze mechanism.

### Example 3

```text id="r8j3xa"
Monday ✓
Tuesday ✓
Wednesday ✓
Thursday ✗
Friday ✗
```

Current streak:

**0**

or whatever the existing product rule specifies.

Verify the actual intended behavior.

---

# 7. Current Streak vs Longest Streak

These are different concepts.

Audit whether the implementation correctly separates:

### Current Streak

The number of consecutive active days ending at the current relevant date.

### Longest Streak

The maximum consecutive active-day sequence across the user's complete history.

Example:

```text id="v4kq0z"
Jan 1  ✓
Jan 2  ✓
Jan 3  ✓
Jan 4  ✓
Jan 5  ✗

Jan 10 ✓
Jan 11 ✓
```

Current streak:

**2**

Longest streak:

**4**

Ensure the current implementation does not accidentally overwrite the longest streak when the current streak resets.

---

# 8. Timezone Handling — CRITICAL

Perform a dedicated timezone audit.

Do not rely blindly on:

```dart
DateTime.now()
```

or UTC date comparisons.

A streak is based on the user's **calendar day**, not simply a UTC timestamp.

Investigate:

- Device timezone
- UTC conversion
- Server timezone
- Stored timestamps
- Date-only values
- Day boundaries
- Daylight saving changes
- Travel across timezones
- Date serialization
- Firebase timestamps
- API timestamps

Example:

A user logs an activity at:

```text
23:55 local time
```

and the server receives it at:

```text
18:25 UTC
```

It must still belong to the user's correct local calendar day.

Do not allow timezone conversion to accidentally move activity to another day.

---

# 9. Midnight Edge Cases

Test activity around midnight.

Examples:

```text id="qj7t4r"
23:59
00:00
00:01
```

Ensure the correct day is assigned.

Also test:

- App open across midnight
- App backgrounded across midnight
- App resumed after midnight
- Activity queued offline before midnight
- Activity synced after midnight

The UI and streak calculation must remain consistent.

---

# 10. Multiple Activities

Test users performing many actions during one day.

Example:

```text id="4c8p2h"
Meal logged
Meal logged
Food scanned
Chat used
Symptom recorded
Meal logged
```

Ensure the implementation does not accidentally create multiple streak days.

The daily activity representation should be deterministic.

---

# 11. Offline Behavior

If GutGood supports local/offline functionality, audit streak behavior while offline.

Test:

```text id="0g7k3b"
Offline
 ↓
User performs streak activity
 ↓
Activity stored locally
 ↓
App closes
 ↓
App opens
 ↓
Activity still exists
 ↓
Internet returns
 ↓
Activity syncs
```

Ensure the streak does not disappear because synchronization has not happened yet.

Also prevent duplicate synchronization from creating duplicate activity records.

---

# 12. Persistence

Test the streak after:

- App restart
- Force close
- Device restart
- Logout/login
- App update
- Cache clearing
- Database migration
- Offline/online transitions

The streak must not unexpectedly reset.

If the current implementation stores only the calculated streak number, determine whether that is sufficient.

Prefer storing the underlying activity/date information required to reliably reconstruct the streak when appropriate.

---

# 13. App Lifecycle

Audit:

- Cold start
- Warm start
- Resume
- Background
- App termination
- App restart

Check whether streak state is recalculated unnecessarily or becomes stale.

Example:

```text id="z3p5sa"
App opened at 23:59
 ↓
App remains open
 ↓
Midnight occurs
 ↓
Date changes
```

The displayed streak state should remain logically correct.

---

# 14. State Management

Audit the current state-management implementation.

Look for:

- Duplicate streak state
- Unnecessary rebuilds
- State being reset
- Incorrect provider invalidation
- Race conditions
- Async state inconsistencies
- Stale state
- UI calculating its own streak
- Provider and database disagreeing

The UI should consume the authoritative streak state rather than independently calculating it.

---

# 15. UI Audit

Review the complete Streak UI.

Evaluate:

- Current streak display
- Longest streak display
- Daily activity indicators
- Calendar
- Progress indicators
- Icons
- Typography
- Spacing
- Empty state
- Loading state
- Error state
- Animation
- Accessibility
- Dark mode
- Responsive behavior

The UI should clearly communicate what the streak actually represents.

Avoid misleading UI such as:

> "You're on a 7-day streak!"

when the underlying activity does not support that claim.

---

# 16. Loading State

Review the streak loading experience.

Do not show:

```text id="q5n8yv"
0 days
```

while the real streak is still loading if that could be interpreted as the user's actual streak.

Use an appropriate:

- Skeleton
- Shimmer
- Placeholder
- Cached state

depending on the existing architecture.

Avoid unnecessary full-screen loaders.

---

# 17. Empty State

Determine what happens for a brand-new user.

Example:

```text id="y6m4w1"
No activity yet
Start tracking today to begin your streak.
```

Do not display misleading:

```text
Current streak: 0
Longest streak: 0
```

without context if the product design expects an onboarding experience.

---

# 18. Error State

If streak data cannot be loaded:

Do not silently display incorrect data.

Handle:

- Network error
- Database error
- Corrupt data
- Parsing error
- Authentication failure
- Sync failure

Preserve previously known valid state when appropriate.

Provide retry behavior where appropriate.

---

# 19. Streak Reset Logic

This is a critical area.

Determine exactly when a streak resets.

Do not reset a streak merely because:

- The app was not opened
- The provider was recreated
- Cache is empty
- The device restarted
- Network is unavailable
- The user logged out temporarily

Only reset the streak when the **actual streak business rule** says it should reset.

---

# 20. Streak Freeze / Grace Period

Check whether the product currently supports:

- Streak freeze
- Grace days
- Recovery
- Missed-day protection

If not supported:

**Do not invent or implement these features.**

If code exists for them, verify that it works correctly.

---

# 21. Data Integrity

Look for:

- Duplicate activity dates
- Invalid future dates
- Missing dates
- Incorrect timestamps
- Duplicate streak records
- Corrupted streak counters
- Negative streak values
- Impossible longest streak values
- Current streak greater than total active days
- Inconsistent user IDs

Add validation where appropriate.

---

# 22. Security & Trust

A streak is a user-facing trust metric.

Prevent clients from blindly modifying authoritative streak values if a backend exists.

Do not trust:

```text id="7f1n5b"
currentStreak
longestStreak
```

from an untrusted client if the backend is intended to be authoritative.

Prefer deriving important values from trusted activity data where appropriate.

---

# 23. Performance

Audit:

- Database queries
- API requests
- Date calculations
- Calendar generation
- State rebuilds
- Repeated streak calculations
- Unnecessary recalculation on every widget build

A simple streak calculation should not trigger expensive operations every time the screen rebuilds.

Cache derived values appropriately while maintaining correctness.

---

# 24. Race Conditions

Look specifically for:

```text id="f7v2k1"
Activity added
      ↓
Streak calculation starts

Another activity added
      ↓
Another calculation starts

First calculation finishes last
      ↓
Old result overwrites new result
```

Prevent stale asynchronous results from overwriting newer state.

Also test:

- Rapid activity logging
- Multiple meals
- App restart during save
- Sync during calculation
- Logout during request
- Date rollover during request

---

# 25. Calendar / History Accuracy

If GutGood displays streak history or a calendar:

Verify:

- Correct dates
- Correct month boundaries
- Correct weekdays
- Correct leap years
- Correct current day
- Correct active days
- Correct inactive days
- Correct future dates
- Correct timezone
- Correct month navigation

Test:

- January → February
- December → January
- Leap year February
- Month with 28/29/30/31 days

---

# 26. Animation & Celebration

If the streak feature includes animations or celebrations:

Audit:

- Animation triggers
- Duplicate animation triggers
- App restart behavior
- State restoration
- Reduced-motion/accessibility
- Performance

A streak celebration should trigger because of a meaningful streak event, not simply because the screen rebuilt.

For example:

```text id="w7r4np"
Screen rebuild
→ celebration
→ rebuild
→ celebration
→ rebuild
→ celebration
```

must never happen.

---

# 27. Architecture Improvements

After understanding the current implementation, propose the cleanest architecture.

Prefer a flow similar to:

```text id="4q4t4u"
User Activity
      ↓
Activity Repository
      ↓
Daily Activity Source
      ↓
Streak Calculator
      ↓
Streak State
      ↓
UI
```

The exact architecture should be adapted to the existing GutGood codebase.

Do not introduce unnecessary layers.

The streak calculation should be:

- Deterministic
- Testable
- Independent of UI
- Easy to reason about
- Timezone-aware
- Reusable

---

# 28. Testing Requirements

Create and run tests for at least:

### Basic

- No activity
- One active day
- Two consecutive days
- Multiple consecutive days

### Broken streak

- Active → inactive → active
- Several missed days
- Long inactive period

### Same-day activity

- One activity
- Multiple activities
- Activities at different times

### Time

- 23:59 activity
- 00:00 activity
- 00:01 activity
- Timezone changes
- App open across midnight

### History

- Current streak
- Longest streak
- Old streak
- New streak

### Persistence

- Restart
- Force close
- Offline
- Online
- Sync

### Edge cases

- Duplicate records
- Missing timestamps
- Invalid timestamps
- Future timestamps
- Leap year
- Month boundary
- Year boundary

### State

- Rapid updates
- Concurrent updates
- Conversation/app lifecycle changes
- Logout/login

---

# 29. Do Not Change Existing Product Functionality

This is extremely important.

Do not change the intended behavior of GutGood.

Do not introduce:

- New streak rules
- Streak freezes
- Rewards
- Gamification mechanics
- New activity definitions

unless they already exist in the code/product requirements.

Your job is to make the **existing streak feature work correctly and reliably**.

---

# 30. Final Deliverables

After the audit and implementation, provide:

## Current Architecture

Explain how the existing streak system works.

## Data Flow

Show:

```text id="m8r0x1"
User Activity
      ↓
Persistence
      ↓
Streak Calculation
      ↓
State Management
      ↓
Streak UI
```

Adapt this to the actual implementation.

## Problems Found

For every important issue provide:

- File
- Location
- Problem
- Root cause
- Impact
- Severity

## Business Logic

Clearly document:

- What counts as an active day
- How current streak is calculated
- How longest streak is calculated
- When a streak resets
- How dates are interpreted
- How timezone is handled

## Fixes Implemented

Explain exactly what was changed.

## Edge Cases Fixed

List the edge cases that are now handled correctly.

## Tests Added

List the streak scenarios covered by tests.

## Remaining Risks

Identify anything that still requires future work.

---

# FINAL ENGINEERING PRINCIPLE

Treat the streak as a **data-driven product feature**, not merely a number displayed on the UI.

The UI must never be the source of truth.

The streak must be derived from reliable activity data using deterministic, timezone-aware business logic.

Most importantly:

> **Do not simply make the streak display look correct. Prove that the underlying streak calculation, persistence, date handling, state management, and edge cases are correct.**

The final implementation should be something you would be comfortable shipping to **millions of GutGood users without users unexpectedly losing or gaining streaks.**