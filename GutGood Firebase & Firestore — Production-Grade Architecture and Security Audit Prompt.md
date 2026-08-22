Act as a **Principal Firebase Architect, Senior Flutter Engineer, and Google Cloud/Firestore Expert** with extensive experience designing production applications at scale.

You are joining the existing **GutGood Flutter codebase**.

Your task is to **completely audit, reverse-engineer, test, and improve the existing Firebase implementation**, including **Firebase Authentication, Cloud Firestore, Firebase Storage, security rules, indexes, data modeling, queries, offline behavior, synchronization, performance, scalability, and error handling**.

Do not blindly rewrite the Firebase architecture.

First understand exactly how the current application uses Firebase, identify the root causes of problems, and then implement production-grade improvements while preserving existing functionality.

The goal is:

**Secure → Correct → Reliable → Scalable → Cost-efficient → Offline-resilient → Maintainable → Production-ready**

---

# 1. FIRST: Reverse-Engineer the Complete Firebase Architecture

Before making any changes, inspect the entire codebase and identify every Firebase-related implementation.

Search for:

- Firebase initialization
- `firebase_core`
- Firebase Auth
- Firestore
- Firebase Storage
- Firebase Analytics
- Crashlytics
- Cloud Functions
- FCM
- Remote Config
- App Check
- Firebase configuration
- `google-services.json`
- `GoogleService-Info.plist`
- Firebase options
- Security Rules
- Firestore indexes
- Storage Rules
- Authentication configuration
- Firebase emulator configuration
- Environment configuration

Also inspect:

- Repositories
- Services
- Providers
- Notifiers
- Controllers
- Models
- DTOs
- Serialization
- Authentication state listeners
- Firestore listeners
- Storage upload/download logic

Do not rely only on filenames.

Trace the actual dependencies and data flow.

---

# 2. Create a Firebase Data-Flow Map

Document how data moves through GutGood.

For example:

```text
Flutter UI
   ↓
State Management
   ↓
Repository
   ↓
Firebase Service
   ↓
Firebase Auth / Firestore / Storage
   ↓
Firebase Response
   ↓
Model Mapping
   ↓
Application State
   ↓
UI
```

Adapt this diagram to the actual architecture.

Identify where:

- Authentication occurs
- Authorization occurs
- Data is validated
- Data is transformed
- Data is persisted
- Data is read
- Data is cached
- Data is synchronized
- Errors are handled

---

# 3. Firebase Authentication Audit

Perform a complete Firebase Auth review.

Inspect:

- Sign up
- Sign in
- Sign out
- Session persistence
- Auth state changes
- Email/password authentication
- Google Sign-In
- Apple Sign-In if present
- Anonymous authentication if present
- Password reset
- Email verification
- Account deletion
- Re-authentication
- Token handling
- Token refresh
- Account linking
- Multiple providers
- Duplicate accounts
- Disabled users
- Expired sessions

Determine whether authentication state is handled correctly throughout the app.

---

# 4. Auth State Management

Audit the relationship between:

```text
FirebaseAuth.instance.authStateChanges()
FirebaseAuth.instance.userChanges()
FirebaseAuth.instance.idTokenChanges()
```

Determine which stream is actually appropriate for each use case.

Look for:

- Duplicate auth listeners
- Auth listeners created inside widgets
- Memory leaks
- Incorrect provider lifecycle
- Auth state race conditions
- UI showing authenticated content before auth is resolved
- UI incorrectly showing logged-out state during token refresh
- Stale user data

Ensure authentication state has a clear source of truth.

---

# 5. Authentication Lifecycle

Test:

```text
App Start
 ↓
Firebase Initialization
 ↓
Auth State Resolution
 ↓
Authenticated / Unauthenticated
 ↓
Load User Data
```

Verify that the application does not:

- Flash the wrong screen
- Create duplicate user documents
- Load another user's data
- Query Firestore before authentication is resolved
- Lose state during token refresh
- Log users out unexpectedly

---

