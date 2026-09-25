**Application cleanup review — 2026-09-24**

Reviewed the local Flutter app, native platform configuration, assets, TypeScript Firebase backend, Hosting, Firestore/Storage rules, indexes, dependency manifests, tests, and historical architecture decisions. The initial app inventory contained 287 Dart files; import/export traversal from lib/main.dart found 10 unreachable files before cleanup. Reference searches included tests and documented decisions; member-name counts were treated as candidates, not proof of dead code.

Existing staged feature work was preserved. All cleanup edits are unstaged. No account data, deployed functions, hosted files, Remote Config, or cloud secrets were changed. This is a static cleanup review plus local validation, not production traffic verification or a full security certification.

**Preliminary safety classification**

| Category | Evidence and action |
|---|---|
| Confirmed dead code | Four unimported utility/prompt files; three uncalled history-total methods superseded by watchHistoryCounts; two unused packages. Removed. |
| Redundant diagnostics | Widget-build RECENT LOGS data dump. Removed; actionable error logging retained. |
| WIP / reserved / uncertain | Insights UI variants, empty interaction handlers, explicitly reserved score helper, new gut-score service methods, feature toggle action, developer fixtures and design tokens. Retained. |
| Configuration / infrastructure | Retired report rule and stale server-insights comment cleaned locally. All exported functions, active secrets/flags, migration code, platform boilerplate and indexes retained. |

No TODO/FIXME match alone was used to justify deletion. Explicit reservations, interface overrides, DI registrations, routes, migration compatibility, test seams and design work were considered separately.

**Frontend findings and retained work**

The six remaining files outside the main import graph are below. Unreachability is confirmed; permanent obsolescence is not. Treat these as integration/design decisions, not approved deletions.

| File | Recommendation |
|---|---|
| lib/features/insights/presentation/pages/action_detail_screen.dart | Retain pending a decision about the action-detail flow and route integration. |
| lib/features/insights/presentation/pages/evidence_methodology_screen.dart | Retain the evidence/methodology view until its intended entry point is settled. |
| lib/features/insights/presentation/pages/all_pattern_occurrences_screen.dart | Retain the disconnected occurrence-browser flow; it references MealSymptomDetailScreen. |
| lib/features/insights/presentation/pages/meal_symptom_detail_screen.dart | Retain with its occurrence-browser consumer; these form an unreachable subgraph rather than independent dead classes. |
| lib/features/insights/presentation/widgets/active_experiment_card.dart | Retain: experiments have active models, persistence and seeded data. Decide where the card belongs in the evolving feed. |
| lib/features/insights/presentation/widgets/insight_history_tile.dart | Retain both history variants pending design consolidation. insights_history_screen.dart currently renders its private _InsightHistoryTile; this file also contains a gallery-redesign InsightHistoryCard. |

Additional members with no direct app/test call sites were retained for development context:

- lib/features/insights/presentation/pages/gut_score_detail_screen.dart: _bandLabel explicitly says it is reserved for a score-band overlay.
- lib/core/services/firestore/gut_score_firestore_service.dart: getLatestGutScore and getWeeklyScores belong to the newly staged score feature.
- lib/features/insights/domain/usecases/generate_insight_usecase.dart: suppressed unused _historyFirestoreService injection; retained during the staged score refactor. Remove the constructor/DI/test plumbing together if the final design does not need it.
- lib/features/profile/presentation/providers/profile_provider.dart: updateInsightsDisabled supports a feature flag that the insight generator still honors. Wire the settings control or document its planned activation.
- lib/features/product_details/presentation/utils/scan_result_utils.dart: logSwapToJournal may support the unfinished swap action; retained.
- lib/features/insights/presentation/widgets/v2/v2_data.dart: trendWord, confidenceWord and patternPillSub are unused presentation helpers in the active redesign. Consolidate after the UI settles.
- lib/core/constants/app_sizes.dart: icon28 is an unused design token; retaining a standard size is reasonable development boilerplate.
- lib/core/services/debug_mock_data_service.dart: generateInsufficientDataState is an unused developer fixture, retained intentionally.

Empty handlers remain in insight_bento_screens.dart (Apply this swap) and v2_feed.dart (hero tap and next-step cards). These are unfinished interactions, not dead code. Framework callbacks such as shouldRepaint/shouldReclip and Open Food Facts Parameter.getName/getValue must remain even when local textual call counts are zero.

