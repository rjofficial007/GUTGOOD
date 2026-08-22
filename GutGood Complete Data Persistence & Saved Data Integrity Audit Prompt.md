Act as a **Principal Flutter Engineer, Backend/Data Architect, and Data Integrity Specialist** joining the existing **GutGood** codebase.

Your task is to perform a **complete production-grade audit of every feature that creates, saves, updates, retrieves, synchronizes, or deletes user data**.

The goal is to ensure that GutGood **never silently loses data, saves incomplete data, saves incorrect data, creates duplicates, or stores records without the required relationships/context**.

Do not focus only on the UI.

Trace the complete data lifecycle:

```text id="9k2h4m"
User Action
    ↓
Validation
    ↓
Model Creation
    ↓
State Management
    ↓
Repository
    ↓
Local / Backend Storage
    ↓
Sync
    ↓
Retrieval
    ↓
Model Mapping
    ↓
State
    ↓
UI
```

First reverse-engineer the existing implementation, then identify problems, and finally fix them.

---

# 1. COMPLETE DATA STORAGE AUDIT

Find every feature in GutGood that stores user data.

At minimum review:

- Saved chats
- Chat messages
- Conversations
- Meal logs
- Food logs
- Symptom logs
- Scan history
- Food scan results
- Food details
- Insights
- Streak/activity data
- User profile/context
- Preferences
- Uploaded images
- Meal images
- Food images
- Attachments
- AI-generated analysis
- Ratings
- Nutrition information
- Timestamps
- User actions
- Any other persisted user data

Do not assume these are the only persisted entities.

Search the complete codebase for all persistence operations.

---

# 2. BUILD A DATA INVENTORY

Create a complete inventory of all persisted entities.

For each entity identify:

| Entity | Created By | Stored Where | Required Fields | Relationships | Updated By | Deleted By |
|---|---|---|---|---|---|---|

Determine the actual implementation rather than guessing.

For every entity answer:

- What is the unique ID?
- Who creates the ID?
- Is the ID stable?
- What fields are required?
- What fields are optional?
- What fields can be null?
- What timestamps are stored?
- Which user does it belong to?
- Which conversation/meal/scan/symptom does it belong to?
- What relationships exist?
- Can the record be reconstructed?
- Can the record be duplicated?
- Can the record become orphaned?

---

# 3. SAVED CHAT AUDIT

Completely review the chat persistence system.

Verify that when a user sends a message, the system correctly saves all required information.

A message may need information such as:

```text id="j1w8e6"
messageId
conversationId
userId
role
content
createdAt
updatedAt
status
attachments
image references
metadata
AI model information if required
AI response metadata if required
```

Do not blindly add fields.

Determine what the existing product actually requires.

Verify:

- User message is saved
- AI response is saved
- Conversation is saved
- Messages belong to the correct conversation
- Messages belong to the correct user
- Ordering is preserved
- Timestamps are correct
- Streaming responses are not saved as duplicate messages
- Failed messages are handled correctly
- Retry does not create duplicate messages
- Conversation switching cannot save a response into the wrong conversation
- Attachments remain associated with the correct message
- Images remain accessible
- Markdown/content is preserved correctly
- Long messages are not truncated
- Special characters are preserved

---

# 4. CHAT PERSISTENCE FLOW

Trace:

```text id="o7z8s1"
Send Message
 ↓
Create User Message
 ↓
Persist User Message
 ↓
AI Request
 ↓
Create/Update AI Message
 ↓
Stream Response
 ↓
Persist Final AI Response
 ↓
Update Conversation Metadata
```

Identify whether the current implementation:

- Saves before AI generation
- Saves only after AI generation
- Saves partial responses
- Updates instead of duplicating
- Handles failed requests
- Handles app termination during generation

Fix any data-loss scenarios.

---

# 5. CHAT CONVERSATION METADATA

Audit saved conversation information.

Verify whether the conversation correctly stores required metadata such as:

- Conversation ID
- User ID
- Title
- Created timestamp
- Updated timestamp
- Last message timestamp
- Last message preview if used
- Message count if used
- Archived/deleted state if supported
- Any required AI/chat metadata

Ensure conversation lists remain accurate after:

- New message
- Message deletion
- Retry
- App restart
- Conversation rename
- Conversation switching

---

