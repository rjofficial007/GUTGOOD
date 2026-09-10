# Known Issues & Technical Debt

This document tracks identified bugs, technical debt, and planned improvements to the GutGood codebase.

> ⚠️ **Before adding entries here:** several behaviors that *look* like bugs
> (client-writable `isPremium`, unvalidated `timezoneOffset`, deletable guest
> profile root, empty Android RevenueCat key, un-throttled magic-link endpoint,
> no App Check) are **intentional, owner-accepted decisions** — they are
> registered with blast radius and revisit triggers in
> [`ACCEPTED_RISKS.md`](ACCEPTED_RISKS.md). Do not "fix" them without reading it.

## 1. Resolved Issues
- **Scan Doc Bloat (audit P0-2):** Every scan doc persisted the entire decoded AI JSON blob (`rawData`). `saveToScanHistory` now writes `toPersistenceMap()` (blob stripped, `rawDataHash` kept); readers still hydrate legacy docs with the blob.
- **Zero Scan Caching (audit P0-3):** Every re-scan re-ran OFF + full AI analysis + new history doc. Fresh (<30d) personal scans now short-circuit: engine re-score on persisted inputs (bit-exact), sensitivity re-flagging (union, never hides), chat message + analytics only. OFF lookups also memoized per session (30-min TTL). Requires the new `(barcode, createdAt)` composite index.
- **Saved-State Flap (latent):** `isFoodSaved` filters on barcode+isSaved with no composite index, so it always failed and every re-save reset `isSaved=false`. Added the `(barcode, isSaved)` index.
- **History Counting Cost (audit P0-1):** Dashboard counts, insight-gating totals, and the profile average each downloaded whole collections (1 billed read per doc). One-shot counts now use server-side `count()` aggregations; live counts read the trigger-maintained `counters/totals` doc (single-doc read, seeded lazily — no backfill needed).
- **Classifier Vocabulary Drift (audit P1-1):** The intent-detection rules ordered non-vocabulary tokens (`meal_overview`, `menu`, `full_analysis`, lowercase `health_assessment`) that the parser silently downgraded. Rules now interpolate the `UserIntent` constants, the image classifier covers all 17 intents, the insights prompt defines its ZERO PATTERN CASE, and `prompts_test.dart` locks the vocabulary with regression tests.
- **Dead Code (audit Phase 0):** Removed zero-caller `saveLabelScan`/`saveMenuScan`, the `onSymptomCreated` trigger on the nonexistent `symptom_logs` collection, and the unimported `meal_overview_prompt.dart`.
- **Release Log Noise (audit P2-8):** The insights dashboard dumped a ~20-line `debugPrint` block on every state emission, including production builds. Replaced with a single release-gated `AppLogger` line (the OFF-service dumps were already debug-only).
- **Functions Build Break:** `ai_reports.ts` imported `getTransporter` from `email.ts`, which never exported it — `tsc` failed repo-wide, blocking every functions deploy. Fixed with the missing `export`.
- **Stale Schema Doc:** `FIRESTORE_SCHEMA.md` described `meal_logs`/`symptom_logs` collections and `time` fields that don't exist. Regenerated from `toMap` methods, services, triggers, and rules (incl. `journal_logs`, `counters`, `pattern_data`, `health_alerts`).
- **Dead Result Routes:** The result-screen consolidation removed the per-type result destinations, but five navigation sites (chat "View full report", saved foods, scan history journal, history sections, scanner summary sheet) still pushed them, landing users on the "Page Not Found" screen. Fixed by routing all scan types to the unified `/scan-result` screen, making history meal rows non-navigating (they render inline), and removing the dead route constants.
- **AI Payload 502 Errors:** Previously, large history payloads containing structured tags caused Cloud Function timeouts. This is now resolved via payload optimization (tag stripping) and history summarization.
- **AI Consistency:** Intent-specific personas are now isolated in `mode_prompts/`, significantly improving response relevance.
- **Truncated JSON:** The `ModelUtils.extractJson` "auto-repair" logic now handles cases where the LLM cuts off mid-JSON.

## 2. Technical Debt
- **Message Deduplication:** The `ChatComposerNotifier` uses `optimisticIds` but the `localId` field in Firestore is not yet strictly enforced as a unique key in security rules.
- **AI Summary Strategy:** The `summarizeHistory` function currently runs after every 6 messages. We have optimized this with tag-stripping, but further windowing could be explored.
- **Image Compression:** Current image compression in `StorageService` is synchronous. For very large images, this could cause a brief frame drop. Consider moving to an isolate.

## 2. Known Limitations
- **Offline Vision:** AI Vision (Food/Menu/Label) requires an active internet connection to communicate with OpenAI. The UI correctly identifies this, but a "queued scan" feature is not yet implemented.
- **Meal Logs Aggregation:** The "Insights" engine identifies patterns but doesn't yet support complex multi-day correlations (e.g., "Symptoms occur 48 hours after eating dairy").
- **Currency Handling:** Subscription prices are currently hardcoded in UI strings. They should be dynamically fetched from the `purchases_flutter` package.

## 3. Recommended Improvements
- **Unit Testing:** While the Clean Architecture supports it, the current project has low unit test coverage for the `domain` and `data` layers.
- **Semantic Search:** Implementing a vector-based search for "Saved Foods" would allow users to find items based on concepts (e.g., "High protein snacks") rather than just name matches.
- **Cycle Sync Refinement:** The cycle phase calculation is currently manual. Integrating with HealthConnect/Apple Health for automated cycle data would improve UX.

## 4. TODOs in Code
- [ ] `AuthRepositoryImpl`: Further refine re-authentication logic for sensitive actions (account deletion).
- [ ] `InsightFirestoreService`: Add batching support for `savePatternData` to reduce write operations.
- [ ] `AppRouter`: Refactor the `redirect` logic into a separate `Guard` class to reduce complexity.