All five remaining image assets and the streak animation have live AppAssets consumers. InterTight's six font files are declared in pubspec.yaml and its family is used by both Insights theme systems. Retain assets/fonts/OFL.txt as the font license. The user's already-staged image removals were not expanded. Native app icons, platform registrations, Hosting association files and standalone HTML design references are not disposable merely because Dart does not import them. No separate production CSS framework was found to uninstall.

All remaining runtime packages have Dart imports. mocktail/flutter_test serve tests; flutter_lints is analyzer configuration. No unused-import/local-variable diagnostics were reported. Broad formatting changes to the staged Insights implementation were deliberately avoided.

**Backend findings**

The backend is Firebase Functions; no separate REST router, GraphQL service or socket server was found. All 13 exports in functions/src/index.ts have a local invocation or platform trigger:

| Function(s) | Consumer / trigger |
|---|---|
| aiProxy | AiService HTTP requests using RemoteConfigService.aiProxyUrl. |
| sendCustomMagicLink | AuthRepositoryImpl callable before login. |
| mergeAnonymousAccount | AuthRepositoryImpl guest-to-permanent account merge. |
| deleteAccount | AuthRepositoryImpl account deletion callable. |
| onProfileWritten | Firestore user_profiles writes; welcome-email lifecycle. |
| onUserDeleted | Firebase Auth deletion; cascade cleanup backstop. |
| cleanupAnonymousUsers | Daily scheduled abandoned-account cleanup. |
| onScanCreated, onScanDeleted | scan_history create/delete; counters and scan warnings. |
| onJournalEntryCreated, onJournalEntryDeleted | journal_logs create/delete; streak/counter maintenance. |
| onInsightCreated | insights create; profile gut-score propagation. |
| generateFoodThumb | Storage finalize on canonical food-image objects. |
| sweepUnlinkedFoodImages | Daily scheduled registry/object cleanup. |

All 12 TypeScript source modules participate in the exported function graph. No orphaned backend model, utility module or exported helper was proven removable. firebase-admin, firebase-functions, nodemailer and sharp are all used. typescript and the Node/nodemailer typings support compilation. No npm uninstall is warranted.

Preserve merge.ts's meal_logs, symptom_logs, label_scans and restaurant_menu_scans migrations, and the saved-food fallback in HistoryFirestoreService. Legacy stored records can still require them even though new clients use consolidated collections. Architecture/security decisions recorded in docs/ACCEPTED_RISKS.md were not silently changed by this cleanup.

**Firebase infrastructure findings**

All remaining rule paths correspond to app/server data: user_profiles, chat_history, scan_history, journal_logs, food_images, saved_foods, insights, gut_scores, experiments, daily_usage, pattern_data, counters, health_alerts and merges. Storage users/{uid}/... remains necessary for profile and food uploads. No Realtime Database configuration was found.

| Index | Decision |
|---|---|
| journal_logs: type ASC, createdAt DESC | Keep: filtered meal/symptom timelines. |
| journal_logs: type ASC, createdAt ASC | Keep: count-since range queries; absence of explicit orderBy alone does not prove redundancy. |
| scan_history: source ASC, createdAt DESC | Keep: label/menu history. |
| scan_history: barcode ASC, createdAt DESC | Keep: latest barcode scan cache. |
| scan_history: barcode ASC, isSaved ASC | Keep: legacy saved-food checks/removal. |
| gut_scores: type ASC, createdAt DESC | Keep: new daily/weekly score queries and staged feature work. |
| scan_history: isSaved ASC, createdAt DESC | Candidate only: current getSavedFoods fallback filters isSaved but does not order server-side. Retained until older client queries and deployed index usage are checked. |

The food-image sweeper uses collectionGroup('food_images').where('linkCount', '==', 0); check its deployed collection-group index configuration during infrastructure validation. The local fieldOverrides array is empty, and this review did not run that query against an emulator or deployment. Do not infer that an index is unnecessary merely because it is not queried directly by Flutter.

All three local Remote Config keys are active: openai_model, ai_proxy_url and is_force_update. All six declared function secrets are consumed: OPENAI_API_KEY and SMTP_HOST/PORT/USER/PASS/FROM. No project .env file was found outside ignored dependency/build directories; no secret values were read or reproduced.

The historical audit records retirement of generateInsights, requestInsightRefresh, revenuecatWebhook and insights_client_generation_enabled. They are absent from the current source surface; inspect deployed inventories before removing any lingering cloud resources or REVENUECAT_WEBHOOK_SECRET. Deployed invocation counts, external consumers, old mobile clients, console-created indexes and Remote Config templates were not inspected.

