Act as a **Principal Flutter Engineer, Data-Driven UI Architect, and Senior UX Engineer** who has built production-grade health, nutrition, AI, and data-heavy applications.

You are working on the existing **GutGood Flutter application**.

The persistence layer has already been reviewed. Your task now is to **audit and improve how all saved data is retrieved, transformed, loaded, and displayed throughout the application**.

The goal is:

> **Every piece of data that GutGood successfully saves must be displayed correctly, completely, consistently, and in the appropriate UI — without hardcoded values, missing fields, duplicate records, stale state, incorrect relationships, or unnecessary loading.**

Do NOT redesign the entire application.

Do NOT change existing business functionality.

First understand the existing data flow, then identify display/integration problems, and finally implement production-grade fixes.

---

# 1. COMPLETE DATA → UI AUDIT

Trace the complete flow for every major saved entity:

```text
Persisted Data
    ↓
Repository
    ↓
Data Source
    ↓
API / Database / Local Storage
    ↓
Model / DTO
    ↓
Mapping
    ↓
State Management
    ↓
Controller / Provider / Notifier
    ↓
UI
```

Audit every stage.

Verify that the UI is displaying **real persisted data**, not:

- Mock data
- Hardcoded values
- Placeholder values
- Default values hiding missing data
- Stale cached data
- Previously loaded data
- Incorrectly mapped fields

---

# 2. COMPLETE FEATURES TO REVIEW

Review all screens and components that display saved user data, including at minimum:

### Chat

- Conversation list
- Conversation detail
- Saved messages
- User messages
- AI responses
- Message timestamps
- Attachments
- Food images
- Chat history
- Pagination

### Meal Log

- Meal history
- Meal detail
- Food items
- Portions
- Nutrition
- Meal time
- Meal type
- Images
- AI analysis
- Ratings
- Notes

### Symptom Log

- Symptom history
- Symptom details
- Severity
- Date/time
- Duration
- Notes
- Related meal
- Related food

### Scan History

- Previously scanned foods
- Product name
- Brand
- Barcode
- Nutrition
- Ingredients
- Images
- Scan date/time

### Insights

- Generated insights
- Pattern details
- Supporting data
- Confidence/evidence where supported
- Related meals
- Related symptoms

### Streak

- Current streak
- Longest streak
- Activity history
- Calendar/history if available

Also find other screens that display persisted user data.

---

# 3. NO HARDCODED DATA

Search the complete codebase for hardcoded values being displayed in production UI.

Look for:

```dart
"7 day streak"
"12 meals"
"Good"
"8.5"
"2 symptoms"
"Today"
```

or similar values that should come from actual persisted data.

Replace hardcoded data with the correct data source where appropriate.

Do NOT blindly replace legitimate static UI text.

Distinguish between:

```text
Static UI content
```

and:

```text
Dynamic user data
```

---

# 4. DATA COMPLETENESS

For every UI component, determine whether it displays all relevant persisted data.

For example, if a meal contains:

```text
Meal
 ├── Date
 ├── Time
 ├── Meal Type
 ├── Food Items
 ├── Portions
 ├── Nutrition
 ├── Image
 ├── Notes
 └── AI Analysis
```

verify that the appropriate screens correctly display these fields.

Do not display everything everywhere.

Instead:

> **Display the right amount of information at the right level of the UI.**

For example:

### Meal List

Show concise information:

- Meal name/type
- Time
- Main foods
- Useful summary
- Relevant nutrition

### Meal Detail

Show the complete available information.

---

# 5. DATA MAPPING AUDIT

Inspect every model-to-UI transformation.

Look for:

- Wrong field mapping
- Incorrect nullable handling
- Wrong enum mapping
- Incorrect date formatting
- Incorrect numeric formatting
- Missing nested objects
- Missing list items
- Incorrect relationships
- Wrong image URLs
- Incorrect IDs
- Fields silently discarded during mapping

Example:

```dart
MealModel(
  name: response.title,
  calories: response.calories,
)
```

but the response also contains:

```text
protein
carbs
fat
fiber
ingredients
portion
```

Determine whether those fields are intentionally omitted or accidentally lost.

