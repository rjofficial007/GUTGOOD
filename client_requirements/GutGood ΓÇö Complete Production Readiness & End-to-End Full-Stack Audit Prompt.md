# GutGood — Complete Production Readiness & End-to-End Full-Stack Audit

Act as a **Principal Software Engineer + Senior Flutter Architect + Firebase Architect + Cloud Functions Engineer + AI/LLM Engineer + Prompt Engineer + Database Engineer + Security Engineer + QA Engineer + UI/UX Engineer + Product Engineer**.

You are taking ownership of the existing **GutGood** production codebase.

Your job is to perform a **complete end-to-end audit of the actual application**, identify every issue that can cause incorrect behavior, inconsistent AI responses, data corruption, crashes, security problems, broken flows, duplicated data, incorrect UI state, or mismatch with GutGood's product requirements, and then **fix the issues in the codebase without breaking existing functionality**.

This is NOT a simple code review.

The final objective is:

> **Every user action should travel through one predictable pipeline and return the correct GutGood result every time.**

---

# 1. PRODUCT CONTRACT

First understand the actual GutGood product requirements.

GutGood is an AI food/body intelligence application.

Core product flow:

```text
User
 ↓
Chat / Photo / Camera / Barcode
 ↓
AI understands user input
 ↓
AI determines image type + user intent
 ↓
Correct analysis pipeline
 ↓
Correct prompt
 ↓
AI structured response
 ↓
Response parser
 ↓
Database persistence
 ↓
Pattern Engine
 ↓
Gut Score / Insights
 ↓
Flutter UI
```

The application must remain:

- AI-first
- Conversation-first
- Personalized
- Minimal manual logging
- Food/body intelligence focused
- Not a calorie tracker
- Not a medical diagnosis application

The existing requirements explicitly define Chat, Food Scanner, Insights, Profile, authentication, subscriptions, Firebase, OpenAI, Open Food Facts and personalized pattern learning as core functionality. Audit against those requirements rather than inventing a different product.

---

# 2. DO NOT TRUST DOCUMENTATION

Do NOT assume the existing PRD or previous implementation is correct.

Do NOT assume folder names represent actual architecture.

Do NOT assume comments are accurate.

Do NOT assume a function works because it exists.

Trace the actual code.

For every major feature determine:

```text
UI
 ↓
Provider / State
 ↓
Use Case
 ↓
Repository
 ↓
Service
 ↓
Firebase / API / Cloud Function
 ↓
Response
 ↓
Parser
 ↓
Persistence
 ↓
Provider update
 ↓
UI
```

Find broken links in this chain.

---

# 3. FIRST BUILD AN ARCHITECTURE MAP

Before modifying code, inspect the complete repository.

Identify:

```text
Flutter
 ├── Screens
 ├── Widgets
 ├── Providers
 ├── State management
 ├── Use cases
 ├── Repositories
 ├── Services
 ├── Models
 ├── Database
 ├── Firebase
 ├── Storage
 ├── Authentication
 ├── AI
 ├── Scanner
 ├── Notifications
 ├── Subscription
 └── Configuration

Firebase
 ├── Authentication
 ├── Firestore
 ├── Storage
 ├── Cloud Functions
 ├── Scheduled Functions
 ├── Triggers
 ├── Rules
 └── App Check

External
 ├── OpenAI
 ├── Open Food Facts
 └── RevenueCat
```

Document how these actually communicate.

---

# 4. COMPLETE FRONTEND AUDIT

Review every screen and every user interaction.

Audit:

### Authentication

- Anonymous/guest authentication
- Signup
- Login
- Logout
- Apple Sign-In
- Google Sign-In
- Email authentication
- Email-link authentication
- Session restoration
- Auth state changes
- Account linking
- Anonymous → permanent account migration
- Failed authentication
- Recent-login requirements
- Account deletion

Verify that user data survives account conversion correctly.

---

# 5. CHAT AUDIT

