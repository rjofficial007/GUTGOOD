# 5. Feature Ticket List

> **Product Name:** GutGood — AI Health Intelligence  
> **Current source alignment:** 2026-10-03
> **Document Purpose:** Break down product requirements into discrete, actionable feature tickets for engineering execution.

---

## Ticket Backlog Overview

```
 [EPIC 1: AUTH & USER MANAGEMENT]
   ├── TICKET-101: Guest Anonymous Auth & Migration
   ├── TICKET-102: Apple & Google Social Authentication
   └── TICKET-103: Onboarding & Health Goal Personalization

 [EPIC 2: SCANNER & PRODUCT ANALYSIS]
   ├── TICKET-201: Barcode Scanner & Open Food Facts Integration
   ├── TICKET-202: Vision-AI Ingredient Label Parser
   ├── TICKET-203: Meal Snap Vision Analyzer
   └── TICKET-204: Restaurant Menu Survival Mode

 [EPIC 3: AI CHAT COMPANION & PASSIVE LOGGING]
   ├── TICKET-301: AI Proxy SSE Streaming Interface
   ├── TICKET-302: Passive Conversation Tag Extractor
   └── TICKET-303: Offline Outbox Queue

 [EPIC 4: INSIGHTS & GUT SCORE ENGINE]
   ├── TICKET-401: Daily Gut Score Algorithm (0-100)
   ├── TICKET-402: Bento Grid Insights Dashboard
   ├── TICKET-403: 14-Day Symptom Correlation Engine
   └── TICKET-404: Food Swaps Recommender

 [EPIC 5: MONETIZATION & SECURITY]
   ├── TICKET-501: RevenueCat Paywall Integration
   └── TICKET-502: Account Deletion & Data Cascade
```

---

## Implementation status and ownership

The ticket descriptions remain the product acceptance baseline. The current implementation is organized as follows:

- App bootstrap, composition-root DI, routing, and global theme: `lib/app/`
- Shared AI contract and infrastructure: `lib/core/ai/`
- Chat orchestration: `lib/features/chat/`
- Scanner orchestration: `lib/features/scanner/`
- Insights application, data, domain, and semantic presentation: `lib/features/insights/`
- Auth-owned quota and usage behavior: `lib/features/auth/`
- No standalone `v2` or export-only compatibility directories are part of the active source tree.

A ticket is considered implementation-complete only after behavior, persistence, security, and loading/error flows are verified—not merely after a screen or prompt is added.

---

## EPIC 1: Auth & User Management

### `TICKET-101`: Guest Anonymous Auth & Migration
* **Task Description:** Implement seamless guest account creation on app launch and atomic migration to permanent credentials via `mergeAnonymousAccount` Cloud Function.
* **Acceptance Criteria:**
  1. App initializes an anonymous Firebase user if no session exists.
  2. When guest converts to permanent account (Email/Social), `mergeAnonymousAccount` function runs.
  3. All local and cloud scans, chat messages, and logs migrate to the new UID without duplicates.
* **Dependencies:** Firebase Auth, `functions/src/merge.ts`
* **Priority:** `P0` (Critical)

### `TICKET-102`: Apple & Google Social Authentication
* **Task Description:** Wire up Google Sign-In and Apple Sign-In with cryptographically secure SHA-256 nonces.
* **Acceptance Criteria:**
  1. Google Sign-In returns valid OAuth credentials and logs user into Firebase Auth.
  2. Apple Sign-In generates raw nonce, hashes with SHA-256, validates token, and logs in user.
* **Dependencies:** `google_sign_in`, `sign_in_with_apple`, `crypto`
* **Priority:** `P0` (Critical)

### `TICKET-103`: Onboarding & Health Goal Personalization
* **Task Description:** Multi-page onboarding flow collecting health goals, sensitivities, and cycle sync setup.
* **Acceptance Criteria:**
  1. User can select dietary goals (e.g., reduce bloating, eliminate UPFs, boost fiber).
  2. Sensitivities list updates user profile in Firestore.
  3. Cycle sync setup allows entering last period date and cycle length.
* **Dependencies:** `user_profiles` Firestore collection
* **Priority:** `P1` (High)

---

## EPIC 2: Scanner & Product Analysis

### `TICKET-201`: Barcode Scanner & Open Food Facts Integration
* **Task Description:** Live camera barcode scanning using `mobile_scanner` and Open Food Facts API query.
* **Acceptance Criteria:**
  1. Scanning valid barcode queries `https://world.openfoodfacts.org/api/v2/product/{barcode}.json`.
  2. Returns product title, brand, ingredients, NOVA group, and additive list.
  3. Displays result in `ScanResultScreen` with Gut Health Score.
* **Dependencies:** `mobile_scanner`, `openfoodfacts` package
* **Priority:** `P0` (Critical)

### `TICKET-202`: Vision-AI Ingredient Label Parser
* **Task Description:** Capture photo of ingredient label and process via GPT Vision through `aiProxy`.
* **Acceptance Criteria:**
  1. Photo is compressed locally to max 1024px before transmission.
  2. GPT Vision extracts ingredients, flags high-risk additives, and calculates Gut Health Score.
  3. Handles blurry or unreadable photos with retry suggestions.
* **Dependencies:** `image_picker`, `flutter_image_compress`, `aiProxy`
* **Priority:** `P1` (High)

### `TICKET-203`: Meal Snap Vision Analyzer
* **Task Description:** Analyze meal photos to identify food components, estimate inflammatory risk, and log meal.
* **Acceptance Criteria:**
  1. User takes meal photo in `Meal Snap` mode.
  2. AI returns identified foods, estimated fiber/quality, and gut score impact.
  3. Meal entry is saved to the `user_profiles/{uid}/journal_logs` subcollection automatically.
