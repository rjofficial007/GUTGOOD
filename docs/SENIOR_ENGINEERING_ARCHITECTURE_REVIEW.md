# Senior Engineering Architecture Review

**Date:** 2026-10-03  
**Repository:** GutGood Flutter application and Firebase Functions backend  
**Review objective:** Understand the complete runtime/data flow, identify architecture, duplication, performance, scalability, and maintainability risks, and define behavior-preserving production refactoring strategies.

## 1. Executive summary

GutGood is a feature-oriented Flutter application with Firebase Authentication, Firestore, Cloud Storage, Firebase Functions, OpenAI-backed AI flows, local persistence, streaming chat, scanner orchestration, and a GoRouter shell with four authenticated branches.

The codebase has useful seams already in place:

- repositories and domain contracts exist for Auth, Chat, History, Insights, Logs, Profile, and Scanner;
- Firebase implementations are mostly isolated behind services/repositories;
- the AI key is kept server-side in Cloud Secret Manager;
- server-side usage counters and idempotency are implemented for AI requests;
- deterministic scanner scoring is separated from AI orchestration;
- chat outbox/upload recovery, optimistic messages, and stream cleanup are explicitly handled;
- security rules default-deny unrelated Firestore and Storage paths;
- the app composition root, DI orchestration, Insights application layer, and Auth-owned services have been separated during this refactor.

The principal remaining risks are not missing folders. They are cross-cutting responsibilities and operational coupling:

1. `HistoryFirestoreServiceImpl` performs a 30-day score recomputation and three additional reads after every saved scan.
2. History queries still fetch broad result sets and filter product eligibility in memory.
3. Global GetIt access remains common outside the composition root, which makes lifecycle and dependency contracts implicit.
4. Large stateful coordinators combine streaming, persistence, caching, retries, optimistic UI, summaries, and analytics.
5. Premium state is intentionally client-writable and the AI proxy has a premium fail-open path; this is an explicit accepted risk but remains a security and cost boundary.
6. Several shared contracts are broader than their current consumers, including the central model barrel and `HistoryRepository.getMessages`, which currently returns an empty list. Standalone forwarding/deprecated source files are not retained.

No product behavior should be changed speculatively. The recommended changes below preserve route values, Firebase paths, payloads, prompt text, scoring rules, persistence keys, provider order, loading/error states, and user flows.

## 2. Current architecture breakdown

### 2.1 Runtime composition

```text
main.dart
  -> AppBootstrap.initialize()
       -> Firebase initialization
       -> AppNotificationNavigation
       -> app/di/injection_container.dart
            -> app/di/core_di.dart
            -> app/di/service_di.dart
            -> app/di/feature_di.dart
            -> app/di/usecase_di.dart
       -> FCM background handler
       -> Crashlytics handlers
       -> device/app metadata warmup
       -> portrait orientation
  -> GutGoodApp
       -> MultiProvider
       -> _GutGoodShell
            -> MaterialApp.router
            -> OfflineBanner
            -> VerificationOverlay
            -> AppRouter
```

Provider construction order is currently preserved as:

```text
ThemeNotifier
GutAuthNotifier
ProfileNotifier
UsageNotifier
ChatHistoryNotifier
ChatComposerNotifier
InsightsNotifier
ScannerNotifier
PurchaseProvider
HistoryNotifier
SavedFoodsProvider
```

The GetIt handle remains a small core primitive (`core/di/di_instance.dart`), while registration orchestration now belongs to the app composition layer (`app/di`).

### 2.2 Layer responsibilities

