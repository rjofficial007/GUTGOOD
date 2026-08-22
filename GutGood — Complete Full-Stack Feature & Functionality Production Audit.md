# GutGood — Complete Full-Stack Feature & Functionality Audit

Act as a **Principal Software Engineer, Senior Flutter Engineer, Backend Architect, Firebase Architect, Cloud Functions Engineer, Database Engineer, Security Engineer, QA Engineer, and Product Engineer**.

You are joining the existing **GutGood AI application** as a senior engineer taking ownership of an unfamiliar production codebase.

Your responsibility is to perform a **complete end-to-end audit of the entire application** and ensure that **every existing feature and functionality works correctly across the complete stack**.

This is NOT a UI-only review.

You must review and understand:

- Flutter frontend
- State management
- Navigation
- API layer
- Backend
- Firebase
- Firestore / database
- Firebase Authentication
- Firebase Storage
- Cloud Functions
- AI integrations
- Notifications
- Background processing
- Local persistence/cache
- Security rules
- Data validation
- Error handling
- Loading states
- Pagination
- Offline behavior
- Synchronization
- Analytics if present
- App lifecycle
- Performance
- Scalability
- Data integrity
- Production configuration

---

# 1. FIRST: REVERSE-ENGINEER THE ENTIRE APPLICATION

Do NOT immediately start changing code.

First understand the architecture.

Build a mental model of:

```text
User
 ↓
Flutter UI
 ↓
State Management
 ↓
Repository / Service
 ↓
API / Firebase
 ↓
Cloud Functions / Backend
 ↓
Database / Storage
 ↓
External Services / AI
 ↓
Response
 ↓
Backend Processing
 ↓
Flutter State
 ↓
UI
```

Trace real data flows through the codebase.

Identify:

- Frontend entry points
- Backend entry points
- Firebase configuration
- Cloud Functions
- Firestore collections
- Storage buckets
- Authentication flow
- API endpoints
- AI endpoints
- Background jobs
- Scheduled functions
- Triggers
- Security rules
- Environment variables
- Configuration files

Do not assume the architecture from folder names.

Verify how the application actually works.

---

# 2. CREATE A COMPLETE FEATURE INVENTORY

Find every feature in the application.

At minimum audit:

## Authentication

- Sign up
- Login
- Logout
- Session restoration
- Authentication persistence
- Password reset if supported
- Google/Apple authentication if supported
- Account deletion
- Authentication error handling

## AI Chat

- New conversation
- Existing conversation
- Send message
- AI response
- Streaming if supported
- Retry
- Failed message
- Conversation history
- Saved chats
- Pagination
- Attachments
- Images
- AI context
- Chat persistence
- Conversation deletion
- Conversation rename

## Meal Logging

- Add meal
- Edit meal
- Delete meal
- Meal history
- Meal detail
- Food items
- Portions
- Nutrition
- Images
- AI meal analysis
- Meal rating
- Notes

## Symptom Logging

- Add symptom
- Edit symptom
- Delete symptom
- Severity
- Timestamp
- Duration
- Notes
- Related meal
- Related food
- Symptom history

## Food Scanner

- Barcode scanning
- Food recognition
- Open Food Facts integration if used
- Food validation
- Nutrition retrieval
- Food saving
- Scan history
- Invalid scan handling
- Non-food filtering

## Insights

- Insight generation
- Pattern detection
- Data requirements
- Insight persistence
- Insight retrieval
- Insight refresh
- Empty states
- Insufficient-data handling

## Streak

- Current streak
- Longest streak
- Daily activity
- Streak calculation
- Date handling
- Timezone
- Streak persistence
- Streak reset
- Calendar/history

## Profile / Settings

- Profile
- Preferences
- Dietary information
- Notifications
- Account settings
- Data management

## Any Other Feature

Search the complete codebase and include anything else you find.

---

# 3. FEATURE-BY-FEATURE END-TO-END AUDIT

For EVERY feature, trace:

```text
UI
 ↓
User Action
 ↓
Validation
 ↓
State
 ↓
Repository
 ↓
API / Firebase
 ↓
Backend
 ↓
Cloud Function
 ↓
Database
 ↓
Response
 ↓
State Update
 ↓
UI
```

Verify that every step works.

Do not declare a feature working simply because the UI exists.

---

# 4. FRONTEND AUDIT

Review the complete Flutter application.

Audit:

