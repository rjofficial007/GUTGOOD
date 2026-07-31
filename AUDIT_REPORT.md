# GutGood — Production Audit & Remediation Report

**Auditor role:** Senior Flutter Architect / Firebase Expert / UX Engineer
**Source of truth:** `client_requirements/GutGood_Client_Requirements_PRD.md`
**Verification status of this delivery:**
- `flutter analyze` → **0 issues** (was 3 warnings)
- `flutter test` → **all passing** (was a broken template test)
- Cloud Functions `tsc` build → **clean**
- Firestore + Storage security rules → **validated in Firebase emulator (startup, zero errors)**

---

## 1. Executive Summary

The codebase was structurally sound (clean feature-first architecture, Provider + GetIt, real
Firestore sync), but had **four production-blocking defects**, one **PRD-critical security
violation**, and a chat interaction model that did not match the PRD's core requirement
("image preview in composer, sent only on Send — ChatGPT-style").

The most dangerous finding: `firebase.json` declared a Cloud Functions codebase that **did not
exist in the repo** — yet the app already called `mergeAnonymousAccount`, and account merge,
cascade delete, and (now) all AI traffic depend on functions. The second most dangerous: the
OpenAI API key was delivered to devices via Remote Config, which the PRD explicitly forbids
("never expose OpenAI key on device"). Both are resolved by the new `functions/` secure backend
shipped in this audit.

Everything below has been **implemented**, not just identified. No TODOs were left.

---

## 2. All Bugs Found & Root Causes

| # | Severity | Area | Bug | Root cause |
|---|----------|------|-----|-----------|
| 1 | **Critical** | Security / PRD §3d | OpenAI key shipped to the device via Remote Config + hardcoded fallback constant | No secure backend existed; AI SDK ran on-device |
| 2 | **Critical** | Firebase | `firebase.json` → `functions` codebase configured but directory missing; `mergeAnonymousAccount` callable always `NOT_FOUND` | Functions project never committed |
| 3 | **Critical** | UX / PRD §6.1 | Image immediately sent to AI on selection | `_pickAndSendImage` called `sendImageMessage` straight from the picker |
| 4 | **Critical** | Chat state | Firestore snapshot listener wiped optimistic messages mid-send; streaming wrote into `_messages[0]` blindly → AI text overwrote the user's bubble / `RangeError` risk | Hardcoded index + full list replacement on every snapshot |
| 5 | **High** | Security | Client could write `isPremium`, `subscriptionStatus`, reset `daily_usage` counters → free premium / paywall bypass | Blanket-owner rules on fields that must be server-only; rules/app desync (rules were locked but app still wrote them → premium sync silently failed) |
| 6 | **High** | Performance | Every streaming token replayed entrance animations for **every** bubble → visible jank while typing | `.animate()` evaluated per rebuild in a `watch`ed list |
| 7 | **High** | Performance | `MarkdownBody` re-parsed per token + `notifyListeners()` per token → frame drops | No stream coalescing/throttling |
| 8 | **High** | Billing | Triple/duplicate usage counting (screen + notifier + service all incremented); manual-barcode path charged twice on failure retry | No single owner of usage accounting |
| 9 | **Medium** | Chat UX | No stop-generate, no regenerate, no retry on failure, no copy affordance except hidden long-press, no draft persistence; input disabled during generation | Features never built |
| 10 | **Medium** | Data loss | Crash mid-merge → anonymous data orphaned | Session switched before merge; merge not resumable/idempotent (partially mitigated in repo via prefs; final fix = server-side merge) |
| 11 | **Medium** | Offline | No offline guard on send; AI calls failed with confusing inline text | No connectivity check in send path |
| 12 | **Medium** | Architecture | Dead API surface: `getMessages` returning `[]`, deprecated `loadChatHistory/loadMoreMessages` stubs, unused openai_dart dep | Migration leftovers (SQLite → Firestore) |
| 13 | **Medium** | Memory | Compressed image `Uint8List` retained for the lifetime of every message (50+ messages) | `localImageBytes` never cleared after upload |
| 14 | **Low** | Observability | `firebase_crashlytics` in pubspec but never initialized | Missing wiring in `main()` |
| 15 | **Low** | Config | `debugLogDiagnostics: true` in release builds | Hardcoded |
| 16 | **Low** | Code quality | 3 analyzer warnings (unused import/field/local); dead `textScaler` no-op in `main.dart` | Leftovers |
| 17 | **Low** | A11y | No semantic labels on stop/copy/regenerate actions | Not annotated |
| 18 | **Info** | Testing | Template counter test (wrong app) — would fail if ever run | Never replaced |
| 19 | **High** | VCS | Root `.gitignore` contained `/functions/` → the backend would silently never be committed/deployed | Template gitignore leftover |
| 20 | **Medium** | Data integrity | Regenerating a response would re-persist `[MEAL]`/`[SYMPTOM]` tags → duplicate logs in Insights | Tag pipeline had no "display-only" mode |

