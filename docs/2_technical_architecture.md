# 2. Technical Architecture Document

> **Project Name:** GutGood  
> **Architecture Pattern:** Clean Architecture (Feature-First) + Repository & UseCase Pattern  
> **Document Purpose:** Engineering blueprint detailing tech stack, directory layouts, database schemas, API architecture, and environment configuration.

---

## 1. Tech Stack

| Layer | Technology | Purpose |
|---|---|---|
| **Frontend Framework** | Flutter (Dart 3.11+) | Cross-platform iOS & Android user interface |
| **State Management** | `provider` + `ChangeNotifier` | Reactive UI state propagation |
| **Dependency Injection** | `get_it` | Service locator & singleton lifecycle management |
| **Navigation** | `go_router` | Declarative routing with `StatefulShellRoute` architecture |
| **Backend & Cloud Services** | Firebase (Auth, Firestore, Storage, Remote Config, Cloud Functions, Messaging, Crashlytics, Analytics) | User authentication, cloud database, serverless backend, and telemetry |
| **Local Persistence** | `sqflite` (SQLite) + `shared_preferences` | Offline outbox, local caching, and key-value preferences |
| **AI Processing** | OpenAI GPT-4o / GPT-4o-mini via `aiProxy` Cloud Function | Vision analysis, streaming chat responses, and intent detection |
| **Nutrition Database** | Open Food Facts API (`openfoodfacts` package) | Global barcode lookup for food products and ingredients |
| **In-App Purchases** | RevenueCat (`purchases_flutter`) | Cross-platform subscription & entitlement management |

---

## 2. File & Folder Structure

```text
gutgood_app/
├── lib/
│   ├── core/                        # Shared infrastructure & core utilities
│   │   ├── constants/               # Strings, Sizes, Assets, API endpoints, Prompts
│   │   ├── database/                # SQLite helper & offline table definitions
│   │   ├── di/                      # Dependency Injection setup (GetIt)
│   │   ├── router/                  # GoRouter configuration & route arguments
│   │   ├── services/                # Infrastructure services (AI, Firestore, Storage, Usage)
│   │   ├── theme/                   # AppPalette, AppTextStyles, AppTheme (iOS HIG)
│   │   ├── utils/                   # Logger, Haptics, DateFormatters, QuotaGuard
│   │   └── widgets/                 # Standardized UI components (GutAppBar, GutTextField, OfflineBanner)
│   │
│   ├── features/                    # Modular feature-first architecture
│   │   ├── auth/                    # Login, Social Auth, Anonymous Migration, Paywall Provider
│   │   ├── chat/                    # AI Chat Companion, Composer, Outbox, Tag Processing UseCases
│   │   ├── history/                 # Scan History, Saved Foods, Journal Timeline
│   │   ├── home/                    # MainShell bottom navigation controller
│   │   ├── insights/                # Gut Score, Bento Feed, Patterns, Swaps, Experiments
│   │   ├── logs/                    # Meal & Symptom logging data layer
│   │   ├── onboarding/              # Onboarding flow, Personalization, Cycle Sync
│   │   ├── product_details/         # Scan results, Additive detail, Symptom detail
│   │   ├── profile/                 # User settings, Health goals, Cycle phase, Usage
│   │   └── scanner/                 # Barcode Scanner, Meal Snap, Menu Scanner, Vision-AI
│   │
│   └── main.dart                    # Application entry point & service initialization
│
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

#### Collection: `chat_histories/{uid}/messages/{messageId}`
```json
{
  "id": "string",
  "sender": "user | assistant",
  "content": "string",
  "timestamp": "timestamp",
  "attachmentUrl": "string?",
  "tags": [
    {
      "type": "MEAL | SYMPTOM | SCAN",
      "payload": "map"
    }
  ]
}
```

#### Collection: `historical_scans/{uid}/scans/{scanId}`
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
  "timestamp": "timestamp"
}
```

#### Collection: `symptom_logs/{uid}/logs/{logId}`
```json
{
  "id": "string",
  "symptomType": "string",
  "severity": "number (1-10)",
  "notes": "string?",
  "timestamp": "timestamp"
}
```

#### Collection: `usage_counters/{uid}`
```json
{
  "dailyChatsCount": "number",
  "dailyScansCount": "number",
  "lastResetDate": "string (YYYY-MM-DD)"
}
```

### 3.2 Local SQLite Schema (`sqflite`)

Used for offline message queuing, cached scan offline playback, and outbox resilience.

* **`outbox_messages` Table:** `id TEXT PRIMARY KEY, payload TEXT, status TEXT, retries INTEGER, created_at INTEGER`
* **`cached_scans` Table:** `barcode TEXT PRIMARY KEY, json_data TEXT, cached_at INTEGER`

---

## 4. API Structure

### 4.1 Cloud Functions API Endpoints

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

### 4.2 External Integrations
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
