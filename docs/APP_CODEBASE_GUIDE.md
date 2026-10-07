# GutGood Application Codebase Guide

**Purpose:** A practical guide for understanding the current GutGood Flutter application.

**Audience:** The product owner, new developers, reviewers, and anyone who wants to understand how a user action travels through the app.

**Source of truth:** The implementation under `lib/`, tests under `test/`, and Firebase Functions under `functions/`.

---

## 1. What GutGood does

GutGood is a health-intelligence application built around:

- user onboarding and a health profile;
- goals, sensitivities, lifestyle, and cycle information;
- AI chat;
- barcode and vision scanning;
- Open Food Facts product information;
- deterministic gut-health scoring;
- meal, symptom, and scan history;
- deterministic, client-generated Insights and patterns;
- AI-assisted photo and chat interpretation where it adds value;
- notifications and reminders;
- usage limits and subscriptions.

The application combines Flutter UI, Provider state management, Firebase, local persistence, external APIs, an AI proxy, and RevenueCat.

---

## 2. The application in one diagram

```text
User
  |
  v
Flutter screens and widgets
  |
  v
Provider ChangeNotifiers
  |
  v
Feature use cases and repositories
  |
  +--------------------+----------------------+-------------------+
  |                    |                      |
  v                    v                      v
Firebase adapters   AI client contract    External adapters
  |                    |                      |
  v                    v                      v
Firestore/Auth/    AI proxy transport    Open Food Facts /
Storage/FCM        and response logic    RevenueCat/platform APIs
```

The composition root connects these parts:

```text
lib/app/
  bootstrap.dart
  app.dart
  di/
  router/
  theme/
```

The main architectural rule is:

```text
Screens display state.
Notifiers coordinate interaction.
Use cases coordinate workflows.
Repositories coordinate feature data.
Infrastructure talks to external systems.
Core contains shared contracts and rules.
App assembles everything.
```

---

## 3. How the app starts

The startup path is intentionally short:

```text
lib/main.dart
    |
    v
AppBootstrap.initialize()
    |
    +--> Firebase initialization
    +--> GetIt dependency registration
    +--> Crashlytics configuration
    +--> Firebase Messaging background registration
    +--> app and device metadata loading
    +--> portrait orientation configuration
    |
    v
runApp(const GutGoodApp())
    |
    v
MultiProvider
    |
    v
MaterialApp.router
    |
    v
AppRouter / GoRouter
```

### Important startup files

| File | Responsibility |
|---|---|
| `lib/main.dart` | Ensures Flutter is initialized, runs bootstrap, and starts the widget tree. |
| `lib/app/bootstrap.dart` | Initializes Firebase, dependency injection, Crashlytics, FCM, metadata, and orientation. |
| `lib/app/app.dart` | Creates the provider tree and `MaterialApp.router`. |
| `lib/app/router/app_router.dart` | Defines routes and authentication/onboarding redirects. |
| `lib/app/di/injection_container.dart` | Calls DI registration modules in order. |

`main.dart` should remain small. Process startup belongs in `AppBootstrap`, and widget composition belongs in `GutGoodApp`.

---

## 4. Project structure

