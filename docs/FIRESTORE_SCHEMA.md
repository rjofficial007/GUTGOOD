# Firestore Database Schema

> Regenerated from code (`toMap` methods, services, triggers, rules). The previous
> revision of this doc described `meal_logs` / `symptom_logs` subcollections and a
> `time` field that do not exist — those were replaced by the consolidated
> `journal_logs` collection (type discriminator) and `createdAt` timestamps.

The database is structured around a single root collection, `user_profiles`, with all
user-specific data organized into subcollections under each user's UID.

## 1. `user_profiles` (Root Collection)

**Purpose:** Core user identity, health profile, and personalization settings.
Source: `UserProfile.toMap()`.

| Field | Type | Description |
| --- | --- | --- |
| `uid` | String | Firebase Authentication UID. |
| `displayName` | String | User's preferred name or "Guest". |
| `email` | String | Authenticated email address. |
| `photoUrl` | String | URL to profile picture in Storage. |
| `onboarded` | Boolean | Whether onboarding is complete. |
| `isPremium` | Boolean | Mirror of the RevenueCat entitlement (client SDK writes; client-authoritative by design — accepted risk R1, see `ACCEPTED_RISKS.md`). |
| `subscriptionStatus` | String | "free" or "premium" (client-written; same R1 caveat). |
| `isAnonymous` | Boolean | Whether the account is guest/anonymous. |
| `authProvider` | String | Login method (google.com, apple.com, etc). |
| `goals` | List<String> | Selected health goals. |
| `sensitivities` | List<String> | Selected food sensitivities. |
| `lifestyle` | List<String> | Selected lifestyle factors. |
| `cycleSyncEnabled` | Boolean | Opt-in status for hormonal tracking. |
| `cyclePhase` | String | Current menstrual cycle phase. |
| `insightsDisabled` | Boolean | C-4 kill switch for server insight generation (default false). |
| `chatSummary` | String | AI-generated rolling summary of recent history. |
| `gutScore` | Number | Aggregated health score (0-100, server-written by `onInsightCreated`). |
| `streak` | Number | Current daily check-in streak (server-written). |
| `longestStreak` | Number | All-time highest streak achieved (server-written). |
| `lastActivityDate` | String | ISO Date (YYYY-MM-DD) of last activity (server-written). |
| `timezoneOffset` | Number | User's local timezone offset in minutes. |
| `notificationPreferences` | Map | User's alert settings. |
| `createdAt` | Timestamp | Account creation time. |
| `updatedAt` | Timestamp | Last profile update time. |

Fields marked server-written are excluded from `toUpdateMap()` so client writes can't
race the triggers.

---

## 2. `user_profiles/{uid}/chat_history` (Subcollection)

**Purpose:** Conversational turns between the user and AI. Slim since P2-1:
new writes store text, image refs, `scanId`+`scanPreview`, `journalEntryIds`,
`symptomLogs`, `swapData`, mentions, and feedback — `mealLogs` and
`analysisResult` are no longer written (legacy docs still carry them and
`fromMap` still reads them; never bulk-rewritten).

| Field | Type | Description |
| --- | --- | --- |
| `localId` | String | Client-side UUID for deduplication. |
| `role` | String | "user" or "ai". |
| `text` | String | Message content (Markdown). |
| `imageUrls` | List<String> | Storage URLs for attached images. |
| `imageHashes` | List<String> | Registry identities (`sha256_16`) parallel to `imageUrls`; empty on legacy / partially-uploaded turns. |
| `scanData` | Map | Embedded `ScanResult` if AI analyzed a product. |
| `swapData` | List<Map> | AI-suggested product alternatives. |
| `isSwap` | Boolean | Flag for swap-heavy responses. |
| `feedback` | String | "helpful" or "not_helpful". |
| `foodMentions` | List<String> | Automatically extracted food items. |
| `symptomMentions` | List<String> | Automatically extracted symptoms. |
| `wasTruncated` | Boolean | P3-4: proxy truncated this turn (caption rendered; never fed back to AI). |
| `promptVersion` | Number? | J-4 §17: chat-prompt version that produced this turn (proxy echo). |
| `model` | String? | J-4 §17: serving model id echoed by the proxy. |
| `createdAt` | Timestamp | Message creation time. |

---

## 3. `user_profiles/{uid}/scan_history` (Subcollection)

**Purpose:** Food/product scan results (barcode, vision, chat-confirmed meals).
Source: `ScanResult.toMap()` + service-added envelope fields.
Label and menu analyses are intentionally NOT persisted here (chat-only).

