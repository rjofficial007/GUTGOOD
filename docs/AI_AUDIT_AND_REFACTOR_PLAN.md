# GutGood AI — Architecture Audit & Refactoring Plan

**Date:** 2026-09-08 · **Scope:** full AI pipeline (prompts → proxy → parsing → models → Firestore/Storage → UI)
**Method:** every finding below cites the actual file that proves it. No generic advice.

---

## Executive summary

GutGood's AI foundation is **better than typical**: server-side key isolation, transactional quotas
with idempotency + refunds, a deterministic scoring engine that outranks the LLM, a 0.6 confidence
gate before auto-persisting AI guesses, and an evidence-first insight pipeline (deterministic
patterns → AI explanation). **Do not rewrite this.**

The real problems are concentrated in five areas:

1. **Firestore cost bombs** — full-collection reads used as counters, in one-shot *and* realtime
   stream form, plus full AI JSON blobs persisted inside every scan doc.
2. **No result caching** — re-scanning a barcode re-pays OFF + full AI analysis; classifier
   re-sends vision bytes the analysis call also sends.
3. **Prompt-vocabulary drift** (the exact class of bug the codebase thought it fixed) — the intent
   classifier emits tokens that don't exist, silently degrading every routed turn.
4. **Image lifecycle is URL-strings-only** — no image records, no dedup, upload failure kills
   turns unnecessarily, per-message deletes orphan Storage files.
5. **Mixed prose+JSON protocol** — chat and scanner both depend on parsing `[GUTGOOD_DATA]` out
   of a Markdown stream, which is why `mode: 'plain'` + regex repair exists instead of
   guaranteed-structured output.

The plan below fixes these in dependency order (Phase 0 → 5, §M) without changing product
behavior, and migrates old data without breaking readers.

---

## A. Current architecture (as built)

### A.1 Chat turn (text ± image)

```
ChatScreen → ChatComposerNotifier.send()
  ├─ optimistic user msg + AI placeholder (localImages preview)     ✓ good UX
  ├─ parallel: classify (intent/image) + upload image + save user msg
  │    ├─ classifyTextIntent: keyword fast-path, else model call    (extra round-trip)
  │    ├─ classifyImage: full vision generateContent call           (2nd vision round-trip)
  │    └─ uploadFoodImage → Storage users/{uid}/food_images/       (failure kills turn ✗)
  ├─ _streamReply: chatSystemInstruction (~16k chars) + 25 msgs + userText (+bytes)
  │    └─ AiService.sendMessageStream → aiProxy(mode=stream) → SSE frames
  ├─ 60ms flush timer → ProcessChatTagUseCase(full text so far) → live UI
  ├─ persist AI msg every 3s during stream
  └─ _finalizeStream → parse(isFinal) → PersistAiResponseUseCase → save msg → precomputeSummary
```

Key files: `chat_composer_notifier.dart`, `ai_service.dart`, `process_chat_tag_usecase.dart`,
`persist_ai_response_usecase.dart`, `prompts.dart`, `ai_proxy.ts`.

### A.2 Barcode scan

```
SuperScanner → ScannerNotifier.processBarcode()
  ├─ OffService.getProduct(barcode) — no cache                        ✗
  ├─ uploadFoodImage (optional captured image)
  ├─ getUserMetadata (profile read) + getBetterAlternatives (OFF search)
  ├─ analyzeProductWithAi → generateContent(mode='plain')             (no json_object ✗)
  ├─ ProcessChatTagUseCase → _applyEngineScore (YukaScore + OFF truth) ✓
  └─ saveScanResult → chat msg + journal symptoms/meals + scan_history
```

Vision scan is the same but with `classifyImage` first, then analysis with the same bytes again.

### A.3 Insight generation (daily, on-device)

```
InsightsNotifier: dashboard stream (combineLatest6) + chatUpdated listener (5s debounce)
  → GenerateInsightUseCase.execute()
      ├─ 24h throttle (SharedPreferences, Firestore fallback)          ✓
      ├─ 3× FULL-collection count queries                              ✗ P0
      ├─ threshold: ≥3 scans OR (≥3 meals + ≥1 symptom)
      ├─ 6 parallel fetches (30d meals/symptoms/scans, full insight history,
      │   patterns, 30d chat) + PatternEngineService.runAnalysis (150+150 docs)
      ├─ tiered journal: 7d verbatim + 8–30d AI-summarized             ✓
      ├─ analyzeGutHealth → generateContent(json) → AIInsight          ✓ json mode
      └─ save insight → onInsightCreated mirrors gutScore to profile   ✓
```

### A.4 Backend (`functions/src/`)

`aiProxy`: CORS → Bearer auth → arg validation (images rejected *before* charging ✓) →
transactional `checkAndConsume` (daily_usage/{date}, idempotency keys, premium bypass) →
capped message build → OpenAI (`temperature: 0.2`, `max_tokens: 16384`, `json_object` for
json modes, `stream_options.include_usage`) → SSE re-emit / `{text}` → `recordTokens` →
`refund` on any failure. Triggers: streaks, NOVA-3/4 warning (3-in-3-days, weekly throttle),
gutScore mirror, account-deletion Storage cleanup, guest merge.

### A.5 Persistence (actual — the schema doc is stale, see P2-7)

| Collection (`user_profiles/{uid}/…`) | Content | Ordering clock |
|---|---|---|
| `chat_history/{localId}` | text, imageUrls, **scanPreview + full mealLogs/symptomLogs/swapData + analysisResult−rawData**, mentions, feedback | serverTimestamp ✓ |
| `scan_history/{scanId}` | **full ScanResult incl. `rawData` (whole GUTGOOD_DATA JSON)** ✗ | serverTimestamp ✓ |
| `journal_logs/{msgId}_{meal,symptom(_i)}` | `{…log.toMap(), type, createdAt: client/AI time ✗, loggedAt: server}` | **client clock** ✗ |
| `insights/{autoId}` | full AIInsight digest | serverTimestamp ✓ |
| `pattern_data/latest` | `{patterns: [...]}` single doc, overwrite | serverTimestamp ✓ |
| `health_alerts/{autoId}` | alerts | serverTimestamp ✓ |
| `daily_usage/{YYYY-MM-DD}` | counters + recentIds (server-only write ✓) | n/a |
| `ai_reports/{autoId}` (top-level) | create-only user reports ✓ | client+server |

---

## B. Problems found

### P0 — Critical

**P0-1 · Full-collection reads used as counters (one-shot AND streaming).**
`history_firestore_service.dart`: `getTotalScansCount / getTotalMealLogsCount /
getTotalSymptomsCount` call `.get()` on entire collections and return `.size`; the three
`*CountStream` variants keep **live snapshots of whole collections** open inside the dashboard's
`combineLatest6`, so every journal/scan write re-prices the world. `getAverageFoodScore(Stream)`
additionally `ScanResult.fromMap`s every doc. A 2-year user pays thousands of reads to render
one dashboard. Insight generation also burns 3 full reads per run (after the 24h gate).
*Fix (K-1): `count()` aggregation queries for one-shots; cached counters on the profile doc
(maintained by the existing triggers) for streams.*

**P0-2 · Entire AI JSON blob persisted in every scan doc.**
`ScanResult.toMap()` (`scan_result.dart`) includes `'rawData': rawData` — the complete decoded
`[GUTGOOD_DATA]` block — and `saveToScanHistory` writes it verbatim. Chat persistence already
strips it (`chat_message.dart::_analysisResultMapForPersistence`, with a comment explaining
why); scan_history never got the same treatment. Doc bloat toward the 1 MB cap, slower
history/insight reads that fetch full scans.
*Fix (I-1): strip `rawData` (and `menu` verbatim text) at the scan persistence boundary; keep a
`rawDataHash` for dedup instead.*

**P0-3 · Zero result caching on the scan path.**
`off_service.dart#getProduct` has no cache; `processBarcode` re-runs OFF + full AI analysis +
new history doc on every re-scan of the same product. At GPT-4o-mini vision/text prices this
is the app's largest avoidable AI bill, and the largest avoidable latency (2 network hops +
model call before any UI).
*Fix (K-2): personal barcode cache — `scan_history` hit by `barcode` within N days short-circuits
to the stored result (re-scored by the engine with current profile); then a shared read-only
product cache.*

### P1 — High