---

# 6. NULL & MISSING DATA

Handle missing data properly.

Do NOT blindly display:

```text
null
N/A
0
Unknown
```

for every missing field.

Determine the appropriate UX for each field.

For example:

```text
Missing image
→ Use appropriate placeholder

Missing nutrition
→ "Nutrition information unavailable"

Missing notes
→ Don't display an empty notes section
```

Avoid misleading users by converting unknown values into valid-looking values.

---

# 7. LIST SCREEN ARCHITECTURE

Audit all history/list screens.

Examples:

- Chat history
- Meal history
- Symptom history
- Scan history
- Insight history

Ensure they use efficient lazy rendering such as:

```dart
ListView.builder
```

or an appropriate equivalent.

Avoid:

- Loading the entire dataset into memory unnecessarily
- Nested unbounded lists
- `shrinkWrap` everywhere
- Rebuilding the entire list for one changed item
- Fetching the same data repeatedly

---

# 8. PAGINATION

Implement/review proper pagination for large datasets.

For:

- Chat history
- Messages
- Meals
- Symptoms
- Scan history
- Insights

Use appropriate cursor/page-based pagination based on the existing backend/storage architecture.

Expected behavior:

```text
Initial Load
    ↓
Load latest/relevant records
    ↓
User scrolls
    ↓
Load next page
    ↓
Append records
    ↓
Continue until no more data
```

Ensure:

- No duplicate records
- No missing records
- Stable ordering
- No repeated requests
- Loading state
- End-of-list state
- Retry
- Refresh
- Correct pagination cursor

---

# 9. CHAT DATA DISPLAY

The Chat UI must display the persisted conversation exactly as stored.

Verify:

- Correct conversation
- Correct user
- Correct message ordering
- Correct role
- Correct timestamps
- Correct attachments
- Correct images
- Correct AI responses
- No duplicated messages
- No missing messages

When older messages are loaded:

```text
Older messages
      ↓
Insert above existing messages
      ↓
Preserve viewport
```

Do not reorder messages incorrectly.

---

# 10. MEAL DATA DISPLAY

Review Meal Log end-to-end.

Verify that the UI correctly displays:

- Meal date
- Meal time
- Meal type
- Food items
- Portions
- Nutrition
- Calories
- Protein
- Carbohydrates
- Fat
- Fiber
- Images
- Notes
- AI analysis
- Rating

Only display fields that actually exist.

Do not invent nutritional information when it is missing.

---

# 11. SYMPTOM DATA DISPLAY

Ensure symptoms are displayed with their correct context.

Display applicable information such as:

- Symptom
- Severity
- Date
- Time
- Duration
- Notes
- Related meal
- Related food

The UI should not accidentally associate a symptom with the wrong meal.

---

# 12. SCAN HISTORY DISPLAY

Show only valid saved food scan records.

Verify:

```text
Saved Food
 ↓
Scan History
 ↓
Correct Product
 ↓
Correct Nutrition
 ↓
Correct Image
 ↓
Correct Timestamp
```

Do not show restaurant menus, ingredient-label scans, invalid scans, or failed scan results if those were intentionally excluded from persistence.

---

# 13. INSIGHTS DISPLAY

Audit how persisted insight data is displayed.

Important:

**Do not create fake insight information in the UI.**

If an insight contains evidence such as:

```text
Pattern
Evidence
Frequency
Related foods
Confidence
```

display it accurately.

If there is insufficient data:

```text
No insight
```

rather than displaying a generic placeholder as if it were a real personalized insight.

---

# 14. STREAK DISPLAY

Ensure the streak UI displays the authoritative streak state.

Verify:

- Current streak
- Longest streak
- Active days
- Calendar/history
- Correct dates

Do not calculate a different streak inside the UI.

The UI should consume the authoritative streak state.

---

# 15. LOADING STATES

Every data-driven screen must have a proper loading state.

Use appropriate:

### Initial Loading

Skeleton/shimmer matching the actual content.

### Pagination Loading

Small loader at the appropriate edge of the list.

### Refreshing

Subtle refresh state without destroying existing content.