Completely audit Chat.

Test:

```text
New chat
Existing chat
Send text
Send image
Send barcode
Send menu
Send ingredient label
Send nutrition label
Retry
Streaming
Network failure
Empty response
AI failure
Duplicate send
App backgrounding
App termination
Chat history reload
Chat persistence
Conversation switching
```

Verify:

```text
User message
+
Image
+
Conversation context
+
User profile
+
Relevant history
```

are sent correctly.

Make sure unrelated context is not accidentally included.

---

# 6. AI IMAGE CLASSIFICATION — NEW SINGLE SOURCE OF TRUTH

Remove manual image-mode assumptions from business logic.

AI must determine what an uploaded image represents.

Minimum supported modes:

```text
FOOD
RESTAURANT_MENU
PRODUCT_BARCODE
INGREDIENTS_LABEL
NUTRITION_LABEL
PACKAGED_PRODUCT
FOOD_RECIPE
OTHER
UNKNOWN
```

The classification must use:

```text
IMAGE
+
USER MESSAGE
+
RELEVANT CONTEXT
```

NOT:

```text
camera source
gallery source
scanner screen
route
button pressed
```

The image source must never determine the meaning of the image.

---

# 7. SAME IMAGE = SAME RESULT

This is a hard requirement.

Test the same image through:

```text
Camera
Gallery
Chat upload
Scanner upload
Re-upload
```

The resulting:

```text
image_mode
intent
analysis pipeline
response structure
```

must be equivalent.

Normalize:

- Orientation
- EXIF
- Resolution
- Compression
- MIME type
- Cropping
- Encoding

so that different upload mechanisms don't accidentally produce different AI inputs.

---

# 8. AI INTENT DETECTION

Remove manual intent detection from the primary decision flow.

AI must determine user intent.

Support at least:

```text
MEAL_RECOGNITION
MEAL_RATING
HEALTH_ASSESSMENT
IMPROVEMENT_REQUEST
SWAP_REQUEST
COMPLETE_ANALYSIS
INGREDIENT_ANALYSIS
NUTRITION_ANALYSIS
PRODUCT_IDENTIFICATION
MENU_RECOMMENDATION
NUTRITION_COMPARISON
GENERAL_FOOD_QUESTION
GENERAL_WELLNESS
```

Do not infer intent merely because a capability exists.

Examples:

```text
"my lunch"
→ MEAL_RECOGNITION

"rate my lunch"
→ MEAL_RATING

"is this healthy?"
→ HEALTH_ASSESSMENT

"what should I change?"
→ IMPROVEMENT_REQUEST

"what should I swap?"
→ SWAP_REQUEST

"tell me everything"
→ COMPLETE_ANALYSIS
```

---

# 9. IMAGE MODE AND INTENT ARE DIFFERENT

Never confuse:

```text
IMAGE_MODE
```

with:

```text
USER_INTENT
```

Example:

```text
IMAGE_MODE = FOOD
INTENT = MEAL_RATING
```

or:

```text
IMAGE_MODE = RESTAURANT_MENU
INTENT = MENU_RECOMMENDATION
```

or:

```text
IMAGE_MODE = NUTRITION_LABEL
INTENT = HEALTH_ASSESSMENT
```

The image determines what the content is.

The user request determines what they want to know about it.

---

# 10. ONE CANONICAL AI ROUTER

Create one authoritative routing layer.

Conceptually:

```text
AI Classification
       ↓
ImageMode + Intent
       ↓
AnalysisRouter
       ↓
Correct Prompt
       ↓
Correct Analyzer
       ↓
Correct Response Schema
```

Do not allow:

```text
Camera → old prompt
Gallery → different prompt
Barcode → separate hidden logic
Menu → UI-selected mode
Chat → another intent system
```

unless there is a legitimate product reason.

All paths must converge.

---

# 11. PROMPT AUDIT

Review every prompt in:

- prompts.dart
- mode_prompts.dart
- intent-aware prompts
- vision prompts
- pattern prompts
- insight prompts
- scan prompts
- Cloud Function prompts
- fallback prompts

Find:

- Contradictory instructions.
- Duplicate instructions.
- Old prompt behavior.
- Conflicting mode rules.
- Incorrect JSON requirements.
- Unnecessary tags.
- Prompt injection risks.
- Prompt sections that force unwanted output.
- Prompts that cause full reports when only a focused answer is required.

There must be one clear hierarchy:

```text
SYSTEM RULES
 ↓
SAFETY RULES
 ↓
IMAGE CLASSIFICATION
 ↓
USER INTENT
 ↓
RELEVANT USER CONTEXT
 ↓
ANALYSIS RULES
 ↓
OUTPUT SCHEMA
```

---

# 12. RESPONSE CONTRACT

Do not rely on fragile natural-language parsing.

Where structured data is required, use strict structured output/schema validation.

The system must distinguish:

```text
Visible response
Structured persistence data
UI metadata
Internal classification
```

Do not mix these together.

Avoid making UI behavior depend on arbitrary text such as:

```text
"---"
"N/A"
"None"
```

Normalize these values in the model/parser layer.

---

# 13. CHAT TAG / STRUCTURED DATA AUDIT

Audit:

```text
[MEAL]
[SYMPTOM]
[SCAN]
[SWAPS]
```

and all equivalent mechanisms.

Ensure streaming cannot persist the same event multiple times.

Every event needs a deterministic identity.

Use:

```text
eventId
messageId
conversationId
userId
source
createdAt
```

where appropriate.

Persistence must be idempotent.

The same AI response processed twice must NOT create duplicate database records.

---

# 14. STREAMING AUDIT

Streaming must never cause:

- Duplicate meals.
- Duplicate symptoms.
- Duplicate scans.
- Duplicate notifications.
- Duplicate Firestore writes.
- Duplicate chat messages.

Do not repeatedly parse the entire accumulated AI response unnecessarily.

Use a robust incremental parser or final structured response processing.

---

# 15. DATABASE AUDIT

Audit all local and cloud persistence.

Identify exactly where these are stored:

```text
User
Profile
Goals
Sensitivities
Lifestyle
Cycle
Chat
Meals
Symptoms
Scans
Saved foods
Insights
Patterns
Subscription
Usage
```

Do not create duplicate collections if the same information already exists.

Merge overlapping data models where appropriate.

Every stored record must have:

```text
userId
stable id
createdAt
updatedAt
source
```

when appropriate.

---

# 16. FIRESTORE DATA OWNERSHIP

Every user-owned document must be isolated by authenticated user identity.

Verify:

```text
request.auth.uid == resource.userId
```

or an equivalent secure ownership model.

Do not rely on the Flutter client correctly passing the user's UID.

Security must be enforced by Firestore Rules.

Audit:

- Read
- Create
- Update
- Delete
- Collection group queries
- Subcollections
- Storage access

---

# 17. FIRESTORE RULES

Locate and inspect:

```text
firestore.rules
storage.rules
```

If missing, create appropriate rules.

Verify:

- Anonymous users.
- Authenticated users.
- User-owned documents.
- Public/static documents.
- Admin-only operations.
- Server-side Cloud Function writes.
- Storage ownership.

Never leave permissive development rules in production.

---

# 18. CLOUD FUNCTIONS

Review every Cloud Function.

For every function determine:

```text
Who can call it?
What input does it accept?
What validation occurs?
What authentication is required?
What App Check is required?
What external APIs are called?
What database writes occur?
What happens on failure?
Is it idempotent?
Can it be abused?
Does it have rate limits?
```

Audit:

- HTTP functions.
- Callable functions.
- Firestore triggers.
- Scheduled functions.
- Background jobs.
- Subscription functions.
- Insight generation.
- AI calls.
- Open Food Facts calls.
- Notifications.

---