| Field | Type | Description |
| --- | --- | --- |
| `productName` | String | Name of the scanned item. |
| `brand` | String | Product manufacturer. |
| `category` | String | food / meal / product / packaging / menu / non-food / label. |
| `imageUrl` | String? | Catalog image (e.g. Open Food Facts). |
| `score` | Number | Gut health score (0-100). |
| `impactType` | String | "positive", "neutral", or "negative". |
| `impact` | String | Summary of health effects. |
| `badge` | String? | Display badge. |
| `nutriscore` | String? | Grade (A-E). |
| `novaGroup` | String? | Processing level (1-4). |
| `nutriscoreScore` | Number? | Original-algorithm FSA points (persisted engine input for cache re-scores). |
| `isOrganic` | Boolean? | Organic label flag (persisted engine input for cache re-scores). |
| `allergens` | String? | Allergen statement. |
| `additives` / `additiveItems` | String? / List | Additive summary + detail. |
| `ingredients` | List? | Ingredient entries. |
| `nutrients` / `nutrientLevels` | Map? | Nutrient values + traffic-light levels. |
| `impacts` | List? | Per-claim impact breakdown. |
| `swaps` | List? | Embedded product alternatives. |
| `cycleInsight` | String? | Cycle-phase-specific note. |
| `barcode` | String? | EAN/UPC barcode string. |
| `source` | String | food / meal / vision / chat (origin of the scan). |
| `userImageUrl` | String? | Storage URL of the photo taken. |
| `flaggedIngredients` | List<String> | Ingredients triggering sensitivities. |
| `isSaved` | Boolean | Bookmarked by the user. |
| `scanId` | String | Deterministic client ID (idempotency key). |
| `chatMessageId` | String? | Link back to the originating chat turn. |
| `servingSize` | String? | Serving size statement. |
| `createdAt` | Timestamp | Server timestamp (set by the service). |
| `rawDataHash` | String? | SHA-256 of the decoded AI payload. The `rawData` blob itself is stripped at persistence (P0-2); legacy docs may still carry it and `fromMap` still reads it. |
| `nutritionEstimated` | Boolean? | Whether nutrients were AI-estimated. |
| `userId` | String | Owner UID (service-added envelope). |
| `v` | Number | Schema version (currently 1; see §17 versioning). Missing on legacy docs = 1. |
| `promptVersion` | Number? | J-4 §17: prompt version that produced this scan (builder disambiguated by `source`). |
| `model` | String? | J-4 §17: serving model id echoed by the proxy. |

---

## 4. `user_profiles/{uid}/journal_logs` (Subcollection)

**Purpose:** Consolidated meal + symptom journal. The `type` field discriminates;
there are NO separate `meal_logs` / `symptom_logs` collections (legacy
`symptom_logs` docs are migrated into this collection by `mergeAnonymousAccount`).

| Field | Type | Description |
| --- | --- | --- |
| `type` | String | "meal" or "symptom" (service-added discriminator). |
| `chatMessageId` | String? | Link back to the originating chat turn. |
| `source` | String | "chat", "scanner", or "manual". |
| `createdAt` | Timestamp | Log time = when the record was written (ordering/pagination clock). NEVER carries AI time estimates. |
| `occurredAt` | Timestamp? | When the meal/symptom actually happened, when known (Phase 2 clock split). Null = unknown → readers fall back to `createdAt` via `eventTime`. |
| `occurredAtProvenance` | String? | `user` (vetted input) or `ai_estimated` (parsed from AI `time`, sanity-clamped to now+1h / now−30d). |
| `v` | Number | Schema version (currently 1). |
| `promptVersion` | Number? | J-4 §17: chat-prompt version that extracted this entry. |
| `model` | String? | J-4 §17: serving model id echoed by the proxy. |

Meal-only fields (`MealLog.toMap()`):

| Field | Type | Description |
| --- | --- | --- |
| `items` | List<String> | Description of items eaten. |
| `notes` | String? | Free-form details. |
| `mealType` | String? | "breakfast", "lunch", "dinner", "snack". |
| `photoUrl` | String? | Storage URL of the meal photo. |
| `analysisResult` | Map? | Embedded analysis snapshot. |
| `foodTags` | List<String> | AI-extracted health tags. |

Symptom-only fields (`SymptomLog.toMap()`):

| Field | Type | Description |
| --- | --- | --- |
| `symptom` | String | Reported symptom (e.g. Bloating). |
| `severity` | Number? | Scale (1-10). Null when not reported — never invented (P2-4). |
| `notes` | String? | Free-form details. |
| `energyLevel` | Number? | Scale (1-10). Null when not reported — never inferred from the symptom name (P2-4). |
| `provenance` | String? | `ai_extracted` (structured AI entry) or `keyword_fallback` (regex guess from user text; excluded from pattern corroboration). Null on legacy docs = treated as confirmed. |
| `mood` / `sleep` | String? / Number? | Context signals. |
| `lastMealFirestoreId` | String? | Nearest preceding meal (for correlation). |
| `foodName` | String? | Suspected food. |
| `imageUrl` | String? | Attached photo. |