```text
lib/
├── app/
│   ├── app.dart                  # Application widget and provider composition
│   ├── bootstrap.dart            # Process-level initialization
│   ├── di/                       # GetIt registration modules
│   ├── router/                   # GoRouter and navigation adapter
│   └── theme/                    # App-wide theme composition
│
├── core/
│   ├── ai/                       # Shared AI contracts, prompts, protocol, validation
│   ├── constants/                # App constants, strings, storage keys
│   ├── data/                     # Shared reference data
│   ├── di/                       # GetIt instance handle
│   ├── errors/                   # SDK-neutral failure types
│   ├── models/                   # Shared domain and persistence-shaped models
│   ├── router/                   # Route values and navigation ports
│   ├── services/                 # Shared app state, policies, and contracts
│   ├── theme/                    # Shared design tokens and extensions
│   ├── utils/                    # Pure and shared helpers
│   └── widgets/                  # Reusable core widgets
│
├── infrastructure/
│   ├── ai/                       # Concrete AI proxy transport
│   ├── firebase/                 # Firebase and local-notification adapters
│   │   └── firestore/             # Firestore service implementations
│   ├── open_food_facts/           # Open Food Facts adapter
│   ├── payments/                  # RevenueCat adapter
│   └── platform/                  # Device and platform integrations
│
└── features/
    ├── auth/                     # Authentication, profile access, paywall, usage
    ├── chat/                     # Streaming chat, history, attachments, outbox
    ├── history/                  # Scan history, saved foods, journal timeline
    ├── home/                     # Main navigation shell
    ├── insights/                 # Rule-based patterns, scores, persistence, and feed UI
    ├── logs/                     # Meal, symptom, and scan persistence policy
    ├── onboarding/               # Personalization and initial setup
    ├── product_details/          # Scan, symptom, additive, and swap details
    ├── profile/                  # Goals, sensitivities, lifestyle, notifications
    ├── scanner/                  # Barcode, label, menu, and vision scanning
    ├── splash/                   # Startup screen
    └── welcome/                  # Unauthenticated entry flow
```

---

## 5. Architecture layers

### `lib/app/`: the composition root

The app layer is allowed to know about both features and infrastructure. It owns construction and wiring, not business behavior.

It contains:

- process startup;
- dependency injection;
- router composition;
- app-wide theme composition;
- app-supplied navigation adapters.

### `lib/core/`: shared code

The core layer contains reusable code that is not owned by one feature.

Important examples:

```text
lib/core/ai/client/ai_client.dart
lib/core/ai/prompts/
lib/core/ai/protocol/
lib/core/ai/validation/
lib/core/models/
lib/core/router/app_routes.dart
lib/core/theme/
lib/core/utils/
```

Core code should not directly import Firebase, REST adapters, RevenueCat, Firestore, or platform implementations.

### `lib/features/`: feature ownership

Features own behavior that exists because of a particular product capability.

A feature may contain:

```text
presentation/   Screens, widgets, providers, and notifiers
application/    Feature workflows that coordinate multiple dependencies
domain/         Contracts and dependency-light rules
data/           Repositories, data services, and feature persistence
```

Not every feature must contain every directory. The folders describe responsibility rather than a requirement to create empty layers.

### `lib/infrastructure/`: concrete integrations

Infrastructure contains code that knows about external SDKs or APIs:

- Firebase SDKs;
- Firestore;
- Firebase Storage;
- Firebase Messaging;
- RevenueCat;
- Open Food Facts;
- Dio and HTTP transport;
- device and platform APIs;
- local notifications.

Features may receive infrastructure abstractions through dependency injection, but feature domain code should not import concrete infrastructure directly.

---

## 6. Dependency injection

The GetIt instance is exposed through:

```text
lib/core/di/di_instance.dart
```

The registrations are composed through:

```text
lib/app/di/injection_container.dart
```

The order is:

```text
initCoreDI()
    |
    +--> low-level SDK objects and SharedPreferences

initServiceDI()
    |
    +--> initPlatformDI()
    +--> initAiDI()
    +--> initFirebaseDI()
    +--> initExternalDI()
    +--> initFeatureServiceDI()

initFeatureDI()
    |
    +--> repositories and feature notifiers

initUseCaseDI()
    |
    +--> application and domain use cases
```

### DI module ownership

| Module | Registers |
|---|---|
| `core_di.dart` | Firebase SDK instances, Dio, SharedPreferences, Google Sign-In, local notifications. |
| `platform_di.dart` | App state, configuration, app version, device information, connectivity. |
| `ai_di.dart` | `AiClient`, `AiProxyClient`, and AI classification services. |
| `firebase_di.dart` | Analytics, Crashlytics, Remote Config, Firestore adapters, Storage, notifications. |
| `external_di.dart` | Open Food Facts and RevenueCat adapters. |
| `feature_service_di.dart` | Shared policies, outboxes, scoring, profile-owned services, and theme state. |
| `feature_di.dart` | Feature repositories and Provider/ChangeNotifier objects. |
| `usecase_di.dart` | Chat, Insights, logging, and journal use cases. |

