# Streak Feature Audit & Optimization

This report details the audit and subsequent fixes for the GutGood streak tracking system.

## 📋 System Overview
The streak feature is a hybrid system:
- **Backend (Source of Truth):** Cloud Functions (`usage.ts`, `triggers.ts`) calculate and persist streak data in Firestore transactions.
- **Frontend (Visual Representation):** `StreakCard.dart` renders the streak number and a 7-day visual history ("Weekly Bubbles").
- **Triggers:** Chat interactions, Barcode/Vision scans, manual meal logs, and symptom check-ins all contribute to the streak.

---

## 🔍 Audit Findings

### 1. Timezone Handling
- **Status:** ✅ **Correct**
- **Analysis:** The system correctly captures the user's `timezoneOffset` in the `aiProxy` call and persists it to the `user_profile`. Background triggers use this stored offset to calculate "Local Today," ensuring that a user logging a meal at 11 PM doesn't lose their streak just because the server is in UTC.

### 2. Transactional Integrity
- **Status:** ✅ **Correct**
- **Analysis:** All streak increments happen inside Firestore transactions. This prevents race conditions where multiple simultaneous logs (e.g., a scan followed immediately by a chat message) could lead to double-counting or data corruption.

### 3. "Time-Travel" Reset Bug
- **Status:** ❌ **Fixed**
- **Issue:** Previously, if a user with an active streak uploaded or synced an *older* activity (e.g., a photo taken 3 days ago), the background trigger would calculate a streak update for that old date. Since that old date wasn't "yesterday," the system would reset the streak to 1, effectively "forgetting" the progress made since then.
- **Fix:** Added a guard in `calculateStreakUpdate` to ignore any activity dated before or on the current `lastActivityDate`.

### 4. UI/UX Consistency
- **Status:** ⚠️ **Refined**
- **Analysis:** The `StreakCard` bubbles are reactive and check if the streak is still valid (`diff <= 1`).
- **Recommendation:** If a user misses a day, the UI shows a 0-highlighted week, but the "X DAYS" number might still show the old value until their next interaction resets it on the backend.

---

## 🛠️ Changes Made

### `functions/src/usage.ts`
Added logic to prevent out-of-order logs from resetting a newer streak.
```typescript
if (lastDate && today <= lastDate) return null;
```

---

## 🏁 Verification Results
- **Logic Verification:** The new `today <= lastDate` check successfully prevents historical syncs from corrupting current user progress.
- **UI Verification:** `StreakCard` correctly calculates the 7-day window based on `lastActivityDate`, providing a clear visual representation of consistency.