# 19. OPENAI SECURITY

The OpenAI API key MUST NEVER be shipped in the Flutter application.

Remove:

```text
hardcoded OpenAI keys
Remote Config OpenAI key fallbacks
client-side OpenAI API calls
```

Architecture should become:

```text
Flutter
 ↓
Authenticated Cloud Function
 ↓
Validate Auth
 ↓
Validate App Check
 ↓
Validate usage
 ↓
Validate request
 ↓
OpenAI
 ↓
Validate AI response
 ↓
Firestore
 ↓
Flutter
```

Rotate any key that has previously existed in source code.

---

# 20. OPEN FOOD FACTS

Audit:

```text
Barcode
 ↓
Open Food Facts
 ↓
Product normalization
 ↓
AI analysis
 ↓
Scan result
```

Handle:

- Product found.
- Product missing.
- Invalid barcode.
- API failure.
- Timeout.
- Missing nutrition.
- Missing ingredients.
- Multiple formats.
- Cached result.

Never allow missing Open Food Facts data to produce fabricated product information.

---

# 21. GUT SCORE

Find the exact Gut Score calculation.

Document:

```text
Inputs
Weights
Time range
Normalization
Missing data behavior
Positive signals
Negative signals
```

Do NOT let the AI invent the Gut Score.

AI can explain the score.

The calculation must be deterministic and testable.

Same input data should produce the same score.

---

# 22. INSIGHT ENGINE

Audit the Pattern Engine.

Supported patterns:

```text
Bloating
Energy
Headache
Digestion
Fullness
Sleep
```

Verify:

- Data sufficiency.
- Confidence.
- Recurrence.
- Timing.
- Correlation logic.
- False positives.
- Duplicate events.
- Timezone.
- Date calculations.

Never generate a strong pattern from insufficient data.

The product requirements explicitly call for personalized patterns rather than medical conclusions.

---

# 23. INSIGHT GENERATION

Do not generate fake insights.

The insight pipeline should be:

```text
Raw user events
 ↓
Normalize
 ↓
Deduplicate
 ↓
Pattern detection
 ↓
Confidence calculation
 ↓
Evidence selection
 ↓
AI explanation
 ↓
Persist insight
 ↓
Display
```

AI should explain evidence.

AI must not invent evidence.

Every insight should be traceable to underlying records.

---

# 24. INSIGHT UI

Use the new GutGood Insights design direction:

```text
Insights
 ↓
Gut Score Hero
 ↓
Trend
 ↓
Quick status
 ↓
Top Insights carousel
 ↓
Patterns to watch
 ↓
Recent logs
```

The Gut Score must be the hero.

Avoid the old generic stacked-card dashboard.

Use visual storytelling, interaction and discovery.

However, do not change business logic merely to achieve visual design.

The UI must consume the real data layer.

---

# 25. PROFILE

Audit:

- Goals.
- Sensitivities.
- Lifestyle.
- Cycle.
- Saved foods.
- Subscription.
- Notifications.
- Privacy.
- Account deletion.
- Logout.
- Account switching.

Profile updates must not unnecessarily reload unrelated screens.

For example:

```text
Profile update
```

must not cause:

```text
Chat messages → clear → reload
```

unless genuinely required.

---

# 26. AUTHENTICATION + ACCOUNT MERGE

This is critical.

Test:

```text
Guest
 ↓
Chat
 ↓
Meal
 ↓
Symptom
 ↓
Scan
 ↓
Sign in
 ↓
Permanent account
```

Verify that guest data is correctly transferred.

Do not lose:

- Chat history.
- Meals.
- Symptoms.
- Scans.
- Saved foods.
- Insights where appropriate.

Do not duplicate data during migration.

Migration must be idempotent.

---

# 27. SUBSCRIPTION / REVENUECAT

Audit:

- Offerings.
- Trial.
- Purchase.
- Restore.
- Cancellation.
- Expiration.
- Entitlements.
- Premium state.
- Free usage.
- Paywall.
- Failed purchase.
- Offline purchase state.

