# GutGood Architecture Audit & Behavior-Preserving Refactor

**Date:** 2026-10-03  
**Baseline:** `a00ccac` (`main`, clean checkout before this refactor)  
**Scope:** Flutter application in `lib/`, tests in `test/`, Firebase Functions in `functions/`, and the checked-in product/architecture documentation.

## Executive summary

GutGood already had a feature-oriented structure and several useful Clean Architecture seams, but the boundaries were not consistently enforced. The highest-risk issue was not a missing folder; it was responsibility leakage:

- the process bootstrap, Firebase setup, provider composition, lifecycle handling, and router were coupled to `main.dart`/`core/`;
- feature-owned screens and theme extensions were exported from `core/widgets`/`core/theme`;
- presentation notifiers reached into the service locator for sibling presentation objects;
- long-lived auth subscriptions were created without being retained and cancelled;
- the central model barrel mixed domain-shaped models, persistence DTOs, and UI/navigation concerns.

The refactor was intentionally incremental. It changes structure and dependency ownership without changing routes, provider order, Firebase paths, API payloads, prompts, scoring rules, loading states, or user-facing flows.

### Implemented in this pass

1. Extracted process startup into `lib/app/bootstrap.dart`.
2. Extracted the application composition root and lifecycle shell into `lib/app/app.dart`.
3. Moved the feature-aware router to `lib/app/router/app_router.dart`.
4. Moved global `AppTheme` to `lib/app/theme/app_theme.dart`, where it is valid for the app composition layer to register Insights theme extensions.
5. Moved the purchase paywall and quota guard into the Auth/Monetization feature.
6. Moved `GutScoreCard` into the Insights feature and removed feature exports from the core widget barrel.
7. Removed navigation knowledge from the `ScanResult` model; callers now select `AppRoutes.scanResult`.
8. Replaced presentation-layer service-locator lookups for scan/chat streak celebrations with injected callbacks.
9. Injected `FirebaseAuth`, `SharedPreferences`, and `AppStateService` into profile/usage presentation objects instead of resolving them from `sl`.
10. Retained and cancelled auth-state subscriptions in Chat, History, Profile, and Usage notifiers.
11. Moved the app navigation adapter to `lib/app/router/app_navigator.dart` and updated notification integration.
12. Moved the bento/semantic Insights theme extensions and shared `BentoMetrics` to `lib/core/theme/` after tracing their real use from Insights, History, and Product Details; bento cards/widgets remain feature-owned.
13. Replaced notification infrastructure's direct app-router dependency with a `NotificationNavigationPort` supplied by the app composition root.
14. Extracted deterministic scanner scoring and sensitivity re-flagging into `features/scanner/data/services/scanner_score_service.dart`, preserving the existing score inputs, fallback rules, diagnostics, and output values.
15. Extracted the existing chat medical-safety disclaimer policy into `features/chat/domain/services/chat_safety_guardrails.dart` and added focused unit coverage without changing response text or trigger words.
16. Extracted pinned-entity context and grounded-swap prompt formatting into `features/chat/domain/services/chat_prompt_context.dart`, updating existing tests to target the domain service.
17. Added a dependency-free `AppFailure` taxonomy and adopted it for Scanner operation state while preserving the existing `null` return contract and offline UI behavior.
18. Decomposed the largest presentation files into named Dart library parts while keeping their primary library paths stable: Chat screen, Chat composer workflows, Scanner result sections, Insights Bento screens/widgets, semantic Insights feed, Highlight detail, Pattern detail, Smart Insight detail, and Super Card widgets.
19. Moved the immutable additive profiles out of `AdditiveConcernDb` into named category files under `core/data/`, keeping the lookup API and keys unchanged.
20. Split debug fixture generation into named seed responsibilities for thirty-day data, chat history, showcase scans, and insufficient-data state.
21. Split the history Firestore contract from its implementation without changing the injected `HistoryFirestoreService` type.
22. Added this report and aligned the code/documentation structure around the actual feature inventory.
23. Moved shared AI infrastructure behind `core/ai/` (`AiClient`, proxy implementation, prompts, protocol models, and validation), while keeping Chat, Insights, and Scanner orchestration feature-owned and removing obsolete forwarding facades.
24. Moved shared Firebase adapters and cross-cutting integrations from the former core service area into `lib/infrastructure/firebase/`, with Firestore adapters under `lib/infrastructure/firebase/firestore/`; Firebase initialization remains in `lib/app/bootstrap.dart` and feature repositories remain feature-owned.
25. Moved the Open Food Facts adapter into `lib/infrastructure/open_food_facts/` and concrete device, app-version, connectivity, sharing, review, and URL integrations into `lib/infrastructure/platform/`; class contracts and runtime behavior remain unchanged.
26. Moved the concrete `AiProxyClient` implementation into `lib/infrastructure/ai/` while keeping the `AiClient` contract, exceptions, protocol, prompts, and validation under `lib/core/ai/`.
27. Moved the concrete RevenueCat purchase adapter into `lib/infrastructure/payments/`; Auth presentation/data code continues to own entitlement, paywall, and quota orchestration through the unchanged `PurchaseService` contract.
28. Moved profile-owned debug fixture generation into `features/profile/data/services/`, keeping the named seed parts and generated data behavior unchanged.
29. Moved `DomainEventPersister` into `features/logs/data/services/` because its meal, symptom, and scan persistence policy is feature data orchestration rather than a generic core service.
30. Moved the Firebase-dependent `PersistAiResponseUseCase` into `features/chat/application/usecases/`, keeping the pure chat parsing and policy use cases under `domain/`.
31. Extracted notification payload-to-route mapping into `lib/infrastructure/firebase/notification_payload_router.dart` and added focused route-behavior tests; notification scheduling, payload values, and navigation outcomes remain unchanged.
32. Split the app composition registrations into explicit AI, Firebase, platform, external, feature-service, repository/provider, and use-case DI modules while preserving registration types, singleton lifetimes, and initialization order.
33. Extracted local notification scheduling, reminder preferences, cancellation, and stable notification IDs into `NotificationScheduler` and `NotificationIds`; `NotificationService` retains the existing public contract and Firebase Messaging initialization.

### Validation status

Static repository checks completed:

- `git diff --check` passed.
- All non-generated internal `package:gutgood/...` imports resolve to files in the checkout.
- Old paths for moved `AppTheme`, router, paywall, quota guard, `GutScoreCard`, navigator, and Insights theme extensions were removed from Dart imports.
- The shared bento/semantic Insights theme extensions no longer require app or Product Details code to import an Insights presentation path.
- Active AI imports now target `core/ai/`; former AI service, prompt, validator, constants, and protocol facade files were removed.
- Core notification infrastructure no longer imports `lib/app`; navigation is supplied through `NotificationNavigationPort` at bootstrap.
- Shared Firebase imports resolve under `lib/infrastructure/firebase/`; no legacy Firebase service or Firestore path remains under `lib/core/services/`.
- Open Food Facts and platform-service imports resolve under `lib/infrastructure/open_food_facts/` and `lib/infrastructure/platform/`; no legacy imports remain for those services.
- The concrete AI proxy import resolves under `lib/infrastructure/ai/`; feature code continues to depend on the `AiClient` contract under `lib/core/ai/`.
- The RevenueCat purchase adapter import resolves under `lib/infrastructure/payments/`; no legacy purchase-service import remains.
- Profile debug fixture imports resolve under `features/profile/data/services/`; all Dart `part` relationships remain valid.
- Persistence orchestration imports resolve under `features/logs/data/services/` and `features/chat/application/usecases/`; the chat `domain/` layer no longer imports Firebase or infrastructure services.
- Notification payload routing has focused coverage for chat, Insights, archive, unknown, and absent payloads.
- The notification service contract still has implementations for all 22 public asynchronous methods after scheduler extraction.
- DI registration types and counts remain present across the grouped `app/di/` modules; the composition root still initializes core, services, features, and use cases in the same order.
- No remaining `sl<ProfileNotifier>()` calls exist in presentation notifiers.
- Scanner scoring, chat safety, prompt-context, failure-taxonomy, and large-file decomposition part references resolve; the new pure policy tests are present but cannot be executed without Flutter.
- All 19 remaining Dart libraries decomposed with `part` directives point to existing matching `part of` files and occur before declarations; the package import scan covered 467 current Dart files across `lib/` and `test/`.