A registration such as:

```dart
sl.registerLazySingleton<AiClient>(
  () => AiProxyClient(...),
);
```

means that callers request the stable `AiClient` contract while DI supplies the concrete implementation.

`registerLazySingleton` means one shared instance is created when first requested and reused afterward.

---

## 7. State management

GutGood uses Provider and ChangeNotifier.

The general pattern is:

```text
Screen
  → context.watch<SomeNotifier>()
  → notifier method
  → repository/use case
  → notifier updates state
  → notifyListeners()
  → screen rebuilds
```

Examples:

| Notifier | Main responsibility |
|---|---|
| `GutAuthNotifier` | Authentication and account state. |
| `ProfileNotifier` | Profile loading, updates, preferences, and profile-related effects. |
| `ChatHistoryNotifier` | Loading and displaying persisted chat history. |
| `ChatComposerNotifier` | Sending, streaming, attachments, retry, and offline outbox behavior. |
| `ScannerNotifier` | Scan state, permissions, errors, and scan completion. |
| `InsightsNotifier` | Insight loading, refresh, generation, and dashboard state. |
| `HistoryNotifier` | History and journal state. |
| `PurchaseProvider` | Subscription and entitlement UI state. |

The composition root creates these objects through GetIt and exposes them through `MultiProvider`.

---

## 8. AI architecture

The AI boundary is deliberately split:

```text
Feature code
    ↓
AiClient contract
    ↓
AiProxyClient implementation
    ↓
AI proxy backend
```

### AI ownership

| Area | Location |
|---|---|
| AI contract | `lib/core/ai/client/ai_client.dart` |
| AI exceptions | `lib/core/ai/client/ai_exceptions.dart` |
| AI prompts | `lib/core/ai/prompts/` |
| AI protocol and constants | `lib/core/ai/protocol/` |
| AI response validation | `lib/core/ai/validation/` |
| Concrete proxy client | `lib/infrastructure/ai/ai_proxy_client.dart` |
| Feature orchestration | Chat, Scanner, and Insights feature directories |

The OpenAI/API transport is not placed in the UI or feature domain. The client-side app uses the AI proxy so sensitive server credentials do not belong in the mobile application.

---

## 9. Chat flow

A normal Chat request travels through this path:

```text
ChatScreen
    ↓
ChatComposerNotifier
    ↓
SendMessageStreamUseCase
    ↓
ChatRepository
    ↓
AiClient
    ↓
AiProxyClient
    ↓
AI proxy backend
    ↓
streamed response
    ↓
ChatComposerNotifier updates the UI
    ↓
PersistAiResponseUseCase
    ↓
Firestore, journal, and tag processing
```

`ChatComposerNotifier` manages presentation-facing workflow state:

- loading;
- streaming;
- attachments;
- image upload recovery;
- offline message queueing;
- retry and regeneration;
- session reset;
- connectivity changes;
- completion callbacks.

The pure Chat use cases and policies remain separate from the concrete AI transport.

Important files:

```text
lib/features/chat/presentation/pages/chat_screen.dart
lib/features/chat/presentation/providers/chat_composer_notifier.dart
lib/features/chat/domain/usecases/send_message_stream_usecase.dart
lib/features/chat/application/usecases/persist_ai_response_usecase.dart
lib/features/chat/data/repositories/chat_repository_impl.dart
lib/infrastructure/ai/ai_proxy_client.dart
```

---

## 10. Scanner flow

The Scanner path is:

```text
Scanner screen
    ↓
ScannerNotifier
    ↓
ScannerRepository
    ↓
Open Food Facts and/or AI
    ↓
ScannerScoreService
    ↓
ScanResult
    ↓
Firestore history and chat preview
    ↓
Product details presentation
```

The Scanner supports:

- barcode lookup;
- barcode result caching;
- label and ingredient analysis;
- meal, menu, and vision flows;
- AI classification;
- deterministic Gut Score calculation;
- sensitivity re-flagging;
- alternatives and better swaps;
- scan persistence;
- streak and notification effects.

Important files:

```text
lib/features/scanner/presentation/
lib/features/scanner/data/repositories/scanner_repository_impl.dart
lib/features/scanner/data/services/scanner_score_service.dart
lib/features/scanner/domain/
lib/infrastructure/open_food_facts/off_service.dart
```

`ScannerScoreService` contains deterministic scoring and sensitivity policy. The repository coordinates the external work and persistence around that policy.

---

## 11. Insights flow

The core Insights refresh is deterministic and client-side:

```text
Insights UI / journal update / client lifecycle
    ↓
InsightsNotifier (debounced while the client is active)
    ↓
GenerateInsightUseCase
    ├── recent meals, symptoms, and scans from Firestore
    ├── PatternEngineService (rolling 30-day rules)
    └── GutScoreCalculatorService (score + weekly recap)
    ↓
RuleBasedInsightBuilder
    ↓
upsert `user_profiles/{uid}/insights/rule_based_latest`
    ↓
Insights feed
```

This core path does not request AI, does not gate analysis on the former daily AI threshold, and adds no Cloud Function. Manual meal/symptom writes signal the client notifier; scanner/chat/profile changes and dashboard-count stream updates also schedule a debounced refresh. The screen requests a refresh when opened.

Refresh is not guaranteed while the app is closed or suspended. Without a server-side trigger, the next refresh occurs when the app resumes, opens Insights, or receives a supported client-side update. AI-assisted photo/chat interpretation remains separate from core Insights generation. A distinct, user-triggered AI context action is available only when rule-based patterns span at least two areas; it receives pattern summaries only and cannot change the underlying findings.

The deterministic builder reports matched observations and log counts only. Missing symptom entries are treated as unknown, not symptom-free; the rule engine does not publish heuristic evidence ratios as confidence percentages.

Important files:

```text
lib/features/insights/application/usecases/generate_insight_usecase.dart
lib/features/insights/application/usecases/generate_insight_ai_interpretation_usecase.dart
lib/features/insights/data/repositories/insight_repository_impl.dart
lib/features/insights/data/services/pattern_engine_service.dart
lib/features/insights/domain/services/rule_based_insight_builder.dart
lib/features/insights/presentation/providers/insights_notifier.dart
lib/features/insights/presentation/widgets/insight_feed/
```

The former full AI Insights synthesis prompt/API and supporting journal-generation pipeline remain removed. Legacy `AIInsight` fields remain readable so previously persisted documents continue to render; new snapshots are composed deterministically and saved to Firestore. A separate optional `GenerateInsightAiInterpretationUseCase` adds only user-requested cross-pattern prose for rule findings from multiple areas, stores it under `aiInterpretation`, and merges that field without rewriting the deterministic snapshot.

---

## 12. Authentication, profile, and payments

The authentication flow is:

```text
Login or account screen
    ↓
GutAuthNotifier
    ↓
AuthRepository
    ↓
Firebase Auth, Google, Apple, email, or account-linking flow
    ↓
profile/session state
```

The Auth feature owns the user-facing workflow. Firebase and RevenueCat implementations remain adapters.

### Profile responsibilities

The profile area manages:

- goals;
- sensitivities;
- lifestyle;
- cycle phase;
- notification preferences;
- onboarding state;
- user metadata;
- session changes.

### Payment responsibilities

The contract and feature flow use `PurchaseService`.

The concrete RevenueCat implementation is:

```text
lib/infrastructure/payments/purchase_service.dart
```

The Auth feature owns:

- paywall presentation;
- entitlement state for the UI;
- quota and usage behavior;
- subscription-related decisions.

The infrastructure adapter owns communication with RevenueCat.

---

## 13. Persistence and data sources

### Firebase Authentication

Used for identity and session state:

- anonymous users;
- email login;
- Google and Apple sign-in;
- account upgrades;
- logout and account switching.

