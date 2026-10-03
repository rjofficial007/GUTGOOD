# 3. Security & Access Document

> **Product Name:** GutGood — AI Health Intelligence  
> **Current source alignment:** 2026-10-03
> **Document Purpose:** Define authentication, authorization, data access rules, permission boundaries, error handling, and security edge cases.

---

## 1. Authentication Methods

GutGood implements a multi-tiered identity architecture using Firebase Authentication:

```
                  ┌────────────────────────┐
                  │   Anonymous Guest User │
                  └───────────┬────────────┘
                              │
                    User chooses to Sign Up
                              │
          ┌───────────────────┼───────────────────┐
          ▼                   ▼                   ▼
   Email & Password    Google Sign-In      Apple Sign-In
   (Magic Link / OTP) (OAuth 2.0 Credential) (SHA-256 Hashed Nonce)
          │                   │                   │
          └───────────────────┼───────────────────┘
                              │
                    [mergeAnonymousAccount]
                 Atomic Cloud Function Call
                              │
                  ┌───────────▼────────────┐
                  │ Permanent User Account │
                  └────────────────────────┘
```

### Identity Features
1. **Anonymous Sign-In (Guest Mode):** Enables instant onboarding without friction. Guest UID is issued immediately upon app startup.
2. **Social Sign-In:** Google Sign-In and Apple Sign-In with cryptographically generated SHA-256 nonces for replay attack prevention.
3. **Atomic Data Migration (`mergeAnonymousAccount`):** Idempotent Cloud Function migrates all scan records, chat history, and symptom logs from the anonymous UID to the newly authenticated permanent UID without data loss or duplication.

---

## 2. User Roles & Access Capabilities

| Role | Access Level | AI Quota / Capabilities | Data Retention |
|---|---|---|---|
| **Guest User** *(Anonymous UID)* | Basic App Features | • 5 Scans / Day<br>• 10 AI Chat Messages / Day<br>• Basic Gut Score | 14-Day Cloud TTL (automatically purged if idle via cron) |
| **Free Registered User** *(Authenticated)* | Standard Features | • 5 Scans / Day<br>• 10 AI Chat Messages / Day<br>• Basic Insights & History | Permanent Cross-Device Cloud Storage |
| **GutGood+ Premium User** *(RevenueCat Entitled)* | Full Unlimited Access | • **Unlimited** Scans & Vision Analysis<br>• **Unlimited** AI Chat Companion<br>• Deep Bento Insights, Cycle Sync, Menu Survival Mode | Permanent Cloud Storage + Priority Processing |
| **Firebase Admin / System** | Server-Level Admin | • Executes Cloud Triggers, Usage Sweeps, and Maintenance | Full Backend Database Operations |

---

## 3. Permissions & Security Rules

### 3.1 Firestore Security Rules (`firestore.rules`)

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

### 3.2 Firebase Storage Rules (`storage.rules`)

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

### 3.3 Hardware Permissions (Mobile Device)
* **Camera Permission:** Required for live barcode scanning and ingredient label photo capture.
* **Photo Library Permission:** Required for uploading food photos or menu images.
* **Notification Permission:** Required for daily meal/symptom reminders and cycle phase alerts.

---

## 4. Error Handling & Resiliency

```
          ┌────────────────────────────────────────┐
          │         Network Request Initiated      │
          └───────────────────┬────────────────────┘
                              │
                     Is Device Online?
                    /                 \
                 [YES]               [NO]
                  │                    │
        Call AI Proxy / Firebase  Queue in local outbox
                  │            Display `OfflineBanner`
       Status Code Check               │
        /    │      \                  │
     [200] [429]   [5xx/Error]         │
       │     │         │               │
    Process Quota   Fallback to        Wait for Connection
    Stream  Limit   Cached Data        Drain Outbox Queue
            Prompt  & Retry
```

### Error Handling Strategies
1. **Quota Exceeded (429):** The proxy error is surfaced through the AI client boundary and handled by the Auth-owned `features/auth/presentation/utils/quota_guard.dart`; the UI presents a friendly paywall modal encouraging upgrade to GutGood+.
2. **Network Offline:** `InternetConnectionChecker` displays a subtle non-blocking top banner (`OfflineBanner`); chat messages and image uploads are queued through the SharedPreferences/file-backed outbox services.
3. **Firestore Transaction Teardowns:** Benign transaction-cancel logs on channel shutdown are automatically suppressed in Crashlytics to reduce diagnostic noise.

### Current security boundary

- `lib/core/ai/client/ai_client.dart` exposes no API key or provider SDK details to feature code.
- `AiProxyClient` obtains a Firebase ID token from the active session and calls only the configured `aiProxy` URL.
- `AiQuotaExceededException`, `AiAuthException`, and `AiServiceException` are defined under `lib/core/ai/client/ai_exceptions.dart` and are handled at feature/UI boundaries.
- Chat, Scanner, and Insights decide whether a failed or low-confidence response may be persisted; the shared validator does not bypass feature-owned persistence rules.
- No forwarding AI or prompt facade is retained in the application source.

---

## 5. Security Edge Cases & Registered Decisions (R1–R9)

| ID | Security / Architecture Decision | Rationale & Mitigation |
|---|---|---|
| **R1** | **Client-side RevenueCat Mirroring** | RevenueCat SDK handles entitlement validation on device and mirrors `isPremium` to Firestore profile. Server-side AI Proxy double-checks usage limits to prevent abuse. |
| **R2** | **Guest Account Cleanup Cron** | Cron job `cleanupAnonymousUsers` runs daily to purge guest user records older than 14 days to prevent database clutter and storage bloat. |
| **R3** | **API Key Protection** | OpenAI API key is stored exclusively in Firebase Secret Manager and never exposed in application source code or client network traffic. |
| **R4** | **Silent Switch Protection** | Prevents social sign-in from overriding an existing active session without user confirmation, protecting against account hijacking. |
| **R5** | **Vision Photo Downscaling** | All captured photos are compressed locally to a maximum dimension of 1024px before transmission, reducing upload bandwidth, latency, and Vision token costs. |
| **R6** | **Irreversible Account Deletion** | Executed via callable function `deleteAccount` in a strict sequence: deletes auth credentials, Firestore user trees, and Storage images atomically. |
| **R7** | **Atomic Usage Counters** | Daily usage increment operations use Firestore `FieldValue.increment(1)` inside transactions to avoid race conditions across concurrent requests. |
| **R8** | **Content-Type Validation** | Firebase Storage upload rules strictly restrict file uploads to `image/*` formats under 5MB to prevent arbitrary file execution. |
| **R9** | **CORS & Proxy Sanitization** | `aiProxy` validates Authorization headers and origin tokens before making external requests to OpenAI. |