A Flutter analyzer/test run could not be executed in this workspace because the Flutter SDK is not installed (`flutter: command not found`). The repository also intentionally ignores the generated `firebase_options.dart`; it must be produced by `flutterfire configure` in a configured Firebase environment. This is an environment/configuration limitation, not a refactor-generated source error.

The Firebase Functions backend was install/build checked with `npm ci && npm run build`; TypeScript compilation passed. The workspace has Node 20 while `functions/package.json` declares Node 22, so npm emitted an engine warning. `npm ci` also reported 16 dependency audit findings (11 moderate, 5 high); dependency remediation should be handled as a separate security change rather than silently changing backend versions during this behavior-preserving refactor.

### Dead-code cleanup pass (2026-10-03)

A repository-wide dead-code review followed the architecture refactor. The scan resolved relative/package imports, exports, Dart `part` relationships, route declarations, and test imports. Starting from `lib/main.dart` plus all test libraries, the post-cleanup graph contains **417 Dart files under `lib/`; all 417 are reachable**. The five originally unreachable Insights files were removed after confirming that their filenames, widget/class names, route names, and relevant symbols had no repository references:

- `features/insights/presentation/pages/action_detail_screen.dart`
- `features/insights/presentation/pages/all_pattern_occurrences_screen.dart`
- `features/insights/presentation/pages/evidence_methodology_screen.dart`
- `features/insights/presentation/widgets/active_experiment_card.dart`
- `features/insights/presentation/widgets/insight_history_tile.dart`

The same pass removed only additional high-confidence dead implementation:

- the uncalled insufficient-data debug fixture part;
- the now-unreachable `InsightUiUtils` helper;
- the unused legacy Super-card facade and eight unreferenced companion widget/painter files;
- two empty legacy feed library parts left after removing obsolete widgets;
- unreferenced widgets/classes including `InsightScoreTrendCard`, `PatternGrid`, `MiniChart` and its painters, `AdditiveConcernPill`, obsolete Bento score/art helpers, and unused legacy feed kit primitives;
- unreferenced helpers/constants such as `BottomSheetHelper.showGutSheet`, `BentoData.matchLabel`, `PatternCardStyle.foodHeroColor`, the unregistered `AppRoutes.gutScoreDetail`, obsolete feed label helpers, `ProfileNotifier.updateInsightsDisabled`, `logSwapToJournal`, and the unused experiment date/check-in convenience methods;
- unused internal AppSizes/AppIcons entries, dead Bento/Insights metric constants and obsolete typography aliases, while keeping persistence keys, route values, theme-extension contract members, and intentional barrels intact.

The review explicitly retained ambiguous public/model candidates rather than guessing: `ScannerNotifier.lastFailure`, `AiAnalysisResult.menuResult`, and `UserProfile.notifPrefs` have no in-repository callers but remain available as model/notifier surfaces. The semantic Insights feed view-model fields remain because they are consumed by the current renderer and are fed by persisted AI insight blocks. The active-experiment persistence/repository path and debug thirty-day fixture also remain because they still participate in registered/runtime flows even though the removed card is no longer a consumer.

Validation for this pass: `git diff --check` passed; the part graph has 129 directives with no missing owners/targets; all internal package imports/exports resolve except the pre-existing generated `firebase_options.dart` imports; and the combined runtime/test reachability scan reports no unreachable `lib/` file. A Flutter analyzer/test run remains unavailable because the Flutter SDK is not installed. Identifier scans were conservative and are not a substitute for analyzer diagnostics.

### Continuation audit: naming, reuse, and dependencies

A follow-up production-readiness scan found no legacy `_new`, `_old`, `_backup`, `_temp`, or numbered implementation filenames. The remaining `v2` names are intentional design-version boundaries, and `super_scanner` is a product/screen name rather than a stale implementation suffix. Every declared runtime dependency in `pubspec.yaml` has at least one Dart import; no package was removed speculatively. The two `BentoCard` classes remain intentionally separate: the core card and the Insights bento card have different constructor contracts, styling systems, and ownership, so merging them would violate the behavior-preservation requirement rather than reduce safe duplication. The first similarity pass found no additional 80–90% widget merge that was high-confidence enough to apply without changing API or visual contracts; the later targeted duplicate review is documented below.


### Continuation audit: safe duplicate presentation extraction (2026-10-03)

The duplicate-widget review was continued after the dead-code pass. Four extractions were applied only where the rendering structure was identical or where the small visual difference could be represented explicitly without changing a caller's contract:

- `InsightNextStepCheckRow` now owns the shared check-mark row used by Pattern, Smart Insight, and Synergy details. Pattern/Smart retain their existing light/dark colors, while Synergy continues to resolve its semantic `insightColor` palette at the call site.
- `InsightEvidenceMetricRow` now owns the shared metric-row layout used by all three Insights detail screens. Existing blue light/dark colors and Synergy semantic colors are supplied unchanged by each caller.
- `ProductDetailHeaderTag` now owns the shared header-tag treatment used by symptom and scanned-product detail headers. Its `uppercaseLabel` parameter preserves the symptom header's uppercase rendering while leaving scan-result labels unchanged.
- `ProfileSelectionHeader` and `ProfileSelectionFooter` now own the identical preference-selection chrome shared by Goals, Lifestyle, and Sensitivities screens.

The six duplicate Insights page-part files were removed after their callers were migrated:
`pattern_next_step_row.dart`, `smart_insight_next_step_row.dart`, `synergy_next_step_row.dart`, `pattern_evidence_metric_row.dart`, `smart_insight_evidence_metric_row.dart`, and `synergy_evidence_metric_row.dart`. The four shared widget files live under their owning feature presentation widget directories. No route, state, data, persistence, API, theme-resolution, or user-flow behavior was changed.

Post-extraction validation reports **415/415 `lib/` Dart libraries reachable**, zero runtime-only unreachable libraries, and **123 valid `part` directives** with no missing targets or owners. The package import scan resolves 1,688 of 1,690 package references; the only two unresolved imports are the pre-existing generated `firebase_options.dart` imports. `git diff --check` passes. A normalized duplicate-class scan has no remaining cross-file candidates at or above the 98.5% threshold; lower-similarity candidates were retained where responsibilities or styling contracts differ.


### Continuation audit: Insights domain/application boundary (2026-10-03)

The Insights orchestration layer was separated from the domain layer. `GenerateInsightUseCase` and `SummarizeJournalUseCase` now live under `features/insights/application/usecases/`, where their concrete Firebase, notification, AI, Remote Config, SharedPreferences, and calculator dependencies are appropriate. The pure envelope/status policy and newest-first chat limiting moved to `features/insights/domain/services/insight_generation_policy.dart`; the existing `stampInsightEnvelope` and `takeRecentChat` behavior is unchanged, and the focused test now imports the dependency-free policy directly. The unused `HistoryFirestoreService` injection into `GenerateInsightUseCase` was also removed after repository-wide reference verification.