---

## 5. `user_profiles/{uid}/insights` (Subcollection)

**Purpose:** Generated health insights (latest doc drives the dashboard).
Source: on-device `GenerateInsightUseCase` + `PatternEngineService` (reactive cadence; no server pipeline).

| Field | Type | Description |
| --- | --- | --- |
| `firestoreId` | String? | Document ID echo. |
| `gutScore` | Number | Score at generation time (0-100). |
| `scoreDiff` | Number? | Delta vs previous insight. |
| `topInsight` | Map? | Highest-confidence pattern (`DetectedPattern`). |
| `healingGoal` / `healingTrend` | String? | Goal statement + trend. |
| `healingFoods` | List<Map> | Beneficial foods with evidence. |
| `triggerSymptom` / `triggerTrend` | String? | Primary symptom + trend. |
| `triggerFoods` | List<Map> | Suspect foods with evidence. |
| `detectedPatterns` | List<Map> | All detected patterns. |
| `topTrigger` / `topHealing` | Map? | Top food-impact entries. |
| `foodImpacts` | List<Map> | Per-food impact assessments. |
| `weeklyRecap` | Map? | Narrative recap block. |
| `type` | String? | Insight type tag. |
| `confidenceLevel` | String? | Overall confidence. |
| `triggerData` | Map? | Raw trigger evidence. |
| `updatedAt` | Timestamp | Generation time. |
| `period` | Map? | P2-10 v2 envelope: `{from, to}` data window (30d). |
| `evidence` | Map? | P2-10 v2 envelope: `{patternRefs[], sampleSizes{meals,symptoms,scans}, spanDays}`. |
| `actions` | List<String> | P2-10 v2 envelope: recommended actions (from `topInsight.nextSteps`). |
| `model` | String? | P2-10 v2 envelope: serving model id. |
| `promptVersion` | Number? | P2-10 v2 envelope: insights-prompt version (2 = data-only schema). |
| `status` | String | P2-10 v2 envelope: `ready` or `insufficient_data` (min-evidence doctrine). |
| `expiresAt` | Timestamp? | P2-10 v2 envelope: regeneration horizon (stale reads stay servable). |
| `origin` | String? | Writer provenance: `client` (null on legacy docs; retired server values `server-scheduled` / `server-refresh` may appear on old docs). |

Food `emoji` values in `healingFoods`/`triggerFoods`/`foodImpacts`/`topTrigger`/`topHealing`
are Dart-resolved caches (`InsightPresentation`), not LLM output — prompt v2 omits them.

---

## 6. `user_profiles/{uid}/pattern_data` (Subcollection)

**Purpose:** Pattern-engine state — latest analysis evidence (single `latest` doc).
Rules enforce the shape (`isValidPatternData`, < 512 KB).

| Field | Type | Description |
| --- | --- | --- |
| `patterns` | List<Map> | `BodyPattern` entries: `type`, `trigger`, `reaction`, `frequency`, `confidence`, `description`, `involvedFoods`, `recommendation`, `occurrences`, `commonFactors`, `totalSimilarMeals`, `timeframeDays`, `evidenceRatio`, `positiveCount`, `negativeCount`, `v`. |
| `v` | Number | Schema version (currently 1). |
| `updatedAt` | Timestamp | Last analysis time. |

---

## 7. `user_profiles/{uid}/health_alerts` (Subcollection)

**Purpose:** Proactive alerts (e.g. NOVA ultra-processed warnings from `onScanCreated`).
Source: `HealthAlert.toMap()`.

| Field | Type | Description |
| --- | --- | --- |
| `title` | String | Alert title. |
| `message` | String | Alert body. |
| `type` | String | Alert category. |
| `createdAt` | Timestamp | Creation time. |
| `isRead` | Boolean | Read flag. |

---

## 8. `user_profiles/{uid}/daily_usage` (Subcollection)

**Purpose:** Server-managed AI rate limits (one doc per local date; the date key is derived from the client-supplied `timezoneOffset`, intentionally not range-validated — accepted risk R2, see `ACCEPTED_RISKS.md`).

| Field | Type | Description |
| --- | --- | --- |
| `messages` | Number | Total AI messages sent today. |
| `scans` | Number | Total food scans performed today. |
| `date` | String | ISO Date (YYYY-MM-DD). |

