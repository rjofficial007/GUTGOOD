# 2. Technical Architecture Document

> **Project Name:** GutGood  
> **Current source alignment:** 2026-10-03
> **Architecture Pattern:** Practical Clean Architecture (Feature-First) + Repository & UseCase Pattern
> **Document Purpose:** Engineering blueprint detailing the current source layout, dependency direction, database schemas, API architecture, and environment configuration.

---

## 1. Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| **Frontend Framework** | Flutter (Dart 3.11+) | Cross-platform iOS & Android user interface |
| **State Management** | `provider` + `ChangeNotifier` | Reactive UI state propagation |
| **Dependency Injection** | `get_it` | Service locator & singleton lifecycle management |
| **Navigation** | `go_router` | Declarative routing with `StatefulShellRoute` architecture |
| **Backend & Cloud Services** | Firebase (Auth, Firestore, Storage, Remote Config, Cloud Functions, Messaging, Crashlytics, Analytics) | User authentication, cloud database, serverless backend, and telemetry |
| **Local Persistence** | Firestore offline persistence + `shared_preferences` + file-backed outbox | Offline Firestore reads, lightweight key-value preferences, and resilient chat/image queues |
| **AI Processing** | `AiClient` in `lib/core/ai/` with `AiProxyClient` in `lib/infrastructure/ai/` via the `aiProxy` Cloud Function | Vision analysis, streaming chat responses, intent detection, structured validation, and quota-aware error handling |
| **Nutrition Database** | Open Food Facts API (`openfoodfacts` package) | Global barcode lookup for food products and ingredients |
| **In-App Purchases** | RevenueCat (`purchases_flutter`) | Cross-platform subscription & entitlement management |

---

## 2. File & Folder Structure

```text
gutgood_app/
├── lib/
│   ├── app/                         # Composition root, bootstrap, router, and global theme
│   │   ├── app.dart
│   │   ├── bootstrap.dart
│   │   ├── router/                   # Feature-aware GoRouter and navigation adapter
│   │   └── theme/                    # Global theme and registered feature extensions
│   │
│   ├── core/                        # Shared models, utilities, app services, and widgets
│   │   ├── ai/                      # Client contract, proxy, prompts, protocol, validation
│   │   ├── constants/               # App constants and string catalogs
│   │   ├── data/                    # Shared additive/reference data
│   │   ├── di/                      # GetIt handle only
│   │   ├── errors/                  # SDK-neutral failure taxonomy
│   │   ├── models/                  # Shared domain and persistence models
│   │   ├── router/                  # Route values, codecs, navigation ports
│   │   ├── services/                # Shared app state, configuration, and policies
│   │   ├── theme/                   # AppPalette, AppTextStyles, ThemeExtensions
│   │   ├── utils/                   # Logger, haptics, date helpers, pure utilities
│   │   └── widgets/                 # Core-only reusable UI components
│   │
│   ├── infrastructure/
│   │   ├── ai/                       # Concrete AI proxy implementation
│   │   ├── firebase/                # Shared Firebase adapters and Firestore services
│   │   │   └── firestore/            # Firestore adapters and contracts
│   │   ├── open_food_facts/          # Open Food Facts/Dio adapter
│   │   ├── payments/                # RevenueCat purchase adapter
│   │   └── platform/                # Device, connectivity, app, and platform adapters
│   │
│   ├── features/                    # Modular feature-first architecture
│   │   ├── auth/                    # Login, migration, profile access, subscriptions
│   │   ├── chat/                    # Chat orchestration, composer, outbox, tag use cases
│   │   ├── history/                 # Scan history, saved foods, journal timeline
│   │   ├── home/                    # Main shell bottom navigation
│   │   ├── insights/                # application, data, domain, semantic presentation
│   │   ├── logs/                    # Meal and symptom logging data layer
│   │   ├── onboarding/              # Onboarding, personalization, cycle sync
│   │   ├── product_details/         # Scan, additive, symptom, and swap details
│   │   ├── profile/                 # Goals, sensitivities, cycle, usage, settings
│   │   └── scanner/                 # Barcode, Meal Snap, menu, and vision flows
│   │
│   └── main.dart                    # Minimal process entry point
│
├── firebase.json                    # Firebase CLI project/deployment configuration
├── .firebaserc                       # Firebase project aliases
├── firestore.rules                   # Firestore security rules
├── storage.rules                     # Cloud Storage security rules
├── functions/                       # Firebase Cloud Functions (TypeScript)
│   ├── src/
│   │   ├── index.ts                 # Function exports
│   │   ├── ai_proxy.ts              # OpenAI HTTPS proxy with streaming & quota enforcement
│   │   ├── auth.ts                  # Magic links & account deletion
│   │   ├── config.ts                # Server-side quota rules & model config
│   │   ├── counters.ts              # Atomic usage counter updates
│   │   ├── food_images.ts           # Thumbnail generation & image cleanup
│   │   ├── lifecycle.ts             # User lifecycle triggers & cleanup crons
│   │   ├── merge.ts                 # Anonymous to permanent user data migration
│   │   ├── triggers.ts              # Firestore creation triggers
│   │   └── usage.ts                 # Daily usage calculation logic
│   └── package.json
```