| Layer | Current responsibility | External dependencies | Assessment |
|---|---|---|---|
| `app/` | Startup, composition, DI registration, routing, theme registration | Flutter, Firebase, GetIt, feature providers | Correct composition-root ownership; routing remains large |
| `core/constants` | Routes, storage keys, prompt/version constants, assets, sizes | None or Flutter constants | Useful shared contracts; avoid adding feature logic |
| `core/models` | Shared DTO/entity barrel, persistence models, navigation arguments | `equatable`, JSON helpers | Shared-model barrel still crosses into Auth; AI protocol models have a canonical `core/ai/protocol` owner |
| `core/services` | App state, configuration, gut-score calculation, streak policy, and reference data | Flutter, selected packages | Remaining entries are shared application policies/state rather than external SDK adapters |
| `lib/infrastructure/ai` | Concrete AI proxy client and provider-facing request transport | Dio, Firebase Auth, Remote Config, Analytics, Crashlytics | External AI transport is isolated; features depend on `AiClient` |
| `lib/infrastructure/payments` | RevenueCat purchase, restore, login/logout, and entitlement adapter | RevenueCat, Flutter platform APIs | Payment SDK is isolated; Auth owns entitlement and paywall orchestration |
| `lib/infrastructure/firebase` | Firebase/Firestore, Storage, Remote Config, analytics, Crashlytics, and notifications | Firebase, Flutter, platform SDKs | Explicit shared Firebase boundary; feature repositories consume these adapters |
| `lib/infrastructure/open_food_facts` | Open Food Facts product lookup, mapping, and session cache | Dio, Open Food Facts SDK | Concrete external API adapter; Scanner and Chat retain orchestration |
| `lib/infrastructure/platform` | Device metadata, app version, connectivity, sharing, reviews, and URL launching | Flutter, platform SDKs | Concrete platform integrations are isolated from core |
| `core/widgets` | Truly shared UI and application overlays | Flutter | Mostly appropriate; feature-owned widgets have been moved out |
| `features/*/domain` | Repository contracts, pure policies, pure use cases | No Flutter/Firebase/SDK imports after the latest pass | Correct direction |
| `features/*/data` | Repository implementations, feature services, external orchestration | Firebase/AI/local persistence | Correct ownership, though some repositories are still coordinators |
| `features/*/presentation` | Screens, providers/notifiers, feature widgets | Flutter, Provider, routing | Functional but several notifiers remain broad |
| `functions/` | AI proxy, auth/account operations, usage counters, lifecycle triggers, email, merge | Firebase Admin, OpenAI | Good server boundary; `ai_proxy.ts` is still a large multi-responsibility function |

### 2.2.1 Shared AI boundary

```text
Feature orchestration
  Chat / Scanner / Insights
          │
          ▼
AiClient contract
  lib/core/ai/client/ai_client.dart
          │ registered as
          ▼
AiProxyClient
  lib/infrastructure/ai/ai_proxy_client.dart
          │ Firebase ID token + typed errors + request metadata
          ▼
aiProxy Cloud Function
          │
          ▼
OpenAI
```

Prompt catalogs, schemas, protocol models, and response validation live under `lib/core/ai/`. The shared AI layer does not import feature code; feature layers retain ownership of orchestration and persistence decisions.

### 2.3 Feature inventory

- **Auth:** anonymous and permanent authentication, email links, Google/Apple, account merge/delete, premium state, quota/paywall UI, deep-link handling.
- **Chat:** streamed AI responses, persistent chat history, optimistic messages, image uploads, offline outbox, summaries, passive meal/symptom/scan persistence, feedback.
- **History:** scans, saved foods, meal/symptom logs, pagination, history counters.
- **Home:** authenticated shell and branch navigation.
- **Insights:** dashboard streams, gut score, AI insights, patterns, alerts, experiments, food intelligence, bento/v2 presentation.
- **Logs:** journal persistence contract and implementation.
- **Onboarding:** goals, sensitivities, lifestyle, cycle configuration.
- **Product Details:** scan, additive, symptom, swap, and not-found details.
- **Profile:** profile, usage, notifications, goals, lifestyle, sensitivities, cycle phase.
- **Scanner:** barcode, label, menu, image classification, AI analysis, deterministic scoring, persistence.
- **Splash/Welcome:** startup, auth entry, link handling, service initialization.