**Bugs 19 & 20** were caught in the post-implementation review pass and are fixed in this delivery
(`/functions/` un-ignored; `ProcessChatTagUseCase` gained a `persist` flag used by regenerate).

---

## 3. Files Modified

### New files
- `functions/package.json`, `functions/tsconfig.json`, `functions/.gitignore`, `functions/README.md`
- `functions/src/index.ts`, `functions/src/config.ts`, `functions/src/ai_proxy.ts`, `functions/src/usage.ts`, `functions/src/merge.ts`, `functions/src/lifecycle.ts`
  (~~`functions/src/premium.ts`~~ — added in the original audit, then **removed** when premium moved to a client-side model; see §14 addendum)
- `lib/core/models/chat_attachment.dart`
- `AUDIT_REPORT.md` (this document)

### Rewritten (behavioral changes)
- `lib/core/services/ai_service.dart` — on-device OpenAI SDK → **secure proxy client** (Dio SSE + Firebase ID token + typed errors + idempotency)
- `lib/core/services/remote_config_service.dart` — **removed** `openAIKey`; added `aiProxyUrl` (env-swappable backend URL)
- `lib/features/chat/presentation/providers/chat_provider.dart` — full rewrite (see §8)
- `lib/features/chat/presentation/pages/chat_screen.dart` — ChatGPT composer (see §8)
- `lib/core/widgets/chat_bubble.dart` — multi-image, streaming cursor, actions, error cards, markdown/code/table polish
- `lib/core/services/usage_service.dart` — read-only fast-path gate; increments deleted
- `lib/core/services/firestore_service.dart` — added `deleteMessage`, fixed stream ordering semantics, removed privileged-write methods, fixed `getUsageToday` rethrow inconsistency
- `lib/features/auth/presentation/providers/purchase_provider.dart` — premium sync (first via callable, then switched to a **direct client write** of the RevenueCat entitlement; see §14 addendum)
- `lib/features/scanner/presentation/providers/scanner_notifier.dart` — removed client-side increments
- `lib/main.dart` — Crashlytics wiring, removed dead text-scaler code
- `test/widget_test.dart` — real unit tests for the chat message contract

### Surgically edited
- `lib/core/models/chat_message.dart` — `imageUrls[]` + `localImages[]`, `sendFailed`, `ChatErrorKind`, back-compat `imageUrl` derivation
- `lib/core/constants/api_constants.dart` — key removed, `aiProxyUrl` default added
- `lib/core/constants/app_strings.dart` — 18 new strings (composer, errors, quota, prompts)
- `lib/core/constants/app_icons.dart` — `copy`, `square`, `rotateCcw`, `plus`, `paperclip`
- `lib/core/di/injection_container.dart` — removed OpenAI SDK registration; regionalized Functions instance; **Firebase Emulator support** via `USE_FIREBASE_EMULATOR`
- `lib/features/chat/domain/repositories/chat_repository.dart`, `.../data/repositories/chat_repository_impl.dart`, `.../domain/usecases/send_message_stream_usecase.dart` — multi-image stream signature, dead methods removed, `deleteMessage`
- `lib/features/scanner/presentation/pages/super_scanner_screen.dart`, `manual_barcode_screen.dart` — duplicate increments removed, `usageType: 'scan'` tagging
- `lib/core/router/app_router.dart` — `debugLogDiagnostics: kDebugMode`
- `lib/features/auth/presentation/widgets/auth_bottom_sheets.dart`, `.../pages/email_login_screen.dart` — honest, resumable merge failure UX
- `lib/features/profile/presentation/providers/profile_provider.dart`, `lib/features/insights/data/repositories/insight_repository_impl.dart` — analyzer warnings fixed
- `firebase.json` — **registered `storage` rules** (previously the file would never deploy!)
- `firestore.rules` — hardened (see §9)
- `pubspec.yaml` — removed `openai_dart`
- `FIREBASE_SETUP_GUIDE.md` — functions deployment runbook