### Current dependency boundaries

- `lib/app/` composes the application. Firebase initialization remains in `lib/app/bootstrap.dart`; registration modules under `lib/app/di/` are grouped by AI, Firebase, platform, external, feature services, repositories/providers, and use cases; `lib/core/di/di_instance.dart` only owns the GetIt handle.
- `lib/infrastructure/firebase/` owns shared Firebase adapters and Firestore services. Feature repositories remain under `lib/features/*/data/repositories` and retain orchestration ownership.
- `lib/infrastructure/open_food_facts/` owns the concrete Open Food Facts adapter; Scanner and Chat retain feature orchestration and repository ownership.
- `lib/infrastructure/payments/` owns the concrete RevenueCat purchase adapter; Auth retains entitlement, paywall, and usage orchestration.
- `lib/infrastructure/platform/` owns concrete device, app-version, connectivity, sharing, review, and URL-launching integrations.
- `lib/core/ai/client/ai_client.dart` is the neutral AI contract. `lib/infrastructure/ai/ai_proxy_client.dart` is the concrete implementation and is registered as `AiClient`.
- `lib/core/ai/` contains shared AI protocol, prompt, and validation contracts and does not import feature code. Chat, Scanner, and Insights own AI orchestration, repository decisions, loading/error flows, and persistence decisions.
- `lib/features/insights/` uses `application/`, `data/`, `domain/`, and `presentation/` layers. The active feed is under `presentation/widgets/insight_feed/`; no standalone legacy-version compatibility directory is retained.
- `core/models/models.dart` remains a shared barrel for existing model consumers. It exports the canonical AI protocol model from `core/ai/protocol/ai_analysis_result.dart`.
- Former forwarding/deprecated facade files were removed. Internal imports must use canonical paths directly.

---

## 3. Database Schema

### 3.1 Cloud Firestore Schemas

#### Collection: `user_profiles/{uid}`
```json
{
  "uid": "string",
  "email": "string?",
  "displayName": "string?",
  "isAnonymous": "boolean",
  "isPremium": "boolean",
  "createdAt": "timestamp",
  "lastLoginAt": "timestamp",
  "healthGoals": ["string"],
  "sensitivities": ["string"],
  "cycleSync": {
    "enabled": "boolean",
    "lastPeriodDate": "timestamp?",
    "cycleLengthDays": "number"
  },
  "notificationPreferences": {
    "dailyReminders": "boolean",
    "insightAlerts": "boolean"
  }
}
```

#### Subcollection: `user_profiles/{uid}/chat_history/{localId}`
```json
{
  "localId": "string",
  "role": "user | ai",
  "text": "string",
  "createdAt": "timestamp",
  "imageUrls": ["string"],
  "mealLogs": ["map"],
  "symptomLogs": ["map"],
  "analysisResult": "map?",
  "promptVersion": "number?"
}
```

#### Subcollection: `user_profiles/{uid}/scan_history/{scanId}`
```json
{
  "id": "string",
  "barcode": "string?",
  "productName": "string",
  "brand": "string?",
  "imageUrl": "string?",
  "novaGroup": "number (1-4)",
  "gutHealthScore": "number (0-100)",
  "additives": [
    {
      "code": "string",
      "name": "string",
      "riskLevel": "low | moderate | high"
    }
  ],
  "ingredientList": ["string"],
  "aiSummary": "string",
  "timestamp": "timestamp",
  "scanConfidence": "number (0..1)?",
  "scanVerdict": "food | non_food | uncertain?"
}
```