# 6. User Document Architecture

Inspect the Firestore user model.

Determine whether the structure is something like:

```text
users/{uid}
```

and identify:

- User profile
- Preferences
- Settings
- Subscription state
- Onboarding state
- Streak data
- Meal data
- Chat data
- Insight data
- Scan history
- Symptoms
- Other user-specific information

Determine whether data is stored in:

```text
users/{uid}/subcollection/{document}
```

or:

```text
collection/{uid}
```

or other structures.

Evaluate whether the current structure is:

- Secure
- Queryable
- Scalable
- Cost-efficient
- Maintainable

Do not change the schema unnecessarily.

---

# 7. Firestore Data Modeling Audit

Perform a deep Firestore schema review.

For every collection identify:

- Collection purpose
- Document structure
- Document size
- Relationships
- Ownership
- Read patterns
- Write patterns
- Query patterns
- Index requirements
- Expected growth
- Retention requirements

Look for:

- Excessive nesting
- Excessive denormalization
- Under-normalization
- Duplicate data
- Large documents
- Hot documents
- Unbounded arrays
- Unbounded subcollections
- Data that should be separated
- Data that should be embedded

Do not automatically normalize everything.

Firestore data modeling should be based on **actual read/write patterns**.

---

# 8. Firestore Security Rules — CRITICAL

Perform a complete security audit of Firestore Rules.

Do not simply check whether the rules compile.

Verify:

- Authentication checks
- UID ownership
- Read permissions
- Create permissions
- Update permissions
- Delete permissions
- Field-level restrictions
- Role-based access
- Immutable fields
- Server-managed fields
- User-controlled fields
- Cross-user access
- Collection group access
- Nested subcollection access

Look specifically for dangerous rules such as:

```text
allow read, write: if request.auth != null;
```

or:

```text
allow read, write: if true;
```

These are unacceptable unless there is an extremely specific and justified use case.

---

# 9. Prevent Cross-User Data Access

This is critical for GutGood.

A user must never be able to read or modify another user's:

- Meals
- Chat messages
- Conversations
- Food scans
- Symptoms
- Insights
- Streak data
- Profile
- Personal data
- Uploaded images
- Other private information

Verify ownership at the Firestore Rules level.

Do not rely solely on Flutter code to enforce ownership.

---

# 10. Field-Level Security

Audit whether users can modify fields they should not control.

For example, determine whether the client can arbitrarily change:

```text
uid
createdAt
updatedAt
role
subscriptionStatus
isAdmin
verified
serverCalculatedValue
streak
permissions
```

Where appropriate:

- Make immutable fields immutable
- Use server timestamps
- Validate allowed fields
- Prevent privilege escalation

Do not trust client-provided authorization information.

---

# 11. Firebase Storage Security Audit

If GutGood uses Firebase Storage, inspect:

- Food images
- Profile images
- Chat attachments
- Uploaded files
- Temporary files
- Generated files

Audit Storage Rules.

Verify:

- Authentication requirements
- User ownership
- File path structure
- File size restrictions
- MIME type validation
- Unauthorized downloads
- Unauthorized uploads
- Unauthorized deletion

For example, a path such as:

```text
users/{uid}/chat/{file}
```

should be protected so that the authenticated user can only access their own files.

---

# 12. Firestore Queries

Find every Firestore query.

Audit:

- `where`
- `orderBy`
- `limit`
- `startAfter`
- `startAt`
- `endBefore`
- `snapshots`
- `get`
- `add`
- `set`
- `update`
- `delete`
- transactions
- batched writes

For each query determine:

- Why it exists
- Expected result size
- Required indexes
- Cost
- Pagination
- Whether it is duplicated
- Whether it can be optimized

---

# 13. Firestore Pagination

Audit every paginated Firestore query.

Prefer cursor-based pagination such as:

```text
limit()
startAfterDocument()
```

or an equivalent cursor strategy.

Avoid loading unbounded collections.

Verify:

- First page
- Next page
- Last page
- Empty page
- Duplicate documents
- Ordering consistency
- New documents arriving during pagination
- Deleted documents
- Concurrent requests
- Loading locks
- `hasMore`
- Cursor persistence

Pagination must not cause duplicate or skipped records.

---

# 14. Realtime Listeners

Audit all:

```text
snapshots()
```

listeners.

Determine whether realtime listeners are actually necessary.

Look for:

- Listeners that never get disposed
- Listeners attached to widgets unnecessarily
- Multiple listeners on the same collection
- Listening to huge collections
- Realtime listeners where a one-time query would be sufficient
- Excessive read costs

For every listener ask:

> Does this screen genuinely require realtime updates?

If not, consider a normal query.

---

# 15. Firestore Cost Optimization

Review the implementation from a Firebase billing perspective.

Identify:

- Excessive reads
- Repeated reads
- Duplicate listeners
- Large result sets
- Unbounded queries
- Unnecessary document reads
- Repeated profile fetching
- Re-fetching unchanged data
- Inefficient pagination
- Poor caching

Do not optimize only for performance.

Optimize for:

**Performance + Correctness + Firebase cost.**

---

# 16. Firestore Offline Behavior

Audit Firestore offline persistence.

Determine:

- Whether offline persistence is enabled
- What happens when offline
- How writes are queued
- How reads behave
- How conflicts are handled
- How the UI displays pending writes
- How synchronization works after reconnect

Test:

```text
Offline
 ↓
Create meal
 ↓
Create chat message
 ↓
Close app
 ↓
Reopen app
 ↓
Internet returns
 ↓
Data synchronizes
```

Ensure data is not accidentally duplicated.

---

# 17. Data Synchronization

Audit synchronization between:

```text
Local State
Firebase Cache
Firestore
UI
```

Look for:

- Stale data
- Last-write-wins problems
- Duplicate writes
- Race conditions
- Lost updates
- Optimistic update failures
- Incorrect merge behavior

Determine the correct source of truth for each type of data.

---

# 18. Server Timestamps

Audit timestamp handling.

Avoid relying unnecessarily on:

```dart
DateTime.now()
```

for server-authoritative timestamps.

Where appropriate use:

```text
FieldValue.serverTimestamp()
```

or the equivalent current Firebase SDK mechanism.

Verify:

- `createdAt`
- `updatedAt`
- meal timestamps
- chat timestamps
- activity dates
- sync timestamps

Be especially careful with timezone-sensitive features such as:

- Streaks
- Meal timing
- Daily insights
- Activity history

---

# 19. Transactions & Atomic Writes

Identify operations that require atomicity.

Look for code such as:

```text
Read
 ↓
Calculate
 ↓
Write
```

where concurrent users/devices could cause incorrect results.

Determine whether a:

- Transaction
- Batched write
- Atomic field operation

is required.

Do not use transactions unnecessarily.

---

# 20. Duplicate Data & Idempotency

Audit whether operations can safely be retried.

For example:

```text
Send message
 ↓
Network timeout
 ↓
Retry
```

must not necessarily create two messages.

Check:

- Client-generated IDs
- Server IDs
- Idempotency
- Duplicate prevention
- Retry behavior
- Offline synchronization

This is especially important for:

- Chat messages
- Meals
- Food scans
- Symptoms
- Streak activities

---

# 21. Firebase Initialization

Audit Firebase initialization.

Verify:

- Initialization happens exactly once
- Correct environment is loaded
- Initialization errors are handled
- Firebase is not accessed before initialization
- Background isolates are handled correctly if applicable
- Platform configuration is correct

Look for unnecessary initialization duplication.

---

# 22. Environment Management

Audit whether development, staging, and production Firebase environments are separated appropriately.

Check:

- Firebase project IDs
- Configuration files
- API keys
- Environment variables
- Build flavors
- Debug vs release configuration

Never expose sensitive secrets unnecessarily.

Remember:

**Firebase client configuration values are not equivalent to server-side secrets.**

