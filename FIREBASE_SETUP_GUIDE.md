# GutGood Firebase Setup Guide

Since you have already created the Firebase project, follow these steps to link your app and make all features work.

---

## 1. Android Configuration (Required)

### Step 1: Register Android App
1. Go to the [Firebase Console](https://console.firebase.google.com/).
2. Select your project.
3. Click the **Android icon** to add an app.
4. **Android Package Name**: `com.gutgood.app` (This must match `android/app/build.gradle.kts`).
5. Download the `google-services.json` file.

### Step 2: Place the configuration file
1. Move `google-services.json` into the `android/app/` directory of your project.

### Step 3: Verify build files (Already updated by AI)
I have already updated your `android/settings.gradle.kts` and `android/app/build.gradle.kts` to include the Google Services plugin.

---

## 2. iOS Configuration (Optional but Recommended)

### Step 1: Register iOS App
1. In Firebase Console, click **Add App** and select **iOS**.
2. **iOS Bundle ID**: `com.gutgood.app` (or your specific bundle ID).
3. Download the `GoogleService-Info.plist` file.

### Step 2: Place the configuration file
1. Open your project in **Xcode**.
2. Drag and drop `GoogleService-Info.plist` into the `Runner` folder in Xcode.
3. Ensure "Copy items if needed" is checked.

---

## 3. Enable Firebase Services

You **MUST** enable these in the Firebase Console for the app to function:

### A. Authentication
1. Go to **Build > Authentication**.
2. Click **Get Started**.
3. Enable **Anonymous** (Required for guest flow).
4. Enable **Google** and **Apple** (If you want users to link accounts).
5. Enable **Email/Password**.

### B. Firestore Database
1. Go to **Build > Firestore Database**.
2. Click **Create Database**.
3. Select a location near you.
4. Start in **Production Mode** (recommended) or **Test Mode** (easiest for setup).
5. If in Production Mode, set your **Rules** to:
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId}/{document=**} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```

### C. Firebase Storage (For Image Uploads)
1. Go to **Build > Storage**.
2. Click **Get Started**.
3. Set your **Rules** to:
   ```
   rules_version = '2';
   service firebase.storage {
     match /b/{bucket}/o {
       match /users/{userId}/{allPaths=**} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```

---

## 4. Remote Config Setup (CRITICAL for API Keys)

To manage your API keys without hardcoding them, I have enabled **Firebase Remote Config**. You must add these parameters in the Firebase Console:

1. Go to **Build > Remote Config**.
2. Click **Create Configuration**.
3. Add the following parameters:

| Parameter Key | Data Type | Description | Example Value |
| :--- | :--- | :--- | :--- |
| `openai_api_key` | String | Your OpenAI API Key | `sk-proj-...` |
| `openai_model` | String | GPT Model to use | `gpt-4o-mini` |
| `revenuecat_api_key` | String | Your RevenueCat API Key | `goog_...` |

4. Click **Save** and then **Publish Changes**.

---

## 5. Final Verification

After placing `google-services.json`, run:

```bash
flutter clean
flutter pub get
flutter run
```

Your app will now automatically sync between the **Local Cache (sqflite)** and **Firebase Cloud**.

---

## 4. Cloud Functions (Required — Secure Backend, PRD §3d)

The app's secure backend now lives in `functions/`. It is **mandatory**: the OpenAI key never ships to devices, free-tier limits are enforced server-side, and the anonymous→permanent account merge only works through these functions.

### Step 1: Build
```bash
cd functions
npm install
npm run build
```

### Step 2: Set secrets
```bash
firebase functions:secrets:set OPENAI_API_KEY          # REQUIRED (only secret needed)
```

### Step 3: Deploy
```bash
firebase deploy --only functions,firestore:rules,storage
```

### Deployed functions
| Function | Purpose |
|---|---|
| `aiProxy` | Firebase-auth-gated OpenAI proxy (SSE streaming + JSON). Enforces free-tier limits transactionally. |
| `mergeAnonymousAccount` | Atomic + idempotent guest→account data merge (called after sign-in conflicts). |
| `onUserDeleted` | Cascade-deletes Firestore + Storage when an account is deleted. |
| `cleanupAnonymousUsers` | Daily purge of guest accounts idle > 14 days. |

> **Premium:** managed client-side via the RevenueCat SDK (`purchases_flutter`).
> The app mirrors the entitlement into `user_profiles/{uid}.isPremium` so the
> `aiProxy` quota check can read it. No RevenueCat server secrets, no webhook.

> **Important:** Until the functions are deployed, the app's chat/AI features and the merge-conflict flow will not work (auth, onboarding, scanning cache and local UI still will).

### Emulator (optional local development)
```bash
cd functions && npm run serve   # starts functions + firestore + auth + storage emulators
flutter run --dart-define=USE_FIREBASE_EMULATOR=true
```