#### Subcollection: `user_profiles/{uid}/journal_logs/{logId}`
```json
{
  "id": "string",
  "symptomType": "string",
  "severity": "number (1-10)",
  "notes": "string?",
  "timestamp": "timestamp"
}
```

#### Subcollection: `user_profiles/{uid}/daily_usage/{date}`
```json
{
  "dailyChatsCount": "number",
  "dailyScansCount": "number",
  "lastResetDate": "string (YYYY-MM-DD)"
}
```

### 3.2 Local persistence

The checked-in Flutter application does not currently depend on `sqflite`. Firestore persistence provides the remote document cache; `shared_preferences` stores lightweight preferences, cached summaries, and outbox metadata; image bytes for pending uploads are kept in the OS temporary directory by the upload outbox.

* **Firestore cache:** chat, history, profile, usage, and insights documents.
* **`shared_preferences`:** onboarding flags, preferences, summaries, experiment cache, and serialized chat/outbox metadata.
* **Temporary upload directory:** pending image bytes; entries are expendable and are dropped gracefully if the OS purges them.

---

## 4. API Structure

### 4.1 Flutter AI client boundary

Feature code depends on the SDK-neutral `AiClient` contract:

```text
Chat / Scanner / Insights orchestration
                │
                ▼
lib/core/ai/client/ai_client.dart (AiClient)
                │ registered implementation
                ▼
lib/infrastructure/ai/ai_proxy_client.dart (AiProxyClient)
                │ Firebase ID token + quota-aware proxy request
                ▼
functions/src/ai_proxy.ts (aiProxy)
                │
                ▼
OpenAI
```

Prompt construction is centralized under `lib/core/ai/prompts/`, structured results and version constants under `lib/core/ai/protocol/`, and response gating under `lib/core/ai/validation/`. This keeps shared AI infrastructure in one boundary without moving feature-owned orchestration into `core`.

### 4.2 Cloud Functions API Endpoints

```
[Flutter App]
     │
     ├── HTTPS POST ──> [aiProxy]
     │                   ├── Verify Firebase ID Token
     │                   ├── Check Usage Counters in Firestore
     │                   └── Forward to OpenAI API (SSE Stream output)
     │
     ├── Callable ────> [mergeAnonymousAccount]
     │                   └── Atomically migrate guest Firestore records to permanent UID
     │
     └── Callable ────> [deleteAccount]
                         └── Delete Auth account + trigger cascade deletion in Storage/Firestore
```

### 4.3 External Integrations
* **Open Food Facts REST API:**
  - `GET https://world.openfoodfacts.org/api/v2/product/{barcode}.json`
  - Fetches product name, brand, ingredients, additives, NOVA group, and images.
* **RevenueCat SDK (`purchases_flutter`):**
  - Entitlement listener syncs `isPremium` status into local `PurchaseProvider` and `user_profiles/{uid}` in Firestore.

---

## 5. Environment & Config

### Firebase Remote Config Keys

| Key | Default Value | Description |
|---|---|---|
| `openai_model` | `gpt-4o-mini` | Default model used for chat and vision analysis |
| `ai_proxy_url` | `https://[region]-[project].cloudfunctions.net/aiProxy` | HTTPS endpoint for AI Proxy |
| `is_force_update` | `false` | Forces app update prompt via Upgrader |
| `min_required_version` | `1.0.0` | Minimum supported app build version |
| `daily_free_scan_limit` | `5` | Maximum daily scans for free users |
| `daily_free_chat_limit` | `10` | Maximum daily chat messages for free users |

### Firebase Secret Manager Keys (Cloud Functions Only)
* `OPENAI_API_KEY`: Strictly isolated on backend serverless environment; never shipped to client devices.
* `REVENUECAT_SECRET_KEY`: Server secret for validating entitlement webhooks if enabled.

---

## 6. Source alignment and validation

The current source tree contains no standalone export-only compatibility files. Canonical AI imports resolve under `lib/core/ai/`, canonical Insights feed imports resolve under `lib/features/insights/presentation/widgets/insight_feed/`, and scanner mode models resolve under `lib/core/models/scans/scanner_mode.dart`.

The SDK-independent architecture check is available at `tool/check_architecture.py`; it validates package/relative imports, `part` ownership, stale moved paths, feature-domain dependency direction, and duplicate typed DI registrations. The two expected generated `firebase_options.dart` imports require a configured FlutterFire environment. Run `flutter analyze`, `flutter test`, and platform builds in a Flutter-enabled environment before release.