The Insights domain tree now has **zero imports of Flutter, Firebase, Firestore, SharedPreferences, HTTP clients, routing, provider, GetIt, or other SDK infrastructure**. Post-change reachability is **416/416 `lib/` Dart libraries**, with zero runtime-only unreachable libraries; the part graph remains 123 valid directives. Final package import validation resolves 1,689 of 1,691 references, excluding only the two generated `firebase_options.dart` imports. Analyzer and tests remain unavailable because the Flutter/Dart SDK is not installed in this workspace.


### Continuation audit: composition-root DI ownership (2026-10-03)

The DI orchestration libraries moved from `lib/core/di/` to `lib/app/di/`: `core_di.dart`, `feature_di.dart`, `service_di.dart`, `usecase_di.dart`, and `injection_container.dart`. The core layer retains only the small `di_instance.dart` GetIt handle; runtime consumers now import that primitive directly, while process bootstrap imports the app-owned initialization entrypoint. Registration order, singleton lifetimes, provider construction, and all injected implementations are unchanged.

The Auth-owned `LinkService` and `UsageService` implementations now live under `features/auth/data/services/`; all consumers and the UsageService test were migrated without changing their contracts or quota/deep-link behavior.

The Auth-owned implementation boundaries remain clean: the only non-compatibility core-to-feature seam is the documented `AuthUser` export from the central `core/models/models.dart` barrel. All in-repository imports now target canonical paths; the former core DI, UsageService, AppTheme, GutScoreCard, Insights use-case, AI, prompt, and legacy Insights facade files have been removed. The part graph remains valid, and the only unresolved package imports remain the two generated Firebase options imports.

### Continuation audit: low-risk infrastructure hardening (2026-10-03)

The next behavior-preserving pass applied three narrow changes. `InsightRepositoryImpl.getLatestInsight()` now treats malformed local insight JSON as a cache miss, removes the invalid cache entry, and logs a warning; valid cloud and local cache behavior is unchanged. Key provider registrations in `app/di/feature_di.dart` now use explicit dependency types for positional constructor arguments, improving composition readability without changing constructors, provider order, or lifetimes. Finally, `HistoryFirestoreServiceImpl` now receives the existing `GutScoreFirestoreService` abstraction through DI. The dependency remains optional for compatibility callers, which preserves the previous concrete fallback; the registered application path, score calculator, Firestore paths, write timing, and error behavior are preserved.

Static validation after this pass includes `git diff --check`, internal reference verification, and the existing reachability/part/dependency scans. A follow-up compile-error correction restored active `AppSizes`/`AppTextStyles` aliases, moved chat stream state out of an invalid extension field, and wrapped the three Insights detail section part files in explicit screen extensions. The obsolete export-only DI, theme, UsageService, GutScoreCard, Insights use-case, AI, prompt, and legacy Insights facade files were then removed after the in-repository references were migrated to canonical paths. The subsequent analyzer-info cleanup removed the redundant `dart:ui` and route-argument imports, applied the safety-policy tear-off, and removed unnecessary receiver qualifiers from the decomposed chat and Insights parts. The current package/test import scan resolves every internal reference except the two generated Firebase options imports; the Flutter/Dart analyzer and runtime tests should be rerun in CI or the configured developer environment before merge.

---

## A. Current architecture

### A.1 Product/features discovered

The application currently contains these feature modules:

- **Auth:** anonymous, email/password, magic link, Google, Apple, account merge/deletion, RevenueCat entitlement state.
- **Chat:** streaming AI assistant, persistent history, attachments, offline outbox, passive `[MEAL]`/`[SYMPTOM]`/`[SCAN]` processing, summaries, feedback/reporting.
- **History:** scan history, saved foods, meal/symptom journal timeline, pagination.
- **Home:** `StatefulShellRoute` bottom-navigation shell.
- **Insights:** gut score, AI insights, patterns, alerts, experiments, swaps, bento/v2 presentation systems.
- **Logs:** meal and symptom repository seam used by the logging pipeline.
- **Onboarding:** personalization and cycle-sync setup.
- **Product details:** unified scan result, additives, symptom, swap, and product-not-found flows.
- **Profile:** profile, goals, sensitivities, lifestyle, notifications, cycle phase, usage.
- **Scanner:** barcode, label, meal, menu, and vision-AI orchestration.
- **Splash/Welcome:** startup and unauthenticated entry flows.

### A.2 Runtime composition flow

The actual runtime flow before this pass was:

```text
main.dart
  ├── Firebase.initializeApp
  ├── GetIt init()
  ├── Crashlytics / FCM handlers
  ├── device and app metadata warmup
  ├── orientation configuration
  └── MultiProvider
        └── GutGoodApp
              └── MaterialApp.router
                    └── core/router/AppRouter
```

The resulting flow is:

```text
main.dart
  └── AppBootstrap.initialize()
        ├── Firebase / FCM / Crashlytics
        ├── GetIt registration
        ├── metadata warmup
        └── orientation configuration
  └── GutGoodApp
        ├── MultiProvider composition
        └── _GutGoodShell
              └── MaterialApp.router
                    └── app/router/AppRouter
```

Provider order is unchanged:

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

### A.3 Actual data flows

#### Authentication and profile

```text
Welcome / Login / Onboarding UI
  ↓
GutAuthNotifier / ProfileNotifier
  ↓
AuthRepository / AuthFirestoreService
  ↓
FirebaseAuth + Firestore + Cloud Functions for merge/delete
  ↓
AuthUser / UserProfile streams
  ↓
Provider listeners and GoRouter redirect
  ↓
UI
```

`AuthRepository` is the strongest existing domain boundary: it exposes `AuthUser` and auth operations while `AuthRepositoryImpl` owns Firebase/social-provider details.

#### Chat

```text
ChatScreen
  ↓
ChatComposerNotifier ───────→ ChatHistoryNotifier
  ↓                                  ↓
SendMessageStreamUseCase             ChatFirestoreService stream
  ↓                                  ↓
ChatRepository interface              ChatMessage state
  ↓
ChatRepositoryImpl
  ├── AiClient → AiProxyClient → Cloud Function aiProxy → OpenAI SSE
  ├── ChatFirestoreService → Firestore
  ├── ChatSafetyGuardrails → deterministic response safety policy
  ├── FoodImageService / StorageService → Storage
  └── StreakService

Streamed response
  ↓
ProcessChatTagUseCase
  ↓
PersistAiResponseUseCase / DomainEventPersister
  ↓
HistoryFirestoreService → meal/symptom/scan records
```

#### Scanner

```text
SuperScannerScreen
  ↓
ScannerNotifier
  ↓
ScannerRepository interface
  ↓
ScannerRepositoryImpl
  ├── OffService → Open Food Facts
  ├── AiClassifierService / AiClient → aiProxy
  ├── ScannerScoreService → deterministic YukaScore / additive concerns
  ├── DomainEventPersister
  └── Firestore services
  ↓
ScanResult / AiAnalysisResult
  ↓
saveScanResult → scan history + chat bubble + passive logs
  ↓
Scan result UI / History UI
```

The scanner repository currently owns orchestration, deterministic scoring, AI response parsing, persistence policy, and analytics. It is a high-value next extraction target, but splitting it blindly would risk changing scan persistence and barcode-cache behavior.

#### Insights

```text
InsightsScreen / detail pages
  ↓
InsightsNotifier
  ├── InsightRepository streams
  ├── History counts and score streams
  └── GenerateInsightUseCase
        ↓
      CheckInsightThresholdUseCase
      BuildUnifiedJournalUseCase
      SummarizeJournalUseCase
        ↓
      InsightRepositoryImpl
        ├── Firestore insight/history/chat services
        ├── SharedPreferences cache
        └── AiClient → aiProxy
  ↓
InsightsDashboardState / AIInsight / BodyPattern
  ↓
Bento and semantic Insights feed widgets
```