# 6. MEAL LOG AUDIT

Completely review Meal Log persistence.

Determine exactly what information is captured when a meal is saved.

Verify required data such as applicable fields including:

- Meal ID
- User ID
- Meal type
- Date
- Time
- Timestamp
- Food items
- Food names
- Quantity
- Portion
- Ingredients
- Nutrition data
- Calories
- Protein
- Carbohydrates
- Fat
- Fiber
- Meal image
- AI analysis
- Meal rating
- User notes
- Location if explicitly supported
- Metadata
- Created timestamp
- Updated timestamp

Do not invent fields that the product does not need.

The key requirement is:

> **Every meal must contain enough information to understand what the user actually consumed.**

---

# 7. MEAL LOG DATA INTEGRITY

Verify that:

- Saving a meal does not lose food items
- Multiple foods remain associated with the correct meal
- Portions are preserved
- Nutrition values are preserved
- Images are linked correctly
- Meal timestamps are correct
- Editing a meal updates the correct record
- Deleting a meal deletes associated data appropriately
- Duplicate saves do not create duplicate meals
- Failed saves do not appear as successfully saved meals
- App restart does not lose the meal
- Offline saves work correctly if supported

---

# 8. SYMPTOM LOG AUDIT

Completely review symptom persistence.

Determine all data currently captured for a symptom.

For applicable fields, verify:

```text id="m0x4vb"
symptomId
userId
symptomType
severity
timestamp
date
duration
notes
associatedMealId
associatedFoodId
createdAt
updatedAt
```

Again, use the actual product requirements rather than blindly adding fields.

The system must preserve enough context to understand:

**What happened → when it happened → how severe it was → what it may be associated with.**

---

# 9. SYMPTOM ↔ MEAL RELATIONSHIP

This is especially important for GutGood.

Verify whether symptom records can correctly relate to relevant meals.

For example:

```text id="p5c9r1"
Meal
 ↓
Meal ID
 ↓
Symptom
 ↓
Symptom timestamp/severity
```

The relationship must not depend only on fragile UI state.

Ensure historical records remain correctly associated after:

- App restart
- Editing
- Pagination
- Sync
- Database migration

---

# 10. SCAN HISTORY AUDIT

Completely review Scan History.

Important product rule:

> **Scan History should save only actual food items that qualify as food products/items.**

Do NOT save irrelevant scan results such as:

- Restaurant menus
- Ingredient labels that are not actual food products
- Random text
- Non-food objects
- Unsupported barcode results
- Invalid scans
- Failed scans

Determine where this filtering currently happens.

The validation should occur at the appropriate data/business layer, not only in the UI.

---

# 11. SCAN HISTORY REQUIRED DATA

For valid food scans, verify that the saved record contains all required information available from the scan.

Potential fields include:

```text id="2j4k7p"
scanId
userId
food/product ID
barcode
product name
brand
category
serving size
nutrition values
ingredients
allergens
image
source
scan timestamp
createdAt
```

Only store fields relevant to the actual product.

Verify that:

- Valid food → saved
- Non-food → not saved
- Invalid result → not saved
- Failed API lookup → not saved as a valid food
- Duplicate scans behave correctly according to product requirements
- Scan history displays the same information that was originally saved

---

# 12. DUPLICATE DATA AUDIT

Search the entire codebase for duplicate-save scenarios.

Examples:

```text id="1f6w9q"
Button tap
 ↓
save()
 ↓
provider update
 ↓
save()
```

or:

```text id="x4k8c2"
API response
 ↓
save()
 ↓
state listener
 ↓
save() again
```

Check for duplicates in:

- Chats
- Messages
- Meals
- Foods
- Symptoms
- Scan history
- Insights
- Streak activity

Every persisted entity should have a clear identity strategy.

---

# 13. IDENTITY & IDEMPOTENCY

Every persisted record should have a stable unique identity.

Audit:

- UUIDs
- Server IDs
- Client-generated IDs
- Composite keys
- Barcode IDs
- Conversation IDs
- Message IDs

Ensure retries do not create duplicate records.

For example:

```text id="k5w2x7"
Request fails after server saves
 ↓
Client retries
 ↓
Same logical operation
 ↓
Should not create duplicate data
```

Implement idempotency where appropriate.

---

# 14. TIMESTAMP AUDIT

Review every timestamp in the application.