firebase.json's Firestore, Storage, Functions build hook and Hosting configuration remain active. public/.well-known/apple-app-site-association and assetlinks.json support native link handling. Generated Firebase/native plugin setup and essential platform boilerplate were retained.

**File updates — exact diffs against the starting working tree**

These diffs exclude the user's pre-existing staged changes. For deleted files, the full removed content is shown; there is no replacement.

**File Path:** `pubspec.yaml`  
**Status:** [Remove Dependencies]  
**Reason:** Removed cupertino_icons and logger. Neither package is imported by application or tests. Icons use Material/Lucide; AppLogger uses dart:developer and Crashlytics, not package:logger.

**Cleaned Code Solution:**

```diff
--- a/pubspec.yaml
+++ b/pubspec.yaml
@@ -15,7 +15,6 @@
     sdk: flutter
 
   # UI & Design System
-  cupertino_icons: ^1.0.9
   flutter_animate: ^4.5.2
   lucide_icons_flutter: ^3.1.17
   shimmer: 3.0.0
@@ -80,7 +79,6 @@
   in_app_review: ^2.0.12
   upgrader: ^13.7.0
   uuid: ^4.6.0
-  logger: ^2.7.0
   rxdart: ^0.28.0
   smooth_page_indicator: ^3.0.0
 
```

**File Path:** `pubspec.lock`  
**Status:** [Remove Dependencies]  
**Reason:** Offline dependency resolution removed only cupertino_icons 1.0.9 and logger 2.8.0. Other resolved versions and the existing staged lockfile changes are preserved.

**Cleaned Code Solution:**

```diff
--- a/pubspec.lock
+++ b/pubspec.lock
@@ -201,14 +201,6 @@
       url: "https://pub.dev"
     source: hosted
     version: "1.0.2"
-  cupertino_icons:
-    dependency: "direct main"
-    description:
-      name: cupertino_icons
-      sha256: "41e005c33bd814be4d3096aff55b1908d419fde52ca656c8c47719ec745873cd"
-      url: "https://pub.dev"
-    source: hosted
-    version: "1.0.9"
   dbus:
     dependency: transitive
     description:
@@ -896,14 +888,6 @@
       url: "https://pub.dev"
     source: hosted
     version: "6.1.0"
-  logger:
-    dependency: "direct main"
-    description:
-      name: logger
-      sha256: "2a0dc097e7b01d942475bdd552356db2d0f768b05540bd4b2b53f1840f2239a7"
-      url: "https://pub.dev"
-    source: hosted
-    version: "2.8.0"
   logging:
     dependency: transitive
     description:
```

**File Path:** `lib/core/widgets/super_card.dart`  
**Status:** [Refactor Code]  
**Reason:** Removed the RECENT LOGS debug dump on every build, including food names and image URLs. It contributes no UI state or behavior. currentFood remains because rendering uses it; scanner error diagnostics remain.

**Cleaned Code Solution:**

```diff
--- a/lib/core/widgets/super_card.dart
+++ b/lib/core/widgets/super_card.dart
@@ -191,20 +191,6 @@
     final hasFoods = totalPages > 0;
 
     final currentFood = hasFoods ? widget.foods[_currentIndex] : null;
-
-    if (widget.title.toUpperCase() == 'RECENT LOGS') {
-      debugPrint('--- SuperFoodGaugeCard: RECENT LOGS DEBUG ---');
-      debugPrint('Title: ${widget.title}');
-      debugPrint('Total Pages: $totalPages');
-
-      if (currentFood != null) {
-        debugPrint('Current Food Name: ${currentFood.name}');
-        debugPrint('Current Food Image URL: ${currentFood.imageUrl}');
-        debugPrint('Dynamic Image URL: ${getDynamicImageUrl(currentFood.name)}');
-      }
-
-      debugPrint('----------------------------------------------');
-    }
 
     return GestureDetector(
       onTap: widget.onTap,
```

**File Path:** `lib/core/extensions/date_time_extensions.dart`  
**Status:** [Delete File]  
**Reason:** DateTimeFormattingX has no imports or consumers. Existing DateUtils.isSameDay calls use Flutter, not this extension. No TODO, reservation, or feature dependency was found.

**Cleaned Code Solution:**