Never charge usage before the operation actually succeeds.

Never display a button label that does not match its action.

---

# 28. USAGE LIMITS

Verify:

```text
Free users
 ↓
Daily chat limit
 ↓
Daily scan limit
 ↓
Paywall
```

Usage must only be consumed after successful operations.

Examples:

Camera cancelled:

```text
usage = unchanged
```

AI request failed:

```text
usage = unchanged
```

Successful AI response:

```text
usage = increment
```

Make the behavior atomic wherever possible.

---

# 29. NOTIFICATIONS

Audit:

- Post-meal reminders.
- No-meal reminders.
- Symptom reminders.
- Restaurant reminders.
- Duplicate scheduling.
- Permission handling.
- Timezone.
- App restart.
- Notification cancellation.

Never schedule duplicate notifications from duplicate AI streaming events.

---

# 30. LOCAL DATABASE

Audit:

- Schema.
- Versioning.
- Migrations.
- Queries.
- Indexes.
- Transactions.
- Concurrent writes.
- Deletion.
- User switching.
- Logout.
- Offline state.

Every schema version must have a real migration path.

Do not leave empty `onUpgrade` blocks for schema changes.

---

# 31. OFFLINE / SYNC

Test:

```text
Offline
 ↓
Create chat/meal/scan
 ↓
App restarts
 ↓
Network returns
 ↓
Sync
```

Verify no duplicates.

Use stable IDs and idempotent writes.

Conflict resolution must be deterministic.

---

# 32. ERROR HANDLING

Every external operation must have:

```text
Loading
Success
Empty
Failure
Retry
```

Audit:

- OpenAI.
- Firebase.
- Open Food Facts.
- RevenueCat.
- Camera.
- Gallery.
- Barcode scanner.
- Storage.
- Notifications.

Do not silently swallow important errors.

---

# 33. ASYNC SAFETY

Search for:

```text
setState after await
context after await
mounted
disposed
listeners
streams
subscriptions
timers
controllers
```

Every provider and screen must correctly dispose:

- Stream subscriptions.
- Controllers.
- Listeners.
- Timers.
- Animation controllers.
- Text controllers.

---

# 34. NAVIGATION

Audit every route.

Verify:

```text
Push
Pop
Replacement
Deep navigation
Nested navigator
Bottom tabs
Auth transitions
Guest transitions
Paywall transitions
Scanner transitions
History transitions
```

Find dead screens and unreachable screens.

Remove misleading class names.

---

# 35. PERFORMANCE

Look for:

- O(n²) loops.
- Repeated DB reads.
- Repeated network requests.
- Full history reloads.
- Full list rebuilding.
- Repeated AI calls.
- Large Firestore reads.
- Excessive rebuilds.
- Image memory problems.
- Unnecessary regex processing.
- Duplicate RevenueCat calls.

Do not optimize prematurely, but fix measurable architectural inefficiencies.

---

# 36. AI COST CONTROL

Ensure the app does not unnecessarily call AI multiple times for the same request.

Consider:

```text
classification
analysis
insight generation
```

as distinct responsibilities.

Cache deterministic external data where appropriate.

Do not cache personalized AI responses in a way that causes stale user-specific information.

---

# 37. AI RESPONSE CONSISTENCY TESTING

Create a matrix.

For every supported mode:

```text
FOOD
MENU
BARCODE
INGREDIENT LABEL
NUTRITION LABEL
PRODUCT
```

test:

```text
"What is this?"
"Rate this."
"Is this healthy?"
"What should I change?"
"What should I swap?"
"Tell me everything."
```

Verify the output is appropriate for the combination.

Example:

```text
FOOD + "rate this"
→ rating

FOOD + "is this healthy?"
→ health assessment

FOOD + "what should I swap?"
→ swaps

MENU + "what should I order?"
→ menu recommendations

NUTRITION_LABEL + "how much protein?"
→ nutrition answer

INGREDIENTS_LABEL + "what ingredients stand out?"
→ ingredient analysis
```