## 3. Complete data-flow map

### 3.1 Authentication and onboarding

```text
Welcome/Login/Onboarding UI
  -> GutAuthNotifier / ProfileNotifier
  -> AuthRepository interface
  -> AuthRepositoryImpl
  -> FirebaseAuth + AuthFirestoreService + Cloud Functions
  -> AuthUser/UserProfile streams
  -> Provider state
  -> GoRouter redirect
  -> shell or onboarding route
```

Local SharedPreferences values are used as fast-path/fallback state for onboarding and profile preferences. Firestore remains the primary profile source for initialized users. The router intentionally pauses redirects while profile initialization, account merge, or logout is in progress.

### 3.2 Chat and AI streaming

```text
Chat UI
  -> ChatComposerNotifier
       -> attachment/upload/outbox workflows
       -> SendMessageStreamUseCase
       -> ChatRepository
       -> AiClient
       -> HTTPS aiProxy Cloud Function
            -> Firebase ID-token verification
            -> server-side quota transaction
            -> OpenAI request / SSE stream
            -> token accounting/refund
       -> streamed ChatMessage state
       -> ChatHistoryNotifier optimistic/server merge
       -> ChatFirestoreService
       -> Firestore user_profiles/{uid}/chat_history
```

Completed chat turns are passed through tag processing and persistence use cases. Meal, symptom, and scan tags can write journal/history records through the shared event persister. Images use a separate upload outbox and hash-based food-image registry.

### 3.3 Scanner

```text
Scanner UI
  -> ScannerNotifier
  -> ScannerRepository
       -> barcode: OffService -> alternatives -> AI product analysis
       -> image: AiClassifierService -> AiClient / AiProxyClient vision analysis
       -> ProcessChatTagUseCase
       -> ScannerScoreService deterministic score/explanation
       -> DomainEventPersister
       -> HistoryFirestoreService / ChatFirestoreService
       -> Analytics / streak / notifications
       -> scan result UI and history
```

Barcode cache hits avoid Open Food Facts and AI calls, re-run deterministic scoring, re-apply current sensitivities, create a fresh chat turn, and do not write another scan document. Barcode persistence has an explicit fallback that forces a verified product into scan history if generic event gating declines it.

### 3.4 Insights

```text
Insights dashboard/detail UI
  -> InsightsNotifier
       -> InsightRepository stream
            -> InsightFirestoreService streams
            -> HistoryFirestoreService.watchHistoryCounts()
       -> today-count reads
       -> debounced GenerateInsightUseCase
            -> local/cloud cadence and profile settings
            -> recent meals/symptoms/scans/history/patterns/chat reads
            -> PatternEngineService
            -> BuildUnifiedJournalUseCase
            -> SummarizeJournalUseCase when historical context is large
            -> InsightRepository.analyzeGutHealth
                 -> prompt builder -> AiClient / AiProxyClient -> aiProxy
            -> deterministic gut score and weekly recap
            -> domain insight envelope policy
            -> save insight, alert, notification
```

The pure envelope/status rules now live under `features/insights/domain/services`. Infrastructure-heavy orchestration lives under `features/insights/application/usecases`.

### 3.5 Firestore and Storage

```text
user_profiles/{uid}
  ├── chat_history/{localId}
  ├── scan_history/{scanId}
  ├── journal_logs/{logId}
  ├── saved_foods/{key}
  ├── insights/{id}
  ├── gut_scores/{id}
  ├── experiments/{id}
  ├── health_alerts/{id}
  ├── pattern_data/{id}
  ├── counters/{id}
  ├── daily_usage/{id}
  └── food_images/{hash}

Storage: users/{uid}/...
Cloud Functions: ai proxy, quota, auth/account operations, lifecycle cleanup,
usage/counter triggers, food-image cleanup, notification/email workflows.
```

## 4. Critical problem areas

### C1 — Premium authority is an accepted security/cost risk