Look for:

- `DateTime.now()`
- UTC timestamps
- Local timestamps
- Server timestamps
- Date-only fields
- String dates
- Unix timestamps

Ensure timestamps are:

- Consistent
- Timezone-aware
- Correctly serialized
- Correctly parsed
- Not accidentally overwritten
- Not generated multiple times for the same logical event

Be especially careful with:

- Meals around midnight
- Symptoms around midnight
- Chat timestamps
- Scan history
- Streak calculations

---

# 15. USER OWNERSHIP

Every user-specific record must belong to the correct user.

Audit:

```text id="3p6y8a"
userId
 ↓
record
```

Ensure data from one user can never appear in another user's:

- Chat
- Meals
- Symptoms
- Scan history
- Insights
- Streak
- Preferences

Do not trust only UI state for ownership.

If a backend exists, enforce ownership at the data/backend layer.

---

# 16. SAVE vs STATE

A critical audit:

Determine whether the UI is confusing:

```text id="j8r3v1"
State exists in memory
```

with:

```text id="s2n6w4"
Data is actually persisted
```

A record should not be considered saved merely because it appears in the UI.

Verify:

```text id="z9k1p5"
Create
 ↓
Persist
 ↓
Close app
 ↓
Reopen
 ↓
Retrieve
 ↓
Same data exists
```

Perform this verification for every important entity.

---

# 17. READ-BACK VERIFICATION

For critical saves, verify the complete round trip:

```text id="d6p4s2"
Create
 ↓
Save
 ↓
Read
 ↓
Deserialize
 ↓
Compare
```

Check whether any information is lost during:

- Serialization
- Database insertion
- API transformation
- JSON conversion
- Model mapping
- Local storage
- Retrieval

Pay particular attention to:

- Nullable fields
- Lists
- Nested objects
- Images
- Dates
- Enums
- Numeric values
- Long strings

---

# 18. EDIT FUNCTIONALITY

Audit every edit operation.

For example:

```text id="u5m9q2"
Existing meal
 ↓
Edit
 ↓
Save
 ↓
Only intended fields change
```

Ensure editing one field does not accidentally erase unrelated fields.

Test:

- Meal edits
- Symptom edits
- Chat metadata edits
- User profile edits
- Scan records if editable

---

# 19. DELETE FUNCTIONALITY

Audit deletion carefully.

Determine:

- What happens when a meal is deleted?
- What happens to associated symptoms?
- What happens to images?
- What happens to AI analysis?
- What happens to references?
- What happens to streak/insight calculations?

Do not automatically cascade-delete related data unless that is the intended product behavior.

Document the current relationship and correct any accidental orphaned records.

---

# 20. Offline & Sync

If GutGood supports local-first/offline functionality, audit:

```text id="c3w7m8"
Local Write
 ↓
Local Persistence
 ↓
Sync Queue
 ↓
Backend
 ↓
Conflict Resolution
 ↓
Local State
```

Test:

- Offline creation
- Offline editing
- Offline deletion
- App restart
- Network reconnect
- Duplicate sync
- Failed sync
- Partial sync
- Conflict resolution

Never silently lose locally created data.

---

# 21. Pagination & Saved Data

Audit pagination for every historical dataset:

- Chat history
- Meal history
- Symptom history
- Scan history
- Insight history if applicable

Verify:

- Correct ordering
- Cursor handling
- No duplicate records
- No missing records
- Stable ordering
- Loading state
- End-of-data state
- Retry
- Refresh
- New records appearing correctly

Do not load the entire history unnecessarily.

---

# 22. Cache Audit

Determine what is cached and why.

Identify:

- Source of truth
- Cache
- Cache invalidation
- Cache expiration
- Refresh behavior

Prevent stale cached data from overwriting newer persisted data.

---

# 23. Error Handling

Audit every save operation.

The application must distinguish between:

```text id="m4n8x2"
Saving
Saved
Failed
Retrying
```

Never show:

> "Saved successfully"

before persistence actually succeeds.

If a save fails:

- Preserve the user's data
- Show an appropriate error
- Allow retry
- Avoid duplicate records
- Avoid losing unsaved input

---

# 24. App Lifecycle & Data Loss

Test:

- App killed while saving
- App backgrounded while saving
- Network lost during save
- Screen closed during save
- User navigates away during save
- Device restarted
- Authentication expires during save