* **Dependencies:** `aiProxy` Vision API
* **Priority:** `P1` (High)

### `TICKET-204`: Restaurant Menu Survival Mode
* **Task Description:** Scan restaurant menu photo and rank top 3 safest dishes based on user's health profile.
* **Acceptance Criteria:**
  1. Photo of menu is submitted to `aiProxy`.
  2. AI parses menu items and ranks dishes with green/amber/red gut safety ratings.
  3. Suggests specific item modifications (e.g., *"Ask for dressing on the side"*).
* **Dependencies:** `aiProxy` Vision API
* **Priority:** `P2` (Medium)

---

## EPIC 3: AI Chat Companion & Passive Logging

### `TICKET-301`: AI Proxy SSE Streaming Interface
* **Task Description:** Implement real-time streaming chat UI with OpenAI proxy.
* **Acceptance Criteria:**
  1. Message input sends request to `aiProxy` Cloud Function.
  2. Chat UI streams text word-by-word using Server-Sent Events (SSE).
  3. Supports markdown formatting and link rendering.
* **Dependencies:** `http` / `dio`, `aiProxy` Cloud Function
* **Priority:** `P0` (Critical)

### `TICKET-302`: Passive Conversation Tag Extractor
* **Task Description:** Run `ProcessChatTagUseCase` on incoming assistant responses to extract `[MEAL]` and `[SYMPTOM]` tags.
* **Acceptance Criteria:**
  1. Conversation mentioning food triggers `[MEAL]` tag and creates a meal entry in `user_profiles/{uid}/journal_logs`.
  2. Mentioning bloating/pain triggers `[SYMPTOM]` tag and logs a symptom entry in `user_profiles/{uid}/journal_logs`.
  3. Tag chips appear inside chat bubbles allowing editing.
* **Dependencies:** `ProcessChatTagUseCase`
* **Priority:** `P0` (Critical)

### `TICKET-303`: Offline Outbox Queue
* **Task Description:** Queue chat messages through the existing SharedPreferences-backed outbox when the device is offline.
* **Acceptance Criteria:**
  1. Offline messages serialize into the SharedPreferences-backed outbox with a pending status.
  2. When connection restores, `ChatOutboxService` automatically flushes the queue in sequence.
  3. Displays `OfflineBanner` UI feedback when offline.
* **Dependencies:** `shared_preferences`, `InternetConnectionChecker`
* **Priority:** `P1` (High)

---

## EPIC 4: Insights & Gut Score Engine

### `TICKET-401`: Daily Gut Score Algorithm (0-100)
* **Task Description:** Calculate daily gut health score based on meal quality, UPF exposure, and symptom logs.
* **Acceptance Criteria:**
  1. Score recalculates daily or upon new log entries.
  2. Score maps to band: Excellent (80-100), Good (60-79), Fair (40-59), Poor (0-39).
  3. Displays score gauge on home/insights tab.
* **Dependencies:** `GutScoreCalculatorService`
* **Priority:** `P0` (Critical)

### `TICKET-402`: Bento Grid Insights Dashboard
* **Task Description:** Build responsive Bento feed layout using `InterTight` typography and modular cards.
* **Acceptance Criteria:**
  1. Displays Bento cards for Gut Score, Body Patterns, Food Swaps, and Active Experiments.
  2. Smooth layout transitions and HIG dark mode card background fills.
* **Dependencies:** `InterTight` font, `BentoFeed`
* **Priority:** `P1` (High)

### `TICKET-403`: 14-Day Symptom Correlation Engine
* **Task Description:** Run pattern recognition service to detect food triggers over a rolling 14-day window.
* **Acceptance Criteria:**
  1. Identifies recurring symptoms following specific ingredients (12-48h window).
  2. Generates `AiInsight` record with evidence score and confidence rating.
* **Dependencies:** `PatternEngineService`
* **Priority:** `P1` (High)

### `TICKET-404`: Food Swaps Recommender
* **Task Description:** Recommend healthier food alternatives for high-additive scanned products.
* **Acceptance Criteria:**
  1. Scanned UPF or additive-rich item generates 1-3 clean food swaps.
  2. Tap on swap displays detailed comparison (ingredients, NOVA group, gut score impact).
* **Dependencies:** `aiProxy`, `BetterSwapsScreen`
* **Priority:** `P1` (High)

---

## EPIC 5: Monetization & Security

### `TICKET-501`: RevenueCat Paywall Integration
* **Task Description:** Integrate `purchases_flutter` SDK for subscription management and paywall presentation.
* **Acceptance Criteria:**
  1. Fetches offerings from RevenueCat backend.
  2. Successful subscription unlocks `gutgood_premium` entitlement and updates Firestore profile `isPremium = true`.
  3. Free user reaching daily limit triggers paywall modal.
* **Dependencies:** `purchases_flutter`, `PurchaseProvider`
* **Priority:** `P0` (Critical)

### `TICKET-502`: Account Deletion & Data Cascade
* **Task Description:** Provide irreversible account deletion in profile settings adhering to App Store requirements.
* **Acceptance Criteria:**
  1. User confirms deletion through safety dialog.
  2. Calls `deleteAccount` Cloud Function.
  3. Permanently deletes Firebase Auth user, user profile, Firestore subcollections, and Storage images.
* **Dependencies:** `functions/src/auth.ts`, `deleteAccount`
* **Priority:** `P0` (Critical)

---

## Current validation gate

Before release, run `flutter analyze`, `flutter test`, and platform builds from a configured Flutter environment. Static repository checks currently cover canonical imports, relative imports, Dart `part` relationships, and removal of stale compatibility paths. The generated `firebase_options.dart` file must be produced by FlutterFire for a local build.
