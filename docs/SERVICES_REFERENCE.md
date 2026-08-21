# Services Reference

GutGood uses a service-oriented architecture where core logic is encapsulated into singleton service classes registered with `GetIt`.

## 1. `AiService`
**Implementation:** `AiServiceImpl`
- **Responsibility:** All communication with the `aiProxy` Cloud Function.
- **Modular Prompts:** Uses a decentralized prompt architecture located in `lib/core/services/prompts/mode_prompts/`.
- **Key Methods:**
    - `streamChat(...)`: SSE streaming for conversational AI.
    - `analyzeImage(...)`: Vision-based product analysis.
    - `summarizeHistory(...)`: Long-term memory compression (optimized with tag stripping).

## 2. `ModelUtils`
**Implementation:** `lib/core/utils/model_utils.dart`
- **Responsibility:** Reliability layer for data parsing.
- **Key Features:**
    - "Auto-repair" logic for truncated JSON strings from AI.
    - Safe parsing for nested models and clamped scores.

## 2. `FirestoreServices` (Modularized)
**Implementation:** `lib/core/services/firestore/`
- **Responsibility:** Domain-specific CRUD operations for Cloud Firestore.
- **Modules:**
    - `AuthFirestoreService`: User profiles and account metadata.
    - `ChatFirestoreService`: Real-time conversation streaming and history.
    - `HistoryFirestoreService`: Scan history and saved products.
    - `InsightFirestoreService`: AI-generated recaps and pattern data.
    - `UsageFirestoreService`: Quota tracking and daily limit enforcement.

## 3. `StorageService`
**Implementation:** `StorageServiceImpl`
- **Responsibility:** Managing file uploads to Firebase Storage.
- **Key Features:**
    - On-device image compression before upload.
    - Path management (scans vs. profile pictures).

## 4. `OffService` (Open Food Facts)
**Implementation:** `OffServiceImpl`
- **Responsibility:** Interfacing with the external Open Food Facts REST API.
- **Key Features:**
    - Barcode lookup.
    - Category-based product discovery for healthier alternatives (swaps).

## 5. `PurchaseService`
**Implementation:** `PurchaseServiceImpl`
- **Responsibility:** Subscription management via RevenueCat.
- **Key Features:**
    - Entitlement checks.
    - Purchase flow triggering.
    - Mapping RevenueCat state to the `isPremium` Firestore flag.

## 6. `UsageService`
**Implementation:** `UsageServiceImpl`
- **Responsibility:** Enforcing daily limits for free-tier users.
- **Key Features:**
    - Client-side gatekeeping for Scans and Messages.
    - Reads server-authoritative `daily_usage` counters.

## 7. `NotificationService`
**Implementation:** `NotificationServiceImpl`
- **Responsibility:** Local and push notification scheduling.
- **Key Features:**
    - Automated meal/symptom reminders.
    - Handling "Smart Reminders" based on AI-identified patterns.

## 8. `PatternEngineService`
**Implementation:** `PatternEngineServiceImpl`
- **Responsibility:** Local logic for identifying correlations in health data.
- **Key Features:**
    - Correlating `MealLog` timestamps with `SymptomLog` severity.
    - Providing context for the "Insights" feature.