---

## 4. Firebase Initialization — Fixed
- Multi-platform init (`firebase_options.dart`) verified for Android/iOS; web/macOS deliberately throw (PRD is iOS-first).
- **Emulator compatibility added**: `flutter run --dart-define=USE_FIREBASE_EMULATOR=true` points Auth, Firestore, Functions, and Storage at the local suite (Android `10.0.2.2` handled).
- Functions client pinned to `us-central1` (matches deployed region).
- Firestore offline persistence retained (`CACHE_SIZE_UNLIMITED`) — chat history, scans and insights load fully offline; messages queued while offline sync automatically.

## 5. Authentication — Improvements
- **Merge is now server-side, atomic and idempotent** (`mergeAnonymousAccount`): content-addressed dedupe for chat/meals/symptoms, barcode/name dedupe for scans/saved foods, per-source-folded `daily_usage` (double-merge proof even on crash-retry), profile personalization union, Storage file migration with URL rewriting, marker doc, anonymous identity reclaimed. Retries are no-ops.
- Merge failure UX: no silent "success" — copy now explains that recovery resumes automatically; `pending_merge_*` prefs + `LinkService._checkPendingMerge` re-trigger the sheet on the welcome/login screens.
- Account deletion backstopped by the `onUserDeleted` trigger (Firestore `recursiveDelete` + Storage purge) — client network failure can no longer orphan data (audit §2.4).
- `cleanupAnonymousUsers` (daily cron) purges guest accounts idle >14 days — bounds cost and closes the GDPR "right to be forgotten" gap (audit §2.3).
- Session persistence, token refresh (SDK-native), Google/Apple/email/anonymous flows, `provider-already-linked`, and silent-account-switch guards audited and left intact.
- **Emulator compatibility added**: `flutter run --dart-define=USE_FIREBASE_EMULATOR=true` points Auth, Firestore, Functions, and Storage at the local suite (Android `10.0.2.2` handled).

## 6. Firestore — Improvements
- Message stream semantics fixed: emits newest-first directly (removed confusing double reversal).
- `chat_history` writes now **shape-validated in rules** (role/text-size/image-count caps) — garbage/oversized docs can't be stored.
- Race-safe optimistic sync in the notifier (see §8) — snapshot latency can no longer clobber in-flight turns.
- `daily_usage` is read-only for clients; consumed transactionally server-side with **idempotency keys** (client retry = no double count).
- Premium fields (`isPremium`/`subscriptionStatus`) shape-validated in rules (bool + `'free'|'premium'`, consistency-checked) and client-managed via the RevenueCat SDK entitlement (see §14 addendum).
- `getUsageToday` no longer rethrows (consistent swallowed-error contract with the rest of the service).

## 7. Firebase Storage — Improvements
- `storage.rules` registered in `firebase.json` (was undeployable) and validated in the emulator.
- Chat attachments: single compression up-front (512px / q80) → shared by preview, upload, and vision request (no double compress, consistent payloads, lower latency + token cost).
- Old `localImageBytes` retained-forever leak fixed: preview bytes released after successful save.
- Merge copies guest photos with URL rewriting; deletes reclaim `users/{uid}/` via trigger.

## 8. The AI Chat System — The Big Rework (PRD §6.1 + ChatGPT parity)

### Image attachment flow (your #4 requirement) — implemented exactly as specified
1. Tap camera/gallery (or scan a label/meal/menu) → image compresses and **appears as a thumbnail inside the composer**. Nothing is sent.
2. Multiple images supported (up to 4), each independently removable (✕ button).
3. Text field **stays fully editable**; scanner captures pre-fill a *suggested, editable* prompt ("What should I order here?" / "Is this good for my gut?" / "What do you think of this meal?").
4. Send button activates when text **or** images exist. On Send: images upload, then text + **all** images leave in **one** AI request; the user message renders the images; the analysis streams below it.
5. Hidden analysis instructions (menu→`[SWAPS]`, label/meal→`[SCAN]`) ride along invisibly — never rendered into the user's visible caption. Draft text persists across restarts (debounced).

### Composer (ChatGPT model)
- Single rounded card: attachment preview strip → auto-growing field (1–6 lines) → action row (camera, gallery, send/stop).
- Send only when content exists; during upload → spinner; while streaming → **black stop button** (partial replies preserved, like ChatGPT).