**P1-1 · Intent classifier emits tokens that don't exist.**
`intent_detection_prompt.dart` "STRICT CLASSIFICATION RULES" order the model to return
`` `meal_overview` `` (not a `UserIntent`), `` `menu` `` (should be `MENU_RECOMMENDATION`),
`` `full_analysis` `` (should be `COMPLETE_ANALYSIS`), lowercase `` `health_assessment` ``.
`AiClassifierService._canonicalIntent` can't match these, so affected turns silently fall back
to `COMPLETE_ANALYSIS` (+ a warning log nobody reads) — prompt routing is degraded by the
router's own instructions. Related drift: the image classifier's category list omits
`SYMPTOM_ANALYSIS`, `MEAL_PLANNING`, `GENERAL_CHAT`, so photo+symptom turns can't classify
correctly either — the "three drifting vocabularies" problem the schema comments claim was
fixed survives in the natural-language lists.
*Fix (J-1): generate category lists from `UserIntent.all` (same trick `schema_definitions.dart`
already uses); delete the invalid-token rules.*

**P1-2 · Journal ordering runs on client/AI clock; scans/chat on server clock.**
`logMeal`/`logSymptom` store `createdAt: log.createdAt` (client now, or **AI-estimated** meal
time) and every journal query `orderBy('createdAt')`. Pattern windows ("symptom ≤4h after meal")
are therefore computed on estimated timestamps, and clock skew can mis-order the journal.
*Fix (D-4): order/filter by server `loggedAt`; keep `occurredAt` (nullable, provenance-tagged)
as display/correlation input with sanity clamping.*

**P1-3 · Image lifecycle is bare URL strings (fails 5 of the doc's §6 requirements).**
Today: `uploadFoodImage` (320px/50q — the *only* stored copy, visibly lossy on re-view) →
URL string copied into chat msg + scan/meal/symptom docs. Consequences:
(a) upload failure aborts the whole turn (`ChatSendError.uploadFailed`) even though the AI
could proceed on bytes; (b) retry/regenerate **re-uploads identical bytes** as new files;
(c) `deleteMessage`/`deleteLogsForMessage` orphan Storage files (`deleteImage` has **zero**
callers); (d) no thumbnails vs full-size distinction; (e) no way to answer "which logs share
this photo". What *does* work: local preview (`localImages`), late URL hydration, images
independent of AI success.
*Fix (E): `food_images/{hash}` metadata records + hash-deduped Storage paths (§E).*

**P1-4 · Two divergent persistence routers + dead methods.**
`PersistAiResponseUseCase` (chat path) and `ScannerRepositoryImpl.saveScanResult` (scanner path)
independently re-implement label/menu gating, stable IDs, and meal/symptom writes — same policy
in two places, already subtly different (chat path has the confidence gate; scanner path doesn't
call it). `saveLabelScan`/`saveMenuScan` have **zero callers**.
*Fix (C-2): one `DomainEventPersister` used by both paths; delete the dead methods.*

**P1-5 · Mixed prose+JSON protocol instead of guaranteed-structured output.**
Chat streams Markdown + `[GUTGOOD_DATA]` in one generation; scanner calls use `mode: 'plain'`
(no `response_format`), so parsing depends on `extractJson` auto-repair + legacy-tag fallbacks.
This is the root cause of an entire class of fragility (truncation → lost data block; the
removed per-intent token budgets existed because of it).
*Fix (F): split data from prose — data calls use `json_object`/strict schemas; chat keeps a
streaming prose call that references already-validated data (§F).*

**P1-6 · Insight generation is heavy, client-side, and open-gated.**
Each daily run: 3 count-queries + 30-day everything + 150/150 pattern docs + full insight
history + 2 AI calls, all on-device, triggered by app-open/chat events. Background refresh,
retry, and cost control are all hostage to the client.
*Fix (C-4): move generation to a scheduled Cloud Function; client keeps threshold UI +
renders results. (Keeps the evidence-first design — just relocates it.)*

**P1-7 · Pattern engine statistics are weaker than its schema suggests.**
`pattern_engine_service.dart`: exact lowercased-string food matching (no normalization —
"paneer tikka" vs "paneer" never join); single-item triggers only; fixed 3/4/6h windows;
sleep detector has a 20:00–21:00 dead zone and uses `meals.last` (unordered!) as "latest";
energy uses only the *first* symptom in window; `confidence` = frequency ≥ 5 while the stored
`evidenceRatio`/`negativeCount` don't influence it; window is "last 150 logs" regardless of
span (2 weeks for power users, 6 months for light ones), yet `timeframeDays` claims a real
window; headache misses "migraine".
*Fix (H-2): normalize food keys, order-safe windows, ratio-aware confidence, time-bounded
(not count-bounded) inputs.*

### P2 — Medium

**P2-1 · Chat docs duplicate journal/scan data.** `ChatMessage.toMap` embeds full
`mealLogs`/`symptomLogs`/`swapData` maps **and** `journalEntryIds`, plus `analysisResult.scan`
(full, minus rawData) **and** `scanPreview`. Same meal lives in 2 docs; same scan in ~2.2.
*Fix (D-2): chat docs keep preview + IDs; hydrate from journal/scan collections on open.*

**P2-2 · 25-message context window with full structured attachments.** `_buildHistory` sends up
to 25 turns each carrying `[SCAN_CONTEXT]/[MEAL_CONTEXT]/[SYMPTOM_CONTEXT]` JSON — the summary
covers only aged-out overflow (≤6 msgs). Heavy users push large prompts every turn.
*Fix (K-4): window 10–12 + rolling summary + pinned entity memory.*

**P2-3 · Vision bytes travel twice per image turn.** `classifyImage` sends full image bytes to
`generateContent`, then analysis sends them again (chat *and* scanner — the scanner even
discards its own UI mode hint and always re-classifies). Double vision tokens + a blocking
round-trip before streaming starts.
*Fix (K-3): trust UI mode hint with classifier fallback; long-term, one vision call returning
classification + data.*

**P2-4 · Regex symptom fallback invents clinical data.** `ProcessChatTagUseCase` step 2.5 logs
e.g. `Bloating, severity: 5` from substring matches on user text — severity/energy numbers the
user never gave — with `source: 'chat'`, indistinguishable from confirmed logs downstream.
*Fix: tag `provenance: 'keyword_fallback'`, omit severity/energy (null, not 5), and exclude
from pattern corroboration until confirmed.*

**P2-5 · Summary runs an AI call + 2 writes after nearly every turn** once history > 6 msgs
(`precomputeSummary`), burning the 20/day `system` quota that classification shares — heavy
chatters silently lose both intent routing and summaries.
*Fix: summarize only when ≥4 newly-aged-out msgs; skip when system quota low.*

**P2-6 · Saved-foods is a distributed flag.** Every scan save does an extra `isFoodSaved` read;
`toggleSaveFood` batch-updates **all** history instances of a product (write amplification).
*Fix: `saved_foods/{barcodeOrHash}` collection (or profile array for small N).*

**P2-7 · Docs describe a schema that doesn't exist.** `FIRESTORE_SCHEMA.md` documents
`meal_logs`/`symptom_logs` collections and embedded `scanData` in chat — reality is
`journal_logs` + `scanPreview`. Any agent/teammate trusting docs will write wrong code.
*Fix: regenerate from §D below (10-minute job, do first).*

**P2-8 · Prod log noise.** `debugPrint` state dumps on every dashboard emission
(`insights_notifier.dart`); `AppLogger.data('OFF_RAW_RESPONSE', …)` ships full OFF payloads to
logs. *Fix: demote to verbose/debug-only.*

**P2-9 · No versioning anywhere.** No `schemaVersion`/`promptVersion`/`modelVersion` on AI
artifacts; readers rely on tolerant `fromMap`. The next model/prompt change can't distinguish
old-shaped docs. *Fix (§17/F): stamp every AI write; see migration §L.*

**P2-10 · `AIInsight` mixes data with presentation.** Schema *requires* emoji, icon names, color
strings, pre-written 140-char sentences (`healingTrend`, `scoreSub`) — the LLM does the UI's
job, in every supported language's future. Overlapping sections (`healingFoods` vs
`foodImpacts[]` vs `topHealing`) invite contradiction. *Fix (H): core-evidence model + thin
presentation mapping in Dart.*

**P2-11 · "See more swaps" is ungrounded.** `handleSeeMoreSwaps` calls
`getBetterAlternatives(null, null)` — no category, no grade — then asks the AI to invent from
titles. Swap schema has no product IDs/barcodes, so swaps can't deduplicate, re-score, or link
to scans. *Fix (G-3): OFF-backed swaps with IDs; AI ranks/explains, never invents products.*

**P2-12 · `premium` is client-mirrored.** Per `config.ts`'s own note, `isPremium` is set
on-device (RevenueCat SDK) and merely *read* by quota checks — a tampered client grants itself
unlimited AI. *Fix: RevenueCat webhook → server-stamped `premiumUntil`; treat client flag as
hint only. (Explicitly deferred by the team before; keeping it visible.)*

### P3 — Low

