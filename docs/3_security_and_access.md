# 3. Security & Access Document

> **Product Name:** GutGood — AI Health Intelligence  
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
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper Functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    function isServerAdmin() {
      return request.auth.token.admin == true;
    }

    // User Profile Rules
    match /user_profiles/{userId} {
      allow read: if isOwner(userId);
      // Prevent client from manually overriding server-managed fields like `isPremium`
      allow create, update: if isOwner(userId) 
        && (!request.resource.data.diff(resource.data).affectedKeys().hasAny(['isPremium', 'createdAt']));
      allow delete: if isOwner(userId);
    }

    // Subcollections (Scans, Chat, Logs, Insights)
    match /chat_histories/{userId}/messages/{messageId} {
      allow read, write: if isOwner(userId);
    }
    
    match /historical_scans/{userId}/scans/{scanId} {
      allow read, write: if isOwner(userId);
    }
    
    match /symptom_logs/{userId}/logs/{logId} {
      allow read, write: if isOwner(userId);
    }

    match /usage_counters/{userId} {
      // Usage counters are updated exclusively by Cloud Functions
      allow read: if isOwner(userId);
      allow write: if false;
    }
  }
}
```

### 3.2 Firebase Storage Rules (`storage.rules`)

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/{allPaths=**} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId
                   && request.resource.size < 10 * 1024 * 1024 // 10MB limit
                   && request.resource.contentType.matches('image/.*');
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
        Call AI Proxy / Firebase  Queue in SQLite Outbox
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
1. **Quota Exceeded (429):** Intercepted gracefully by `QuotaGuard`; presents a friendly paywall modal encouraging upgrade to GutGood+.
2. **Network Offline:** `InternetConnectionChecker` displays a subtle non-blocking top banner (`OfflineBanner`); chat messages and logs are queued locally in `sqflite` outbox.
3. **Firestore Transaction Teardowns:** Benign transaction-cancel logs on channel shutdown are automatically suppressed in Crashlytics to reduce diagnostic noise.

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
| **R8** | **Content-Type Validation** | Firebase Storage upload rules strictly restrict file uploads to `image/*` formats under 10MB to prevent arbitrary file execution. |
| **R9** | **CORS & Proxy Sanitization** | `aiProxy` validates Authorization headers and origin tokens before making external requests to OpenAI. |