```diff
--- a/lib/core/extensions/date_time_extensions.dart
+++ /dev/null
@@ -1,5 +0,0 @@
-/// Extension on [DateTime] providing relative day formatting and date helpers.
-extension DateTimeFormattingX on DateTime {
-  /// Returns true if two DateTime objects fall on the exact same calendar day.
-  bool isSameDay(DateTime other) => year == other.year && month == other.month && day == other.day;
-}
```

**File Path:** `lib/core/services/firestore/firestore_runner.dart`  
**Status:** [Delete File]  
**Reason:** runFirestoreOperation has no imports or callers. Live services handle errors with AppLogger directly; deleting this unadopted wrapper does not remove their error handling.

**Cleaned Code Solution:**

```diff
--- a/lib/core/services/firestore/firestore_runner.dart
+++ /dev/null
@@ -1,14 +0,0 @@
-import 'package:gutgood/core/utils/logger_service.dart';
-
-/// Centralized runner for Firestore operations that standardizes error logging.
-Future<T> runFirestoreOperation<T>({
-  required String operationName,
-  required Future<T> Function() action,
-}) async {
-  try {
-    return await action();
-  } catch (e, stack) {
-    AppLogger.firestore('Firestore operation failed [$operationName]', error: e, stackTrace: stack);
-    rethrow;
-  }
-}
```

**File Path:** `lib/core/services/prompts/mode_prompts/structured_tag_prompt.dart`  
**Status:** [Delete File]  
**Reason:** StructuredTagPrompt is neither imported nor selected by the active prompt pipeline. Live prompts reference SchemaDefinitions and their own formatting rules directly. No prompt output changes.

**Cleaned Code Solution:**

```diff
--- a/lib/core/services/prompts/mode_prompts/structured_tag_prompt.dart
+++ /dev/null
@@ -1,22 +0,0 @@
-import 'package:gutgood/core/services/prompts/schema_definitions.dart';
-
-class StructuredTagPrompt {
-  StructuredTagPrompt._();
-
-  static String get instruction =>
-      '''
-STRUCTURED DATA ENFORCEMENT
-
-Your response MUST conclude with exactly ONE [GUTGOOD_DATA] block that captures all domain events and intent from this turn.
-
-${SchemaDefinitions.unifiedDataSchema}
-
-STRICT JSON RULES:
-- VALIDITY: JSON must be syntactically perfect.
-- POSITION: The block MUST be at the very end of your response.
-- ALIGNMENT: The data in the JSON must match your conversational claims.
-- DATES: Use ISO 8601 for all `time` fields.
-- CATEGORIES: Follow the schema types exactly as defined.
-${SchemaDefinitions.typeRules}
-''';
-}
```

**File Path:** `lib/core/services/prompts/mode_prompts/default_objective_prompt.dart`  
**Status:** [Delete File]  
**Reason:** DefaultObjectivePrompt is never imported or selected by intent routing. Active intent prompts and GeneralRulesPrompt provide the current behavior; this file has no WIP markers.

**Cleaned Code Solution:**

```diff
--- a/lib/core/services/prompts/mode_prompts/default_objective_prompt.dart
+++ /dev/null
@@ -1,11 +0,0 @@
-class DefaultObjectivePrompt {
-  DefaultObjectivePrompt._();
-
-  static const String instruction = '''
-CORE OBJECTIVE
-Transform food logging and food questions into useful food intelligence.
-Answer the user's specific question directly and conversationally.
-Be helpful but stay focused on the user's question.
-If a specific food or meal was discussed, you MUST include the [GUTGOOD_DATA] block at the very end of your response.
-''';
-}
```

**File Path:** `firestore.rules`  
**Status:** [Refactor Code]  
**Reason:** Removed isValidAiReport and the /ai_reports create grant. There are no local report producers, models, or handlers, and docs/AI_AUDIT_AND_REFACTOR_PLAN.md explicitly records retirement of the entire report flow on 2026-09-09. Existing reports are not deleted; the default-deny rule covers this path. Also corrected the obsolete scheduled-generateInsights comment. This is a local change, not a deployment; older external clients were not inspected.

**Cleaned Code Solution:**