Do not return the same generic report for every request.

---

# 38. SAFETY

Maintain GutGood's safety philosophy.

Never:

- Diagnose.
- Claim a food definitely caused a symptom.
- Claim a food will cure a condition.
- Present correlations as medical causation.
- Call ingredients "toxic" generically.

Use:

```text
may
might
appears
tends to
your history suggests
you reported
is associated with
```

The safety layer should avoid naive substring matching that creates false positives.

---

# 39. STRUCTURED AI DATA VALIDATION

Every AI-generated structured object must be validated before persistence.

If invalid:

```text
Do not write corrupt data.
```

Use:

```text
AI response
 ↓
Schema validation
 ↓
Normalization
 ↓
Business validation
 ↓
Persistence
```

Never allow arbitrary AI output to directly become trusted database state.

---

# 40. TEST DATA

Create realistic mock data for:

```text
Meals
Scans
Symptoms
Energy
Sleep
Digestion
Goals
Sensitivities
Chat
Patterns
```

Do NOT create fake insight records if the purpose is testing the Insight Engine.

Instead create the underlying raw data that should cause the engine to generate the expected insight.

This validates the actual system rather than the UI alone.

---

# 41. AUTOMATED TESTS

Add tests for the highest-risk logic.

At minimum:

```text
AI intent classification
Image mode classification
Prompt routing
Response parsing
Meal persistence
Symptom persistence
Idempotency
Pattern engine
Gut Score
Firestore ownership
Usage limits
Account merge
Subscription state
```

Especially test:

```text
same image
same message
different upload source
```

Expected:

```text
same image mode
same intent
same analysis route
equivalent response
```

---

# 42. STATIC ANALYSIS

Run:

```text
flutter analyze
dart analyze
flutter test
```

and relevant Firebase/Cloud Function checks.

Fix:

- Errors.
- Warnings that indicate real defects.
- Dead code.
- Unused imports.
- Type inconsistencies.
- Nullability problems.
- Async problems.

Do not hide warnings simply to achieve a clean build.

---

# 43. BUILD VALIDATION

Verify:

```text
Debug
Release
iOS
Firebase configuration
Cloud Functions
Environment configuration
Production API configuration
```

Ensure development credentials cannot accidentally ship in release builds.

---

# 44. SECURITY AUDIT

Check for:

- API keys.
- Tokens.
- Secrets.
- Firebase credentials.
- Environment variables.
- Logging of private data.
- User IDs in logs.
- Unsafe URLs.
- Insecure HTTP.
- Firestore rules.
- Storage rules.
- App Check.
- Rate limiting.
- Abuse protection.

Any secret previously committed to source should be considered compromised.

---

# 45. DATA PRIVACY

Audit whether the application stores only what it needs.

Especially inspect:

```text
Chat
Images
Meals
Symptoms
Goals
Sensitivities
Cycle data
User profile
```

Ensure deletion removes the appropriate user data.

Verify account deletion is real and complete.

---

# 46. DO NOT CREATE UNNECESSARY COLLECTIONS

Before creating any new collection:

1. Search existing collections.
2. Search existing models.
3. Search existing repositories.
4. Determine whether the same data already exists.
5. Reuse/merge when appropriate.

Avoid:

```text
meal_logs
meals
user_meals
ai_meals
chat_meals
```

containing overlapping representations of the same event.

Prefer one canonical source.

---

# 47. DO NOT BREAK CURRENT FUNCTIONALITY

This is extremely important.

Do not rewrite the entire application.

Do not replace working architecture simply because you prefer another architecture.

Do not remove existing functionality.

Make targeted improvements.

When changing a core system:

```text
Existing behavior
 ↓
Identify defect
 ↓
Minimal architectural correction
 ↓
Regression test
 ↓
Preserve all unrelated behavior
```

