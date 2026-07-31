# GutGood — Complete Change History

**Scope:** Every change made to this project from the pre-audit baseline to the
current production-ready state.
**Baseline:** commit `f1bb748` — *"Merge pull request #1 from jbr731996/develop"*
(the state of the repo when work began).
**Source of truth:** `client_requirements/GutGood_Client_Requirements_PRD.md`
**Detailed audit rationale:** see `AUDIT_REPORT.md` (companion document).

---

## Timeline at a Glance

| Phase | What happened | Delivered |
|---|---|---|
| **1. Production audit & fixes** | Full codebase/Firebase/AI/chat audit against the PRD → **20 bugs found and fixed**, secure Cloud Functions backend built, ChatGPT-style chat rework | `AUDIT_REPORT.md` |
| **2. Android removal** | `android/` platform folder deleted (PRD: iOS-only MVP) | commit `32242d0` |
| **3. Premium model change** | All server-side RevenueCat integration removed per product decision → client-side entitlement model | this document §4 |
| **4. Verification** | PRD section-by-section compliance sweep + repeated green verification runs | §7 |

**Net diff vs baseline:** 71 tracked files changed (+1,780 / −1,908 lines),
plus ~1,100 lines of new backend/model/doc files added.

---

## 1. Phase 1 — Production Audit & Remediation (20 bugs fixed)

### 1.1 Severity summary