### A.4 Firebase/backend boundary

The backend is a TypeScript Firebase Functions package with 2,238 lines across 12 source files. It exposes the following production contracts:

```text
Flutter client
  ├── HTTPS aiProxy
  │     ├── Firebase ID-token authentication
  │     ├── server-side chat/scan/system quota transaction
  │     ├── OpenAI secret kept in Secret Manager
  │     └── SSE or JSON response with prompt/model/truncation metadata
  ├── Callable mergeAnonymousAccount
  │     └── idempotent Firestore + Storage migration
  ├── Callable deleteAccount
  │     └── Auth deletion → onUserDeleted cascade
  ├── Callable sendCustomMagicLink
  └── scheduled/Firestore triggers
        ├── anonymous cleanup
        ├── profile welcome email
        ├── journal/scan counters and streaks
        └── food-image thumbnail/cleanup jobs
```

`functions/src/ai_proxy.ts` (475 lines) is the security and quota boundary for AI. `merge.ts` (345 lines) preserves document IDs, rewrites Storage URLs, deduplicates records, and records merge markers. `lifecycle.ts`, `triggers.ts`, `usage.ts`, and `counters.ts` keep server-authoritative data and cleanup rules outside the Flutter client. No backend source or API contract was changed in this pass.

### A.5 State, data, and infrastructure placement

| Responsibility | Current location | Assessment |
|---|---|---|
| Provider state | `features/*/presentation/providers` | Correct direction; several notifiers are too large and infrastructure-aware. |
| Repository contracts | `features/*/domain/repositories` | Good seam, but not every feature has one. |
| Repository implementations | `features/*/data/repositories` | Correct location, though implementations depend on shared Firebase adapters where persistence is cross-feature. |
| Scanner scoring policy | `features/scanner/data/services/scanner_score_service.dart` | Extracted deterministic score/re-flagging policy; barcode/vision orchestration and persistence remain in the repository for the next incremental slice. |
| Chat safety policy | `features/chat/domain/services/chat_safety_guardrails.dart` | Pure response policy extracted from the composer notifier and covered independently; streaming/persistence orchestration remains in the notifier. |
| Chat prompt context policy | `features/chat/domain/services/chat_prompt_context.dart` | Pinned-entity and grounded-swap formatting are pure domain helpers; network, persistence, and streaming remain outside. |
| Failure taxonomy | `core/errors/app_failure.dart` | SDK-neutral categories retain structured diagnostics; Scanner adopts the type while preserving existing feature-specific user copy and return contracts. |
| Use cases | Chat and Insights domain folders | Good and behaviorally important; logging/scanner use cases are still embedded in repositories/services. |
| Firebase data access | `lib/infrastructure/firebase/firestore` | Shared Firebase adapters are isolated from `core`; feature-specific data-source ownership remains a future incremental step. |
| AI/network access | `lib/core/ai/client/ai_client.dart` (contract), `lib/infrastructure/ai/ai_proxy_client.dart` (implementation), `lib/infrastructure/open_food_facts/off_service.dart` | Shared AI contracts and concrete external adapters have narrow boundaries; Chat, Insights, and Scanner retain feature-owned orchestration. |
| Models/entities | Mostly `core/models` | Works, but mixes persistence, domain, and presentation shapes. Auth is the only clearly separated entity/model pair. |
| App composition | `app/di`, `app/app.dart` | `app/app.dart` is the widget composition root; `core/di` retains only the GetIt handle. |
| Navigation | `app/router/app_router.dart`, route constants in `core/router` | Router now belongs to app; route constants/codec remain shared because notification/model call sites still use them. |
| Theme extensions/design tokens | `core/theme/insight_bento_theme.dart`, `insight_theme.dart` | Shared bento and semantic tokens are consumed by Insights, History, and Product Details; `AppTheme` registers them, while cards/widgets remain feature-owned. |
| Shared UI | `core/widgets` | Core barrel now contains only core widgets; feature-owned paywall and score card were removed. |

---

## B. Problems found

| Problem | Location | Severity | Impact | Solution / status |
|---|---|---:|---|---|
| Bootstrap and widget composition in one entry point | `lib/main.dart` | High | Startup ordering, provider composition, lifecycle, and UI were difficult to test or reason about together. | **Fixed:** extracted `AppBootstrap` and `GutGoodApp`; behavior/order preserved. |
| Feature-aware router lived under `core` | `lib/core/router/app_router.dart` | High | Core depended on nearly every feature page/provider. | **Fixed:** moved to `lib/app/router/app_router.dart`. |
| Global theme under `core` imported Insights widgets | former core theme location | High | Core depended on feature presentation. | **Fixed:** moved `AppTheme` to `lib/app/theme/app_theme.dart`; shared bento and semantic extensions now live in dependency-neutral `core/theme` files. |
| Core widget barrel exported feature widgets | old `core/widgets/widgets.dart` | High | Any core consumer could pull in Insights presentation and create hidden coupling. | **Fixed:** removed `ArcPatternCard`, `GutScoreCard`, and paywall exports. |
| Same `BentoCard` name represented two different APIs | `core/widgets/bento_card.dart`, Insights `bento_widgets.dart` | Medium | Product Details and Insights use different constructor contracts, so broad imports can create ambiguous ownership and make reuse misleading. | **Deferred intentionally:** shared theme/metrics were extracted first; consolidate or rename the card APIs only after comparing visual contracts and call sites. |
| Auth/monetization UI in `core` | old `core/widgets/paywall_screen.dart`, `core/utils/quota_guard.dart` | High | Auth-specific behavior looked globally reusable and made dependency direction unclear. | **Fixed:** moved to `features/auth/presentation/pages` and `presentation/utils`. |
| Domain model knew a concrete route | `ScanResult.detailRoute` | Medium | Core data model depended on navigation. | **Fixed:** route selection is now in `HistorySection`. |
| Presentation notifiers resolved sibling presentation objects from `sl` | Chat/Scanner notifiers | High | Hidden dependencies made tests harder and coupled feature state to the profile provider. | **Fixed:** injected `onTurnCompleted` / `onScanCompleted` callbacks from DI. |
| Profile notifier resolved FirebaseAuth and created SharedPreferences internally | `ProfileNotifier` | High | Hidden runtime dependencies and difficult unit testing. | **Fixed:** `FirebaseAuth` and `SharedPreferences` are constructor dependencies. |
| Usage notifier resolved AppStateService and leaked auth subscription | `UsageNotifier` | High | Hidden dependency and listener lifetime leak. | **Fixed:** injects `AppStateService` and cancels auth subscription. |
| Auth subscriptions were not retained/cancelled | `ChatHistoryNotifier`, `HistoryNotifier`, `ProfileNotifier` | High | Recreated providers could keep receiving events and retain state/services. | **Fixed:** subscriptions are stored and cancelled in `dispose`. |
| Large controller/god-widget/repository surfaces | Previously `ChatComposerNotifier` 1,150 lines, `ChatScreen` 1,211, the legacy Insights feed 2,988, and `scan_result_widgets.dart` 1,765 | High | Review, testing, and safe changes are expensive. | **Improved:** large presentation surfaces are now split into named library parts/extensions; Chat stream/outbox behavior remains in separate workflow files, while `ScannerRepositoryImpl` still needs a later orchestration split. |
| Business/infrastructure logic in presentation | Chat/Profile/Scanner notifiers | High | UI state objects know Firebase SDKs, file system, storage, and profile details. | **Partially addressed:** chat safety policy and scanner scoring are now isolated; continue extracting workflow use cases and narrow data-source contracts incrementally. |
| Repositories depend on shared `lib/infrastructure/firebase/firestore` implementations | all feature data repositories | High | Data-source ownership is not yet feature-local and contracts are hard to mock. | **P1:** move feature-specific adapters into feature `data/datasources` incrementally while keeping the Firebase boundary explicit. |
| Central model barrel mixes entities, DTOs, Firestore maps, and UI argument types | `core/models/models.dart` and subfolders | High | Domain code can accidentally depend on persistence or Flutter types; imports hide ownership. | **P1:** migrate one feature at a time, beginning with Chat and Scanner. |
| Domain contracts use core model types | `features/*/domain/repositories` | Medium | Domain is not fully independent from the shared model/persistence layer. | **P1:** introduce feature entities and mapper boundaries where data transforms are non-trivial. |
| Auth services were placed in the shared core | former `lib/core/services/link_service.dart`, `usage_service.dart` | Medium | Auth-owned session and quota behavior did not have feature-local ownership. | **Fixed:** implementations now live under `features/auth/data/services/`; contracts and quota/deep-link behavior are unchanged. |
| Notification service performed app navigation | `lib/infrastructure/firebase/notification_service.dart` | Medium | Infrastructure service knew concrete app routes and the app router adapter. | **Fixed:** `NotificationNavigationPort` is defined at the core boundary and an app adapter is supplied during bootstrap; payload-to-route mapping and navigation behavior are unchanged. |
| Error results are inconsistent | Firestore services, repositories, notifiers | High | Some failures are logged and converted to `null`, while others rethrow; UI cannot distinguish network, auth, parse, and permission failures consistently. | **Partially addressed:** SDK-neutral `AppFailure` categories now back Scanner operation state without changing current messages or `null` contracts; migrate additional repository boundaries incrementally. |
| `try/catch (_) {}` used for cache fallback parsing | `InsightRepositoryImpl` and other cache paths | Medium | Corrupt cache is silently discarded without telemetry. | **P2:** log a classified cache warning, retain fallback behavior. |
| Pre-login magic-link callable has no rate limit/App Check | `functions/src/auth.ts` (`sendCustomMagicLink`) | High security | Existing accepted risk R5 permits branded-email abuse before public launch. | **P1 security decision:** add rate limiting/App Check without changing the client contract. |
| Profile trigger trusts client-writable email/display name | `functions/src/lifecycle.ts` (`onProfileWritten`) | High security | Existing accepted risk R6 permits arbitrary recipients or unsafe HTML in welcome-email content. | **P1 security decision:** source recipient from Admin Auth, escape HTML, and lock sent flags in rules. |
| Merge has no possession proof for anonymous UID | `functions/src/merge.ts` | Medium security | Existing accepted risk R8 relies on high-entropy UIDs rather than an explicit claim/marker. | **P2:** add a short-lived server-issued merge claim if the threat model requires it. |
| Documentation claims `sqflite`, but `pubspec.yaml` does not include it | `README.md`, `docs/2_technical_architecture.md` | Medium | New engineers may implement against a database that is not present. | **P1:** document the actual Firestore offline cache, SharedPreferences, and outbox storage; do not add a dependency without a product need. |
| Generated Firebase configuration is absent from the checkout | ignored `firebase_options.dart` | Environment | Analyzer/build cannot complete in an unconfigured checkout. | Keep ignored for secrets/project configuration; generate with `flutterfire configure` in CI/developer setup. |