```diff
--- a/firestore.rules
+++ b/firestore.rules
@@ -44,11 +44,9 @@
     /**
      * Validates a single deterministic "body pattern" entry (see
      * BodyPattern.toMap() in the Dart client). These are written by the
-     * scheduled generateInsights function (C-4; the on-device
-     * PatternEngineService remains as a fallback writer) and, unlike most
-     * user data, are later read back by the server-side (and AI) insight
-     * generation pipeline as trusted evidence for health narratives — so a
-     * garbage/malformed entry here can silently corrupt an AI insight.
+     * on-device PatternEngineService through savePatternData and read back
+     * by the client insight generation pipeline as evidence for health
+     * narratives — so a malformed entry can silently corrupt an AI insight.
      * Firestore rules can't iterate
      * a list generically, so we spot-check the first and last entries (any
      * single malformed write is still bounded by the 512KB doc size cap).
@@ -92,26 +90,6 @@
         && request.resource.size() < 512 * 1024; // Strict 512KB cap
     }
 
-
-    /**
-     * Validates a user-submitted AI response report.
-     *
-     * The allowed `reason` values must stay in sync with
-     * AiReport.allowedReasons in Dart — a test asserts this, because a mismatch
-     * would make every report fail silently in production.
-     */
-    function isValidAiReport(uid) {
-      let data = request.resource.data;
-      return data.keys().hasOnly(['reason', 'messageExcerpt', 'details', 'messageId', 'reportedBy', 'createdAt'])
-        && data.get('reportedBy', '') == uid
-        && data.get('reason', '') in ['inaccurate', 'unsafe', 'offensive', 'off_topic', 'other']
-        && data.get('details', '') is string
-        && data.get('details', '').size() <= 1000
-        && data.get('messageExcerpt', '') is string
-        && data.get('messageExcerpt', '').size() <= 2000
-        && data.get('createdAt', request.time) is timestamp;
-    }
-
     // --- COLLECTION RULES ---
 
     match /user_profiles/{userId} {
@@ -236,25 +214,6 @@
       }
     }
 
-    /**
-     * AI response reports — required by Google Play's generative-AI policy
-     * ("in-app user reporting or flagging ... without needing to exit the app").
-     *
-     * Create-only and owner-stamped: users must never be able to read, edit or
-     * delete a report, not even their own. Moderation reads these via the Admin
-     * SDK / console.
-     *
-     * Deliberately top-level rather than a user_profiles subcollection so
-     * reports survive account deletion and can be reviewed as one queue.
-     */
-    match /ai_reports/{reportId} {
-      allow create: if request.auth != null
-        && isValidAiReport(request.auth.uid)
-        && request.resource.size() < 64 * 1024;
-
-      allow read, update, delete: if false;
-    }
-
     // --- DEFAULT DENY ---
 
     /** Explicitly deny any access not covered by the authenticated owner rules above. */
```

**File Path:** `lib/core/services/firestore/history_firestore_service.dart`  
**Status:** [Refactor Code]  
**Reason:** Removed getTotalScansCount, getTotalMealLogsCount, and getTotalSymptomsCount from both interface and implementation. Each appeared only in its declaration and definition, with no app/test callers. watchHistoryCounts supplies active totals and retains its aggregation fallback; count-since methods remain.

**Cleaned Code Solution:**

```diff
--- a/lib/core/services/firestore/history_firestore_service.dart
+++ b/lib/core/services/firestore/history_firestore_service.dart
@@ -48,10 +48,6 @@
 
   /// Count of scan history records with `createdAt >= [since]`.
   Future<int> getScansCountSince(DateTime since);
-
-  Future<int> getTotalScansCount();
-  Future<int> getTotalMealLogsCount();
-  Future<int> getTotalSymptomsCount();
 
   /// Reactive history totals, read from the server-maintained
   /// `counters/totals` document (single-doc read). Falls back to cheap
@@ -529,27 +525,6 @@
     final doc = _userDoc;
     if (doc == null) return -1;
     return _countQuery(doc.collection('scan_history').where('createdAt', isGreaterThanOrEqualTo: DateTimeUtils.toTimestamp(since)), 'scans-since', onError: -1);
-  }
-
-  @override
-  Future<int> getTotalScansCount() async {
-    final doc = _userDoc;
-    if (doc == null) return 0;
-    return _countQuery(doc.collection('scan_history'), 'scans-total');
-  }
-
-  @override
-  Future<int> getTotalMealLogsCount() async {
-    final doc = _userDoc;
-    if (doc == null) return 0;
-    return _countQuery(doc.collection('journal_logs').where('type', isEqualTo: 'meal'), 'meals-total');
-  }
-
-  @override
-  Future<int> getTotalSymptomsCount() async {
-    final doc = _userDoc;
-    if (doc == null) return 0;
-    return _countQuery(doc.collection('journal_logs').where('type', isEqualTo: 'symptom'), 'symptoms-total');
   }
 
   @override
```