- Widget architecture
- Screens
- Components
- Navigation
- Routing
- State management
- Providers/notifiers/controllers
- Repositories
- Services
- Models
- DTOs
- Serialization
- API clients
- Firebase integration
- Local storage
- Error handling
- Loading states
- Empty states
- Pagination
- Refresh
- Lifecycle
- Memory management
- Async operations
- Streams
- List rendering
- Image handling

Look for:

- Duplicate logic
- Business logic inside widgets
- Excessive rebuilds
- Race conditions
- Memory leaks
- Incorrect provider lifecycle
- State resets
- Stale state
- Unnecessary API calls
- Repeated Firebase queries
- Incorrect navigation
- Broken back behavior
- Hardcoded data
- Magic numbers
- Poor error handling

---

# 5. STATE MANAGEMENT AUDIT

Review the entire state-management architecture.

Determine:

- What is the source of truth?
- Which providers own which state?
- Where is business logic located?
- Where is persistence handled?
- Where are async states handled?

Look for:

```text
UI state
+
Provider state
+
Repository state
+
Cache
+
Firebase state
```

containing conflicting versions of the same data.

Prevent inconsistent state.

Verify:

- Loading
- Success
- Error
- Empty
- Refresh
- Pagination
- Retry
- Optimistic updates
- Rollback
- Concurrent requests

---

# 6. BACKEND AUDIT

Review the complete backend.

Audit:

- API architecture
- Routes
- Controllers
- Services
- Repositories
- Database queries
- Authentication
- Authorization
- Validation
- Error handling
- Logging
- Rate limiting
- Caching
- Transactions
- Concurrency
- Idempotency

Verify that backend logic is actually authoritative where it should be.

Do not trust frontend-provided values for important business logic.

---

# 7. FIREBASE AUDIT

Review the entire Firebase implementation.

Inspect:

- Firebase Authentication
- Firestore
- Firebase Storage
- Cloud Functions
- Security Rules
- App Check if used
- Remote Config if used
- Analytics if used
- Crashlytics if used
- Messaging/FCM if used

Verify Firebase configuration separately for:

- Development
- Staging
- Production

if those environments exist.

---

# 8. FIRESTORE AUDIT

Map the complete Firestore schema.

For every collection/document determine:

```text
Collection
 ↓
Document
 ↓
Fields
 ↓
Relationships
 ↓
Owner
 ↓
Read Operations
 ↓
Write Operations
 ↓
Delete Operations
```

Check:

- Required fields
- Optional fields
- Document IDs
- User ownership
- Relationships
- Timestamps
- Indexes
- Queries
- Pagination
- Sorting
- Duplicate prevention

Look for:

- Unbounded queries
- Full collection reads
- N+1 queries
- Missing indexes
- Excessive reads
- Duplicate documents
- Orphaned documents
- Incorrect user ownership
- Race conditions

---

# 9. FIRESTORE SECURITY RULES

Audit Firebase Security Rules very carefully.

Verify that users cannot:

- Read another user's chats
- Modify another user's meals
- Read another user's symptoms
- Modify another user's insights
- Access another user's scan history
- Access another user's profile
- Upload unauthorized files
- Delete another user's data

Verify that rules enforce:

```text
Authenticated User
+
Correct User Ownership
+
Correct Operation
+
Valid Data
```

Do not rely only on Flutter-side checks.

Frontend checks are NOT security.

---

# 10. FIREBASE STORAGE AUDIT

Review all uploaded files and images.

Verify:

- Upload authentication
- User ownership
- File paths
- File naming
- MIME validation
- File size limits
- Unauthorized access
- Delete behavior
- Orphaned files
- Image references
- Failed upload handling

Ensure a deleted meal/chat does not leave unnecessary orphaned files unless intentionally retained.

---

# 11. CLOUD FUNCTIONS AUDIT

Review EVERY Cloud Function.

For each function determine:

- Trigger
- Input
- Authentication requirement
- Validation
- Business logic
- Database reads
- Database writes
- External APIs
- AI calls
- Error handling
- Retry behavior
- Timeout
- Memory usage
- Concurrency
- Idempotency
- Logging
- Security

Categorize functions:

```text
HTTP
Callable
Firestore Trigger
Storage Trigger
Scheduled
Background
Queue
```

---

# 12. CLOUD FUNCTION FAILURE ANALYSIS

For every Cloud Function test:

```text
Success
Failure
Timeout
Retry
Duplicate invocation
Invalid input
Missing authentication
Database failure
External API failure
AI failure
Partial completion
```