### Flutter-specific observations

- `ChangeNotifier` state is feature-scoped, but several notifiers combine remote streams, mutations, caching, analytics, and navigation-adjacent callbacks.
- The newly retained subscriptions close an explicit lifecycle gap without changing event semantics.
- Chat composer async workflows now have named library boundaries (`send`, `uploads`, `outbox`, `context`, `stream`, and `swaps`) while still sharing one notifier state boundary; preserve that ordering when a future use-case extraction is attempted.
- The application uses `Selector`/`Consumer` in several high-traffic screens, but some large screens still rebuild broad subtrees. Measure before introducing more granular state objects.
- `BuildContext` is kept in presentation code for navigation and UI feedback; no new context is introduced into domain/data layers.

---

## C. Resulting and target folder structure

### C.1 Resulting structure after this pass

```text
lib/
├── app/
│   ├── app.dart                         # Provider composition + MaterialApp shell
│   ├── bootstrap.dart                   # Firebase/DI/Crashlytics startup
│   ├── router/
│   │   ├── app_router.dart              # Feature-aware GoRouter configuration
│   │   └── app_navigator.dart           # App-level router adapter
│   └── theme/
│       └── app_theme.dart               # Global theme + feature extensions
│
├── core/
│   ├── ai/                              # Shared AI contract, proxy, prompts, protocol, validation
│   ├── constants/
│   ├── data/                            # Shared additive reference data
│   ├── di/                              # GetIt handle only
│   ├── errors/                           # SDK-neutral failure categories
│   ├── models/                          # Transitional shared models/barrel
│   ├── router/
│   │   ├── app_routes.dart              # Route names used by shared integrations
│   │   ├── notification_navigation_port.dart
│   │   └── route_codec.dart
│   ├── services/                        # Shared app state, configuration, and deterministic policies
│   ├── theme/                           # Palette, color scheme, text styles, shared bento and semantic tokens
│   ├── utils/
│   └── widgets/                         # Core-only reusable widgets
│
├── infrastructure/
│   ├── ai/                              # Concrete AI proxy implementation
│   ├── firebase/                        # Shared Firebase adapters and Firestore services
│   │   └── firestore/                   # Firestore adapters and contracts
│   ├── open_food_facts/                  # Open Food Facts/Dio adapter
│   ├── payments/                         # RevenueCat purchase adapter
│   └── platform/                         # Device, connectivity, app, and platform adapters
│
├── features/
│   ├── auth/
│   │   ├── data/{models,repositories,utils}
│   │   ├── domain/{entities,repositories}
│   │   └── presentation/{pages,providers,utils,widgets}
│   ├── chat/{data,domain,presentation}
│   ├── history/{data,domain,presentation}
│   ├── home/presentation/pages
│   ├── insights/{data,domain,presentation}
│   ├── logs/{data,domain}
│   ├── onboarding/presentation/{pages,widgets}
│   ├── product_details/presentation/{pages,utils,widgets}
│   ├── profile/{data,domain,presentation}
│   ├── scanner/{data,domain,presentation}
│   ├── splash/presentation/pages
│   └── welcome/presentation/pages
│
└── main.dart
```

### C.2 Large-file decomposition map

The active public import paths now point directly to the canonical libraries. Implementations are grouped into named parts/extensions without retaining export-only compatibility facades:

| Canonical library | Responsibility files |
|---|---|
| `features/chat/presentation/providers/chat_composer_notifier.dart` | `chat_composer_attachments.dart`, `chat_composer_send.dart`, `chat_composer_uploads.dart`, `chat_composer_regeneration.dart`, `chat_composer_outbox.dart`, `chat_composer_context.dart`, `chat_composer_stream.dart`, `chat_composer_swaps.dart` |
| `features/chat/presentation/pages/chat_screen.dart` | `chat_screen_state.dart`, `chat_suggestions_section.dart`, `chat_app_bar.dart`, `chat_message_list.dart`, `chat_composer.dart`, `chat_jump_to_latest.dart` |
| `features/chat/application/usecases/persist_ai_response_usecase.dart` | Firebase-dependent chat persistence orchestration over the shared log-event persister |
| `features/logs/data/services/domain_event_persister.dart` | Shared meal, symptom, and scan persistence policy used by Chat and Scanner |
| `features/product_details/presentation/widgets/scan_result_widgets.dart` | Named score, header, metrics, working, watch, swaps, additives, ingredients, allergens, details, footer, cycle, and save components |
| `features/insights/presentation/widgets/insight_feed/insights_feed.dart` | Feed shell, food-impact, top-food, and weekly-recap component files |
| `features/insights/presentation/widgets/bento/insight_bento_screens.dart` | Recap, history, pattern, synergy, and food-intelligence screens |
| `features/insights/presentation/widgets/bento/bento_widgets.dart` | Card, tag/surface, grid, score hero, spark, tabs, food-tile, and action components |
| `features/insights/presentation/pages/highlight_detail_screen.dart` | Page shell, healing sections, trigger sections, lookup helper, and named subcomponents |
| `features/insights/presentation/pages/pattern_detail_screen.dart` and `smart_insight_detail_screen.dart` | Page shells, section extensions, lookup helpers, and named reusable rows/tiles |
| `core/widgets/super_card.dart` | Named score, metric, gauge, autopilot, goal, pattern, cycler, and painter components |
| `core/data/additive_concern_db.dart` | Named flavor, color, sweetener, emulsifier, acid, preservative, gum/color, and name-only profile files plus the unchanged resolver API |
| `core/constants/app_strings.dart` | Canonical string-catalog entry point over the named `constants/strings/*_strings.dart` catalogs |
| `features/profile/data/services/debug_mock_data_service.dart` | Named thirty-day, chat-history, showcase-scan, and insufficient-data seed files |
| `lib/infrastructure/ai/ai_proxy_client.dart` | Concrete authenticated AI proxy transport implementation |
| `lib/infrastructure/firebase/notification_service.dart` | Firebase Messaging initialization and public notification orchestration contract |
| `lib/infrastructure/firebase/notification_scheduler.dart` | Local notification display, scheduling, reminder preferences, and cancellation |
| `lib/infrastructure/firebase/notification_ids.dart` | Stable local notification identifiers |
| `lib/infrastructure/firebase/notification_payload_router.dart` | Payload-to-route mapping through `NotificationNavigationPort` |
| `lib/infrastructure/firebase/firestore/history_firestore_service.dart` | Explicit history contract and Firestore implementation files |
| `lib/infrastructure/open_food_facts/off_service.dart` | Concrete Open Food Facts adapter and product mapping/cache implementation |
| `lib/infrastructure/payments/purchase_service.dart` | Concrete RevenueCat purchase and entitlement adapter |
| `lib/infrastructure/platform/` | Concrete app-version, device-info, connectivity, sharing, review, and URL integrations |

All these files remain in the same Dart library where private implementation names were shared. Callers should import the canonical entry libraries, never the `part` files directly. This preserves the existing public APIs and UI behavior while making ownership and review boundaries explicit.

### C.3 Five-year target structure

The following is the recommended end state, using the actual GutGood feature names. It is a migration target, not a claim that every legacy model/service has already been moved:

```text
lib/
├── app/
│   ├── app.dart
│   ├── bootstrap.dart
│   ├── di/
│   │   ├── core_registrations.dart
│   │   ├── feature_registrations.dart
│   │   └── use_case_registrations.dart
│   ├── router/
│   │   ├── app_router.dart
│   │   ├── app_navigator.dart
│   │   └── app_routes.dart
│   └── theme/
│       └── app_theme.dart
├── core/
│   ├── constants/
│   ├── errors/
│   ├── extensions/
│   ├── network/
│   ├── storage/
│   ├── theme/
│   ├── utils/
│   └── widgets/
├── infrastructure/
│   ├── ai/
│   ├── firebase/
│   │   └── firestore/
│   ├── open_food_facts/
│   ├── payments/
│   └── platform/
├── features/
│   ├── auth/
│   │   ├── data/{datasources,models,repositories}
│   │   ├── domain/{entities,repositories,usecases}
│   │   └── presentation/{pages,providers,widgets}
│   ├── chat/
│   │   ├── data/{datasources,models,repositories,services}
│   │   ├── domain/{entities,repositories,services,usecases}
│   │   └── presentation/{pages,providers,widgets}
│   ├── history/
│   │   ├── data/{datasources,models,repositories}
│   │   ├── domain/{entities,repositories,usecases}
│   │   └── presentation/{pages,providers,widgets}
│   ├── home/presentation/pages
│   ├── insights/
│   │   ├── data/{datasources,models,repositories}
│   │   ├── domain/{entities,repositories,usecases}
│   │   └── presentation/{pages,providers,widgets}
│   ├── logs/{data,domain,presentation}
│   ├── onboarding/presentation/{pages,widgets}
│   ├── product_details/presentation/{pages,widgets}
│   ├── profile/{data,domain,presentation}
│   ├── scanner/
│   │   ├── data/{datasources,models,repositories,services}
│   │   ├── domain/{entities,repositories,usecases}
│   │   └── presentation/{pages,providers,widgets}
│   ├── splash/presentation/pages
│   └── welcome/presentation/pages
└── main.dart
```

The target deliberately does **not** move every file into `core` or the shared Firebase boundary. Cross-feature Firebase adapters remain under `lib/infrastructure/firebase/`; feature-specific Firestore classes, DTOs, prompt contracts, repositories, and presentation widgets should remain with their owning feature and can move into feature `data/datasources/` incrementally.

---

## D. Dependency diagram and boundaries

### D.1 Intended dependency direction

```text
┌──────────────────────────────┐
│ Presentation                 │
│ pages, widgets, providers    │
└──────────────┬───────────────┘
               │ depends on
               ▼
┌──────────────────────────────┐
│ Domain                       │
│ entities, use cases, ports   │
└──────────────┬───────────────┘
               │ depends on abstractions
               ▼
┌──────────────────────────────┐
│ Data                         │
│ repository implementations   │
│ DTOs, mappers, data sources  │
└──────────────┬───────────────┘
               ▼
┌──────────────────────────────┐
│ Infrastructure               │
│ Firebase, Dio, storage, SDKs │
└──────────────────────────────┘
```

The practical rule is:

```text
UI → provider/controller → use case → repository interface
                                      ↑
                         repository implementation
                                      ↓
                                  data source
                                      ↓
                              Firebase/API/local SDK
```

### D.2 Boundary rules

- `domain/` must not import Flutter, Firebase, Dio, SharedPreferences, or RevenueCat.
- `presentation/` may use `BuildContext`, GoRouter, and UI-only callbacks, but must not construct Firebase/Dio clients or implement Firestore queries.
- `data/` owns DTOs, model mapping, persistence, and repository implementations.
- `core/` is for infrastructure and genuinely cross-feature primitives; it is not a second feature folder. Shared design tokens/extensions belong here when multiple features consume them; feature-specific cards do not.
- `app/` is allowed to compose features, register providers, configure routes, and attach global theme extensions.
- Cross-feature presentation imports should be replaced by domain contracts or app-level composition where the dependency is not truly shared.
- Infrastructure may depend on core ports; the app composition root supplies app-specific adapters such as notification navigation.

The current code now follows these rules for the app composition, router/theme ownership, core widget barrel, paywall/quota ownership, injected streak callbacks, and notification navigation port. The remaining data/model migrations are deliberately staged because changing model boundaries can alter Firestore serialization if done in one sweep.

---

## E. Refactored code

These are the production source files now in the repository, not pseudocode.

### E.1 Minimal process entry point

