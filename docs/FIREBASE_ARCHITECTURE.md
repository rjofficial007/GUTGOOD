# Firebase Architecture

GutGood leverages Firebase for its entire backend infrastructure, ensuring scalability, real-time sync, and secure data handling.

## 1. Firebase Authentication
**Purpose:** Handles user identity and session management.
- **Providers:** Anonymous (Default), Google, Apple, Email/Password, Email Link (Magic Link).
- **Key Files:** `AuthRepositoryImpl.dart`, `GutAuthNotifier.dart`.
- **Special Logic:** Support for linking anonymous credentials and server-side account merging via Cloud Functions.

## 2. Cloud Firestore
**Purpose:** Primary NoSQL database for user profiles, logs, and history.
- **Structure:** Hierarchical data model anchored at `user_profiles/{uid}`.
- **Security:** Strict attribute-level Security Rules (`firestore.rules`) ensure users can only access their own data.
- **Offline Persistence:** Enabled with `CACHE_SIZE_UNLIMITED` for seamless offline logging.

## 3. Firebase Cloud Functions
**Purpose:** Secure execution of logic that requires API keys or administrative privileges.
- **`aiProxy`:** Secure gateway to OpenAI. Handles auth verification, quota management (PRD §3.1), and SSE streaming.
- **`mergeAnonymousAccount`:** Atomic, idempotent migration of data from a guest UID to a permanent UID.
- **`onUserDeleted`:** Firestore trigger for cascade deletion of all user-related data (GDPR compliance).
- **`cleanupAnonymousUsers`:** Cron job to purge abandoned guest accounts after 14 days.

## 4. Firebase Storage
**Purpose:** Storing binary assets.
- **Paths:**
    - `users/{uid}/profile.jpg`: User avatar.
    - `users/{uid}/scans/{uuid}.jpg`: Images captured during food scanning or chat.
- **Security:** Only the owner can read/write to their `users/{uid}/` prefix.

## 5. Firebase Remote Config
**Purpose:** Dynamic configuration without app store updates.
- **Usage:**
    - AI System Prompts (Chat, Scanner, Insights).
    - Feature Flags (Enabling/disabling specific features).
    - Quota limits for free tier users.

## 6. Firebase Crashlytics & Analytics
**Purpose:** Observability and product metrics.
- **Crashlytics:** Captured fatal errors and non-fatal exceptions in production.
- **Analytics:** Tracks key events: `food_scanned`, `meal_logged`, `symptom_logged`, `premium_upgraded`.

---

## Data Flow (Firebase Focus)

| Feature | Trigger | Firebase Service | Logic |
| --- | --- | --- | --- |
| **Login** | User Action | Auth | Identity token generation |
| **Scan Food** | Barcode/Image | Storage -> Functions | Upload image -> Process via `aiProxy` |
| **Save Log** | Notifier/Tag | Firestore | Real-time write to `user_profiles/{uid}/meal_logs` |
| **Upgrade** | Auth Repository | Functions | `mergeAnonymousAccount` moves collections |
| **Paywall** | Usage Service | Firestore | Read `daily_usage` counter for fast-path check |