**Evidence:** `firestore.rules` allows clients to write `isPremium` and `subscriptionStatus`; `AuthFirestoreServiceImpl.updatePremiumStatus` writes those fields. `functions/src/ai_proxy.ts` also has a premium fail-open path when usage checks fail.

**Impact:** A modified client can self-identify as premium. This is documented as an accepted risk, but it can bypass the intended paywall and increase AI cost. The risk is not equivalent to data ownership bypass because Firestore ownership remains enforced, but it is a material entitlement and cost-control weakness.

**Behavior-preserving strategy:**

1. Treat RevenueCat/webhook state or server-issued custom claims as authoritative.
2. Keep the existing client mirror only as a display cache.
3. Make the proxy fail closed for unknown entitlement state, with a short-lived server-side entitlement cache if latency requires it.
4. Add emulator tests for premium downgrade, webhook delay, usage-check failure, and replayed requests.
5. Change rules/functions only behind a migration flag and preserve current UI fallback states.

### C2 — Scan persistence performs expensive synchronous score recomputation

**Evidence:** `lib/infrastructure/firebase/firestore/history_firestore_impl.dart:20-50` calls `_updateGutScoreRealTime()` after every scan. `_updateGutScoreRealTime()` at lines 56-108 reads recent scans, meals, and symptoms again, recalculates the weekly score, constructs a record, and writes it.

**Impact:** Every scan can incur three extra Firestore reads plus a score write before the save path fully settles. This increases latency, read cost, write contention, and the chance of overlapping score writes when users scan rapidly or multiple persistence paths run concurrently.

**Behavior-preserving strategy:**

- Keep the same score formula and document shape.
- Move recalculation behind a coalescing `GutScoreRefreshCoordinator` that guarantees at most one refresh per user at a time.
- Trigger it after persistence with the current fire-and-forget semantics, or use a server counter trigger if exact timing is not UI-critical.
- Preserve the current immediate cached UI by publishing the last known score while refresh runs.
- Add tests for two concurrent scan saves, failure recovery, and latest-write-wins behavior.

### C3 — History queries scale poorly for mixed scan types

**Evidence:** `history_firestore_impl.dart:147-184` fetches scan history, then parses and filters `scan.isLoggableProduct` in memory. With a limit, it requests `limit * 2`; without a limit it can load the full collection. Label/menu queries use separate source queries, so the main history path is compensating for legacy/mixed documents in application code.

**Impact:** Read amplification, unpredictable pagination, high memory use, and incomplete pages when more than `limit * 2` records are filtered out. At scale, a user with a long history pays for documents that the UI will discard.

**Behavior-preserving strategy:**

- Introduce a persisted normalized field such as `historyVisibility` or `isLoggableProduct` at write time.
- Backfill legacy documents gradually.
- Query the normalized field with the existing order and cursor.
- Keep the in-memory predicate as a compatibility fallback during migration.
- Never change the visible ordering or inclusion rules until backfill coverage is measured.

### C4 — Global service locator access hides lifecycle and dependency contracts

**Evidence:** `sl<T>()` is still read from router, core widgets, services, feature pages, and providers. `app/di` now owns registration, but most consumers still resolve dependencies at use time.

**Impact:** Construction order is implicit, tests need global reset/unregister operations, and it is difficult to determine which route owns a subscription or long-lived service. This increases the risk of accidental singleton state leakage between authenticated users.

**Behavior-preserving strategy:**

- Keep GetIt only at the composition boundary initially.
- Inject dependencies into long-lived providers and route shells first.
- Use small application ports for notifications/navigation rather than importing router implementations.
- Migrate one feature at a time; retain a compatibility registration during transition.
- Add lifecycle tests around logout/login and provider disposal.

### C5 — State coordinators combine too many responsibilities

Current sizes include:

- `InsightsNotifier`: 450 lines
- `ChatHistoryNotifier`: 355 lines
- `ChatComposerNotifier`: 182 lines plus eight part files
- `ScannerNotifier`: 231 lines
- `ScannerRepositoryImpl`: 342 lines
- `HistoryFirestoreServiceImpl`: 640 lines