Avoid:

```text
Loading...
```

for every screen when a better skeleton is possible.

---

# 16. EMPTY STATES

Every data-driven screen must have a meaningful empty state.

Examples:

### No Meals

```text
No meals logged yet

Start tracking your meals to build your food history.
```

### No Symptoms

```text
No symptoms recorded yet
```

### No Scan History

```text
No scanned foods yet
```

### No Chats

```text
No conversations yet
```

The exact copy should match GutGood's existing design system.

Do not use generic:

```text
No data
```

everywhere.

---

# 17. ERROR STATES

Every data-driven screen must handle:

- Initial loading failure
- Pagination failure
- Refresh failure
- Empty response
- Invalid data
- Network error
- Database error
- Authentication failure

Do not replace existing valid content with a full-screen error when only pagination failed.

Example:

```text
Existing meals
Existing meals
Existing meals

Couldn't load more meals
Retry
```

rather than destroying the entire screen.

---

# 18. REFRESH BEHAVIOR

Audit pull-to-refresh or refresh functionality.

Verify:

```text
Refresh
 ↓
Fetch latest data
 ↓
Update state
 ↓
Preserve correct ordering
 ↓
Remove stale records
 ↓
Avoid duplicates
```

Do not append the same records again during refresh.

---

# 19. REAL-TIME / STATE UPDATES

When new data is created elsewhere in the application, determine whether existing screens update correctly.

Example:

```text
User logs meal
 ↓
Meal saved
 ↓
Meal Log screen
 ↓
New meal appears
```

Similarly:

```text
User sends chat
 ↓
Message saved
 ↓
Conversation history
 ↓
Latest conversation updated
```

Avoid requiring unnecessary app restarts to see newly saved data.

---

# 20. CACHE & STALE DATA

Audit caching.

Determine:

- What is cached?
- Where?
- When is it invalidated?
- When is it refreshed?
- Can stale data overwrite newer data?

Example problem:

```text
New meal saved
 ↓
UI displays new meal

Screen rebuild
 ↓
Old cache loaded
 ↓
New meal disappears
```

Find and fix these issues.

---

# 21. DATA CONSISTENCY ACROSS SCREENS

The same data should appear consistently across the app.

For example:

```text
Meal Log
      ↓
Meal Detail
      ↓
Insight
      ↓
Symptom relationship
```

If a meal is named:

```text
Dal + Rice
```

one screen should not display:

```text
Rice
```

unless intentionally summarized.

Audit inconsistent representations of the same entity.

---

# 22. DELETE & EDIT REFLECTION

When data is edited or deleted:

The UI must immediately and correctly reflect the new state.

Example:

```text
Meal edited
 ↓
Meal detail updated
 ↓
Meal list updated
 ↓
Related UI updated
```

and:

```text
Meal deleted
 ↓
Removed from meal list
 ↓
Removed from relevant cached state
 ↓
Related references handled correctly
```

Do not leave stale records visible.

---

# 23. IMAGE DISPLAY

Audit all saved images.

Verify:

- Correct image association
- Image loading
- Placeholder
- Error state
- Caching
- Memory usage
- Large images
- Offline behavior if supported
- Broken URLs
- Deleted images

Do not reload the same image unnecessarily.

---

# 24. DATE & TIME DISPLAY

All persisted dates must be displayed consistently.

Review:

- Today
- Yesterday
- Relative dates
- Full dates
- Time
- Timezone
- Midnight boundaries

For example:

```text
Today · 8:30 PM
Yesterday · 7:10 PM
Aug 20 · 12:30 PM
```

Use a centralized date formatting strategy instead of duplicating date logic across widgets.

---

# 25. STATE MANAGEMENT

Review how saved data is represented in state.

Avoid:

```text
Repository state
+
Provider state
+
Widget local state
+
Cached list
```

all independently containing the same dataset.

Determine the appropriate source of truth.

Ensure updates are propagated correctly without unnecessary rebuilds.

---

# 26. PERFORMANCE

Audit:

- Database queries
- API requests
- Model conversion
- List rendering
- Image loading
- Markdown rendering
- State rebuilds
- Sorting
- Filtering
- Pagination
- Date formatting

