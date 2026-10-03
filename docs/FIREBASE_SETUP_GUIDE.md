# 🌿 GutGood — Firebase Setup & Deployment Guide

> **Current source alignment:** 2026-10-03
> **Notice:** This guide details the complete Firebase configuration, Secret Manager keys, security rules, and serverless deployment process for **GutGood**.  
> **Related Specifications:** See [Technical Architecture](2_technical_architecture.md) and [Security & Access](3_security_and_access.md).
> **Generated client file:** `firebase_options.dart` is created by FlutterFire for the configured environment and is intentionally not committed.
> **Deployment files:** `firebase.json`, `.firebaserc`, `firestore.rules`, `storage.rules`, and `functions/` remain at the repository root.

---

## 1. Android Configuration (Required)

### Step 1: Register Android App in Firebase Console
1. Open the [Firebase Console](https://console.firebase.google.com/).
2. Select your Firebase project.
3. Click **Add App** and choose **Android**.
4. **Android Package Name**: `com.gutgood.app` (matches `android/app/build.gradle.kts`).
5. Download the `google-services.json` file.

### Step 2: Place Configuration File
Move `google-services.json` into the `android/app/` directory:
```text
gutgood_app/
└── android/
    └── app/
        └── google-services.json
```

### Step 3: Gradle Build Script Setup
Ensure `android/settings.gradle.kts` and `android/app/build.gradle.kts` include the Google Services plugin:
```kotlin
// android/app/build.gradle.kts
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}
```

---

## 2. iOS Configuration (Recommended)

### Step 1: Register iOS App
1. In Firebase Console, click **Add App** and select **iOS**.
2. **iOS Bundle ID**: `com.gutgood.app`.
3. Download `GoogleService-Info.plist`.

### Step 2: Place Configuration File
1. Open `ios/Runner.xcworkspace` in Xcode.
2. Drag and drop `GoogleService-Info.plist` into the `Runner` target folder in Xcode.
3. Check **"Copy items if needed"**.

---

## 3. Firebase Console Services Configuration

### A. Authentication Setup
1. Go to **Build > Authentication > Sign-in method**.
2. Enable the following providers:
   - **Anonymous:** Required for instant guest onboarding flow.
   - **Google:** For Google OAuth 2.0 account linking.
   - **Apple:** For Apple Sign-In (using SHA-256 hashed nonces).
   - **Email/Password:** For traditional login & passwordless magic links.

### B. Firestore Database Security Rules
1. Go to **Build > Firestore Database > Rules**.
2. Deploy the following security rules (matching `docs/3_security_and_access.md`):

```javascript
rules_version = '2';

/**
 * GutGood Firestore Security Rules
 *
 * Architecture: Per-user subcollection model.
 * Ownership is enforced via the {userId} path parameter matching request.auth.uid.
 */
service cloud.firestore {
  match /databases/{database}/documents {

    // --- SHARED HELPERS ---

    /** Checks if the requester is the authenticated owner of the user profile. */
    function isOwner(userId) {
      return request.auth != null && request.auth.uid == userId;
    }

    /**
     * Validates client-written premium fields.
     * Premium is managed via RevenueCat; the app mirrors the status here for
     * cross-device availability and server-side quota checks in Cloud Functions.
     */
    function isValidPremiumFields() {
      let premium = request.resource.data.get('isPremium', false);
      let status = request.resource.data.get('subscriptionStatus', 'free');
      return premium is bool
        && status is string
        && status in ['free', 'premium']
        // Ensure paid flag and status string are consistent.
        && (premium == false || status == 'premium');
    }

    /** Enforces structure for UserProfile documents. */
    function isValidUserProfile() {
      let data = request.resource.data;
      return isValidPremiumFields()
        && data.get('onboarded', false) is bool
        && data.get('gutScore', 0) is number
        && data.get('gutScore', 0) >= 0
        && data.get('gutScore', 0) <= 100;
    }

    /**
     * Validates a single deterministic "body pattern" entry (see
     * BodyPattern.toMap() in the Dart client). These are written by the
     * on-device PatternEngineService through savePatternData and read back
     * by the client insight generation pipeline as evidence for health
     * narratives — so a malformed entry can silently corrupt an AI insight.
     * Firestore rules can't iterate
     * a list generically, so we spot-check the first and last entries (any
     * single malformed write is still bounded by the 512KB doc size cap).
     */
    function isValidBodyPattern(p) {
      return p is map
        && p.get('type', '') is string
        && p.get('trigger', '') is string
        && p.get('reaction', '') is string
        && p.get('frequency', 0) is number
        && p.get('confidence', '') is string
        && p.get('evidenceRatio', 0) is number
        && p.get('evidenceRatio', 0) >= 0
        && p.get('evidenceRatio', 0) <= 1
        && p.get('positiveCount', 0) is number
        && p.get('positiveCount', 0) >= 0
        && p.get('negativeCount', 0) is number
        && p.get('negativeCount', 0) >= 0;
    }

    /** Enforces structure for pattern_data documents (see savePatternData). */
    function isValidPatternData() {
      let data = request.resource.data;
      let patterns = data.get('patterns', []);
      return patterns is list
        && patterns.size() <= 50
        && (patterns.size() == 0 || isValidBodyPattern(patterns[0]))
        && (patterns.size() <= 1 || isValidBodyPattern(patterns[patterns.size() - 1]));
    }

    /**
     * Validates chat messages to prevent oversized documents or garbage data injection.
     * Prevents cost blowups and ensures UI rendering consistency.
     */
    function isValidChatMessage() {
      return request.resource.data.role in ['user', 'ai']
        && request.resource.data.text is string
        && request.resource.data.text.size() < 20000 // Bound text to ~20KB
        && request.resource.data.get('imageUrls', []) is list
        && request.resource.data.get('imageUrls', []).size() <= 4
        && request.resource.size() < 512 * 1024; // Strict 512KB cap
    }

    // --- COLLECTION RULES ---

    match /user_profiles/{userId} {
      allow read: if isOwner(userId);

      /** Create user profile: includes onboarding and gut health constraints. */
      allow create: if isOwner(userId)
        && isValidUserProfile()
        && request.resource.size() < 256 * 1024;

      /** Update profile: prevents clients from tampering with server-authoritative streak data. */
      allow update: if isOwner(userId)
        && isValidUserProfile()
        && (request.resource.data.get('streak', 0) == resource.data.get('streak', 0))
        && (request.resource.data.get('lastActivityDate', '') == resource.data.get('lastActivityDate', ''))
        && request.resource.size() < 256 * 1024;

      allow delete: if isOwner(userId);

      /** Chat History: Full conversations, excluding bulky analysis payloads (now reference-based). */
      match /chat_history/{docId} {
        allow read: if isOwner(userId);
        allow create: if isOwner(userId) && isValidChatMessage();
        allow update: if isOwner(userId) && isValidChatMessage();
        allow delete: if isOwner(userId);
      }

      /** Scan History: Unified home for Product, Label, and Menu analyses. */
      match /scan_history/{docId} {
        allow read: if isOwner(userId);
        allow write: if isOwner(userId) && request.resource.size() < 512 * 1024;
        allow delete: if isOwner(userId);
      }

      /** Journal Logs: Unified timeline for Meals (consumption) and Symptoms (reactions). */
      match /journal_logs/{docId} {
        allow read: if isOwner(userId);
        allow write: if isOwner(userId) && request.resource.size() < 256 * 1024;
        allow delete: if isOwner(userId);
      }

      /**
       * Food-image registry (§E): one doc per uploaded photo, keyed by
       * sha256_16. Clients create the record, add/remove links, and read
       * thumb URLs; only server workers delete (30d sweep) — clients never
       * need to, since unlinking (not deleting) is the lifecycle.
       */
      match /food_images/{hash} {
        allow read: if isOwner(userId);
        allow create, update: if isOwner(userId) && request.resource.size() < 64 * 1024;
      }

      /**
       * Saved foods (P2-6): one doc per product, keyed by barcode or name
       * hash. The full scan map is embedded so the list renders without
       * joins; clients create/delete on toggle, so delete is owner-allowed
       * here (unlike food_images, which only the server sweeps).
       */
      match /saved_foods/{key} {
        allow read: if isOwner(userId);
        allow create, update: if isOwner(userId) && request.resource.size() < 256 * 1024;
        allow delete: if isOwner(userId);
      }

      /** AI Insights: Generated patterns and health trends. */
      match /insights/{docId} {
        allow read: if isOwner(userId);
        allow write: if isOwner(userId) && request.resource.size() < 512 * 1024;
        allow delete: if isOwner(userId);
      }

      /** Gut Scores: Deterministically calculated daily and weekly gut scores. */
      match /gut_scores/{docId} {
        allow read: if isOwner(userId);
        allow write: if isOwner(userId) && request.resource.size() < 256 * 1024;
        allow delete: if isOwner(userId);
      }

      /** Gut Experiments: User's active or past gut health trial protocols. */
      match /experiments/{docId} {
        allow read: if isOwner(userId);
        allow write: if isOwner(userId) && request.resource.size() < 256 * 1024;
        allow delete: if isOwner(userId);
      }

      /**
       * Authoritative Usage Counters:
       * Clients can READ for paywall logic, but only server (aiProxy) can write.
       */
      match /daily_usage/{docId} {
        allow read: if isOwner(userId);
        allow write: if false;
      }

      /** Pattern Engine state: latest analysis evidence. */
      match /pattern_data/{docId} {
        allow read: if isOwner(userId);
        allow write: if isOwner(userId) && request.resource.size() < 512 * 1024 && isValidPatternData();
      }

      /**
       * History counters (totals + food-score aggregates).
       * Maintained by Cloud Functions triggers; clients read for the
       * dashboard, insight gating, and the profile average — never write.
       */
      match /counters/{docId} {
        allow read: if isOwner(userId);
        allow write: if false;
      }

      /** Health Alerts: Surfaced alerts for UPFs or cycle-specific sensitivities. */
      match /health_alerts/{docId} {
        allow read: if isOwner(userId);
        allow write: if isOwner(userId) && request.resource.size() < 256 * 1024;
        allow delete: if isOwner(userId);
      }

      /** Guest->Permanent merge markers. Server-side only (Admin SDK). */
      match /merges/{anonUid} {
        allow read: if isOwner(userId);
        allow write: if false;
      }
    }

    // --- DEFAULT DENY ---

    /** Explicitly deny any access not covered by the authenticated owner rules above. */
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### C. Firebase Storage Security Rules
1. Go to **Build > Storage > Rules**.
2. Deploy the following rules for food photo uploads:

```javascript
rules_version = '2';

service firebase.storage {
  match /b/{bucket}/o {

    // Helper: Checks if the requester is the owner of the user folder
    function isOwner(userId) {
      return request.auth != null && request.auth.uid == userId;
    }

    // Helper: Validates file type and size
    function isValidImage() {
      return request.resource.contentType.matches('image/.*')
        && request.resource.size < 5 * 1024 * 1024; // 5MB limit
    }

    match /users/{userId}/{allPaths=**} {
      allow read: if isOwner(userId);
      allow write: if isOwner(userId) && isValidImage();
      allow delete: if isOwner(userId);
    }

    // Explicitly deny anything else
    match /{allPaths=**} {
      allow read, write: if false;
    }
  }
}
```

---

## 4. Remote Config & Secret Manager Setup

> ⚠️ **SECURITY WARNING:** The `OPENAI_API_KEY` is **NEVER** stored in Remote Config or client code. It is stored securely in **Firebase Secret Manager** and accessed exclusively by the `aiProxy` Cloud Function.

### A. Firebase Remote Config Parameters

Go to **Build > Remote Config** and add these parameters:

| Parameter Key | Type | Default Value | Purpose |
| :--- | :--- | :--- | :--- |
| `openai_model` | String | `gpt-4o-mini` | Default OpenAI model for vision & chat |
| `ai_proxy_url` | String | `https://[region]-[project].cloudfunctions.net/aiProxy` | Endpoint URL for the AI proxy |
| `is_force_update` | Boolean | `false` | Mandates app upgrade dialog |
| `min_required_version` | String | `1.0.0` | Minimum supported app build version |
| `daily_free_scan_limit` | Number | `5` | Free user daily scan quota |
| `daily_free_chat_limit` | Number | `10` | Free user daily AI chat quota |

### B. Firebase Secret Manager (Cloud Functions)

Set the secret via Firebase CLI:
```bash
firebase functions:secrets:set OPENAI_API_KEY
```

---

## 5. Cloud Functions Deployment

The secure serverless backend resides in `functions/` (TypeScript).

### Step 1: Install Dependencies & Build
```bash
cd functions
npm ci
npm run build
```

### Step 2: Deploy Backend & Rules
```bash
firebase deploy --only functions,firestore:rules,storage
```

### Deployed Endpoints & Triggers
| Function Name | Type | Purpose |
|---|---|---|
| `aiProxy` | HTTPS (SSE Stream) | Secure OpenAI proxy with auth validation and daily quota enforcement. |
| `mergeAnonymousAccount` | Callable | Idempotent migration of guest scan and chat data to permanent UID. |
| `onUserDeleted` | Trigger | Cascade deletes user data in Firestore and Storage upon account removal. |
| `cleanupAnonymousUsers` | Cron | Daily cleanup purging un-merged guest accounts idle > 14 days. |

---

## 6. Client integration boundary

Firebase initialization remains in `lib/app/bootstrap.dart`. Shared client-side Firebase integrations live under `lib/infrastructure/firebase/`, including Firestore adapters, Storage, Remote Config, Analytics, Crashlytics, and notifications. Feature-owned repositories and orchestration remain under `lib/features/`; this separation does not change Firestore paths, serialized fields, rules, caching, or public contracts.

The Flutter client reaches OpenAI only through the authenticated proxy:

```text
features/chat, features/scanner, features/insights
                    │
                    ▼
lib/core/ai/client/ai_client.dart
                    │
                    ▼
lib/infrastructure/ai/ai_proxy_client.dart
                    │ Firebase ID token
                    ▼
functions/src/ai_proxy.ts
```

Do not add an API key or direct OpenAI client to Flutter code. The proxy owns authentication, usage/quota checks, model allowlisting, truncation metadata, and the SSE/JSON response protocol.

## 7. Verification & Emulator Running

To test locally with Firebase Emulators:
```bash
# Start backend emulators
cd functions && npm run serve

# Run Flutter app in emulator mode
flutter run --dart-define=USE_FIREBASE_EMULATOR=true
```

To run against live production Firebase:
```bash
flutter clean
flutter pub get
flutter run
```