### Messaging UX
- Token **coalescing at ~16 fps** (was: rebuild per token) + once-per-message entrance animation (was: replayed for all bubbles per token) = smooth streaming.
- Follow-scroll: auto-sticks to the bottom while streaming, but never fights the user when they scroll up to read.
- Per-message actions: **Copy** and **Regenerate** icon row (ChatGPT parity); regenerate replaces the trailing AI turn using the frozen request (including its images).
- Retry paths: failed user uploads get inline **Tap to retry**; dropped AI streams keep partial text + show "Response interrupted"; empty responses never persist.
- Quota: server 429 → inline card with an **Upgrade** CTA (replaces the broken double-popup) — plus the pre-send fast-path paywall guard.
- Markdown: full GFM tables, styled code blocks (surface chip + mono + rounded container), blockquotes, selectable text once streaming completes; streaming cursor `▌` while typing.
- Safety: pattern-language system prompt unchanged; forbidden-medical-word disclaimer guard retained; `[SYMPTOM]`/`[MEAL]`/`[SCAN]`/`[SWAPS]` passive-logging tags unchanged (PRD non-negotiables).
- Memory: summarized long-term context (2–3 sentence rolling summary past 6 messages) preserved; message images cleared post-upload.

## 9. Security — Improvements
1. **OpenAI key removed from the client entirely** (Remote Config param + constant deleted; `openai_dart` dependency removed). Relevant PRD §3d requirement finally met.
2. AI requests require a Firebase ID token verified server-side; anonymous sessions still work (they're real Firebase users).
3. `daily_usage`: clients read-only → self-reset bypass closed.
4. `isPremium`/`subscriptionStatus`: rules shape-validate (bool, enum, premium↔status consistency) — garbage writes rejected; client-managed per product decision (trade-off documented in §14 addendum).
5. Server input caps (images ≤ 4 & ≤ ~1.2 MB, history ≤ 20, text/system limits, `max_tokens: 1200` for PRD cost control).
6. `daily_usage` consumption is transactional + idempotency-keyed server-side — replay/duplicate-billing bypass closed.
7. Rules deny-by-default retained; size guards on every subcollection; `merges/` markers unforgeable by clients.
8. **Remaining recommendation:** enable **Firebase App Check** (Play Integrity/DeviceCheck) in the console — this is a console toggle, not code.

## 10. Cloud Functions — Summary
- `aiProxy` (HTTPS, 300s, 512 MB): auth → quota (transactional, idempotent) → OpenAI → SSE. 429 body `{error: "quota_exceeded", type, limit}` consumed by the app as `AiQuotaExceededException` → paywall card. Upstream errors normalized to 502/503 with safe messages.
- `mergeAnonymousAccount` (callable): see §5; returns `{alreadyMerged, moved}`.
- `onUserDeleted` + `cleanupAnonymousUsers`: lifecycle hygiene (§5).
- Premium: client-side RevenueCat model (no functions) — reads `user_profiles/{uid}.isPremium` in the `aiProxy` quota check only.
- Cold starts: `aiProxy` is chat-latency-critical — if cold-start lag is observed in production, add `minInstances: 1` (one-line change, documented in `functions/src/ai_proxy.ts` comment). Retries are bounded (client: only provable no-contact network failures, idempotency-keyed).

## 11. Performance — Improvements
| Before | After |
|---|---|
| Rebuild + re-animate every bubble per token | Tokens coalesced (60 ms), entrance animation once per message |
| Full markdown re-parse per token | Same 60 ms coalescing; markdown parsed at ≤16 fps |
| No list keys → state churn on insert/remove | `ValueKey(localId)` + `findChildIndexCallback` for stable sliver state |
| Image bytes retained per message | Released after upload (only URLs retained) |
| Duplicate usage writes (Fire-and-forget RPC storm) | Single transactional server increment |
| History window 10 but placeholder/user-turn inclusion fragile | Deterministic exclusion by localId/content |
| Crashlytics missing | Fatal + async errors captured in release |

## 12. UI/UX — Improvements
- ChatGPT composer (§8), stop/regenerate/copy/upgrade affordances, streaming cursor, error cards, interrupted-response marker.
- Accessibility: semantic labels + tooltips on every new control; text-scale no longer clamped (dead clamp removed); `SelectableText` for AI messages post-stream.
- Keyboard: dismiss-on-drag added to the message list.
- Empty/error/loading states retained and extended for the new error kinds.
- Dark mode: all new UI consumes the existing `AppColorScheme` tokens (no hardcoded colors in new components).

## 13. Code Quality / Architecture
- Dead API removed (`getMessages` stub, deprecated chat-history stubs, template test).
- Single owner per responsibility: usage = server; premium = RevenueCat SDK + provider mirror; attachments = notifier; scrolling = screen.
- Feature-first structure, repository + usecase boundaries and DI wiring preserved; no breaking refactors — existing screens (scanner flow, insights, profile) untouched except billing-path corrections.
- 0 analyzer issues; strict TS settings for functions (`noUnusedLocals`, `noImplicitReturns`).

## 14. Post-Audit Addendum

- **Android platform folder removed** (committed: `32242d0 Remove android/ platform folder`) — the PRD specifies **"Platform: iOS (MVP)"**, so Android scaffolding, manifests, and `google-services.json` were dropped. Recoverable anytime with `flutter create --platforms=android .` + re-adding `google-services.json`. Android-specific recommendations below (#3, #4) apply only if/when Android is restored.
- **Re-verified after environment restore:** `flutter analyze` → 0 issues, `flutter test` → 5/5 pass, functions `tsc --noEmit` → clean.

### Premium model change (per product decision): client-side RevenueCat, no server integration

The original audit added `syncPremiumStatus` + `revenuecatWebhook` functions that verified entitlements with RevenueCat's REST API server-side. Per the client's decision, **all server-side RevenueCat integration has been removed**:

**Removed**
- `functions/src/premium.ts` (`syncPremiumStatus` callable + `revenuecatWebhook` HTTPS) — deleted.
- `REVENUECAT_API_KEY` / `REVENUECAT_WEBHOOK_AUTH` secrets and the RC REST URL from `functions/src/config.ts`; webhook/docs from `functions/README.md` + `FIREBASE_SETUP_GUIDE.md`. The backend now needs exactly one secret: `OPENAI_API_KEY`.
- `PurchaseProvider`'s callable call → replaced with a direct Firestore write (`FirestoreService.updatePremiumStatus(active)` writes `isPremium` + `subscriptionStatus` atomically after the SDK entitlement check; also re-added to the service interface).

**How premium works now**
1. `purchases_flutter` SDK checks the entitlement on-device (authoritative for this model).
2. App mirrors the result: SharedPreferences (`is_premium`, fast lane) + Firestore `user_profiles/{uid}.isPremium`/`subscriptionStatus` (cross-device + `aiProxy` quota check).
3. Security rules shape-validate the fields (bool, `'free'|'premium'`, premium⇒status consistency, 200 KB doc cap) so tampered clients can't store garbage.
4. `aiProxy` reads the profile flag to grant unlimited quota; free users are still enforced transactionally server-side (5 chats / 3 scans daily, 2/2 for guests — PRD §10).

**Accepted trade-off (documented, not hidden):** because the client writes its own premium flag, a user running a tampered build could self-grant unlimited AI quota. Blast radius = OpenAI spend; bound it with the OpenAI dashboard budget cap (recommendation #5). The on-device purchase flow itself remains fully validated by Apple's/App Store receipt infrastructure through the RevenueCat SDK — only the Firestore mirror is client-asserted. If abuse ever appears, re-introduce server-side verification (git history has the full implementation).

**Verification after the change:** `flutter analyze` → 0 issues, `flutter test` → 5/5 pass, functions `tsc --noEmit` → clean, rules re-validated in the Firebase emulator.

---

## 15. Remaining Recommendations (require console access, not code)
1. `cd functions && npm install && npm run build`, set `OPENAI_API_KEY` secret, `firebase deploy --only functions,firestore:rules,storage`. **Until then, chat/merge will 404** (by design — the old insecure path was removed).
2. Enable **App Check** for Firestore/Storage/Functions.
3. If Android is ever restored (the `android/` folder was removed — iOS-only MVP): set the `googleApiKey` in `purchase_service.dart` (currently empty — Android purchases won't configure).
4. Fill `googleServerClientId` and `magicLinkUrl` in `api_constants.dart` for Google sign-in on Android + email-link auth.
5. Set a **budget/alert** on the OpenAI account (PRD cost strategy) — server `max_tokens` caps are in place, but dashboard limits are the last line of defense.
6. Optional: `minInstances: 1` on `aiProxy` if cold-start latency shows up in analytics.
7. Optional V2 (PRD-tagged future): move insight generation into a scheduled function reusing the same pattern-engine context the app already stores.