---

# 48. REQUIRED OUTPUT FROM THE AUDIT

After reviewing the complete codebase, produce:

## A. Architecture Map

Show the actual application architecture.

## B. Feature Matrix

```text
Feature | Frontend | Backend | DB | AI | Status
```

## C. Critical Issues

```text
Issue
File
Function
Root cause
Impact
Fix
Status
```

## D. AI Pipeline

Show:

```text
Input
→ Classification
→ Intent
→ Router
→ Prompt
→ AI
→ Validation
→ Persistence
→ UI
```

## E. Database Map

Show every collection/table and what owns it.

## F. Cloud Function Map

Show every function and its purpose.

## G. Security Report

Identify every security problem.

## H. Test Matrix

Show what was tested and expected result.

## I. Production Readiness Score

Score:

```text
Frontend
Backend
AI
Prompts
Database
Firebase
Cloud Functions
Security
Subscriptions
Performance
Testing
UX
```

Use:

```text
0–59 = Not ready
60–74 = Major work required
75–89 = Nearly ready
90–100 = Production ready
```

---

# 49. FIX, DON'T JUST REPORT

Where a defect is confirmed:

**Fix it.**

Do not simply tell me:

> "This could be a problem."

Make the appropriate code change.

After each important fix:

```text
Re-check dependent code
 ↓
Run analysis
 ↓
Run tests
 ↓
Check for regressions
```

Do not fix one file while leaving callers, models, providers or backend contracts broken.

---

# 50. FINAL ACCEPTANCE STANDARD

GutGood should only be considered complete when this principle is true:

```text
ONE USER ACTION
      ↓
ONE CANONICAL PIPELINE
      ↓
ONE CORRECT ANALYSIS
      ↓
ONE VALID RESPONSE
      ↓
ONE CORRECT DATABASE EVENT
      ↓
ONE CORRECT INSIGHT
      ↓
ONE CONSISTENT UI RESULT
```

The same input must not produce different behavior because it came from:

```text
Camera
Gallery
Scanner
Chat
```

The response must be determined by:

```text
What the image actually contains
+
What the user actually asked
+
Relevant user context
```

not by arbitrary UI state.

---

# 51. FINAL PRODUCT PRINCIPLE

GutGood should behave like an intelligent system, not a collection of disconnected features.

The desired architecture is:

```text
                    ┌──────────────┐
                    │    USER      │
                    └──────┬───────┘
                           ↓
              ┌────────────────────────┐
              │ Chat / Photo / Scanner │
              └───────────┬────────────┘
                          ↓
              ┌────────────────────────┐
              │ AI Classification      │
              │ Image Mode + Intent    │
              └───────────┬────────────┘
                          ↓
              ┌────────────────────────┐
              │ Canonical AI Router    │
              └───────────┬────────────┘
                          ↓
              ┌────────────────────────┐
              │ Correct Prompt / Tool   │
              └───────────┬────────────┘
                          ↓
                    ┌──────────┐
                    │  OpenAI  │
                    └────┬─────┘
                         ↓
              ┌────────────────────────┐
              │ Schema Validation       │
              │ Business Validation     │
              └───────────┬────────────┘
                          ↓
              ┌────────────────────────┐
              │ Canonical Persistence  │
              └───────────┬────────────┘
                          ↓
              ┌────────────────────────┐
              │ Pattern / Gut Score    │
              └───────────┬────────────┘
                          ↓
              ┌────────────────────────┐
              │ Insights                │
              └───────────┬────────────┘
                          ↓
              ┌────────────────────────┐
              │ Flutter UI              │
              └────────────────────────┘
```

The application must be reliable from **input all the way to final UI output**.

Do not declare the project production-ready merely because:

```text
flutter analyze
```

passes.

Production readiness means:

**correct behavior + correct data + correct AI + correct persistence + correct security + correct UI + correct failure handling + regression-tested flows.**