Avoid recalculating expensive values inside `build()`.

Avoid loading data repeatedly when it has already been loaded.

---

# 27. RESPONSIVE UI

Ensure saved-data screens work correctly on:

- Small phones
- Large phones
- Tablets
- Desktop/Web if supported

Avoid:

- Overflow
- Fixed-width layouts
- Clipped text
- Broken cards
- Excessive whitespace
- Unusable large-screen layouts

---

# 28. ACCESSIBILITY

Review:

- Semantic labels
- Text scaling
- Contrast
- Touch targets
- Screen reader support
- Keyboard navigation
- Focus behavior

Do not sacrifice accessibility for visual design.

---

# 29. DATA DISPLAY RULE

Follow this principle:

> **The UI should display what the data actually contains — not what the UI assumes the data contains.**

If data is missing:

```text
Handle missing data honestly.
```

If data exists:

```text
Display it appropriately.
```

Never fabricate values.

Never silently replace missing information with incorrect defaults.

---

# 30. TEST THE COMPLETE DATA LOOP

For every major feature test:

```text
Create
 ↓
Save
 ↓
Close screen
 ↓
Reopen
 ↓
Retrieve
 ↓
Display
 ↓
Edit
 ↓
Display updated value
 ↓
Delete
 ↓
Verify removal
```

Perform this for:

- Chat
- Meals
- Symptoms
- Scan history
- Insights
- Streak
- Other persisted features

---

# 31. Final Deliverables

After the audit and implementation, provide:

## Current Data Display Architecture

Explain:

```text
Storage
 ↓
Repository
 ↓
Model
 ↓
State
 ↓
UI
```

for each major feature.

## Problems Found

For every issue:

- File
- Location
- Problem
- Root cause
- Impact
- Severity

Use:

- P0 — Critical
- P1 — High
- P2 — Medium
- P3 — Low

## Missing Data

Identify data that is successfully stored but currently not displayed where it should be.

## Incorrect Data

Identify places where the UI displays incorrect or stale information.

## Hardcoded Data

Identify dynamic values incorrectly hardcoded in the UI.

## Pagination Problems

Document all pagination issues and fixes.

## Loading / Empty / Error States

Document improvements.

## Performance Improvements

Document meaningful performance optimizations.

## Consistency Improvements

Document places where the same entity was displayed inconsistently.

## Files Changed

List the files modified and why.

## Verification

Confirm that the following work correctly:

- [ ] Saved chats display correctly
- [ ] Saved meals display correctly
- [ ] Saved symptoms display correctly
- [ ] Scan history displays correctly
- [ ] Insights display correctly
- [ ] Streak data displays correctly
- [ ] Pagination works
- [ ] Refresh works
- [ ] Loading states work
- [ ] Shimmer states work
- [ ] Empty states work
- [ ] Error states work
- [ ] Edit updates UI
- [ ] Delete updates UI
- [ ] No duplicate records appear
- [ ] No hardcoded dynamic values remain
- [ ] No stale data overwrites fresh data
- [ ] Existing functionality remains intact

---

# FINAL ENGINEERING PRINCIPLE

GutGood is a **data-driven AI health application**.

The UI must not be treated as a collection of static screens.

Every screen should be a reliable representation of the underlying persisted data.

The complete lifecycle must work:

```text
USER ACTION
    ↓
DATA CREATED
    ↓
DATA PERSISTED
    ↓
DATA RETRIEVED
    ↓
DATA MAPPED
    ↓
DATA STORED IN STATE
    ↓
DATA DISPLAYED
    ↓
USER SEES CORRECT INFORMATION
```

If something is saved, the user must be able to reliably see it.

If something is edited, the UI must reflect it.

If something is deleted, stale UI must disappear.

If data is missing, the UI must handle it honestly.

If there is no data, show a proper empty state.

If data is loading, show an appropriate skeleton/shimmer.

If loading fails, provide a useful error/retry state.

**Do not change GutGood's intended product functionality. Improve the data-to-UI implementation, correctness, performance, and maintainability while preserving existing behavior.**