Identify any scenarios where user data can be lost.

---

# 25. AI-Generated Data

Audit all AI-generated information that is persisted.

For example:

- Meal analysis
- Meal rating
- Food analysis
- Chat responses
- Insights
- Pattern descriptions

Ensure the system knows the difference between:

```text id="b8r2m6"
Raw user data
```

and:

```text id="h4k9x1"
AI-generated interpretation
```

AI-generated content must not overwrite original user-entered data.

For example:

```text id="e6m1q8"
User meal:
"2 rotis + dal"

AI analysis:
"Balanced meal..."
```

The AI analysis should not become the only stored representation of what the user actually consumed.

---

# 26. Required Data for Future Insights

Because GutGood generates personalized insights, verify that the data being stored contains enough information for future analysis.

Do not save only:

```text id="w5p8s3"
"Bloating"
```

if the product requires context such as:

- Timestamp
- Severity
- Related meal
- Food
- Meal timing

Similarly, do not save only:

```text id="n7c2q4"
"Pizza"
```

if future analysis requires:

- Portion
- Ingredients
- Meal time
- Nutritional information

Determine the minimum useful data required for each feature.

---

# 27. Data Schema Quality

Review all models/entities for:

- Naming consistency
- Nullability
- Types
- IDs
- Relationships
- Serialization
- Defaults
- Validation
- Backward compatibility

Identify fields that are:

- Missing
- Duplicated
- Incorrectly typed
- Unnecessarily nullable
- Stored as strings when structured data is required

Do not change schemas unnecessarily.

---

# 28. Source of Truth

For every major entity explicitly determine:

```text id="k0v6x3"
Source of Truth:
Local DB / Backend / API / Firebase / Other
```

Then verify that:

```text id="j6p9w2"
UI
 ↓
State
 ↓
Repository
 ↓
Source of Truth
```

is consistent.

The UI should never become the authoritative storage layer.

---

# 29. Production-Grade Requirements

The final implementation must ensure:

- No silent data loss
- No duplicate records
- No incorrect ownership
- No incomplete critical records
- No incorrect timestamps
- No broken relationships
- No accidental overwrites
- No stale cache overwrites
- No incorrect pagination
- No fake "saved" states
- No data disappearing after restart
- No AI data overwriting raw user data
- No non-food records in food scan history

---

# 30. Final Audit Report

After reviewing and fixing the implementation, provide:

## A. Complete Data Architecture

Show:

```text id="f2k8m1"
User
 ↓
Feature
 ↓
Model
 ↓
Repository
 ↓
Persistence
 ↓
Source of Truth
 ↓
Retrieval
 ↓
State
 ↓
UI
```

## B. Data Inventory

For every major entity provide:

- Entity
- Required fields
- Optional fields
- ID
- Relationships
- Source of truth
- Persistence mechanism

## C. Critical Problems

For each problem:

- Severity
- File
- Location
- Root cause
- Impact
- Fix

Use:

- P0 Critical
- P1 High
- P2 Medium
- P3 Low

## D. Data Loss Risks

List every scenario where data could currently be lost.

## E. Duplicate Risks

List every scenario where duplicate records could currently be created.

## F. Missing Data

Identify records that currently do not store enough information for GutGood's future functionality.

## G. Fixes Implemented

Explain exactly what was changed.

## H. Testing

Verify:

- Create
- Read
- Update
- Delete
- Restart
- Offline
- Online
- Retry
- Pagination
- Duplicate prevention
- Timestamp handling
- User ownership
- Relationships

---

# FINAL ENGINEERING PRINCIPLE

Treat GutGood's saved data as **critical product data**.

A UI that displays a meal, chat, symptom, or scan does NOT mean the data has been successfully saved.

For every important user action, prove:

```text id="v1n7q3"
User Action
    ↓
Validated
    ↓
Correct Model
    ↓
Persisted
    ↓
Read Back
    ↓
Correctly Mapped
    ↓
Displayed
```

The final system should guarantee:

> **If GutGood tells the user that something was saved, the complete required data is actually persisted and can be reliably retrieved later.**

Do not just make the UI appear correct.

**Verify the entire data lifecycle and fix the underlying implementation.**

Do not change existing product functionality unless required to correct a data-integrity problem.