- **P3-1** `scanPreview.intent` reads `rawData['intent']`, but `rawData` is stripped at
  persistence — re-opened chats lose smart-routing input. Store intent as a first-class field.
- **P3-2** Mandatory bold-greeting first line on every reply: repetitive UX + tokens on every
  turn. Vary or drop for follow-ups.
- **P3-3** Global `temperature: 0.2` is right for JSON, flat for chat. Per-mode temperature
  (0.2 data / 0.7 prose) once §F splits the calls.
- **P3-4** `MAX_TEXT_CHARS` head-truncates long user text (pasted recipes) with only a
  server-side warning. Prefer tail-aware truncation + a user-visible notice.
- **P3-5** `nutritionEstimated` flag exists and is used — extend the same honesty pattern to
  AI-estimated meal *times* (P1-2) and fallback symptoms (P2-4).
- **P3-6** `onSymptomCreated` trigger watches a collection that no longer exists
  (`symptom_logs` → `journal_logs`); harmless but delete it.
- **P3-7** Foods are bare strings end-to-end (`meal.items`, `foodTags`, `foodMentions`) — the
  reason P1-7 can't match "dahi" to "yogurt". See `FoodItem` in §I.

### What's genuinely good (keep / extend)

- Proxy: key isolation, model allowlist, pre-charge validation, transactional quota,
  idempotency + refunds, token metering, SSE, documented caps. Textbook.
- 0.6 confidence gate before auto-persistence; engine score outranks LLM score; OFF as ground
  truth; engine-authored explanations that can't contradict the number.
- Evidence-first insights: threshold gate, 24h throttle, deterministic candidates the AI may
  explain but not invent, tiered 7d/30d journal, capped streams, chat hygiene filter.
- Cache-aware prompt ordering; single-schema source of truth; keyword intent fast-path;
  rolling summarization; lean `toAiMap`; idempotent stable doc IDs; merge-set writes.
- Rules: owner isolation, size caps, chat/pattern structural validation, server-only usage,
  create-only reports. Above average.

---

## C. Recommended architecture

### C-1 Target data flow

```
User Input → Intent Router (keywords → cached → model, §J)
  ├─ DATA path (deterministic): barcode cache → OFF → engine score
  └─ AI path: Task Builder → VALIDATED JSON (json_object) → Domain Model
        → Persistence Queue (background) → UI (optimistic)
Text path (chat only): streaming prose call referencing validated data IDs.

Images: pick → preview+hash → dedupe? → compress ladder → resumable upload
  → food_images record → AI bytes (memory, never re-download) → entities link imageId.

Insights (server): scheduler → aggregate → pattern engine → validate → AI explain
  → versioned insight docs + per-pattern docs → FCM + client renders.
```

### C-2 One persistence router

Merge `PersistAiResponseUseCase` + `ScannerRepositoryImpl.saveScanResult` into
`DomainEventPersister.persist(analysis, origin)` implementing, in order: confidence gate →
food/non-food verdict (§8) → label/menu policy → stable IDs → journal + scan writes →
streak/notify side-effects. Both chat and scanner call it. Delete `saveLabelScan/saveMenuScan`.

### C-3 Critical path vs background

| Critical path (blocks pixels) | Background (never blocks) |
|---|---|
| optimistic msg + image preview | Storage upload (proceed on bytes) |
| intent (fast-path; model only on miss) | classification refinement |
| AI stream first token | 3s persist ticks → single end persist |
| validated data render | journal/scan writes, summary, streak, analytics |

Concretely: `send()` must not `await` upload/classify before `_streamReply` starts — start the
stream on the UI hint immediately; reconcile if classification disagrees (it rarely does).

### C-4 Server-owned insight generation

Move `GenerateInsightUseCase` + `PatternEngineService` logic into a scheduled function
(`generateInsights`, daily per active user, threshold-gated). Client keeps: threshold progress
UI, dashboard streams, manual refresh (rate-limited). Removes the heaviest client Firestore
fan-out and makes insights arrive without opening the app.

---

## D. Recommended Firestore schema

**Keep** the `user_profiles/{uid}` root + subcollection model. **Keep** `journal_logs`
(type-discriminated — it was a good consolidation). Changes:

| Collection | Change | Rationale |
|---|---|---|
| `chat_history` | slim: text, imageIds[], scanPreview, journalEntryIds, swapPreview[], mentions, feedback, intent, confidence | P2-1: kill 2× duplication |
| `scan_history` | **drop `rawData`**; add `schemaVersion`, `engineVersion`, `imageId`, `groundTruth: {source}` | P0-2, §17 |
| `journal_logs` | order by server `loggedAt`; add nullable `occurredAt` + `occurredAtProvenance` (`user/ai_estimated/keyword_fallback`) | P1-2, P2-4 |
| `food_images` **(new)** | §E: `{storagePath, hash, w/h, bytes, links:{chatMsg,scans[],meals[],symptoms[]}, createdAt}` | P1-3 |
| `saved_foods` **(new)** | `{barcode\|nameHash → scanRef, savedAt}` | P2-6 |
| `pattern_data` | per-pattern docs `{type,triggerHash,…}` upserted, not single `latest` overwrite | expiry/history/diff |
| `insights` | §H core model + `promptVersion`, `model`, `expiresAt` | §17, staleness UI |
| `counters` **(new)** | `{scans, meals, symptoms, avgFoodScore, updatedAt}` maintained by triggers | P0-1 |
| `daily_usage`, `health_alerts`, `ai_reports` | unchanged | already right |

Embed vs reference rule going forward: **chat embeds previews (≤1 KB), references everything
else by stable ID; journal/scan docs are the system of record; nothing is stored in full twice.**

---

## E. Storage / image architecture (answers §5–§6)

**Verdict: yes to an image record, no to a food-items collection (yet).**

- `food_images/{sha256_16}` docs as above; Storage path `users/{uid}/food_images/{hash}.jpg`
  (+ `thumbs/{hash}_320.jpg` generated by a resize extension/function).