`lib/main.dart`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppBootstrap.initialize();
  runApp(const GutGoodApp());
}
```

### E.2 Composition root

`lib/app/app.dart` owns the existing provider graph and keeps the provider order unchanged:

```dart
class GutGoodApp extends StatelessWidget {
  const GutGoodApp({super.key});

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => sl<ThemeNotifier>()),
      ChangeNotifierProvider(create: (_) => sl<GutAuthNotifier>()),
      ChangeNotifierProvider(create: (_) => sl<ProfileNotifier>()),
      ChangeNotifierProvider(create: (_) => sl<UsageNotifier>()),
      ChangeNotifierProvider(create: (_) => sl<ChatHistoryNotifier>()),
      ChangeNotifierProvider(create: (_) => sl<ChatComposerNotifier>()),
      ChangeNotifierProvider(create: (_) => sl<InsightsNotifier>()),
      ChangeNotifierProvider(create: (_) => sl<ScannerNotifier>()),
      ChangeNotifierProvider(create: (_) => sl<PurchaseProvider>()),
      ChangeNotifierProvider(create: (_) => sl<HistoryNotifier>()),
      ChangeNotifierProvider(create: (_) => sl<SavedFoodsProvider>()),
    ],
    child: const _GutGoodShell(),
  );
}
```

The rest of the file contains the unchanged `MaterialApp.router`, offline banner, verification overlay, focus dismissal, orientation behavior, and connectivity lifecycle hooks.

### E.3 Explicit notifier callback dependencies

`ChatComposerNotifier` and `ScannerNotifier` no longer resolve `ProfileNotifier` from the service locator. Their constructors accept optional callbacks, and the app DI registry wires the existing behavior:

```dart
onTurnCompleted: () => sl<ProfileNotifier>().triggerPendingCelebration(),

onScanCompleted: () => sl<ProfileNotifier>().triggerPendingCelebration(),
```

The callback still fires at the same successful-turn/successful-scan points; only the dependency acquisition changed.

### E.4 Explicit profile/usage dependencies

`ProfileNotifier` now receives `FirebaseAuth` and `SharedPreferences` through its constructor. `UsageNotifier` receives `AppStateService` and owns/cancels its auth subscription. This makes the objects replaceable in unit tests without changing persistence keys or Firestore behavior.

### E.5 Lifecycle-safe subscriptions

The following subscriptions are retained and cancelled in `dispose`:

- `ChatHistoryNotifier._authSub`
- `HistoryNotifier._authSub`
- `ProfileNotifier._authSub`
- `UsageNotifier._authSub`

The existing stream callbacks and reset behavior are unchanged.

### E.6 Notification navigation port

`NotificationServiceImpl` no longer imports the app navigator. It depends on the small core `NotificationNavigationPort`, while `AppNotificationNavigation` adapts the existing `AppNavigator` and is supplied by `AppBootstrap` during DI initialization:

```dart
await init(notificationNavigation: const AppNotificationNavigation());
```

Notification payloads still map to the same existing route constants; only the dependency direction changed.

### E.7 Route ownership removed from models

`ScanResult` no longer imports `AppRoutes` or exposes `detailRoute`. `HistorySection` explicitly pushes `AppRoutes.scanResult`, which keeps navigation decisions in presentation code and leaves the model serializable without router knowledge.

### E.8 Deterministic scanner scoring policy

`ScannerRepositoryImpl` now delegates score calculation and sensitivity re-flagging to `ScannerScoreService`. The service has no Firebase, network, Flutter, or storage dependency; production DI registers it explicitly, while the optional constructor seam keeps existing repository test fixtures source-compatible. The repository still owns AI, Open Food Facts, analytics, cache, persistence, and notification orchestration.

```dart
final updatedScan = _scoreService.applyEngineScore(
  scan,
  nutriscore: product.nutriscore,
  additiveItems: mergedAdditives,
  onDiagnostic: AppLogger.ai,
);
```

The original score inputs, high-risk cap, no-data fallback, explanation preservation, sensitivity union semantics, and diagnostic messages are unchanged.

### E.9 Chat safety policy

`ChatComposerNotifier` now delegates the existing disclaimer rule to `ChatSafetyGuardrails`. The extracted service contains only deterministic string policy, has no Flutter or external-service dependency, and is covered by focused unit tests. All three existing stream-finalization/error paths continue to call the same policy.

### E.10 Chat prompt context policy

Pinned entity extraction and grounded swap prompt formatting now live in `ChatPromptContext`. The notifier still invokes them at the same context-window and "see more swaps" points; output strings and caps remain unchanged.

### E.11 Structured Scanner failures

`core/errors/app_failure.dart` defines SDK-neutral `FailureType` categories and `AppFailure`. `ScannerNotifier` records a structured failure and stack trace for barcode, AI-analysis, and image-processing failures while retaining `lastErrorWasOffline`, existing logs, `null` results, and existing UI messages.

---

## F. Before vs after

### F.1 Application startup

**Before**

```text
main.dart
├── Firebase initialization
├── Crashlytics handlers
├── DI initialization
├── device warmup
├── orientation
├── provider list
├── lifecycle observer
└── MaterialApp.router
```

**After**

```text
main.dart
├── AppBootstrap.initialize()
└── GutGoodApp
    ├── MultiProvider
    └── _GutGoodShell
        └── MaterialApp.router
```

**Benefit:** one responsibility per composition surface. Startup ordering remains explicit and behavior-equivalent.

### F.2 Feature ownership

**Before**

```text
core/widgets/widgets.dart
├── core widgets
├── Insights ArcPatternCard
├── Insights GutScoreCard
└── Auth paywall
```

**After**

```text
core/widgets/widgets.dart
└── core-only reusable widgets

features/insights/presentation/widgets/gut_score_card.dart
features/auth/presentation/pages/paywall_screen.dart
features/auth/presentation/utils/quota_guard.dart
```

**Benefit:** imports communicate ownership, and core no longer exports feature presentation transitively.

### F.3 Data model navigation

**Before**

```text
ScanResult
└── imports AppRoutes
    └── returns the scan-result route
```

**After**

```text
HistorySection
└── AppRoutes.scanResult
    └── ScanResult extra
```

**Benefit:** domain/data-shaped models do not know about UI navigation.

### F.4 Hidden dependencies

**Before**

```text
ScannerNotifier / ChatComposerNotifier
└── sl<ProfileNotifier>()
```

**After**

```text
App DI registration
└── onScanCompleted / onTurnCompleted callback
    └── ProfileNotifier.triggerPendingCelebration()
```

**Benefit:** test doubles can supply a callback; the notifier no longer imports or resolves a sibling presentation object.

### F.5 Shared theme ownership

**Before**

```text
app/theme/app_theme.dart
└── imports shared semantic/bento theme extensions from core/theme
       ↑ Product Details also imports the Insights presentation path for
         BentoTone, BentoPalette, BentoMetrics, and theme extensions
```

**After**

```text
core/theme/
├── insight_bento_theme.dart   # theme extension, palette, tone, metrics
└── insight_theme.dart      # semantic Insights theme extension

app/theme/app_theme.dart ─── registers core theme extensions
Insights/Product Details/History ─── consume core theme APIs
```

**Benefit:** theme composition no longer depends on a feature presentation path, and shared metrics have one owner without moving feature-specific cards or changing rendered values.

### F.6 Notification navigation boundary

**Before**

```text
former shared notification service
└── imports the concrete app/router navigator
```

**After**

```text
lib/infrastructure/firebase/notification_service.dart
└── NotificationNavigationPort
        ↑