> [!IMPORTANT]
> This collection is **read-only** for clients. Increments are performed server-side by the `aiProxy` Cloud Function to prevent tampering.

---

## 9. `user_profiles/{uid}/counters` (Subcollection)

**Purpose:** Server-maintained history totals (single `totals` doc). Read by the
dashboard stream, insight-generation gating, and the profile average — one doc
read replaces full-collection counting. Maintained by `onScanCreated`,
`onScanDeleted`, `onJournalEntryCreated`, `onJournalEntryDeleted` (see
`functions/src/counters.ts`); seeded lazily on first trigger run, so no backfill
job is required.

| Field | Type | Description |
| --- | --- | --- |
| `scans` | Number | Total `scan_history` docs. |
| `meals` | Number | Total `type == 'meal'` journal docs. |
| `symptoms` | Number | Total `type == 'symptom'` journal docs. |
| `foodScoreSum` | Number | Sum of engine scores over loggable food scans. |
| `foodScoreCount` | Number | Count of loggable food scans (average = sum / count). |
| `updatedAt` | Timestamp | Last counter update (server timestamp). |

> [!IMPORTANT]
> This collection is **read-only** for clients (`allow write: if false`).

---

## 10. `user_profiles/{uid}/merges` (Subcollection)

**Purpose:** Idempotency markers for guest→account migration. Doc ID is the anonymous
UID; written transactionally by `mergeAnonymousAccount`.

---

## 11. `user_profiles/{uid}/food_images` (Subcollection)

**Purpose:** Registry for deduplicated food photos (Phase 3 / §E). One doc per
uploaded photo, keyed by `sha256_16` content hash — the source of truth for
the image lifecycle: which chat/meal/scan docs reference the photo (`links`),
where its 320px thumb lives (`thumbUrl`), and whether anything still needs it
(`linkCount`). Legacy timestamp-named Storage objects have no doc and are never
swept.

| Field | Type | Description |
| --- | --- | --- |
| `hash` | String | `sha256_16` of the stored bytes; also the doc ID and Storage filename stem. |
| `storagePath` | String | Canonical original (`users/{uid}/food_images/{hash}.jpg`, 1024px/q80). |
| `downloadUrl` | String? | Cached full-size download URL (refreshed on re-register). |
| `thumbPath` | String? | Server thumb (`.../food_images/thumbs/{hash}.jpg`, 320px). Backfilled by `generateFoodThumb`. |
| `thumbUrl` | String? | Permanent thumb download URL (embedded token). Backfilled by `generateFoodThumb`. |
| `width` / `height` / `bytes` | Number? | Original dimensions + stored bytes. Backfilled by `generateFoodThumb`. |
| `links` | Map | `{chat: [], scans: [], meals: [], symptoms: []}` — referencing doc IDs per bucket. |
| `linkCount` | Number | Denormalized `links` total (sweeper query key; maintained transactionally). |
| `lastUnlinkedAt` | Timestamp? | When the doc last became unlinked (sweeper grace anchor; deleted while linked). |
| `foods` | List<String> | Normalized dish names visible in the photo (reserved; unwritten for now). |
| `createdAt` / `updatedAt` | Timestamp? | Server timestamps. Docs without a known age are never swept. |

Lifecycle: `registerImage` on upload (best-effort) → chat/meal/scan saves link →
deletes unlink → `sweepUnlinkedFoodImages` (daily cron) deletes docs at
`linkCount == 0` past the 30-day `max(createdAt, lastUnlinkedAt)` grace, plus
their Storage objects. Rules: owner read, size-capped create/update, no client
delete (server sweeper only).

---

## 12. `user_profiles/{uid}/saved_foods` (Subcollection)

**Purpose:** Saved/favorite products, one doc per product (P2-6). Key is
`b_{barcode}` or `n_{sha256_16(normalized name)}` (see `savedFoodKey`). The
full scan map is embedded so the list renders with a single collection read,
offline-friendly, and survives `scan_history` deletion. Replaces the old
distributed `isSaved` flag (batch-updated across every history instance on
each toggle); pre-P2-6 flags are lazily migrated into this collection on
`getSavedFoods` and then cleared.

| Field | Type | Description |
| --- | --- | --- |
| *(scan fields)* | mixed | Embedded `ScanResult.toPersistenceMap()` (name, brand, score, images, …). |
| `scanRef` | String? | Originating `scan_history` doc ID (detail-screen re-hydration). |
| `savedAt` | Timestamp | When the item was saved. |
| `isSaved` | Boolean | Always true (marks migrated/current docs). |

Rules: owner read/write/delete (256KB cap — full scan maps are larger than
registry records).
