# 🌿 GutGood — Firebase Setup & Deployment Guide

> **Notice:** This guide details the complete Firebase configuration, Secret Manager keys, security rules, and serverless deployment process for **GutGood**.  
> **Related Specifications:** See [Technical Architecture](file:///Volumes/Data/SVN/gutgood_app/Source/gutgood_app/docs/2_technical_architecture.md) and [Security & Access](file:///Volumes/Data/SVN/gutgood_app/Source/gutgood_app/docs/3_security_and_access.md).

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
service cloud.firestore {
  match /databases/{database}/documents {
    
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }

    match /user_profiles/{userId} {
      allow read: if isOwner(userId);
      allow create, update: if isOwner(userId) 
        && (!request.resource.data.diff(resource.data).affectedKeys().hasAny(['isPremium', 'createdAt']));
      allow delete: if isOwner(userId);
    }

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
      allow read: if isOwner(userId);
      allow write: if false; // Server-only increment via Cloud Functions
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
    match /users/{userId}/{allPaths=**} {
      allow read: if request.auth != null && request.auth.uid == userId;
      allow write: if request.auth != null && request.auth.uid == userId
                   && request.resource.size < 10 * 1024 * 1024
                   && request.resource.contentType.matches('image/.*');
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

## 6. Verification & Emulator Running

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