app/bootstrap.dart
└── AppNotificationNavigation → AppNavigator → GoRouter
```

**Benefit:** core notification behavior is testable with a fake navigation port and no longer depends directly on the app/router implementation. Payload mapping and route behavior remain unchanged.

### F.7 Scanner scoring policy

**Before**

```text
ScannerRepositoryImpl
├── Open Food Facts
├── AI/classification
├── score calculation
├── sensitivity matching
├── persistence
└── notifications
```

**After**

```text
ScannerRepositoryImpl
├── Open Food Facts / AI orchestration
├── ScannerScoreService
│   ├── deterministic score policy
│   └── sensitivity re-flagging
├── persistence
└── notifications
```

**Benefit:** deterministic business policy is independently testable and the repository's remaining external-workflow responsibilities are explicit. No scan output or persistence behavior was changed.

### F.8 Chat safety policy

**Before**

```text
ChatComposerNotifier
└── stream handling + persistence + safety disclaimer policy
```

**After**

```text
ChatComposerNotifier
└── ChatSafetyGuardrails.apply(response)
        └── deterministic, unit-testable disclaimer policy
```

**Benefit:** response safety remains enforced at every existing call site while the policy is no longer embedded in a 1,200-line presentation controller.

### F.9 Chat prompt context policy

**Before**

```text
ChatComposerNotifier
├── context-window selection
├── pinned-entity formatting
└── grounded swap prompt formatting
```

**After**

```text
ChatComposerNotifier
└── ChatPromptContext
    ├── buildPinnedEntities
    └── swapsGroundingFragment
```

**Benefit:** prompt-context rules can be tested without constructing the notifier or its Firebase/storage dependencies, while the generated prompt fragments remain unchanged.

### F.10 Structured Scanner failures

**Before**

```text
ScannerNotifier catch
├── raw exception
├── boolean offline flag
└── null result
```

**After**

```text
ScannerNotifier catch
├── AppFailure(FailureType, cause, stack trace)
├── existing offline flag derived from the same classifier
└── unchanged null result and UI copy
```

**Benefit:** diagnostics are categorizable and testable without exposing Firebase/Dio types to the failure value or changing the existing presentation contract.

---

## G. Reusable components

### Already valid core components

These are genuinely cross-feature and should remain in `core/widgets`:

- `GutButton`, `GutTextField`, `GutChip`, `GutSection`, `GutAppBar`
- `EmptyStateWidget`, `ShimmerGridLoader`, `OfflineBanner`
- `GutBottomSheet`, `FooterActionButton`, `SelectionWrap`
- `ScanResultInlineCard` where its input remains feature-neutral
- `StreakCelebrationOverlay`, `PremiumBadge`, and generic tile/card primitives

### Feature-owned components

These should stay feature-local rather than become core abstractions:

- bento/v2 cards, grids, and other feature presentation widgets (their shared theme extensions/metrics now live in `core/theme` because Product Details and History consume them);
- `GutScoreCard` and pattern styling;
- scanner overlays, scan detail sections, and summary sheets;
- Chat bubbles, composer controls, attachment previews, and thinking indicators;
- paywall, auth option sheets, and quota UX;
- product-detail additive and scan-specific cards.

### Future extraction candidates

Only extract these after confirming repeated behavior in at least two features:

- a shared async state view model for loading/error/empty/success;
- a typed `Failure`/`Result` boundary;
- image-upload policy shared by Chat and Scanner;
- date/time and nutrition formatters that are currently duplicated.

Do not create a generic `Manager`, `Helper`, or `CommonService` solely to reduce file count.

---

## H. Testing strategy

The repository currently has 50 Dart test files and approximately 6,128 test lines. Existing coverage is strongest around model contracts, AI parsing, scoring, outbox behavior, repositories, and use cases; this pass adds focused coverage for safety disclaimers and structured failure categories.

### Unit tests

Prioritize:

- `AppFailure` classification and Scanner failure state;
- `ChatPromptContext`, `ChatSafetyGuardrails`, `SendMessageStreamUseCase`, `ProcessChatTagUseCase`, `PersistAiResponseUseCase`;
- `GenerateInsightUseCase`, `BuildUnifiedJournalUseCase`, `CheckInsightThresholdUseCase`;
- `ScannerScoreService` deterministic score, no-data fallback, explanation preservation, and sensitivity re-flagging;
- `ScannerRepositoryImpl` cache hit/stale/miss and persistence gating;
- model mappers and legacy Firestore map compatibility;
- `AuthRepositoryImpl` merge/error mapping;
- new callback-based notifier seams and subscription disposal;
- validators, barcode normalization, date/time, and `Failure` mapping once introduced.

### Widget tests

Add focused tests for:

- Chat loading, streaming, queued/offline, quota, and error states;
- Scanner barcode/vision loading, not-found, offline, and result states;
- Insights empty/insufficient/loading/error/success states;
- Profile onboarding, auth merge conflict, and paywall states;
- global offline and verification overlays.

### Integration tests

Run against Firebase emulators where possible:

1. anonymous sign-in → onboarding → chat;
2. anonymous account upgrade and merge conflict resolution;
3. chat streaming → passive meal/symptom persistence;
4. barcode scan → Open Food Facts → AI analysis → history;
5. vision scan → scan result → detail route;
6. insight threshold → generation → dashboard stream;
7. logout/login account switching and stream cleanup;
8. notification tap routing.

### Validation commands for a configured developer/CI environment

```bash
flutter pub get
flutter analyze
flutter test
cd functions && npm ci && npm run build
```

For the Firebase-dependent integration suite, start the configured emulators and run the critical-flow tests separately. Do not commit `firebase_options.dart`; provide it through the existing FlutterFire setup/CI secret workflow.

---

## I. Prioritized follow-up plan

### P0 — Critical

- No new P0 behavior or security regression was introduced by this refactor.
- Keep server-authoritative quota, auth merge, scan persistence, and AI proxy contracts unchanged.

### P1 — High value

1. Continue extracting Chat composer library-part workflows into cohesive application services/use cases; the files are now separated by responsibility, while stream protocol and outbox semantics still share the notifier state boundary.
2. Continue splitting `ScannerRepositoryImpl` into barcode lookup, vision analysis, and persistence policies behind the existing `ScannerRepository` contract; deterministic scoring is now isolated in `ScannerScoreService`.
3. Move Firestore implementations into feature `data/datasources` with compatibility adapters.
4. Continue applying the SDK-neutral `AppFailure` taxonomy at repository/use-case boundaries and map categories to current UI messages; Scanner operation state is the first migrated boundary.
5. Migrate Chat/Scanner/Insights models from `core/models` into feature entities and DTOs one contract at a time.
6. Run analyzer and all tests in CI with generated Firebase options/emulator configuration.

### P2 — Maintainability/performance

1. Keep dependency registration orchestration under `app/di`; future work is to reduce remaining direct service-locator reads in presentation/core consumers through explicit composition-root injection where it can be done without changing lifecycle behavior.
2. Measure and reduce broad rebuilds in Chat, Insights v2, and History with `Selector`/smaller state projections.
3. Add telemetry for corrupt cache fallback and classify network/auth/permission errors.
4. Resolve the duplicate `BentoCard` APIs only after an API-by-API visual comparison; prefer explicit names over a risky shared rewrite.
5. Update the remaining documentation and deployment checks to the actual persistence implementation.

### P3 — Nice to have

- Add feature barrel files only where they reduce import noise without hiding ownership.
- Add generated DTOs only if the external schemas stabilize; do not add code generation for current simple maps prematurely.
- Consolidate duplicated presentation constants after the Insights design systems stop evolving.

---

## Final behavior-preservation statement

No product feature, route path, Firestore collection, Firebase function, prompt, scoring rule, API payload, storage key, provider ordering, loading/error copy, or user flow was intentionally changed. The implemented changes move ownership, make dependencies explicit, introduce an app-supplied notification navigation port, and close subscription-lifecycle gaps while retaining the original runtime actions.