These are not automatically defects, but the classes combine state, I/O orchestration, optimistic updates, timers, retries, analytics, persistence, and UI-facing error mapping.

**Impact:** Changes in one flow can affect unrelated states. It is harder to test race conditions, and error handling tends to become broad catch-and-log behavior.

**Behavior-preserving strategy:**

- Keep the existing public notifier API.
- Extract internal coordinators by workflow: chat stream, outbox, upload hydration, insight generation, experiment lifecycle, scanner persistence, and gut-score refresh.
- Make each coordinator return typed outcomes/errors.
- Let notifiers translate outcomes into the existing loading/error/empty state exactly once.
- Do not introduce a new state-management package during this refactor.

### C6 — Cache and persistence failures are inconsistently typed

**Evidence:** `InsightRepositoryImpl.getLatestInsight()` JSON-decodes the local cache without a local try/catch. Several Firestore methods catch `Object` and return `[]`/`null`, while other paths rethrow or surface a generic exception.

**Impact:** Corrupt local state can unexpectedly escape through a read path; callers cannot distinguish offline, permission, malformed-data, and empty results. Silent fallback can also hide production data issues.

**Behavior-preserving strategy:**

- Add a small `AppFailure` mapping at repository boundaries.
- Preserve current return values and UI copy initially, but log a structured failure category.
- Treat malformed cache as a recoverable cache miss and remove only the invalid cache entry.
- Add tests for malformed cache, permission denied, offline, and partial document data.

### C7 — Repository contract drift exists

`HistoryRepositoryImpl.getMessages()` currently returns `[]` with a comment that history has been rerouted to scan history. The method may be a compatibility contract, but returning an unconditional empty list is dangerous if a future caller relies on the repository interface.

**Action:** keep it unchanged until all dynamic/test callers are ruled out, then either remove the method with a documented API decision or implement it as an explicit adapter to `ChatFirestoreService`. Do not silently change its semantics.

### C8 — AI orchestration can duplicate expensive reads and generation triggers

`InsightsNotifier` refreshes today counts with three parallel reads and schedules generation after chat/profile changes. `GenerateInsightUseCase` then performs a separate multi-stream recent-data load. This is guarded by debounce/cadence checks, but the two paths still create duplicated reads and can overlap with Firestore-triggered dashboard updates.

**Strategy:** introduce a per-user generation lease/coordinator with a single in-flight request, a shared recent-data snapshot, and explicit stale/refresh timestamps. Keep the existing 24-hour and threshold gates and preserve the cached dashboard while work runs.

## 5. Duplicate logic review

### Consolidated safely

The following structurally equivalent widgets were consolidated without changing their screen-specific visual contracts:

- `InsightNextStepCheckRow`
- `InsightEvidenceMetricRow`
- `ProductDetailHeaderTag`
- `ProfileSelectionHeader` / `ProfileSelectionFooter`

Pattern/Smart Insight light/dark colors, Synergy semantic colors, and symptom uppercase tag behavior remain explicit at the call sites.

### Intentionally retained

The following candidates were reviewed but should not be merged without changing responsibilities or visual behavior:

- Product symptom `_MetricCard` vs scan `_MetricCard`: different sizing, number formatting, height, capitalization, and layout.
- Symptom severity expander vs scan score expander: different factor models, copy, and row renderers.
- Insights involved-food variants: different data contracts and image/color resolution.
- Core `BentoCard` vs Insights Bento card: different ownership and constructor/style contracts.
- Generic notification/settings/list cards: similar scaffolding but different interaction and state contracts.

The current normalized duplicate scan has no remaining high-confidence cross-file class duplication at the reviewed threshold.

## 6. Performance and scalability review

### Positive existing decisions