Pay special attention to duplicate execution.

Cloud Functions can be retried.

Therefore operations must not blindly create duplicate:

- Messages
- Meals
- Insights
- Notifications
- Streak records
- Database documents

Implement idempotency where required.

---

# 13. AI PIPELINE AUDIT

Review every AI-related flow.

Trace:

```text
User Input
 ↓
Frontend
 ↓
Backend / Function
 ↓
Prompt Construction
 ↓
Context Retrieval
 ↓
AI API
 ↓
Response Validation
 ↓
Persistence
 ↓
Flutter UI
```

Verify:

- Correct prompt
- Correct context
- Correct user data
- Token limits
- Error handling
- Timeout
- Retry
- Rate limits
- Invalid AI output
- Malformed JSON
- Missing fields
- AI hallucination risks
- Duplicate requests
- Cost/scalability concerns

AI output must never silently overwrite raw user data.

---

# 14. GUTGOOD DATA INTEGRITY

Verify that all saved data is complete and correctly related.

Audit:

- Chats
- Messages
- Meals
- Food items
- Symptoms
- Scan history
- Insights
- Streaks
- User data
- Images
- AI analysis

For every record verify:

```text
Created
 ↓
Saved
 ↓
Retrieved
 ↓
Displayed
 ↓
Edited
 ↓
Saved Again
 ↓
Deleted
```

No silent data loss.

No incomplete records.

No incorrect relationships.

No duplicate records.

---

# 15. FRONTEND ↔ BACKEND CONTRACT AUDIT

Compare:

```text
Flutter Model
vs
Request DTO
vs
Backend DTO
vs
Database Schema
vs
Response DTO
```

Look for:

- Missing fields
- Extra fields
- Incorrect types
- Nullable mismatches
- Enum mismatches
- Date mismatches
- Naming mismatches
- Serialization issues

A field should not be:

```text
Flutter: String
Backend: int
Database: timestamp
```

without explicit and correct transformation.

---

# 16. ERROR HANDLING

Every important operation must distinguish:

```text
Loading
Success
Empty
Failure
Retrying
```

Review:

- Network errors
- Firebase errors
- Auth errors
- Backend errors
- AI errors
- Storage errors
- Database errors
- Validation errors
- Timeout errors

Do not silently swallow exceptions.

Do not show "success" before the operation actually succeeds.

---

# 17. OFFLINE / NETWORK BEHAVIOR

If offline/local functionality exists, test:

```text
Offline
 ↓
Create data
 ↓
Persist locally
 ↓
App restart
 ↓
Network returns
 ↓
Sync
```

Check:

- Duplicate sync
- Conflict resolution
- Failed sync
- Partial sync
- Retry
- Ordering
- Data loss

---

# 18. PAGINATION AUDIT

Audit pagination everywhere.

Verify:

- Initial request
- Cursor/page
- Next page
- End of data
- Duplicate prevention
- Stable sorting
- Refresh
- Retry
- Concurrent requests

Never use:

```text
load entire collection
```

for potentially large user histories.

---

# 19. PERFORMANCE AUDIT

Find:

- Expensive rebuilds
- Large Firestore reads
- Repeated queries
- N+1 queries
- Large payloads
- Unoptimized images
- Heavy AI requests
- Expensive Cloud Functions
- Repeated calculations
- Memory leaks
- Unnecessary serialization
- Excessive network calls

Prioritize actual bottlenecks instead of premature optimization.

---

# 20. SCALABILITY AUDIT

Assume GutGood grows from:

```text
1,000 users
→ 100,000 users
→ 1,000,000 users
```

Determine whether the architecture can scale.

Look for:

- Hot Firestore documents
- Unbounded arrays
- Large documents
- Expensive queries
- Full-history reads
- Sequential Cloud Functions
- Global bottlenecks
- AI rate limits
- Storage growth
- Notification scalability

Recommend production-grade solutions.

---

# 21. SECURITY AUDIT

Review:

- Authentication
- Authorization
- Firebase Rules
- API authorization
- Secrets
- API keys
- Environment variables
- Storage access
- User ownership
- Input validation
- Injection risks
- Rate limiting
- Abuse prevention
- Sensitive data exposure

Never expose private server credentials in Flutter.

Check the entire repository for accidentally committed secrets.

---

# 22. AUTHORIZATION

Authentication means:

> Who is this user?

Authorization means:

> What is this user allowed to access?