- **Dedup by hash** before upload (fixes re-upload on retry/regenerate; answers "same photo
  twice" for free). Store `storagePath` as canonical + cached `downloadUrl` (refresh on 403).
- **Upload must not gate AI**: stream starts on in-memory bytes; URL hydration is a background
  patch (fixes P1-3a). AI continues to receive 1280px; Storage keeps 1024px + 320px thumb
  (fixes lossy-only-copy).
- **Orphan collection**: message delete enqueues image unlink; scheduled sweeper deletes
  zero-link Storage objects after 30 days (fixes P1-3c without dangerous synchronous deletes).
- **Why not `foodItems` yet**: per-item nutrition/confidence/serving per photo is the right
  *model* (`FoodItem` entity in Dart, §I) but a premature *collection* — query value is low
  until search-by-food exists; embed `foods[]` in the image record and promote to a collection
  only when a query needs it. This directly answers "image URL + dish name": store
  `imageId + normalizedDishName[]` on the image record — reusable, queryable, no duplication.

Chat lifecycle (§6): local preview → hash → dedupe/upload (background) → record → reference
from msg → AI on bytes → entities link `imageId` → history hydrates from record. Resilient to
AI/upload/network failure, retry-safe (idempotent hash path), restart-safe (outbox in prefs).

---

## F. AI response architecture (answers §4)

**One envelope, two calls.** Data calls use `response_format: json_object` (upgrade path:
Structured Outputs with a published JSON schema); prose stays streamed.

```jsonc
// Every data response — chat scan/meal/symptom extraction, vision analysis,
// barcode analysis. Prose NEVER carries data; data NEVER carries prose.
{
  "v": 1,                        // schemaVersion (§17)
  "intent": "MEAL_RATING",       // UserIntent vocab, validated
  "imageMode": "FOOD|null",
  "confidence": 0.0,             // data confidence; <0.6 → chat-only, no persist
  "verdict": "food|non_food|uncertain",   // §8 gate: non_food → no records, ever
  "data": {
    "scan":   { /* §G, partial OK */ },
    "meal":   { "mealType": "", "foods": [{"name": "", "normalizedName": "",
                "confidence": 0.0, "serving": ""}], "occurredAt": "ISO|null" },
    "symptoms": [ { "symptom": "", "severity": null, "energyLevel": null,
                    "mood": "", "sleep": "", "notes": "" } ],
    "swaps":  [ { "productId": "", "title": "", "reason": "" } ],
    "menu":   { /* venue + items, chat-only by policy */ }
  },
  "needsPersistence": true       // model hint; server/client policy decides
}
```

Validation (client `AiResponseValidator`, mirrored in proxy later): JSON parses → `v`
supported → enums in vocab → required-by-verdict fields present → ranges sane → unknown →
`verdict: uncertain` + chat-only. Malformed output can degrade to prose-only; it can never
crash or corrupt history (§18).

Per-intent contracts (§3): `MEAL_RATING` → score+2 factors; `SWAP_REQUEST` → ranked swaps only;
`SYMPTOM_ANALYSIS` → symptoms + correlations, no scan block; `GENERAL_*` → prose, no data
block at all (extends the existing label/menu no-JSON rule). One schema, per-intent required
subsets — not one giant response for everything.

---

## G. Scan Result model (§12)

Converge barcode + vision into one `ScanResult v2` with explicit provenance per field-group:

- `identity {name, brand, barcode?, category, imageId?}` · `source {kind: barcode|vision|chat,
  mode?}` · `groundTruth {provider: off|label_ocr|none, novaGroup?, nutriscore?, nutrients?}` ·
  `aiEstimate {nutrients?, ingredients[], confidence}` (only when no ground truth) ·
  `engine {score, factors[], explanation, version}` — **score is always engine-authored or
  explicitly `scoreSource: model_fallback`** (photo-no-data case keeps today's safeguard but
  labels it) · `aiLayers {insight, swaps[], cycleInsight?}` · `media {imageId}` ·
  `links {chatMessageId, mealIds[], symptomIds[]}` · `v, promptVersion, model`.
- Partial results are first-class: `completeness: full|partial|verdict_only`; UI renders
  skeletons per missing group instead of `---`/`n/a` strings (deletes `_normalizeHighlight`
  hacks by construction).
- Swaps become `productId`-grounded (`off:{barcode}` or `ai:{hash}`), re-scorable and
  dedupable (§G-3/P2-11).

---

## H. Insight model + generation (§9–§11)

**Keep the data-first pipeline — it's the best part of the app — and harden the math.**
`Raw data → aggregate → pattern engine → statistical validation → AI explanation → versioned
docs → UI` is already the shape; §11's "raw → AI → insight" anti-pattern is *not* what this
codebase does. Strengthen:

- Pattern engine (P1-7 fixes): normalized food keys (lowercase → stem → synonym map, starting
  with the existing dairy/fried/carbs/sodium groups as a real taxonomy); order-safe,
  time-bounded windows (default 30d, min 7d span); ratio-aware confidence
  (`High` = freq ≥ 5 AND ratio ≥ 0.66 AND negatives ≥ 1 observed); fix sleep dead-zone +
  `meals.last`; migraine keyword; multi-item (pair) triggers as v2.
- Minimum-evidence doctrine (§9): **no candidates → digest with score-trend only, zero pattern
  claims, explicit "not enough data yet" state.** The `InsightsPrompt` "ZERO PATTERN CASE" is
  referenced but never defined — define it (P1, prompt bug adjacent to P1-1).
- Insight doc v2: `{id, v, type, period{from,to}, gutScore, scoreDiff, evidence{patternRefs[],
  sampleSizes}, topInsight{…no emoji…}, actions[], presentation{…icons/colors/emoji, Dart-side},
  model, promptVersion, generatedAt, expiresAt, status}`. UI answers What/Why/Evidence/Confidence/
  Action purely from `evidence` + `actions`.
- Relocate to scheduled function (§C-4); keep 24h cadence + threshold; add per-user disable.

---

## I. Dart models (§15)

| Action | Model | Reason |
|---|---|---|
| **Create** | `FoodItem{name, normalizedName, confidence, serving, imageId?}` | P3-7: ends bare-string foods; powers normalization |
| **Create** | `ImageRecord` (+ `FoodImageRef`) | P1-3 / §E |
| **Create** | `AiResponseEnvelope` + `AiResponseValidator` | §F/§18: typed parse boundary |
| **Create** | `InsightEvidence`, `PatternRef` | §H: evidence the UI can render |
| **Split** | `ScanResult` → domain + `ScanResultDto` (persistence) | P0-2: rawData never reaches Firestore by type |
| **Split** | `AIInsight` → core + presentation map | P2-10 |
| **Ground** | `ProductSwap` += `productId`, `barcode?`, `score?` | P2-11 |
| **Enum** | `category`, `source`, `imageMode`, `intent`, `confidence` (+ `unknown` fallback) | stringly-typed pipeline; keep wire strings, parse lenient |
| **Keep** | `HistoricalScan`/`HistoryItem` (used by history UI), `BodyPattern`+`PatternOccurrence` | fine as UI/read models |
| **Delete** | `saveLabelScan`/`saveMenuScan` (service methods, zero callers) | dead |
| **Fix nullability** | `SymptomLog.severity/energyLevel` stay nullable (P2-4: stop inventing 5s); `AIInsight.gutScore` non-null ✓ keep; `ScanResult.score` → non-null + `scoreSource` enum | invented numbers are worse than nulls |
| **Version** | add `v = 1` default to `ScanResult`, `AIInsight`, `BodyPattern`, `MealLog`, `SymptomLog` | §17 |

No DTO→domain→persistence→UI four-layer ceremony: two layers (wire/durable DTO vs domain)
only where the shapes actually differ (scan, insight). Elsewhere the tolerant `fromMap`
pattern already works.

---

## J. Prompt architecture (§3)

```
SYSTEM (static, cacheable): identity → capability → philosophy → safety →
  analysis-discipline → formatting → OUTPUT CONTRACT (schema §F + type rules)
INTENT LAYER (static per intent): one of 17 task prompts, trimmed to its data subset
DYNAMIC (uncached, last): profile → cycle → time → summary → pinned entities
```

- **J-1 (P1-1 fix):** generate classifier category lists from `UserIntent.all`; delete
  invalid-token rules; define the missing `ZERO PATTERN CASE`; add `SYMPTOM_ANALYSIS /
  MEAL_PLANNING / GENERAL_CHAT` to the image classifier.
- **J-2:** per-intent output contracts (§F): each intent declares required data subsets; general
  chat/label/menu emit zero data (already the rule — enforce in validator, not prose).
- **J-3:** dedupe repeated rules (the label/menu no-JSON rule appears in 3 places; safety
  appears in 2) into single blocks; cut ~15% of the 16k system prompt without losing behavior.
- **J-4:** stamp `promptVersion` in every builder; proxy echoes it; writers store it (§17).
- **J-5:** per-mode temperature (0.2 data / 0.7 prose) after the §F split; keep 0.2 until then.

---

## K. Performance plan (§13)

| # | Fix | Removes from critical path | Est. effect |
|---|---|---|---|
| K-1 | `count()` + trigger counters (P0-1) | 1k+ doc reads per dashboard open | −80–95% insight-screen reads |
| K-2 | barcode result cache (P0-3) | OFF + AI call on re-scan | re-scan ~8s → <300ms, $0 AI |
| K-3 | UI mode hint; skip re-classify (P2-3) | 1 vision round-trip per scan | −1–2s + −50% vision tokens |
| K-4 | context 25 → 10–12 + summary + pins (P2-2) | KBs of JSON per turn | faster first token, −30–50% prompt $ |
| K-5 | upload off critical path (P1-3) | Storage await before stream | first token starts ~1s earlier on LTE |
| K-6 | batch summaries (P2-5) | per-turn AI call + 2 writes | −70% system-quota burn |
| K-7 | strip rawData (P0-2) | doc weight on every history/insight read | −40–60% scan doc size |
| K-8 | scope dashboard streams to tab focus; drop `debugPrint` | always-on 6-stream fan-out | idle battery + reads |

Already right (don't touch): SSE streaming, 60ms flush, optimistic UI, prompt-cache ordering,
single-image vision compression ladder, `include_usage` metering, minInstances=1.

---

## L. Migration plan

1. **Docs + rules first:** regenerate schema doc (§D); deploy index additions
   (`journal_logs: type+loggedAt`, `scan_history: barcode`, `food_images: hash`); rules: add
   `food_images`/`saved_foods`/`counters` blocks mirroring existing patterns (owner-only, size
   caps; counters server-write-only like `daily_usage`).
2. **Additive writers:** ship v-stamped writers (new fields only; old readers ignore unknown
   fields by construction). Backfill `counters` with a one-shot function (paginated, resumable).
3. **Lazy image backfill:** existing URL strings resolve to records on first access
   (hash from URL fetch once, then canonical). No mass rewrite.
4. **Pattern docs:** next engine run writes per-pattern docs; keep reading `latest` until all
   writers migrated (2 releases), then delete.
5. **Chat slimming:** new writes slim; old fat docs read via the same tolerant `fromMap`.
   Never rewrite history in bulk.
6. **Insight relocation:** run server + client in parallel for one cycle with `origin` tag;
   compare; then disable client generation via Remote Config flag (instant rollback).
7. **Rollback:** every phase is flag- or additive-gated; nightlies export `insights` +
   `pattern_data` during migration.

---

## M. Implementation order

| Phase | Work | Size | Unblocks |
|---|---|---|---|
| **0 — Hygiene** | regenerate schema doc (P2-7); delete dead methods + `onSymptomCreated` (P1-4/P3-6); demote noisy logs (P2-8); P1-1 prompt-vocab fix + define ZERO PATTERN CASE | S | everything (shared understanding) |
| **1 — Cost fires** | `count()` + trigger counters (P0-1); strip rawData (P0-2); barcode cache (P0-3) | M | burn-rate relief, measurable |
| **2 — Trust** | envelope + validator (F); single persister (P1-4); provenance + clock fix (P1-2, P2-4); versioning stamps (§17) | M | data quality |
| **3 — Images** | `food_images` + hash dedupe + background upload + unlink sweeper (P1-3, §E) | M | UX resilience |
| **4 — Speed** | UI-hint classify (K-3); slim context (K-4); batch summaries (K-5/K-6); saved_foods collection (P2-6); slim chat docs (P2-1) | M | latency + quota |
| **5 — Insights+** | pattern-engine stats (P1-7); insight v2 + presentation split (P2-10); per-intent contracts (J-2); server relocation (P1-6/C-4); swaps grounding (P2-11); premium webhook (P2-12) | L | the "intelligence system" goal |

**Suggested start:** Phase 0 + P0-1 (counters) — smallest diff with the largest bill impact,
and it de-risks everything downstream.

---

## Appendix — section coverage map

§1 pipeline trace → A · §2 challenge → B + "good" list · §3 prompts → J · §4 envelope → F ·
§5 images → E (+P1-3) · §6 chat display → A.1 + E · §7 schema → D · §8 food/non-food →
`verdict` gate (F) + `isLoggableProduct` hardening (G) · §9–11 insights → H + C-4 · §12 scan
model → G · §13 speed → K + C-3 · §14 flows → C-1 · §15 models → I · §16 schema → D ·
§17 versioning → F/H/I + L · §18 validation → F + C-2 · §19 security → rules review (§A.5,
P2-12) — no insecure shortcuts recommended · §20 → this document's A–M.

---

## Implementation log

### 2026-09-09 — Phase 0 + P0-1 (counters), via 📲 Mobile App Builder

**Phase 0 — hygiene (all items):**
- Schema doc regenerated from code (`docs/FIRESTORE_SCHEMA.md`): `journal_logs`
  replaces the fictional `meal_logs`/`symptom_logs`; `createdAt` (not `time`) on
  scans/journal; `counters`, `pattern_data`, `health_alerts`, `merges`, `ai_reports`
  documented. (P2-7)
- Dead code deleted: `saveLabelScan`/`saveMenuScan` (zero callers),
  `onSymptomCreated` trigger (watched nonexistent `symptom_logs`),
  `meal_overview_prompt.dart` (zero imports). (P1-4/P3-6)
- Noisy logs: insights `debugPrint` dump → single release-gated `AppLogger.debug`;
  generation markers → `AppLogger.insights`/`error`. OFF-service dumps verified
  already debug-only, left in place. (P2-8)
- P1-1 prompt-vocab fix: intent rules now interpolate `UserIntent` constants and
  explicitly forbid the legacy tokens; image classifier covers all 17 intents;
  insights prompt defines the ZERO PATTERN CASE; `prompts_test.dart` gains a
  vocabulary-consistency group (5 tests).

**P0-1 — counters:**
- New `HistoryCounts` model + `watchHistoryCounts()` (single-doc `counters/totals`
  read, `count()` fallback while the doc is missing, permission-denied tolerated).
- Dashboard `combineLatest6` → `combineLatest4`; all 6 count one-shots → `count()`;
  average score reads `foodScoreSum/foodScoreCount` (legacy full-read fallback only
  while counters are missing).
- New `functions/src/counters.ts`: increment/decrement + lazy one-time seeding (no
  backfill job); `isLoggableForAverage` mirrors `ScanResult.isLoggableProduct`;
  decrements are transacted and floored at 0. Wired into `onScanCreated` /
  `onJournalEntryCreated`; new `onScanDeleted` / `onJournalEntryDeleted` triggers.
- `firestore.rules`: `counters/{docId}` read-owner / write-never.
- Behavior notes: count methods no longer throw offline (resolve 0); insight gating
  outcome unchanged (0s fail the threshold, same as the old exception path).
- Incidental fix: `email.ts` now exports `getTransporter` (pre-existing `tsc`
  failure blocked ALL functions deploys). `npx tsc --noEmit` is clean.

**Verification:** `tsc --noEmit` ✅ · stale-reference sweep ✅ · Dart side needs
`flutter analyze` + `flutter test` on the user's machine (no Flutter in this
workspace). Deploy order: `firebase deploy --only firestore:rules,functions` first
(triggers seed counters), then ship the app.
- Follow-up noted, not done: GENERAL_CHAT/GENERAL_* intents fall through to the
  heavyweight FullAnalysis prompt (no fast path); consider routing-only handling.

### 2026-09-09 — P0-2 (rawData strip) + P0-3 (barcode cache)

**P0-2:**
- `ScanResult.toPersistenceMap()`: `toMap()` minus the `rawData` blob plus a
  stable SHA-256 `rawDataHash` (crypto was already a dependency). `toMap()` itself
  is untouched (in-memory/chat/args use); only `saveToScanHistory` switched.
- `fromMap` fallbacks kept intact — legacy docs with the blob still hydrate
  (impact summary, swaps, meal-block loggability). New docs simply never trigger
  those branches. `isLoggableProduct` + trigger mirror flip identically for the
  exotic no-signal-with-meal-block case (no marker field added — YAGNI).
- Tests: `test/core/models/scan_result_persistence_test.dart` (strip fidelity,
  hash stability/shape, legacy hydration, null-organic round-trip).

**P0-3:**
- Personal barcode cache: `getLatestScanByBarcode` (newest doc for barcode) +
  `ScannerRepository.getCachedBarcodeScan` (30-day window, engine re-score,
  sensitivity re-flag, chat message + `barcode_cache` analytics, no new
  history/journal docs). Wired into both notifier barcode paths.
- Exactness: `nutriscoreScore` + `isOrganic` persisted as first-class
  `ScanResult` fields; `_applyEngineScore` gained scan fallbacks so a zero-arg
  re-run reproduces the original score bit-for-bit (existing callers unaffected:
  vision/AI scans carry nulls, OFF path still passes explicit values).
- Re-flagging is union-only (stored AI flags kept; current sensitivities add
  substring matches) — documented synonym limitation, safe-monotonic direction.
- OFF session memo in `OffService` (30-min TTL, 200-entry cap, nulls not cached).
- Indexes: +(barcode, createdAt) for the cache query; +(barcode, isSaved) fixes
  the latent `isFoodSaved` failure (was silently resetting saved state on re-save).
- Tests: `test/features/scanner/barcode_cache_test.dart` (miss/stale/hit,
  engine exactness vs direct `YukaScore.evaluate`, fresh IDs, no history writes,
  reflag union, empty-barcode + error fall-through),
  `test/core/services/off_cache_test.dart` (memo hits, per-barcode isolation,
  nulls not cached).
- Deploy note: `firebase deploy --only firestore:indexes` for the 2 composites
  (cache query fails to fall-through-null until the index builds — graceful).
- Follow-up noted, not done: shared read-only product cache across users (needs
  trust design for the population path — the audit's K-2 "then" stage).

### 2026-09-09 — Phase 2 (Trust), via Arena Agent Mode

**Envelope + validator (§F):**
- Client `AiResponseValidator` (`lib/core/services/ai_response_validator.dart`):
  JSON parses → `v` supported → enums in vocab → required-by-verdict fields →
  ranges sane; malformed output degrades to prose-only, never crashes or
  corrupts history.
- `verdict` gate in `ProcessChatTagUseCase`: `non_food` → no records, ever;
  data confidence < 0.6 → chat-only, no persist.

**Single persister (P1-4):**
- `DomainEventPersister` (`lib/core/services/domain_event_persister.dart`) is
  the only record-write path: chat and scanner funnels both route through it
  (same label/menu gating, consumption gating, stable `{chatMessageId}_{scan,meal}`
  IDs). Fixed phantom meal logs on "is this healthy?" scans.

**Provenance + clock (P1-2, P2-4):**
- `occurredAt` + `occurredAtProvenance` (`user` / `ai_estimated` /
  `keyword_fallback`) via `DateTimeUtils.occurredAtFromMap` (AI estimates
  sanity-clamped to now+1h / now−30d); `journal_logs` carry server `loggedAt`
  with log-time `createdAt` as the ordering clock.
- Regex symptom fallback kept but tagged `keyword_fallback` and NEVER carries
  numbers the user didn't give (no invented severity/energy); excluded from
  pattern corroboration.

**Versioning (§17):** `v`/`schemaVersion` stamped on AI writes; legacy docs
read as v1 by tolerant `fromMap`s.

**Verification:** `flutter analyze` + `flutter test` on the user's machine (no
Flutter in this workspace). Tests: `journal_clock_test`,
`schema_version_test`, `process_chat_tag_usecase_test`,
`persist_ai_response_usecase_test`, `domain_event_persister_test`.

### 2026-09-09 — Phase 3 (Images: P1-3 + §E) + offline text outbox, via Arena Agent Mode

**P1-3a/b + §E-lite (non-blocking, deduped uploads):**
- Upload no longer gates the AI turn: user message saved immediately (durable,
  local bytes), reply streams from in-memory bytes, Storage URLs hydrate as a
  background patch (direct doc patch when the message isn't in memory).
- `sha256_16` dedup at idempotent `users/{uid}/food_images/{hash}.jpg` paths +
  prefs URL cache (cap 200); retries/regenerates/re-scans never re-upload.
- Restart-safe upload outbox: bytes on disk (cache dir) + index in prefs,
  retried on turn-complete/reconnect/app-start; 10-attempt poison cap, purged
  files drop gracefully, shared-byte files refcount-deleted.

**Offline text outbox (Scope B, outside §M — user-requested):**
- Prefs-backed FIFO (`ChatOutboxService`), `Queued` bubbles, flush on
  reconnect/composer-init/turn-complete/tap; entries dequeue only after a fully
  successful turn, failures roll back under stable IDs; image turns never queue;
  session reset drops the outbox.

**Full §E (registry, thumbs, lifecycle):**
- `food_images/{sha256_16}` docs: transactional add/removeLink (idempotent,
  self-healing minimal-doc create on add), denormalized `linkCount`,
  `lastUnlinkedAt` grace anchor; `ChatMessage.imageHashes` parallel array.
- 1024px/q80 Storage originals; `generateFoodThumb` (`sharp` Storage trigger,
  hash-named objects only) derives 320px thumbs + backfills meta;
  `RegistryThumbImage` prefers thumbs with full-URL fallback (fallbacks never
  cached as thumbs).
- Links: chat hydration links under the message doc ID; meal/scan links inside
  `HistoryFirestoreService` (single choke point). Deletes unlink
  (`deleteLogsForMessage` unlinks before its batch); daily
  `sweepUnlinkedFoodImages` cron deletes `linkCount == 0` docs past 30d grace
  (single-field query, no composite index; un-ageable/legacy objects never swept).
- Rules: `food_images` owner-read, size-capped create/update, no client delete.
  Docs: `OFFLINE_SYNC.md` §8; schema doc §12 + `imageHashes` row.

**Verification:** `tsc --noEmit` ✅ (incl. new `sharp` dep) · stale-reference
sweep ✅ · Dart side needs `flutter analyze` + `flutter test` on the user's
machine. Deploy order: `firebase deploy --only firestore:rules,functions`
first (thumb/sweep workers live), then ship the app. Tests:
`image_upload_outbox_test`, `chat_composer_notifier_test` (recovery/link),
`chat_repository_impl_test` (unlink-on-delete), `food_image_test`,
`image_hash_test` (parser).

### 2026-09-09 — Phase 4 (Speed: K-6, K-3, P2-6, K-4, P2-1), via Arena Agent Mode

**K-6 / P2-5 — batch summaries:** `precomputeSummary` now runs only with ≥4
newly-aged-out messages and a `UsageService.canSummarize()` gate (system quota
below limit−2 reserve; premium bypasses; guests use lifetime count).
Classification keeps priority on the shared 20/day system budget. Also fixed a
1-message overlap (marker message was re-summarized every run). No caller
changes — gates live inside `precomputeSummary`.

**K-3 / P2-3 — UI-hint classify:** `classifyImage` takes an optional `modeHint`
(scanner mode / attachment source). Known hints (`food`/`menu`/`label`/
`barcode`) skip the vision round-trip; intent still resolves from text
(keyword fast-path first, model only on miss). Gallery/unknown/legacy hints
fall back to full vision classification. Wired at all 3 callsites (chat send,
regenerate, scanner repo — the scanner's "visual content wins" override is
gone).

**P2-6 — `saved_foods` collection:** one doc per product (`b_{barcode}` /
`n_{nameHash}` via `savedFoodKey`), full scan map embedded + `scanRef` +
`savedAt`. Toggle is a single-doc set/delete (was: batch over all history
instances); save path drops its `isFoodSaved` query (was: extra read per
scan); list is one small collection read, client-sorted (no new index).
Pre-P2-6 flags lazily migrate on `getSavedFoods` (backfill + flag clear) with
a legacy fallback in `isFoodSaved`; unsave always clears legacy flags so
stale flags can't resurrect items. Side-effect fix: saved items now survive
`scan_history` deletion (chat-delete cascade). Rules: owner
read/write/delete, 256KB cap. Schema doc §13.

**K-4 / P2-2 — slim context:** window 25 → 12 (`_contextCandidates` shared by
history + pins); new `buildPinnedEntities` salvages foods/symptoms/scans from
windowed-out turns (capped 8/6/6, case-insensitive dedupe) into a
`PINNED ENTITIES` block rendered in the prompt's dynamic section (cacheable
prefix untouched; byte-identical output when no pins). Rolling summary leg
already existed. Both `chatSystemInstruction` callsites pass pins.

**P2-1 — slim chat docs:** `toMap` drops `analysisResult` (zero readers —
was the third copy of scan+meal+symptoms+swaps) and `mealLogs` (no widget
renders them; AI keeps text + foodMentions + summary). Kept: `symptomLogs`
(small, core-loop context), `swapData` (rendered), `scanPreview`+`scanId`
(inline card reads preview fields only; detail re-hydrates by id), mentions,
`journalEntryIds`, feedback, image refs. `fromMap` untouched — legacy fat
docs hydrate identically (§L-5, no bulk rewrite).

**Verification:** stale-reference + brace sweeps ✅ · no functions changes
(`tsc` unaffected) · `firestore.rules` +1 block (saved_foods). Dart side
needs `flutter analyze` + `flutter test` on the user's machine. Tests:
`chat_history_notifier_test` (batch threshold, quota skip, no re-run),
`usage_service_test` (new: gate boundaries, premium bypass, guest lifetime),
`ai_classifier_service_test` (hint map/skip/fall-through, zero-interaction
asserts), `saved_food_key_test` (new), `chat_composer_notifier_test`
(window-12 + pins capture, `buildPinnedEntities` units), `prompts_test`
(pins render/cache-marker), `chat_message_test` (new: slim keys, legacy
hydration, preview-card fallback). Deploy note: `firebase deploy --only
firestore:rules` for the `saved_foods` block (toggles fail closed until then —
service swallows the error, UI shows unsaved).

### 2026-09-09 — Phase 5 (Insights+: J-2, P2-11, P1-7, P2-10, P1-6/C-4, P2-12), via Arena Agent Mode

**J-2 — per-intent contracts:** `AiResponseValidator` gains step 7. Zero-data
intents (general/label/menu/ingredient) strip meal blocks (render-safe, keeps
user symptoms) and block on any scan block (chat card preserved, history
quarantined); symptom/swap intents block invented scans but pass photo-derived
ones via `userImageUrl`; full-data/unknown intents get no opinion.
`DomainEventPersister` reordered policy-before-quality so label/menu turns keep
reporting `labelMenu` instead of `validationFailed` (end states identical).

**P2-11 — swaps grounding:** `handleSeeMoreSwaps(null, null)` always returned
[] (dead code). It now takes the message's scan, resolves category+grade via
the cached OFF product fetch, and grounds the prompt with name/grade/barcode
plus an echo instruction. `ProductSwap` gains `barcode`/`nutriscore`
(round-trip, legacy-tolerant); `OffProduct.toSwap()` maps alternatives.

**P1-7 — engine stats:** 30d time-bounded fetch (existing composite covers the
range); normalized food keys (case/quantity/whitespace); exact Duration
windows (kills the +1h `inHours` leak); order-safe nearest-after readings
(Firestore is newest-first); co-occurring `involvedFoods` (cap 3); §H
confidence (High = freq ≥ 5 + ratio ≥ 0.66 + ≥1 negative; Low now reachable);
migraine detector; contiguous sleep buckets (20:00 split, latest-by-time);
honest 1–30d `timeframeDays`; stale-pattern clear on empty input; rank-map
sorts (engine + notifier). Pair triggers stay deferred v2 per §H.

**P2-10 — insight v2 + presentation split:** prompt v2 drops all REQUIRED
emoji/icon/color (verified write-only: nothing renders `.emoji`); Dart owns
visuals via `InsightPresentation` + food-aware `fromMap` defaults.
`InsightEvidence`/`PatternRef`/`SampleSizes` added; `AIInsight` gains the v2
envelope (`period`, `evidence`, `actions`, `model`, `promptVersion`,
`status`, `expiresAt`) + `copyWith` + `toEvidence()` (legacy recompute);
`AiVersions.insightPromptVersion = 2`; `stampInsightEnvelope` (pure, tested)
applies the minimum-evidence doctrine (`insufficient_data` when zero
candidates or span < 7d). UI untouched — fields preserved, now Dart-resolved.

**P1-6/C-4 — server relocation:** new `functions/src/insights.ts` (compiles
clean): scheduled `generateInsights` (daily 04:00 UTC, per-user 24h cadence,
threshold-gated, disable-aware, bounded fan-out) + `requestInsightRefresh`
callable (6h cooldown). Faithful port of the hardened engine (tz-shifted
wall-clock for sleep/labels), tiered journals, prompt assembly (caps, frozen
v2 instruction in `insights_prompt.ts`), deterministic scoreDiff + v2
envelope, `pattern_data/latest` sync, health alert + FCM, per-user token
accounting. Deliberate divergences: chat uses the 10 most RECENT messages
(client took the 10 oldest — fixed both sides), server caps on unbounded
fetches, dead pattern-cache fetch skipped. Client: auto-trigger removed,
one-shot bootstrap, server-first refresh with local fallback, per-user
`insightsDisabled` toggle (profile settings), chat recent-10 fix. Rules:
`premiumUntil` server-only. Deploy: `firebase deploy --only functions`
(generateInsights + requestInsightRefresh + revenuecatWebhook) and
`--only firestore:rules`.

**P2-12 — premium webhook:** `revenuecatWebhook` endpoint (Bearer secret,
grant/revoke with out-of-order guards, idempotent replays) stamps
`premiumUntil`; `isPremiumUser` treats the stamp as authoritative with a
documented legacy fallback (removal TODO after one billing cycle);
`REVENUECAT_WEBHOOK_SECRET` secret; setup guide
`docs/REVENUECAT_WEBHOOK_SETUP.md`. User-owned: secret value, dashboard
webhook URL + auth header, test event.

**Verification:** `tsc --noEmit` clean (functions) · rules braces 39/39 ·
stale-ref/callsite sweeps per slice. Dart side needs `flutter analyze` +
`flutter test` on the user's machine. Tests: `ai_response_validator_test`
(contracts), `product_swap_test` (new: mapping/round-trip/fragment),
`pattern_engine_service_test` (new: 14 black-box engine cases),
`insight_v2_test` (new: presentation/evidence/envelope/stamp/recent-chat),
`prompts_test` (prompt-v2 asserts), `schema_version_test` (fixed stale
AIInsight ctor). Also fixed in passing: `schema_version_test` referenced
removed `weeklySummary`/`insight` params (didn't compile).

### 2026-09-09 — Phase 6 (migration hardening & prompt hygiene: L-6, P3-4, J-3, J-4)

**L-6 insight-migration rollback story (C-4 follow-up).** `origin` stamped on
every insight write: `server-scheduled` (scheduled fn) / `server-refresh`
(callable) via a new `generateForUser` param, `client-fallback` via
`stampInsightEnvelope`; `AIInsight.origin` constants + tolerant read, schema
doc row, round-trip/legacy/stamp tests. Remote Config kill-switch
`insights_client_generation_enabled` (default true; debug always on) gates
`GenerateInsightUseCase.execute` at the top: once the first server-origin docs
are verified in production, set it false to retire client generation; flip
back for instant rollback. Rollout: deploy functions → confirm a
`server-scheduled` doc looks right → RC false. (The strict "parallel run +
compare" is approximated by origin tags: any fallback write during the
observation window is visibly tagged.)

**P3-4 tail-aware truncation + user notice.** Proxy `buildOpenAIMessages` now
middle-out truncates (head + tail preserved, `[…trimmed for length…]` marker)
system/history/prompt instead of `slice(0, cap)`, which dropped the tail
carrying SCHEMA TYPE RULES / pattern evidence / the user's question.
Truncation is REPORTED, not just server-logged: `finish_reason: length` is
captured on both paths; `json`/`plain` return `{truncated, truncation}`,
streams send a meta frame before `[DONE]`. Client: `AiService` parses the
meta/fields (`lastResponseTruncated`, one-shot log + `ai_response_truncated`
analytics); chat stamps `ChatMessage.wasTruncated` (persisted, rules-safe,
never in `toAiMap`) and the bubble renders a warning caption.

**J-3 prompt dedupe (behavior-preserving).** Removed the repeated rules:
visionCapability's label/menu exception clause (canonical static is now
STRICT FORMATTING #4, extended to cover PACKAGED_PRODUCT as the deleted
clause did; per-turn signal stays the conditional `formatInstruction`
branch); philosophy DOMAIN LOCK + NO DIAGNOSIS folded into IDENTITY/SAFETY
(renumbered); identity evidence-aware bullet (covered by philosophy +
discipline); VisionSafety's exact-dupe individuality line, observations line
(covered by discipline #5 + the fabrication guard), and diagnosis/disease
enumeration (covered by discipline #6 in the same `_sharedRules` assembly —
kept the gut-specific causation guard). Measured: −403 chars of rule blocks
(−6.0%; ~100 tokens/turn on every chat + vision call). The audit's ~15%
assumed the schema double-interpolation a prior phase already removed (~790
tokens) — this is the remaining rule-level yield; deeper cuts need §F/§G.

**J-4 promptVersion in every builder + proxy echo + writers store (§17,
closes P2-9).** `AiVersions.chatPromptVersion/visionPromptVersion = 1`
(first versioned baselines; classifier/summarizer intentionally unversioned —
routing-only / no versioned artifact). Proxy accepts `promptVersion` and
echoes `{promptVersion, model}` (serving model post-allowlist) on EVERY
response — meta frame on streams, fields on one-shots. Client threads
send→echo→stamp: `AiService`/`ChatRepository`/`SendMessageStreamUseCase`
passthrough + `lastPromptVersion`/`lastServedModel`; processor stamps
scan/meal/symptoms at the return edge (uniform call shape at all 7 sites);
`ChatMessage`/`ScanResult`/`MealLog`/`SymptomLog` carry nullable
`promptVersion` + `model` (ctor/fromMap/toMap/copyWith; NOT in props/AI maps;
legacy docs read null). Builder identity: insights = insights builder, chat
records = chat builder, scans disambiguated by `source` ('chat' vs
image-mode/barcode). Tests: mocktail stubs updated at all driven sites
(incl. `verify`/`verifyNever` capture blocks, which would otherwise silently
mismatch), §17 round-trip + processor stamp tests added. Verified `tsc`
clean; `flutter analyze` + `flutter test` still user-side (no SDK here).

**Post-ship review fixes (same day):** (1) visionCapability's exception kept
self-contained (a "see STRICT FORMATTING RULES" pointer would dangle on the
unknown-vision path, which doesn't include that block) — measurement above
re-baselined to −403 chars; (2) processor no longer stamps
`keyword_fallback` symptoms (regex-detected from user text, not
prompt-extracted) + test; (3) see-more-swaps path captures echo flags before
the persist await (closes a concurrent-AI-call interleave window); (4) proxy
protocol-doc line wrap. tsc re-verified clean.

**Closed without code (verified):** P3-1 (intent already first-class),
P3-6 (`onSymptomCreated` already deleted), J-1 (image-classifier intents
present), L-1 (indexes exist; `food_images` hash is the doc ID), J-5/P3-3
still correctly blocked on the §F split.

### 2026-09-09 — P2-12 reverted per user request ("I dont want REVENUECAT_WEBHOOK_SECRET")

Removed the RevenueCat webhook slice: `functions/src/premium.ts`,
`docs/REVENUECAT_WEBHOOK_SETUP.md`, the `REVENUECAT_WEBHOOK_SECRET` define,
the `isPremiumUser` stamp-authoritative branch (back to the client-mirrored
`isPremium`/`subscriptionStatus` check), the `premiumUntil` rules locks, and
the `revenuecatWebhook` export. Premium is again determined on-device by the
purchases_flutter SDK and mirrored to Firestore, as before Phase 5 — no
secrets, no dashboard setup, no new deploy surface. (Rationale for full
removal vs. dropping just the secret: the Bearer secret was the endpoint's
only authentication — RevenueCat doesn't sign payloads — so a secret-less
endpoint would let anyone grant themselves premium via forged events.)
Full backup at `/home/user/revenuecat-backup/` (7 files); restorable on request.

### 2026-09-09 — C-4/L-6 server insight pipeline removed per user request ("i dont want insight generation in server-side")

Deleted `functions/src/insights.ts` (scheduled `generateInsights` + callable
`requestInsightRefresh`, ~1131 lines) and `functions/src/insights_prompt.ts`;
removed the `index.ts` export. Client restored to owned cadence:
`InsightsNotifier` reactive listeners (`chatUpdated`/`profileUpdated`, 5s
debounce) reinstated, server-first `_tryServerRefresh` + `FirebaseFunctions`
dependency removed (DI back to 5 args), L-6 Remote Config kill-switch removed
(`insights_client_generation_enabled`), `origin` reduced to `client` (retired
server values may persist on old docs), and `GenerateInsightUseCase` now
honors the profile `insightsDisabled` toggle itself (the server enforced it
before). Rules need no allow-changes (client writes to `insights` /
`pattern_data` were already permitted); stale C-4 comment reworded. Kept
deliberately: `onInsightCreated` gutScore trigger, `merge.ts` account-merge
migration, `ai_reports.ts` Play-moderation trigger — none of these *generate*
insights. Schema doc §5 updated. Full backup at
`/home/user/server-insights-backup/` (11 files); restorable on request.
Deploy note: next `firebase deploy --only functions` will offer to delete the
two retired functions — confirm; optionally delete the
`insights_client_generation_enabled` Remote Config parameter in the console.

### 2026-09-09 — ai_reports + full report flow removed per user request

Deleted `functions/src/ai_reports.ts` (note: it was never exported from
`index.ts`, so the trigger was already inert — nothing to undeploy),
`lib/core/models/ai_report.dart`,
`lib/features/chat/presentation/widgets/report_ai_response_sheet.dart`, and
`test/core/models/ai_report_test.dart`. Removed the `isValidAiReport`
validator + `/ai_reports/` match from `firestore.rules`, `submitAiReport`
from `ChatFirestoreService` (abstract + impl) and `ChatHistoryNotifier`, the
`onReport` callback from `chat_screen.dart`, the `onReport` param + Report
chip from `chat_bubble.dart`, and the 11-string reporting block from
`chat_strings.dart`. Schema doc §11 removed (§12–13 renumbered). Kept:
`email.ts` (shared by auth magic-link + welcome emails), thumbs feedback
(measure satisfaction, unrelated to safety reporting). COMPLIANCE FLAG: Play's
generative-AI policy expects in-app AI-content reporting/flagging — this
removes that loop entirely; reinstate before any Play review if needed. Full
backup at `/home/user/ai-reports-backup/` (11 files); restorable on request.

### 2026-09-09 — Dead-code pass 1 removed (10 files + 2 functions)

Per unused-code review (`/home/user/unused-review.md`): deleted 10 wholly
unreferenced Dart files (~880 lines: history_hub_sections, modern_gut_score_card,
gut_score_gauge + its `widgets.dart` barrel export, feedback_tag, chat_action_icon,
app_tokens, stream_utils, streak_calculator, pagination_scroll_controller,
failures) and 2 dead Cloud Functions (`getUsage`, `usageFieldFor` in
`functions/src/usage.ts`). Verified: no remaining imports/references, `tsc`
clean (incl. `--noUnusedLocals`). Backup at `/home/user/dead-code-pass1-backup/`
(11 files). Passes 2–4 (dead members in live files, constants/fonts, test-only
trio) still pending user go-ahead.

### 2026-09-09 — Dead-code pass 2 removed (~1,300 lines)

Per unused-code review: 14 dead widgets in live files (dashboard_widgets ×9
incl. 3 cascade: DashboardCard/GutProgressBar/DashboardIconVisualization,
super_card ×4, scan_result_widgets ×2, insight_dashboard_view ×1,
insight_dashboard_sections ×1 — the last file is now deleted as an empty
husk), 15 dead service/repo pairs + 4 singles (mergeData, deleteAllUserData,
updateOnboardingStatus, migrate/deleteAllUserFiles, deleteImage,
getSymptomLogs, getScans/SymptomsCountSince, getAverageFoodScore,
get/saveProfile, checkOnResume, isConfigured, lastTruncationKind,
handleBarcodeScan + cascade processBarcode + ScanAnalysisException,
syncWithAuth, loadMoreMeals, clearAttachments), dead helpers
(insight_ui_utils ×5, dialog_helper whole file, heavy, formatRelative,
toRelativeDayString, toBodyPattern, showRegistrationPrompt), 4 dead privates
+ cascade (_GroupedItem, _getNovaColor, _getNutriScoreColor), extensions ×7,
app_sizes ×26 incl. cascade r10, cascade fields (bluePastel, nutri×5,
ingredientsLabelText). Cascade fixpoint verified by re-scan (193→86
candidates; remainder is pass 3/4). All 29 edited files brace-balanced;
zero whole-word refs remain. Backup at `/home/user/dead-code-pass2-backup/`
(30 files). Pass 3 (dead getters/constants/fonts) + 4 (test-only trio) pending.

### 2026-09-09 — Dead-code pass 3 removed (getters/constants/fonts)

21 dead getters (history ×9, chat ×3, auth ×2, insights ×2, scanner/chat-msg/
purchase/profile/theme ×1), 57 dead const fields (app_strings ×24, palette
×11, logger ×8, assets ×6, profile_strings ×6, notification/composer ×1),
plus an 18-string CommonStrings cascade (orphaned alias targets) and a
duplicate `analyzingProductInfo` in scanner_strings. Deleted 5 Poppins .ttf
files (772 KB) + 10 KB mascot PNG and the `assets/fonts/` pubspec entry —
assets/ is now 136 KB. DELIBERATE KEEP: `RecordProvenance.aiExtracted`
(technically unreferenced, but it's a reserved leg of the live provenance
taxonomy — removing it would erase a wire value, not dead code). Re-scan to
fixpoint: 86→8 (remainder = pass-4 trio + aiExtracted + 4 live DI noise).
All 19 edited files brace-balanced. Backup at
`/home/user/dead-code-pass3-backup/` (26 files). Only pass 4 remains
(GutShimmerSkeleton + test, toEvidence + test, wasCapped + tests).

### 2026-09-09 — Dead-code pass 4 removed (test-only trio) — review complete

Removed `GutShimmerSkeleton` (widget file + barrel export + its widget test
group; EmptyStateWidget tests kept), `AIInsight.toEvidence` (+ doc refs in
ai_insight/insight_evidence; legacy-envelope test keeps its defaults half,
`toEvidence` recompute asserts dropped) and `YukaScore.wasCapped` (cap tests
reworked onto surviving `scoreBeforeCap`: `isTrue`→dropped as redundant,
`isFalse`→`scoreBeforeCap isNull` with the same reason). Re-scan to fixpoint:
8→5 remaining (deliberate keep `aiExtracted` + 4 live DI inits). Backup at
`/home/user/dead-code-pass4-backup/` (8 files). Full-unused review
(`/home/user/unused-review.md`) is now fully executed across passes 1–4.

## 2026-09-09 — Dead-code follow-ups: minInstances removal + extensions.dart repair + deleter audit
- `functions/src/ai_proxy.ts`: removed `minInstances: 1` + its 4-line comment (user: no always-on fee; accepts cold-start latency). `tsc --noEmit` exit 0; zero `minInstances` refs repo-wide. Kept `timeoutSeconds: 300, memory: '512MB'` + cold-start comment.
- `lib/core/utils/extensions.dart` repaired: pass-2 deleter had truncated `paddingSymmetric` (named-param braces on a `=>` sig line) and `paddingOnly` (body on next line), orphaning 15 lines that caused 31 analyzer errors. Orphans deleted; `WidgetExtensions` now only `center()`; braces 3/3. Cause of user's pasted analyzer errors — resolved at source.
- Audited all 101 pass-2/3/4 member deletions for the same signature-brace bug (15-line sig window): 43 flags, all cleared — 17 class-ctor whole-class deletions, 2 whole-file deletions, 17 body-`{`-on-sig-line members (safe by construction), 5 diff-verified complete (`processBarcode`, `handleBarcodeScan`, `_buildGroupedOptions`, `getIngredientColor`, `showRegistrationPrompt`), `expanded` single-line. extensions.dart was the ONLY damaged file.
- `deadcode/ddel.py` fixed: skip past balanced parameter `(...)` before deciding `=>` vs `{`, plus a truncation guard (span must end in `;`/`}`). Proven by replay on the pass-2 backup of extensions.dart — now deletes all 4 members completely.
- User still to run: `flutter analyze` + `flutter test` (device/emulator + network unavailable in this sandbox).