- Chat documents use `localId` as the Firestore document ID for retry idempotency.
- Chat pagination uses `getOlderMessages` with a timestamp cursor.
- AI requests enforce server-side auth, quotas, input limits, model allowlisting, token accounting, and refunds.
- OpenAI input truncation preserves both head and tail context rather than silently dropping the user request or schema tail.
- History counters avoid three full collection streams for the Insights dashboard.
- Scanner scoring is deterministic and isolated from network calls.
- Storage image uploads use bounded file size/type rules and hash-based linking.

### Bottlenecks to address

| Area | Current behavior | Production consequence | Safe improvement |
|---|---|---|---|
| Gut score | Three reads and a write after scan persistence | latency/read amplification | coalesced refresh or server counter trigger |
| Scan history | broad query plus client filtering | read cost and unstable pages | normalized visibility field plus cursor |
| Insights | repeated today-count and generation reads | duplicated reads/AI triggers | shared snapshot + per-user lease |
| Chat stream | bounded stream, but provider merges server and optimistic lists | rebuild/merge cost grows with message window | immutable indexed message store while keeping same UI API |
| Firestore streams | multiple feature streams and listener restarts on auth changes | listener churn during account transitions | centralized session-scoped stream lifecycle |
| AI proxy | one large request handler handles auth, quota, payload building, OpenAI, SSE, refunds | harder load testing and incident isolation | extract pure protocol/quota/SSE modules behind the same HTTP contract |

## 7. Maintainability risks

1. **Positional GetIt registration:** calls such as `InsightsNotifier(sl(), sl(), sl(), ...)` obscure dependency meaning and make constructor changes risky. Prefer named constructor arguments at registration boundaries.
2. **Shared model barrel:** `core/models/models.dart` is a compatibility convenience but mixes core models and feature entities. Keep it stable now; introduce feature-local barrels and migrate callers gradually.
3. **Infrastructure boundaries:** shared Firebase adapters live under `lib/infrastructure/firebase/`, external Open Food Facts access under `lib/infrastructure/open_food_facts/`, RevenueCat under `lib/infrastructure/payments/`, and concrete device/platform integrations under `lib/infrastructure/platform/`. Remaining `core/services` entries should be application policies or shared state; new feature-specific data sources should live under their owning feature.
4. **Stringly-typed persistence keys and source values:** existing constants are good where present, but Firestore field names and source values remain distributed. Centralize schemas without changing serialized values.
5. **Broad exception swallowing:** returning empty lists from infrastructure can make outages look like empty states. Add typed diagnostics before changing UI behavior.
6. **Part-file decomposition:** parts reduced file size, but they share one library scope. Use them for cohesive presentation sections, not as a substitute for domain/application boundaries.
7. **Large router:** `app_router.dart` owns route registration, redirect policy, fallback UI, and many feature imports. Keep route values stable, but extract redirect policy and route builders into app-owned modules.

## 8. Refactoring strategy

### Phase 0 — Safety baseline

- Run `flutter analyze`, `flutter test`, and integration tests with generated Firebase options.
- Run Firestore/Storage emulator tests for rules and quota flows.
- Capture route snapshots and key UI golden baselines.
- Record current prompt/version, Firestore paths, serialized model keys, and analytics event names.

### Phase 1 — Complete low-risk boundaries

- Finish replacing service-locator reads in composition-created providers with explicit injection.
- Extract router redirect policy into a pure, testable policy object.
- Add typed cache/persistence failure categories without changing UI copy.
- Add focused tests for logout/login stream cancellation and generation coalescing.

### Phase 2 — Remove read amplification

- Coalesce gut-score refreshes after persistence.
- Add normalized history visibility fields and a legacy-compatible backfill.
- Reuse a single recent-data snapshot for Insights counts and generation.
- Measure Firestore reads, listener restarts, AI request count, and median scan/chat latency.

### Phase 3 — Decompose coordinators