### Firestore

Used for persisted application data:

- profiles;
- chat history;
- meals;
- symptoms;
- scans;
- Insights;
- usage;
- saved foods;
- image metadata.

Firestore adapters are located under:

```text
lib/infrastructure/firebase/firestore/
```

Feature repositories use these adapters rather than calling Firestore directly from widgets.

### Firebase Storage

Used for uploaded food, profile, and attachment images.

### SharedPreferences

Used for local values such as:

- onboarding flags;
- local preferences;
- timestamps;
- reminder settings;
- cache values;
- pending offline outbox state.

### Firebase Functions and AI proxy

The server-side layer protects sensitive operations and provides the AI proxy boundary. The mobile app should not contain server secrets.

---

## 14. Notifications

Notifications have several separate responsibilities.

### Firebase and remote notification service

```text
lib/infrastructure/firebase/notification_service.dart
```

Handles:

- Firebase Messaging initialization;
- notification permissions;
- foreground notifications;
- background notification handling;
- public notification service contract.

### Payload routing

```text
lib/infrastructure/firebase/notification_payload_router.dart
```

Maps notification payload values to application destinations.

It uses a navigation port supplied by the app composition layer instead of importing the concrete router directly.

### Local scheduling

```text
lib/infrastructure/firebase/notification_scheduler.dart
```

Handles:

- daily reminders;
- meal reminders;
- scan reminders;
- no-meal reminders;
- streak-saver reminders;
- cancellation;
- local notification display.

Stable notification IDs are kept in:

```text
lib/infrastructure/firebase/notification_ids.dart
```

---

## 15. Navigation

Navigation is centered around:

```text
lib/app/router/app_router.dart
lib/core/router/app_routes.dart
lib/app/router/app_navigator.dart
```

`AppRouter` handles:

- route declarations;
- nested navigation shells;
- authentication redirects;
- onboarding redirects;
- profile initialization;
- notification destinations;
- route arguments and codecs.

Redirect decisions use authentication, profile, application state, and local onboarding state.

When tracing a navigation issue, start with:

```text
AppRoutes
  → GoRoute in AppRouter
  → screen constructor
  → route argument decoding
  → notifier/provider initialization
```

---

## 16. History, logs, and journal data

History includes:

- scan history;
- saved foods;
- meal logs;
- symptom logs;
- journal timeline;
- Insight history.

The application also contains a logging pipeline for passive records extracted from Chat and Scanner flows.

The persistence policy lives at:

```text
lib/features/logs/data/services/domain_event_persister.dart
```

The principle is:

```text
Feature workflow detects an event
    ↓
Domain/application policy decides what it means
    ↓
Repository or Firestore adapter persists it
```

This keeps persistence decisions out of UI widgets.

---

## 17. How to trace any behavior

For any screen, button, API call, or bug, follow this sequence:

```text
1. Find the route.
2. Open the screen.
3. Find the provider or notifier.
4. Find the use case or repository it calls.
5. Find the infrastructure adapter.
6. Find the model being read or written.
7. Find the related test.
```

For example, the Scanner path can be traced as:

```text
AppRouter
  → SuperScannerScreen
  → ScannerNotifier
  → ScannerRepository
  → ScannerRepositoryImpl
  → OffService / AiClient / Firestore services
  → ScanResult
  → product detail screens
```

Useful IDE searches:

```text
registerLazySingleton
class ScannerNotifier
class ScannerRepositoryImpl
AiClient
GoRoute
StorageKeys
notifyListeners
```

Do not start by reading every file. Start with one vertical feature flow from the screen to the external system and back.

---

## 18. Recommended learning order

### Stage 1: Startup and composition

Read these files first:

```text
lib/main.dart
lib/app/bootstrap.dart
lib/app/app.dart
lib/app/di/injection_container.dart
lib/app/di/service_di.dart
lib/app/router/app_router.dart
```

Goal: understand how the application is assembled before the first screen appears.

### Stage 2: Chat vertical slice

Read:

```text
lib/features/chat/presentation/pages/chat_screen.dart
lib/features/chat/presentation/providers/chat_composer_notifier.dart
lib/features/chat/domain/usecases/send_message_stream_usecase.dart
lib/features/chat/data/repositories/chat_repository_impl.dart
lib/core/ai/client/ai_client.dart
lib/infrastructure/ai/ai_proxy_client.dart
```

Goal: understand the most important asynchronous flow: UI, state, streaming, errors, and persistence.

### Stage 3: Scanner vertical slice

Read:

```text
lib/features/scanner/presentation/providers/scanner_notifier.dart
lib/features/scanner/data/repositories/scanner_repository_impl.dart
lib/features/scanner/data/services/scanner_score_service.dart
lib/infrastructure/open_food_facts/off_service.dart
```

Goal: understand external data, caching, deterministic scoring, AI analysis, and persistence.

### Stage 4: Insights vertical slice

Read:

```text
lib/features/insights/presentation/providers/insights_notifier.dart
lib/features/insights/application/usecases/generate_insight_usecase.dart
lib/features/insights/data/services/pattern_engine_service.dart
lib/features/insights/data/repositories/insight_repository_impl.dart
lib/features/insights/domain/services/rule_based_insight_builder.dart
```

Goal: understand how raw user activity becomes deterministic evidence, patterns, score, and recap.

### Stage 5: Cross-cutting systems

Then study:

```text
lib/infrastructure/firebase/notification_service.dart
lib/infrastructure/firebase/notification_scheduler.dart
lib/features/auth/
lib/features/profile/
lib/infrastructure/payments/purchase_service.dart
lib/features/history/
lib/features/logs/
```

Goal: understand identity, persistence, subscriptions, reminders, and account lifecycle behavior.

---

## 19. Important contracts not to change casually

The following are behavior-sensitive:

- `AiClient` method signatures;
- AI prompt formats and response schemas;
- Firebase collection and document paths;
- Firestore field names;
- SharedPreferences keys;
- route names and route arguments;
- notification IDs and payload values;
- provider order in `GutGoodApp`;
- GetIt registration types and singleton lifetimes;
- authentication and account-linking behavior;
- loading, empty, offline, and error states;
- score calculation inputs and fallback rules;
- AI caching and retry behavior;
- RevenueCat entitlement handling.

When changing one of these, trace all consumers first and update focused tests before changing the implementation.

---

## 20. Final mental model

GutGood is a feature-first Flutter app with an explicit composition root.

```text
App startup
  assembles dependencies

Features
  own product behavior

Core
  provides shared contracts, models, policies, and reusable UI

Infrastructure
  contains concrete SDK and API integrations

Providers/notifiers
  expose state to the Flutter UI

Repositories and use cases
  coordinate data and business workflows

Tests and architecture checks
  protect boundaries and behavior
```

The safest way to understand the application is to follow a user action end-to-end:

```text
user action
  → screen
  → notifier
  → use case
  → repository
  → adapter
  → external service or persistence
  → model
  → notifier state
  → UI update
```

That same pattern appears repeatedly across Chat, Scanner, Insights, Profile, History, and Notifications.

## 21. Scan consumption and journal-event linking

Every completed scan is treated as consumed food. The shared
`DomainEventPersister` writes the scan to `scan_history` and writes a meal
projection to `journal_logs` with `type: 'meal'`, including label, menu, and
low-confidence/non-product scan variants. A label/menu response with no scan
remains chat-only.

Meal and symptom records remain typed documents so existing Firestore queries
and UI models continue to work. They are connected with the shared
`journalEntryId`; the meal uses its meal document id, and a symptom also keeps
`lastMealFirestoreId` for legacy/detail compatibility. A symptom without an
explicit link is associated with the nearest earlier meal within four hours;
otherwise it remains standalone.

`MealLog.scanId` identifies scan-derived meal projections. Insights and journal
text use it to avoid counting or rendering the same scan twice from
`scan_history` and `journal_logs`. Legacy scan-only records remain supported as
fallback inputs until they receive a meal projection.