Verify both.

A logged-in user must not automatically be allowed to access arbitrary records.

Every user-specific backend operation must verify ownership.

---

# 23. APP LIFECYCLE

Test:

- Cold start
- Warm start
- Background
- Resume
- Force close
- Network loss
- Network recovery
- Authentication expiration
- App restart
- Device restart

Ensure state remains correct.

---

# 24. NAVIGATION AUDIT

Review all navigation flows.

Test:

```text
Login
 ↓
Home
 ↓
Chat
 ↓
Meal
 ↓
Symptom
 ↓
Scan
 ↓
Insights
 ↓
Profile
```

Check:

- Back navigation
- Deep links
- Auth redirects
- State restoration
- Duplicate routes
- Dialog navigation
- Bottom sheets
- Unsaved changes
- Navigation during async operations

---

# 25. LOADING / SHIMMER / EMPTY STATES

Every major data-driven screen must have:

### Loading

Proper skeleton/shimmer.

### Empty

Meaningful empty state.

### Error

Useful error + retry.

### Pagination

Non-disruptive loading indicator.

### Refresh

Correct refresh state.

Do not display misleading `0`, empty cards, or fake data while loading.

---

# 26. LOGGING & OBSERVABILITY

Review:

- Crashlytics
- Firebase logs
- Cloud Function logs
- Backend logs
- Error reporting
- Performance monitoring

Ensure important production failures can be diagnosed.

Do not log sensitive user data unnecessarily.

---

# 27. TESTING

Review existing tests.

Identify missing tests.

Add tests for:

### Unit

- Business logic
- Streak calculation
- Validation
- Mapping
- Pagination
- Data transformation

### Widget

- Loading
- Empty
- Error
- Data display
- User interactions

### Integration

- Login
- Chat
- Meal logging
- Symptom logging
- Scanner
- Insights
- Persistence

### Backend

- Authentication
- Authorization
- API
- Database
- Cloud Functions

### End-to-End

Test critical user journeys from:

```text
Flutter
 ↓
Backend/Firebase
 ↓
Database
 ↓
Cloud Function
 ↓
Response
 ↓
Flutter
```

---

# 28. DO NOT BREAK EXISTING FUNCTIONALITY

This is critical.

Before changing anything:

Understand the current behavior.

Do not remove working functionality.

Do not redesign business rules unless there is a clear bug.

Do not replace working architecture merely because you prefer another architecture.

Improve:

- Correctness
- Reliability
- Performance
- Security
- Maintainability
- Scalability
- Testability

while preserving intended product behavior.

---

# 29. PRIORITIZE ISSUES

Classify every issue:

### P0 — Critical

Data loss, security vulnerability, broken core functionality.

### P1 — High

Major feature failure, incorrect data, serious scalability problem.

### P2 — Medium

Maintainability, performance, UX, non-critical bugs.

### P3 — Low

Minor cleanup or optimization.

Do not spend most of the time fixing P3 issues while P0/P1 problems remain.

---

# 30. IMPLEMENT THE FIXES

Do not stop at reporting problems.

After completing the audit:

1. Identify the root cause.
2. Explain the impact.
3. Implement the fix.
4. Update affected layers.
5. Add/update tests.
6. Verify related functionality.
7. Check for regressions.

Do not apply superficial patches.

Fix the underlying architecture/problem.

---

# 31. FINAL PRODUCTION VERIFICATION

Before considering the audit complete, verify:

## Authentication

- [ ] Login works
- [ ] Logout works
- [ ] Session restoration works
- [ ] Authorization is enforced

## Chat

- [ ] Messages send
- [ ] AI responds
- [ ] Responses persist
- [ ] Conversations persist
- [ ] Pagination works
- [ ] Retry works
- [ ] No duplicates
- [ ] No data loss

## Meals

- [ ] Create works
- [ ] Read works
- [ ] Edit works
- [ ] Delete works
- [ ] Nutrition persists
- [ ] Images persist
- [ ] History works

## Symptoms

- [ ] Create works
- [ ] Read works
- [ ] Edit works
- [ ] Delete works
- [ ] Severity persists
- [ ] Timing persists
- [ ] Relationships work

## Scanner

- [ ] Barcode scanning works
- [ ] Food lookup works
- [ ] Invalid results handled
- [ ] Non-food items excluded
- [ ] Valid foods saved
- [ ] Scan history works

## Insights