- Chat: stream coordinator, outbox coordinator, upload coordinator, tag persistence coordinator.
- Scanner: barcode analysis, image analysis, persistence policy, analytics/notification side effects.
- Insights: dashboard stream coordinator, generation coordinator, experiment coordinator.
- Keep notifier APIs and state values stable while moving private implementation details.

### Phase 4 — Harden entitlement and backend boundaries

- Move premium authority to server-issued entitlement state.
- Decide explicitly whether premium usage-check failures fail open or closed; default to cost-safe fail closed.
- Split `ai_proxy.ts` into independently tested auth, request validation, quota, OpenAI transport, and SSE protocol modules without changing the endpoint contract.
- Add load tests for concurrent idempotency keys, stream disconnects, token refunds, and quota races.

## 9. Production-grade code patterns

### 9.1 Keep pure policy code dependency-free

The implemented `features/insights/domain/services/insight_generation_policy.dart` follows this shape:

```dart
AIInsight stampInsightEnvelope(
  AIInsight insight, {
  required List<BodyPattern> candidates,
  required DateTime periodFrom,
  required DateTime periodTo,
  required SampleSizes sampleSizes,
  required String model,
  required int promptVersion,
  required DateTime expiresAt,
  int? exactGutScore,
  bool? hasGutScore,
  List<int>? weeklyTrend,
  WeeklyRecap? weeklyRecap,
}) {
  final totalFood = sampleSizes.meals + sampleSizes.scans;
  final status = totalFood < 3 || sampleSizes.symptoms < 1
      ? AIInsight.statusInsufficientData
      : AIInsight.statusReady;

  return insight.copyWith(
    gutScore: exactGutScore ?? insight.gutScore,
    hasGutScore: hasGutScore ?? insight.hasGutScore,
    periodFrom: periodFrom,
    periodTo: periodTo,
    evidence: InsightEvidence.fromPatterns(candidates, sampleSizes: sampleSizes),
    status: status,
    model: model,
    promptVersion: promptVersion,
    expiresAt: expiresAt,
    origin: AIInsight.originClient,
  );
}
```

This keeps the rule testable without Flutter, Firebase, SharedPreferences, or a service locator. Existing action/trend preservation logic remains in the actual implementation.

### 9.2 Keep external orchestration in application/data layers

```dart
class GenerateInsightUseCase {
  GenerateInsightUseCase({
    required InsightRepository repository,
    required AuthFirestoreService auth,
    required SharedPreferences prefs,
    required NotificationService notifications,
    required PatternEngineService patternEngine,
  }) : _repository = repository,
       _auth = auth,
       _prefs = prefs,
       _notifications = notifications,
       _patternEngine = patternEngine;

  final InsightRepository _repository;
  final AuthFirestoreService _auth;
  final SharedPreferences _prefs;
  final NotificationService _notifications;
  final PatternEngineService _patternEngine;
}
```

Concrete SDK dependencies are acceptable at the application/infrastructure boundary; they should not leak into feature domain code.

### 9.3 Preserve repository contracts while improving internals

```dart
abstract interface class HistoryMetricsRefresher {
  Future<void> refreshForUser(String uid);
}

class CoalescingHistoryMetricsRefresher implements HistoryMetricsRefresher {
  Future<void>? _inFlight;

  @override
  Future<void> refreshForUser(String uid) {
    final running = _inFlight;
    if (running != null) return running;

    final future = _refresh(uid);
    _inFlight = future.whenComplete(() => _inFlight = null);
    return _inFlight!;
  }

  Future<void> _refresh(String uid) async {
    // Preserve the existing calculator and write shape.
    // Only coalesce duplicate concurrent refreshes here.
  }
}
```

This is a target pattern, not a recommendation to change score timing without tests. The existing score calculation and document schema must remain authoritative.

### 9.4 Keep composition-root registration readable

Prefer named arguments at the app boundary:

```dart
sl.registerLazySingleton<InsightsNotifier>(
  () => InsightsNotifier(
    repository: sl<InsightRepository>(),
    appStateService: sl<AppStateService>(),
    authRepository: sl<AuthRepository>(),
    analyticsService: sl<AnalyticsService>(),
    generateInsightUseCase: sl<GenerateInsightUseCase>(),
    gutScoreFirestoreService: sl<GutScoreFirestoreService>(),
  ),
);
```

This does not require replacing GetIt; it makes the existing composition contract auditable and resilient to constructor changes.

## 10. Changes already implemented in this workspace

- App-owned DI orchestration under `lib/app/di/`.
- Auth `LinkService` and `UsageService` moved into the Auth feature.
- Insights application/domain separation.
- Shared Insights detail rows and product/profile presentation widgets.
- Deterministic scanner score service.
- Chat safety/prompt context domain services.
- Explicit app navigation port for notification infrastructure.
- Subscription cleanup in long-lived notifiers.
- Dead-code cleanup only after reachability/reference checks.
- Documentation of ambiguous shared contracts rather than speculative deletion.
- Hardened the Insights local-cache read path: malformed cached JSON is treated as a cache miss, removed, and logged instead of escaping as a repository failure.
- Made key provider DI registrations type-explicit at the composition boundary, reducing positional `sl()` ambiguity without changing constructor contracts or lifetimes.
- Added composition-root injection of the existing `GutScoreFirestoreService` contract into `HistoryFirestoreServiceImpl`; legacy callers can still omit the optional dependency and retain the previous concrete fallback, while the registered application path and score write behavior are unchanged.
- Restored compatibility design-token getters and text-style aliases that remained in active widget call sites (`AppSizes` and `AppTextStyles`).
- Corrected the Insights detail part decomposition by making Pattern, Smart Insight, and Synergy section methods explicit extensions on their screen classes.
- Moved the chat streaming persistence timestamp from an invalid extension field into `ChatComposerNotifier` state without changing the streaming workflow.
- Added an internal notifier bridge for chat part files to call state notifications without violating `ChangeNotifier`'s protected-member boundary, and removed two confirmed unused score-card imports.
- Removed obsolete export-only facades for the former core DI, theme, `UsageService`, `GutScoreCard`, and Insights use-case paths after migrating all in-repository imports to their canonical locations.
- Cleaned the reported analyzer infos: removed the redundant `dart:ui` and route-argument import, removed obsolete facade comments, applied the safety-policy tear-off, and removed unnecessary receiver qualifiers from the decomposed chat and Insights parts.

## 11. Validation status

Static checks currently pass:

- Operational `lib/` source references resolve against canonical paths; no export-only compatibility facades remain in the application source tree.
- Dart `part` graph: 123 valid directives, no missing targets or owners.
- Package import/export scan: all internal references resolve; only the two generated `firebase_options.dart` imports are absent.
- Feature domain SDK imports: 0.
- Domain-to-data/presentation imports: 0.
- Data-to-presentation imports: 0.
- Core-to-feature imports: one documented shared model-barrel export for `AuthUser`.
- `git diff --check`: passed.
- Firebase Functions TypeScript build was previously verified successfully.

`flutter analyze` and Flutter tests could not be run because the Flutter/Dart SDK is unavailable in this environment. The next production gate is CI/emulator validation of auth, quota, persistence, routing, streaming, notifications, and account-switching flows.

## 12. Final assessment

The current codebase is serviceable and already has several production-minded protections. The safest path is incremental boundary tightening and measured performance work, not a rewrite.

The highest-return next changes are:

1. coalesce and/or move post-scan gut-score recomputation;
2. remove history read amplification with a compatibility-preserving normalized query field;
3. replace positional service-locator registration with named composition contracts;
4. add typed failure/telemetry boundaries for cache, Firestore, AI, and quota failures;
5. harden premium authority and AI cost controls on the server;
6. decompose the large coordinators only after these behaviors have focused tests.

All proposed changes preserve existing functionality and should be delivered behind regression tests, emulator coverage, and measured rollout metrics.