| # | Severity | Bug | Root cause | Fix |
|---|---|---|---|---|
| 1 | **Critical** | OpenAI API key shipped to devices via Remote Config (`openai_api_key` param + hardcoded `ApiConstants.openAIKey`) — PRD §3d forbids this | No secure backend existed; AI SDK ran on-device | Key removed from client; new `aiProxy` Cloud Function holds it server-side; `openai_dart` dependency dropped |
| 2 | **Critical** | `firebase.json` declared a Functions codebase but `functions/` didn't exist → `mergeAnonymousAccount` callable always `NOT_FOUND` | Backend never committed (root `.gitignore` even silenced `/functions/`) | Full `functions/` TypeScript backend created; `.gitignore` fixed |
| 3 | **Critical** | Image sent to AI **immediately on selection** — violated the required ChatGPT composer flow | `_pickAndSendImage` called the send path straight from the picker | Attachment pipeline: preview → editable text → single request on Send (§1.4) |
| 4 | **Critical** | Firestore snapshot listener wiped optimistic messages mid-send; streaming wrote into a hardcoded `_messages[0]` → AI text could overwrite the user's bubble / `RangeError` | Full list replacement per snapshot + hardcoded index | Race-safe optimistic merge keyed by `localId`; streaming targets the message it created |
| 5 | **High** | Client could write `isPremium`/`subscriptionStatus`/`daily_usage` → premium/paywall bypass; rules/app desync also silently broke premium users' profile sync | Blanket-owner rules on server-only data | `daily_usage` write-locked (server-transactional); premium fields later opened to client-writes *with shape validation* (Phase 3) |
| 6 | **High** | Every streaming token replayed entrance animations for every bubble → visible jank | `.animate()` evaluated per rebuild in a watched list | Once-per-message entrance animation |
| 7 | **High** | `MarkdownBody` re-parsed + `notifyListeners()` per token → frame drops | No stream coalescing | Token coalescing at ~16 fps (60 ms `Timer.periodic`) |
| 8 | **High** | Triple usage counting (screen + notifier + service all incremented) | No single owner of usage accounting | Server-side transactional consumption with idempotency keys; client is read-only |
| 9 | **Medium** | No stop-generate, regenerate, retry, copy, or draft persistence; input disabled during generation | Features never built | All implemented (§1.4) |
| 10 | **Medium** | Crash mid guest→account merge → orphaned anonymous data | Client-side merge, not atomic/resumable | Server-side atomic + idempotent `mergeAnonymousAccount` |
| 11 | **Medium** | No offline guard on send | Missing connectivity check | `InternetConnectionChecker` gate with clear error |
| 12 | **Medium** | Dead API surface (`getMessages` → `[]`, deprecated stubs, unused `openai_dart`) | SQLite→Firestore migration leftovers | Removed |
| 13 | **Medium** | Compressed image bytes retained for every message forever | Never cleared post-upload | `localImages` released after save |
| 14 | **Low** | `firebase_crashlytics` in pubspec but never initialized | Missing wiring | `FlutterError.onError` + `PlatformDispatcher.instance.onError` in release |
| 15 | **Low** | `debugLogDiagnostics: true` in release | Hardcoded | `kDebugMode` |
| 16 | **Low** | 3 analyzer warnings + dead `textScaler` no-op in `main.dart` | Leftovers | Fixed/removed |
| 17 | **Low** | No semantic labels on stop/copy/regenerate controls | Not annotated | Added (a11y) |
| 18 | **Info** | Template counter widget test (wrong app's test) | Never replaced | Real `ChatMessage` contract tests (5 tests) |
| 19 | **High** | Root `.gitignore` contained `/functions/` → backend would never be committed | Template leftover | Removed from `.gitignore` |
| 20 | **Medium** | Regenerate re-persisted `[MEAL]`/`[SYMPTOM]` tags → duplicate logs in Insights | Tag pipeline had no display-only mode | `ProcessChatTagUseCase` gained `persist` flag (regenerate → `persist: false`) |

### 1.2 New secure backend (`functions/` — did not exist before)

| Function | Type | Purpose |
|---|---|---|
| `aiProxy` | HTTPS (300 s, 512 MB, `us-central1`) | Firebase-auth-gated OpenAI proxy. Key never on device. Transactional free-tier quota (idempotency-keyed). SSE streaming `data: {"d":…}` → `[DONE]`. 429 → `{error:"quota_exceeded",type,limit}`. Server input caps: ≤4 images, ≤1.2 MB each, ≤20 history messages, `max_tokens: 1200` (PRD cost strategy). |
| `mergeAnonymousAccount` | Callable | Atomic + idempotent guest→account migration: content-addressed dedupe (chat/meals/symptoms), barcode/name dedupe (scans/saved foods), per-source-folded `daily_usage`, profile union, Storage file copy with URL rewrite, anon identity reclaimed, marker doc. Retries are no-ops. Premium fields never copied. |
| `onUserDeleted` | Auth trigger | Guaranteed cascade: Firestore `recursiveDelete` + Storage `users/{uid}/` purge (client network failure can't orphan data). |
| `cleanupAnonymousUsers` | Scheduled (daily 03:00 UTC) | Purges guest accounts idle >14 days (cost + GDPR hygiene). |

*(`syncPremiumStatus` + `revenuecatWebhook` were also built in this phase, then
**removed in Phase 3** per the client-side premium decision.)*

### 1.3 Firebase / Firestore / Storage hardening

- **Rules:** deny-by-default retained; `daily_usage` fully write-locked for
  clients; `chat_history` writes shape-validated (`isValidChatMessage()`: role
  enum, text < 20 KB, ≤4 images, doc < 512 KB); size guards on every
  subcollection; `merges/` markers unforgeable.
- **Storage rules registered in `firebase.json`** (previously undeployable) and
  emulator-validated.
- **Emulator support:** `--dart-define=USE_FIREBASE_EMULATOR=true` points Auth,
  Firestore, Functions, Storage at the local suite (Android `10.0.2.2` handled).
- **Functions client** pinned to `us-central1`; message stream emits
  newest-first directly; `deleteMessage` added; `getUsageToday` no longer
  rethrows.
- **Usage limits (PRD §10):** registered free = 5 chats + 3 scans/day;
  guests = 2/2 then signup wall ("Create a free account to save your results…");
  premium = unlimited.

### 1.4 Chat rework — ChatGPT interaction model (PRD §6.1)

**Image flow (was: instant-send — now exactly the required flow):**
1. Tap camera/gallery (or scanner capture) → image compresses once (512 px/q80)
   → thumbnail appears **inside the composer**. Nothing is sent.
2. Up to 4 images, each independently removable (✕). Text stays fully editable;
   scanner captures pre-fill an editable suggested prompt.
3. Send activates when text **or** images exist. One request carries text + all
   images. Hidden analysis instructions (menu→`[SWAPS]`, label/meal→`[SCAN]`)
   ride invisibly.
4. Draft text persists across restarts (400 ms debounce).

**Composer:** single rounded card → attachment strip → auto-growing field
(1–6 lines) → camera/gallery/send-stop row. Upload → spinner; streaming →
stop button (partial replies preserved, like ChatGPT).

**Messaging:** token coalescing ~16 fps; follow-scroll that never fights the
user; per-message Copy/Regenerate icon row (regenerate replays the frozen
request incl. images, `persist:false`); Tap-to-retry on failed sends;
"Response interrupted" marker; quota card → Upgrade CTA; GFM markdown (code
blocks, tables, blockquotes, lists); streaming cursor `▌`; selectable text
post-stream; keyed slivers (`ValueKey` + `findChildIndexCallback`);
once-per-message entrance animation; semantic labels; dismiss-on-drag keyboard.

**PRD non-negotiables preserved:** passive-logging tags `[MEAL]/[SYMPTOM]/
[SCAN]/[SWAPS]` unchanged; pattern language ("You reported…", never diagnoses)
in system prompts unchanged; rolling summary memory (past 6 messages) retained.

---

## 2. Phase 2 — Android Platform Removed

- Entire `android/` folder (38 tracked files: Gradle, manifests, launcher
  assets, `google-services.json`) deleted — **PRD: "Platform: iOS (MVP)"**.
- Committed as `32242d0 Remove android/ platform folder (iOS-only MVP per PRD)`.
- Recovery path documented: `flutter create --platforms=android .` + re-add
  `google-services.json`.

## 3. Phase 3 — Server-Side RevenueCat Removed (client-side premium model)

Per product decision ("development phase"), all server-side RevenueCat
integration was removed:

**Removed**
- `functions/src/premium.ts` — `syncPremiumStatus` callable + `revenuecatWebhook`
  HTTPS endpoint (**file deleted**).
- Secrets `REVENUECAT_API_KEY`, `REVENUECAT_WEBHOOK_AUTH` and the RC REST URL
  from `functions/src/config.ts`; webhook/secret docs from `functions/README.md`
  and `FIREBASE_SETUP_GUIDE.md`. Backend now needs **one secret: `OPENAI_API_KEY`**.

**Changed**
- `purchase_provider.dart`: callable call → `_persistPremiumStatus()` writing
  directly to Firestore after the **on-device RevenueCat SDK entitlement check**;
  `FirebaseFunctions` dependency swapped for `FirestoreService`.
- `firestore_service.dart`: `updatePremiumStatus(bool)` restored (interface +
  impl) — writes `isPremium` + `subscriptionStatus` atomically.
- `firestore.rules`: premium fields now client-writable **with shape validation**
  (`isValidPremiumFields()`: bool, `'free'|'premium'` enum, premium⇒status
  consistency, 200 KB cap).
- `functions/src/usage.ts` + `merge.ts` + `index.ts` comments updated
  (trust model: profile flag is client-asserted; guests can't smuggle premium
  into a merged account).
- `AUDIT_REPORT.md`: §14 addendum records the change, the rationale, and the
  accepted trade-off (tampered builds could spoof the quota flag → bounded by
  the OpenAI dashboard budget cap).

**Premium flow now:** `purchases_flutter` SDK validates purchases/trial/restore
on-device → app mirrors entitlement to SharedPreferences + Firestore →
`aiProxy` reads the flag for unlimited quota. Deploy surface: **4 functions,
1 secret, no webhook**.

---

## 4. Complete File Inventory

### 4.1 New files
| File | Lines | Purpose |
|---|---|---|
| `functions/src/ai_proxy.ts` | 297 | Secure OpenAI proxy (SSE, auth, quota) |
| `functions/src/config.ts` | 38 | Region, limits, input caps, secret |
| `functions/src/index.ts` | 20 | Exports + admin init |
| `functions/src/lifecycle.ts` | 70 | onUserDeleted + anon cleanup cron |
| `functions/src/merge.ts` | 290 | Atomic idempotent account merge |
| `functions/src/usage.ts` | 117 | Transactional quota + idempotency |
| `functions/{package.json,tsconfig.json,.gitignore,README.md}` | — | Backend tooling + docs |
| `lib/core/models/chat_attachment.dart` | 25 | Composer attachment model |
| `AUDIT_REPORT.md` | 226 | Bug list, root causes, rationale |
| `CHANGE_HISTORY.md` | — | This document |

### 4.2 Modified files (33)
`.gitignore` · `FIREBASE_SETUP_GUIDE.md` · `firebase.json` · `firestore.rules` ·
`pubspec.yaml` / `pubspec.lock` · `lib/main.dart` ·
`lib/core/constants/{api_constants,app_icons,app_strings}.dart` ·
`lib/core/di/injection_container.dart` · `lib/core/models/chat_message.dart` ·
`lib/core/router/app_router.dart` ·
`lib/core/services/{ai_service,firestore_service,remote_config_service,usage_service}.dart` ·
`lib/core/widgets/chat_bubble.dart` ·
`lib/features/auth/presentation/pages/email_login_screen.dart` ·
`lib/features/auth/presentation/providers/purchase_provider.dart` ·
`lib/features/auth/presentation/widgets/auth_bottom_sheets.dart` ·
`lib/features/chat/{data/repositories/chat_repository_impl.dart,
domain/repositories/chat_repository.dart,
domain/usecases/process_chat_tag_usecase.dart,
domain/usecases/send_message_stream_usecase.dart,
presentation/pages/chat_screen.dart,
presentation/providers/chat_provider.dart}` ·
`lib/features/insights/data/repositories/insight_repository_impl.dart` ·
`lib/features/profile/presentation/providers/profile_provider.dart` ·
`lib/features/scanner/presentation/{pages/manual_barcode_screen.dart,
pages/super_scanner_screen.dart,providers/scanner_notifier.dart}` ·
`test/widget_test.dart`

### 4.3 Deleted
- `android/` — 38 files (Phase 2, committed)
- `functions/src/premium.ts` + build output (Phase 3)

---

## 5. PRD Compliance — Verified Section by Section

| PRD § | Requirement | State |
|---|---|---|
| §2 | Passive logging only — chat = automatic log | ✅ `[MEAL]/[SYMPTOM]/[SCAN]/[SWAPS]` tags parsed server-shaped into collections; no manual "add meal" UI |
| §2/§12 | Pattern language, never diagnosis | ✅ prompts mandate "Your history shows…/You reported…", forbid diagnose/cure/treat/condition |
| §3a | OpenAI purpose set (chat, vision, swaps, insights) | ✅ via `aiProxy` |
| §3d | **Never expose OpenAI key on device** | ✅ key removed; proxy holds it |
| §4 | Guest-first, 1–2 free uses, then signup wall | ✅ 2 chats + 2 scans for guests; wall copy exact |
| §5 | 8-step onboarding, multi-select, exact option lists, "Not sure yet", cycle-sync skip, "Ready to spill your gut tea?" | ✅ verified in code |
| §6.1 | ChatGPT-style chat + image upload + menu upload | ✅ Phase-1 rework |
| §6.2 | Scanner: score, flagged ingredients, personalized impact, swaps | ✅ OFF + OpenAI intelligence |
| §6.3 | Insights + "No clear pattern yet…" empty state | ✅ exact copy present |
| §8.2 | Insight triggers (3 scans / 1 meal / 1 symptom) + 24 h cooldown, else show saved | ✅ `insight_repository_impl.dart` |
| §9.2 | V1 notification copy (exact strings) | ✅ all strings present |
| §10 | $4.99/mo, 3-day trial, free 3–5 chats + 3 scans/day, paywall on limit + in chat | ✅ 5/3 limits, paywall |
| §13 | Firestore collections schema | ✅ `user_profiles` + subcollections per schema |
| §14 | Edge cases: OFF miss → OpenAI vision fallback; notifications respect toggle; guests forced signup | ✅ all verified |

---

## 6. Verification Record (final state)

| Check | Result |
|---|---|
| `flutter analyze` | ✅ **0 issues** |
| `flutter test` | ✅ **5/5 passed** (ChatMessage multi-image, clearLocalImages, error kinds) |
| `functions`: `tsc --noEmit` + `npm run build` | ✅ clean; 6 JS outputs |
| Firestore + Storage rules | ✅ validated in Firebase emulator (startup clean, 0 errors) |
| PRD sweep (§5 above) | ✅ all items pass |

## 7. Deployment (final, needs your Firebase credentials)

```bash
cd functions && npm install && npm run build
firebase functions:secrets:set OPENAI_API_KEY
firebase deploy --only functions,firestore:rules,storage
```

**Then in consoles:** enable App Check (Firestore/Storage/Functions); set an
OpenAI dashboard **budget alert** (PRD cost strategy); verify the RevenueCat
(iOS) offering `premium_offering` is live.
**Note:** chat will 404 until functions are deployed — by design (the old
insecure on-device path was removed).

## 8. Workspace / Environment Notes

- Flutter SDK lives at `/home/user/toolchain/flutter-sdk` (3.44.8). Workspace
  snapshots can't persist a full SDK, so `bash /home/user/toolchain/restore-sdk.sh`
  self-heals it (health-check → re-clone → re-download Dart binaries).
- `functions/node_modules` isn't persisted by snapshots either →
  `cd functions && npm ci` restores it.

---

*End of change history. Baseline → current = production-ready per PRD, pending
only the deploy + console steps above.*