- [ ] Correct data source
- [ ] Required data validation
- [ ] No fake insights
- [ ] Correct persistence
- [ ] Correct display

## Streak

- [ ] Correct calculation
- [ ] Correct timezone
- [ ] Correct persistence
- [ ] Correct reset behavior
- [ ] Correct longest streak

## Firebase

- [ ] Authentication
- [ ] Firestore
- [ ] Storage
- [ ] Security Rules
- [ ] Cloud Functions
- [ ] Indexes
- [ ] Error handling

## Backend

- [ ] APIs work
- [ ] Authentication works
- [ ] Authorization works
- [ ] Validation works
- [ ] Database operations work
- [ ] Error handling works
- [ ] Idempotency works where required

## UX

- [ ] Loading states
- [ ] Shimmer
- [ ] Empty states
- [ ] Error states
- [ ] Pagination
- [ ] Refresh
- [ ] Responsive UI
- [ ] Accessibility

---

# 32. FINAL REPORT

At the end, provide a professional engineering report containing:

## 1. Architecture Overview

Explain the complete current architecture.

## 2. Complete Data Flow

Show how data moves through:

```text
Flutter
 ↓
State
 ↓
Repository
 ↓
Backend/Firebase
 ↓
Cloud Functions
 ↓
Database
 ↓
External APIs/AI
 ↓
Response
 ↓
Flutter
```

## 3. Feature Matrix

Create:

| Feature | Frontend | Backend | Firebase | Cloud Function | Database | Status |
|---|---|---|---|---|---|---|

Use:

- ✅ Working
- ⚠️ Needs improvement
- ❌ Broken

## 4. Critical Issues

List P0/P1/P2/P3 issues.

## 5. Data Integrity Issues

List:

- Data loss
- Missing fields
- Duplicate records
- Incorrect relationships
- Stale data
- Incorrect timestamps

## 6. Security Issues

List:

- Authentication problems
- Authorization problems
- Firebase Rule problems
- Storage problems
- Secret exposure
- API vulnerabilities

## 7. Performance Issues

List:

- Expensive queries
- Unnecessary requests
- Rebuilds
- Memory issues
- AI/API bottlenecks

## 8. Scalability Risks

Explain what will break as the user base grows.

## 9. Fixes Implemented

List every meaningful code change.

## 10. Tests Added

List all tests created/updated.

## 11. Remaining Issues

Clearly state anything that could not be fixed or verified.

---

# IMPORTANT RULES

### Rule 1

**Do not assume something works because the code compiles.**

### Rule 2

**Do not assume Firebase is secure because Firebase Authentication exists.**

### Rule 3

**Do not assume data is saved because it appears on the screen.**

### Rule 4

**Do not assume a Cloud Function is reliable because the happy path works.**

### Rule 5

**Do not assume AI responses are valid because the API returned HTTP 200.**

### Rule 6

**Do not assume pagination works because a second page loads.**

Verify duplicates, missing records, ordering, retries, and end-of-data behavior.

### Rule 7

**Do not silently swallow errors.**

### Rule 8

**Do not introduce mock/fake data to hide backend problems.**

### Rule 9

**Do not move business logic into the UI merely to make a feature appear functional.**

### Rule 10

**Backend/Firebase should be the source of truth for authoritative server-side data and business rules where applicable.**

### Rule 11

**Do not change existing product functionality unless required to fix an actual bug, security issue, data-integrity problem, or architectural defect.**

### Rule 12

**Do not perform a superficial review.**

Trace the real implementation across the entire stack.

---

# FINAL OBJECTIVE

Your final goal is not simply:

> "The app runs."

Your goal is:

> **GutGood should behave like a production-grade application where every feature works correctly from the user's interaction all the way through Flutter, state management, backend, Firebase, Cloud Functions, database, AI services, and back to the UI.**

For every important feature, prove:

```text
USER
 ↓
UI
 ↓
STATE
 ↓
BUSINESS LOGIC
 ↓
REPOSITORY
 ↓
API / FIREBASE
 ↓
BACKEND
 ↓
CLOUD FUNCTION
 ↓
DATABASE / STORAGE
 ↓
EXTERNAL SERVICE / AI
 ↓
RESPONSE
 ↓
STATE UPDATE
 ↓
UI UPDATE
```

**Find the problems. Explain the root causes. Fix them. Test them. Verify that the fixes do not break existing functionality.**

Treat the codebase as if you are preparing **GutGood for a real production launch with a large number of users**.