# 🌿 GutGood — AI Health Intelligence

GutGood is a Flutter and Firebase gut-health companion that combines AI chat, passive meal and symptom logging, barcode and vision scanning, personalized food swaps, and evidence-based Insights.

The client uses OpenAI through the authenticated `aiProxy` Cloud Function. The OpenAI key is server-only; the app sends Firebase-authenticated requests through the shared AI client boundary.

---

## 📚 Documentation

All project documentation is in [`docs/`](docs/README.md). The documentation is maintained against the current source tree rather than an earlier `v2` or compatibility layout.

| Document | Description |
|---|---|
| [Documentation index](docs/README.md) | Complete documentation map and current architecture notes. |
| [Product requirements](docs/1_prd.md) | Product goals, personas, user flows, and success metrics. |
| [Technical architecture](docs/2_technical_architecture.md) | Current app structure, dependency direction, persistence, APIs, and configuration. |
| [Security and access](docs/3_security_and_access.md) | Authentication, authorization, Firebase rules, AI proxy security, and resiliency. |
| [Frontend and integration](docs/4_frontend_and_integration.md) | Design tokens, component ownership, UI contracts, and external integrations. |
| [Feature tickets](docs/5_feature_ticket_list.md) | Feature backlog and implementation acceptance criteria. |
| [AI modes overview](docs/AI_MODES_OVERVIEW.md) | Scanner, prompt, classifier, and Insights AI modes. |
| [App data specification](docs/APP_DATA_SPECIFICATION.md) | Persisted models, structured AI envelopes, and screen data requirements. |
| [Models and UI mapping](docs/MODELS_AND_UI_MAPPING.md) | Source model and presentation mapping with examples. |
| [Firebase setup guide](docs/FIREBASE_SETUP_GUIDE.md) | Firebase, Secret Manager, Cloud Functions, rules, and emulator setup. |
| [Architecture refactor report](docs/ARCHITECTURE_REFACTOR_REPORT.md) | Behavior-preserving architecture and naming refactor record. |
| [Senior architecture review](docs/SENIOR_ENGINEERING_ARCHITECTURE_REVIEW.md) | Risks, follow-up priorities, and validation status. |
| [Screen gallery](docs/GUTGOOD_SCREENS.html) | Static gallery of the application screens. |
| [Insights gallery](docs/INSIGHTS.html) | Static visual reference for the Insights experience. |

---

## ✨ Product capabilities

- **AI chat companion:** Streaming conversations about meals, symptoms, food quality, and gut health.
- **Passive logging:** Structured `[MEAL]`, `[SYMPTOM]`, and `[SCAN]` extraction from chat responses.
- **Hybrid scanner:** Barcode lookup through Open Food Facts plus AI analysis for meals, labels, products, and restaurant menus.
- **Personalized food swaps:** Alternatives grounded in the user's goals, sensitivities, and available product data.
- **Insights:** Daily Gut Score, recurring body patterns, food impacts, weekly recaps, experiments, next steps, and evidence.
- **Cycle-aware guidance:** Optional cycle phase context for recommendations and interpretation.
- **Offline resilience:** Firestore persistence, SharedPreferences-backed metadata, and file-backed chat/image outboxes.
- **Premium access:** RevenueCat entitlements and server-enforced free-tier usage limits.

---

## 🛠 Technology stack

- **Framework:** Flutter / Dart 3.11+
- **State:** Provider and `ChangeNotifier`
- **DI:** GetIt, registered from `lib/app/di/`
- **Navigation:** GoRouter with app-owned routing in `lib/app/router/`
- **Backend:** Firebase Auth, Firestore, Storage, Remote Config, Cloud Functions, Messaging, Analytics, and Crashlytics
- **AI:** OpenAI models through the `aiProxy` Cloud Function
- **Nutrition data:** Open Food Facts
- **Subscriptions:** RevenueCat via `purchases_flutter`
- **Monitoring:** Firebase Analytics and Crashlytics

---

## 🏗️ Current architecture

The application follows a practical feature-first Clean Architecture split:

- `lib/app/` owns process bootstrap, composition-root DI, routing, navigation adapters, and global theme registration. DI registrations are grouped into `app/di/` modules for AI, Firebase, platform, external, feature services, repositories/providers, and use cases.
- `lib/core/` contains shared models, application-level services, utilities, design tokens, and reusable core widgets. Firebase adapters do not live here.
- `lib/infrastructure/firebase/` contains shared Firebase adapters for Analytics, Crashlytics, Remote Config, Storage, Messaging/notifications, and Firestore access. Firebase initialization remains in `lib/app/bootstrap.dart`.
- `lib/infrastructure/open_food_facts/` contains the Open Food Facts/Dio adapter used by Scanner and Chat.
- `lib/infrastructure/payments/` contains the concrete RevenueCat purchase adapter; Auth owns entitlement and paywall orchestration.
- `lib/infrastructure/platform/` contains concrete device, app-version, connectivity, sharing, review, and URL-launching integrations.
- `lib/core/ai/` is the shared AI boundary:
  - `client/` — `AiClient` and AI exceptions
  - `classification/` — image and text intent classification
  - `prompts/` — prompt catalog, mode prompts, schemas, and formatting rules
  - `protocol/` — structured AI result and constants
  - `validation/` — structured response sanitization and persistence gating