Identify anything that genuinely must not be shipped in the client.

---

# 23. Firebase App Check

Determine whether Firebase App Check is appropriate for GutGood.

Review whether it should protect:

- Firestore
- Storage
- Cloud Functions
- Other Firebase services

If it is already implemented, verify it correctly.

Do not enable it blindly without understanding development/testing implications.

---

# 24. Cloud Functions / Backend Logic

If Cloud Functions exist, audit:

- Trigger architecture
- Callable functions
- HTTP functions
- Authentication
- Authorization
- Validation
- Error handling
- Retry behavior
- Idempotency
- Cold starts
- Region configuration
- Firestore triggers
- Recursive triggers
- Logging
- Secrets
- Runtime versions

Ensure privileged operations are performed server-side when appropriate.

---

# 25. AI + Firebase Integration

Because GutGood is an AI application, specifically audit how Firebase interacts with AI.

Review:

- Chat persistence
- Conversation storage
- Message storage
- AI request state
- AI response state
- Streaming
- Failed generations
- Retry
- Attachments
- Image storage
- AI metadata

Ensure the system does not accidentally persist:

- Temporary prompts
- Internal system instructions
- API keys
- Sensitive debugging information
- Unnecessary duplicated AI context

---

# 26. Firebase Auth + Firestore Race Conditions

Test scenarios such as:

```text
App starts
 ↓
Auth still loading
 ↓
Firestore query starts
```

and:

```text
User signs out
 ↓
Firestore request still running
 ↓
Request completes
 ↓
Old user's data appears
```

Prevent stale authenticated data from leaking into another session.

Also test:

```text
User A
 ↓
Logout
 ↓
User B login
 ↓
User A's cached state appears
```

This must never happen.

---

# 27. Error Handling

Audit Firebase exceptions.

Do not simply:

```dart
catch (e) {
  print(e);
}
```

Map Firebase errors into meaningful application-level errors.

Handle:

- Permission denied
- Unauthenticated
- Network failure
- Deadline exceeded
- Not found
- Already exists
- Resource exhausted
- Invalid arguments
- Storage failures
- Auth failures

Do not expose internal Firebase errors directly to users.

---

# 28. Security Logging

Ensure logs do not accidentally contain:

- Authentication tokens
- Passwords
- API keys
- Private user data
- Full chat history
- Sensitive health information
- Storage URLs containing sensitive information

Use appropriate logging levels.

Remove debug logging from production where necessary.

---

# 29. Testing Firebase Security Rules

Do not assume rules are secure because they look correct.

Create tests for:

### Authentication

- Unauthenticated user
- Authenticated user

### Ownership

- User A reads User A data
- User A reads User B data
- User A writes User A data
- User A writes User B data

### Updates

- Allowed fields
- Forbidden fields
- Immutable fields

### Deletes

- Own data
- Another user's data

### Storage

- Own file
- Another user's file
- Invalid file type
- Oversized file

### Privileged fields

Attempt to modify:

- Role
- Admin
- Subscription
- UID
- Server-managed values

All unauthorized operations must fail.

---

# 30. Firestore Index Audit

Inspect:

- `firestore.indexes.json`
- Existing composite indexes
- Query requirements

Identify:

- Missing indexes
- Unnecessary indexes
- Duplicate indexes
- Expensive query patterns

Do not add indexes blindly.

Only add indexes required by actual query patterns.

---

# 31. Scalability Audit

Evaluate how the Firebase architecture behaves with:

```text
1,000 users
10,000 users
100,000 users
1,000,000+ users
```

Consider:

- Firestore reads
- Firestore writes
- Hot documents
- Realtime listeners
- Large collections
- Large documents
- Chat history
- Meal history
- Insight generation
- Storage growth
- Cloud Functions
- Authentication
- Query performance

Identify anything that may become a bottleneck at scale.

---

# 32. Data Retention & Cleanup

Audit whether temporary data is cleaned up.

Look for:

- Temporary images
- Failed uploads
- Deleted user data
- Orphaned storage files
- Old chat data
- Unused documents
- Temporary AI records

If cleanup is required, identify the safest implementation.

Do not delete historical user data without an explicit product requirement.

---

# 33. User Account Deletion

If account deletion exists, verify that deleting a user correctly handles:

```text
Firebase Auth account
 ↓
Firestore user data
 ↓
Subcollections
 ↓
Chat history
 ↓
Meal history
 ↓
Food scans
 ↓
Images/Storage
 ↓
Other user-specific data
```

Be careful: deleting a Firestore document does not automatically delete all nested subcollection documents.

Ensure orphaned data is not left behind where the product requires complete deletion.

---

# 34. Production Configuration

Audit release configuration for:

- Debug settings
- Logging
- Crashlytics
- App Check
- Firebase environments
- Rules deployment
- Index deployment
- Cloud Functions deployment
- Storage rules
- Authentication providers

Ensure development configuration cannot accidentally be shipped as production configuration.

---

# 35. Do Not Change Existing Functionality

This is critical.

Preserve:

- Existing authentication flows
- Existing user experience
- Existing Firestore features
- Existing chat functionality
- Existing meal tracking
- Existing food scanning
- Existing insights
- Existing streaks
- Existing storage functionality
- Existing navigation
- Existing business rules

Do not redesign the Firebase architecture just because you personally prefer another architecture.

Only change architecture when there is a clear:

**Security / Correctness / Performance / Cost / Scalability / Maintainability**

reason.

---

# 36. Implementation Rules

After the audit:

1. Identify critical Firebase problems.
2. Explain their root causes.
3. Prioritize them.
4. Fix security issues first.
5. Fix data-integrity issues next.
6. Fix correctness issues.
7. Improve performance and cost.
8. Improve architecture and maintainability.
9. Add tests.
10. Verify existing functionality.

Do not make a massive rewrite.

Prefer incremental, low-risk improvements.

---

# 37. Final Firebase Audit Report

Provide:

## Firebase Architecture

Explain the current Firebase architecture.

## Authentication Architecture

Explain:

- Auth providers
- Auth state
- Session lifecycle
- User provisioning

## Firestore Architecture

Document:

- Collections
- Documents
- Subcollections
- Relationships
- Read/write patterns

## Storage Architecture

Document:

- File paths
- Ownership
- Upload/download flow
- Security

## Security Findings

Classify:

- P0 — Critical security issue
- P1 — High
- P2 — Medium
- P3 — Low

## Performance Findings

Identify:

- Excessive reads
- Excessive writes
- Duplicate listeners
- Poor queries
- Poor pagination
- Large documents

## Cost Findings

Identify potential Firebase billing problems.

## Scalability Findings

Explain what will break or become expensive as the user base grows.

## Data Integrity Findings

Identify:

- Duplicate records
- Race conditions
- Lost updates
- Incorrect timestamps
- Sync problems

## Changes Implemented

Explain every Firebase-related change.

## Security Rules

Show the improved rules and explain the security model.

## Firestore Schema

Show the recommended/current schema.

## Query & Pagination Strategy

Explain the production-grade query approach.

## Testing

List all security, authentication, Firestore, Storage, and synchronization tests performed.

## Remaining Risks

Clearly identify anything that still requires future work.

---

# FINAL ENGINEERING PRINCIPLE

Treat GutGood's Firebase infrastructure as **production infrastructure, not just a database connection**.

Do not judge the system only by whether:

> "The data saves successfully."

Judge it by whether:

**The correct user can access the correct data, at the correct time, with predictable behavior, minimum unnecessary reads/writes, proper security, reliable synchronization, and acceptable cost at scale.**

Most importantly:

> **Never trust the Flutter client as the security boundary. Firebase Security Rules and server-side authorization must protect the data even if a malicious client bypasses the application UI.**

The final Firebase implementation should be:

**Secure + Correct + Reliable + Cost-efficient + Scalable + Offline-resilient + Maintainable + Production-ready.**