**Validation**

- `flutter pub get --offline`: passed; exactly two dependencies removed, no upgrades.
- `functions/node_modules/.bin/tsc --project functions/tsconfig.json --noEmit`: passed with strict/noUnusedLocals enabled.
- `flutter analyze`: 19 existing info-level style diagnostics before and after the final cleanup, no errors/warnings or added diagnostics. The command exits 1 because infos are fatal under its defaults.
- `flutter test --no-pub --reporter expanded`: final source produced **314 passing / 12 failing** tests. An isolated copy restoring the pre-cleanup source produced **314 passing / the identical 12 failing tests**. No new failures from cleanup were observed. The baseline retained the user's staged WIP, rather than reverting to HEAD.
- `git diff --check`: passed.
- Firebase rules emulator/deployment validation was not run: no emulator installation was present in the usual local cache. No production deployment or cloud invocation/index-usage audit was performed.

Existing failures, reproduced before cleanup:

- `test/core/services/off_cache_test.dart: getProduct session memo (P0-3) repeat lookup of the same barcode hits the fetch once`
- `test/features/chat/process_chat_tag_usecase_test.dart: ProcessChatTagUseCase J-4 stamps promptVersion/servedModel onto every extracted record`
- `test/features/insights/arc_pattern_card_test.dart: ArcPatternCard Widget Tests renders PatternCarouselWidget with page indicator`
- `test/features/insights/arc_pattern_card_test.dart: ArcPatternCard Widget Tests renders pattern title, percentage and confidence pill`
- `test/features/insights/bento_insights_test.dart: Screen 01 — bento feed renders the score hero and every bento section`
- `test/features/insights/bento_insights_test.dart: Screen 03 — weekly recap draws the sparkline from real history`
- `test/features/insights/bento_insights_test.dart: Screen 05 — pattern anatomy renders the tick fan with real episode counts`
- `test/features/insights/bento_insights_test.dart: Screen 06 — trigger synergy ranks drivers and shows the rescue protocol`
- `test/features/insights/bento_insights_test.dart: Screen 07 — food intelligence counts boosters vs watch items from real food impacts`
- `test/features/scanner/barcode_cache_test.dart: getCachedBarcodeScan (P0-3) fresh hit re-runs the engine exactly (never passes the stored score through)`
- `test/features/scanner/scanner_repository_test.dart: ScannerRepository saveScanResult saves to Firestore and notifies UI`
- `test/widget_test.dart: ChatMessage persistence dedup (rawData) toMap() strips analysisResult.scan.rawData to avoid triple-storing the same scan data`

Review follow-up: off_cache_test seeds a 12-digit raw key while getProduct normalizes it to a leading-zero EAN-13 key, explaining that fixture mismatch. Review the Insights assertions against the staged redesign, and separately reconcile persistence/version metadata, cached scoring, and scanner notification expectations. These failures were documented rather than rewriting active feature behavior to make the cleanup appear green.


**Cleanup Checklist**

- [x] `pubspec.yaml` — [Remove Dependencies]
- [x] `pubspec.lock` — [Remove Dependencies]
- [x] `lib/core/widgets/super_card.dart` — [Refactor Code]
- [x] `lib/core/extensions/date_time_extensions.dart` — [Delete File]
- [x] `lib/core/services/firestore/firestore_runner.dart` — [Delete File]
- [x] `lib/core/services/prompts/mode_prompts/structured_tag_prompt.dart` — [Delete File]
- [x] `lib/core/services/prompts/mode_prompts/default_objective_prompt.dart` — [Delete File]
- [x] `firestore.rules` — [Refactor Code]
- [x] `lib/core/services/firestore/history_firestore_service.dart` — [Refactor Code]
- [x] `docs/CLEANUP_REVIEW_2026-09-24.md` — added this review, exact diffs and retained-candidate inventory.
- [x] Preserved WIP, feature flags, migration paths, assets/licenses and existing staged changes.
- [x] Refreshed the dependency lockfile offline; no package upgrades.
- [ ] Validate Firestore rules with emulator coverage before deploying the rule change.
- [ ] Check production/older-client usage before removing the retained index or historical cloud resources.
- [ ] Resolve the baseline test failures separately from this dead-code cleanup.

Equivalent package-removal command (already reflected in the manifest and lockfile; no need to rerun):

```sh
flutter pub remove cupertino_icons logger
```

No backend packages can be safely uninstalled based on this review. No Firebase deployment was performed.