- `lib/infrastructure/ai/` contains `AiProxyClient`, the concrete Dio/Firebase-authenticated proxy implementation.
- `lib/features/` owns feature behavior and orchestration. Chat, Scanner, and Insights depend on `AiClient`; they own their own use cases, repositories, and presentation flows.
- `lib/features/insights/` uses semantic names such as `insight_feed`, `InsightsFeed`, `InsightFeedDerivations`, and `insight_blocks.dart`. There is no standalone `v2` compatibility directory.
- Former forwarding/deprecated facade files were removed. Internal code imports canonical locations directly.

### Directory overview

```text
gutgood_app/
├── docs/                         # Product, architecture, security, data, and UI documentation
│   ├── README.md                 # Documentation index
│   ├── 1_prd.md through 5_feature_ticket_list.md
│   ├── AI_MODES_OVERVIEW.md, APP_DATA_SPECIFICATION.md
│   ├── MODELS_AND_UI_MAPPING.md, FIREBASE_SETUP_GUIDE.md
│   ├── ARCHITECTURE_REFACTOR_REPORT.md, SENIOR_ENGINEERING_ARCHITECTURE_REVIEW.md
│   └── GUTGOOD_SCREENS.html, INSIGHTS.html
├── functions/                    # Firebase Cloud Functions (TypeScript)
│   └── src/                      # aiProxy, auth, merge, lifecycle, usage, and triggers
├── firebase.json                 # Firebase CLI project/deployment configuration
├── .firebaserc                   # Firebase project aliases
├── firestore.rules               # Firestore security rules
├── storage.rules                 # Cloud Storage security rules
├── lib/
│   ├── app/                      # Bootstrap, composition root, router, theme
│   │   ├── di/
│   │   ├── router/
│   │   └── theme/
│   ├── core/
│   │   ├── ai/                   # Shared AI contract and infrastructure
│   │   ├── constants/
│   │   ├── data/
│   │   ├── di/                   # GetIt handle only
│   │   ├── errors/
│   │   ├── models/
│   │   ├── router/
│   │   ├── services/             # Shared app state, configuration, and policies
│   │   ├── theme/
│   │   ├── utils/
│   │   └── widgets/
│   ├── infrastructure/
│   │   ├── ai/                    # Concrete AI proxy implementation
│   │   ├── firebase/              # Shared Firebase adapters and Firestore services
│   │   │   └── firestore/
│   │   ├── open_food_facts/       # Open Food Facts/Dio adapter
│   │   ├── payments/              # RevenueCat purchase adapter
│   │   └── platform/              # Device, connectivity, app, and platform adapters
│   ├── features/                 # Auth, Chat, History, Insights, Scanner, and other features
│   └── main.dart                  # Minimal process entry point
└── firebase_options.dart         # Generated locally by FlutterFire; not committed
```

Persisted field names, Firestore paths, API payloads, and schema/version values remain contracts. A schema version or historical data value may still contain `v2`; that does not imply a `v2` source directory or compatibility file.

---

## 🔐 Security boundary

- The app never contains the OpenAI API key.
- `AiProxyClient` attaches a Firebase ID token and calls the configured proxy URL.
- `aiProxy` authenticates the request, applies usage/quota rules, and forwards to OpenAI.
- Firestore and Storage rules scope user data by authenticated UID.
- Account migration and deletion are handled by dedicated Cloud Functions.

---

## 🚀 Quick start

```bash
flutter pub get

dart pub global activate flutterfire_cli
flutterfire configure

cd functions
npm ci
npm run build
firebase deploy --only functions,firestore:rules,storage
cd ..

flutter analyze
flutter run
```

For local Firebase emulators, see [`docs/FIREBASE_SETUP_GUIDE.md`](docs/FIREBASE_SETUP_GUIDE.md).

---

## ✅ Validation

Run `flutter analyze`, `flutter test`, and a platform build in a configured Flutter environment before release. The architecture-check script referenced by older documentation is not present in this repository.

---

## 📄 License

This project is proprietary and confidential. Unauthorized copying of this file, via any medium, is strictly prohibited.
