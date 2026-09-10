# GutGood — Code Review & Security Audit

**Scope:** Flutter client (~45k LOC, 289 Dart files), Cloud Functions backend (~2.2k LOC TypeScript), Firestore/Storage security rules, tests, docs.
**Method:** Manual review of all backend source + security rules; targeted review of auth, payments, AI service, DI, and state layers on the client; `tsc --noEmit` on functions (✅ clean). No Flutter SDK in this environment, so `flutter analyze`/`flutter test` were not executed — the Dart review is manual.

---

## Executive Summary

GutGood is an **unusually well-engineered pre-launch Flutter app**: genuine Clean Architecture, a thoughtful AI proxy with idempotent quota accounting and fair refunds, validated AI-output parsing, 38 test files, and a culture of written audits (`docs/KNOWN_ISSUES.md`). The TypeScript backend compiles cleanly and the security-rules file is far above average (default-deny, per-user ownership, size caps, schema validation).

However, the audit found **three independently exploitable bypasses of the free-tier/paywall system** (which burn your OpenAI budget and let anyone use premium free), plus **one bug that silently disables purchases on Android**, and several medium-severity abuse vectors in the email and account flows. All have concrete fixes below.

| Area | Score | Verdict |
|---|---|---|
| Architecture & code organization | ★★★★½ | Excellent feature-first Clean Architecture, DI, docs |
| Backend (Functions) quality | ★★★★½ | Idempotent, transactional, fail-closed; 2 input-validation gaps |
| Security rules & authorization | ★★½☆☆ | Good baseline, but premium flag + profile delete undermine it |
| Client code quality | ★★★★☆ | Consistent patterns; some god-widgets, debug leftovers |
| Testing | ★★★★☆ | 38 targeted test files; **no CI to enforce them** |
| AI safety / cost engineering | ★★★★½ | Validators, confidence gates, token accounting, model allowlist |

---

## 🔴 Critical Findings

### C1. Users can grant themselves "premium" — full paywall & quota bypass

**Files:** `firestore.rules` (lines 24–33, 100–111), `functions/src/usage.ts` (`isPremiumUser`), `functions/src/config.ts`, `lib/core/services/firestore/auth_firestore_service.dart:98–102`

**The chain:**
1. The backend's premium check, used by `aiProxy` before every AI call, trusts the profile document:
   ```ts
   // usage.ts
   export async function isPremiumUser(uid) {
     const data = (await admin.firestore().doc(`user_profiles/${uid}`).get()).data() ?? {};
     if (data.isPremium === true) return true;
     return (data.subscriptionStatus ?? 'free').toString() !== 'free';
   }
   ```
2. The security rules **allow any client to write those exact fields** on their own profile. The only validation is mutual consistency:
   ```js
   function isValidPremiumFields() {
     let premium = request.resource.data.get('isPremium', false);
     let status = request.resource.data.get('subscriptionStatus', 'free');
     return premium is bool && status in ['free', 'premium']
       && (premium == false || status == 'premium');   // ← true/'premium' passes
   }
   ```
   The `update` rule pins `streak`, `gutScore`, `lastActivityDate` — but **not** `isPremium`/`subscriptionStatus`.
3. Firestore is reachable directly (Fire-and-forget REST call with the user's own ID token — mintable via the public `google-services.json` API key). No tampered app binary needed:
   ```bash
   curl -X PATCH \
     "https://firestore.googleapis.com/v1/projects/gutgood-app-9242d/databases/(default)/documents/user_profiles/$UID" \
     -H "Authorization: Bearer $MY_ID_TOKEN" \
     -d '{"fields":{"isPremium":{"booleanValue":true},"subscriptionStatus":{"stringValue":"premium"}}}'
   ```
4. Result: `checkAndConsume` short-circuits (`limit: Number.MAX_SAFE_INTEGER`) → **unlimited GPT-4o/4o-mini usage at your expense**, and all client paywall UI reads premium state.

**Why this slipped through:** the codebase *knows* this field is server-sensitive — `merge.ts` refuses to copy it during merges ("a guest could smuggle a premium flag"), and `usage_service.dart` comments "the security rules reserve that field for the server." **The rules don't.** The comment in `ai_service.dart` claiming the server-side gate "removes the client-tampering vector" is therefore currently false.

**Fix (both parts required):**

1. Lock the fields in `firestore.rules`:
   ```js
   function premiumFieldsUntouched() {
     return request.resource.data.get('isPremium', false) == resource.data.get('isPremium', false)
       && request.resource.data.get('subscriptionStatus', 'free') == resource.data.get('subscriptionStatus', 'free');
   }
   // create: … && request.resource.data.get('isPremium', false) == false
   //        && request.resource.data.get('subscriptionStatus', 'free') == 'free'
   // update: … && premiumFieldsUntouched()
   ```
2. Establish a **server-trusted premium source**: enable the [RevenueCat webhook integration](https://www.revenuecat.com/docs/integrations/webhooks) → Cloud Function that verifies the webhook auth header and writes `isPremium`/`subscriptionStatus` with the Admin SDK, keyed by `appUserID == uid`. The client keeps listening to `CustomerInfo` for instant UI, but the Firestore copy becomes server-mirrored. Interim cheaper option: a callable that re-verifies the latest receipt/entitlement via the RevenueCat REST API before flipping the flag.

---

### C2. `timezoneOffset` is unvalidated — trivial daily-quota reset

**Files:** `functions/src/ai_proxy.ts` (line ~192), `functions/src/usage.ts` (`todayKey`, `getLocalDate`)

`aiProxy` accepts an arbitrary numeric `timezoneOffset` from the request body and uses it raw to build the daily-quota document key:

```ts
const timezoneOffset = Number(body.timezoneOffset ?? 0);          // ai_proxy.ts — no range check
// usage.ts
const localTime = new Date(now.getTime() + (offset * 60000));
return localTime.toISOString().slice(0, 10);                      // = quota doc id
```

A free user (5 chats/day) can send `timezoneOffset: 99999` and instantly mint a fresh `daily_usage/{far-future-date}` document → counter starts at 0 → quota refilled. Repeat with any offset → **unlimited daily quota**, no Firestore access needed, just one crafted HTTPS call with their own ID token. (Side effect: the request also *overwrites* `userData.timezoneOffset` in the profile, since aiProxy persists any changed offset.)

**Fix** — clamp at the edge, in both `ai_proxy.ts` and `usage.ts`:
```ts
const offsetRaw = Number(body.timezoneOffset ?? 0);
const timezoneOffset = Number.isFinite(offsetRaw)
  ? Math.max(-840, Math.min(840, Math.trunc(offsetRaw)))   // real offsets: UTC−14 … UTC+14
  : 0;
```
(Testing note: legitimate-day-boundary hopping between extreme zones yields at most ±1 day — bounded and acceptable.)

---

### C3. Anonymous users reset their lifetime guest quota by deleting their profile doc

**Files:** `firestore.rules` (`allow delete: if isOwner(userId)` on `user_profiles/{userId}`), `functions/src/usage.ts` (`${field}_lifetime` counters stored on the profile root)

Guests are limited to **2 lifetime actions** before signup (PRD §4), enforced via `chat_count_lifetime` / `scan_count_lifetime` fields kept **on the profile root document**. But the rules let any user delete their own profile doc:

```js
allow delete: if isOwner(userId);   // user_profiles/{userId}
```

Deleting the root doc destroys the lifetime counters (the `daily_usage` *subcollection* survives, but lifetime fields are not there). The guest re-runs onboarding → fresh 2 actions → repeat forever. Scriptable with two REST calls.

**Fix (minimal):** move the lifetime counters to a server-only subcollection, e.g. `user_profiles/{uid}/counters/lifetime` (rules already `write: if false` for `counters/`), updated by `usage.ts` with `FieldValue.increment`. Alternatively remove `allow delete` on the profile root and route self-service deletion through a callable (the `onUserDeleted` trigger already exists as the cleanup engine).

---

## 🟠 High (functional / revenue)

### H1. Android purchases are dead — RevenueCat Google key is empty

**File:** `lib/core/services/purchase_service.dart:33–34`

```dart
static const String _googleApiKey = '';                                  // ← empty
static const String _appleApiKey = 'appl_NQQoVWhHEKFUOXvpiOFeDCBezCm';
```
`Purchases.configure('')` on Android means offerings fetch, purchases, restore and entitlement checks all fail silently (errors are caught and only logged) → **zero revenue on Android** with no user-facing error. Fix: inject per-platform keys via `--dart-define`/build config (they're public SDK keys — embedding is fine), and treat a missing key as a hard configuration error in release builds instead of a swallowed log line.

### H2. RevenueCat debug logging in production + key logged

**File:** `lib/core/services/purchase_service.dart:40–42`

```dart
await Purchases.setLogLevel(LogLevel.debug);                       // always on
AppLogger.payments('Configuring with API Key: $apiKey');           // key into logs
```
Debug-level RC logs are verbose and leak purchase internals into production logcat/Crashlytics-adjacent streams. Gate with `kDebugMode`. (The `printAllOfferings` dump has the same issue.)

---

## 🟡 Medium

### M1. Unauthenticated magic-link endpoint is an open email relay
**File:** `functions/src/auth.ts`
`sendCustomMagicLink` needs no auth and has **no rate limiting** — anyone (script, not even an app) can call it in a loop and flood arbitrary mailboxes through your SMTP with GutGood-branded sign-in links, destroying sender reputation. Fix: per-email and per-IP throttling (e.g. a Firestore counter: max 3/email/hour, 20/IP/hour), require **App Check**, validate email format.

### M2. Welcome-email trigger can mail arbitrary third parties (with HTML injection)
**Files:** `functions/src/lifecycle.ts` (`onProfileWritten`), `functions/src/email.ts`, `firestore.rules`
The trigger reads `email`, `displayName`, `isAnonymous`, `welcomeEmailSent` from the **client-writable** profile doc. A user can (a) set `email` to a victim's address, (b) put HTML in `displayName` (interpolated unescaped into the email body), (c) flip `welcomeEmailSent` back to false and re-trigger an update → repeated branded emails to anyone through your SMTP. Fix: take the recipient from `admin.auth().getUser(uid).email` (server-trusted), HTML-escape `displayName`, and pin `welcomeEmailSent*` in rules like `premiumFieldsUntouched()`.

### M3. No Firebase App Check anywhere
AI proxy, callable functions, Firestore, and Storage accept any request bearing a mintable Firebase ID token. Combined with unlimited account creation, an abuser can farm free tiers across many accounts even after C1–C3 are fixed. Enable App Check (Play Integrity / App Attest / DeviceCheck) with enforcement on Functions + Firestore + Storage.

### M4. `mergeAnonymousAccount` trusts caller-supplied `anonymousUid`
**File:** `functions/src/merge.ts`
The function verifies the *caller* is permanent and the *source* is anonymous — but never that the caller owns the source. Anyone who learns an anonymous UID (leaks via logs/analytics/backups) can absorb that user's data **and delete the account**. Anon UIDs are unguessable at scale, so practical risk is low, but harden with a proof-of-possession step (e.g. require a short-lived custom claim or a marker doc written by the anon session before the session switch — the client already persists `pending_merge_anon_uid`).

### M5. Health data flows to OpenAI — compliance posture needs a decision
Meal photos, symptoms, and menstrual-cycle data are proxied to OpenAI. The proxy does good minimization (compressed images, rolling summaries, no key exposure), but you should confirm: OpenAI API zero-retention/DPA terms, privacy policy disclosure, and GDPR consent copy in-app, given the sensitivity class of this data (health-adjacent).

---

## 🟢 Low / hardening / hygiene

| # | Finding | Where | Recommendation |
|---|---|---|---|
| L1 | Storage rules trust client-supplied `contentType` (`image/.*` is spoofable) | `storage.rules` | Bounded by owner-only reads; optionally verify server-side (`generateFoodThumb` already decodes with `sharp` — reject non-images there) |
| L2 | Only `streak`/`gutScore`/`lastActivityDate` are pinned on profile update; `longestStreak`, `timezoneOffset`, `welcomeEmailSent`, `lastProcessedWarningTime` etc. remain client-writable | `firestore.rules` | Pin all server-authoritative fields with an `untouchedFields()` helper |
| L3 | God-widgets: `scan_result_widgets.dart` (1,776 LOC), `chat_screen.dart` (1,202), `chat_composer_notifier.dart` (1,186) | `lib/features/**` | Split by responsibility; improves reviewability and test reach |
| L4 | `.artifacts/` (23 agent plan dirs) and the 746 KB `GUTGOOD_SCREENS.html` are committed | repo root | Add to `.gitignore`; move mockup to `docs/` or a design repo |
| L5 | No CI (`.github/` absent) | repo | GitHub Actions: `flutter analyze`, `flutter test`, `tsc` — you have 38 test files nothing enforces |
| L6 | `image_picker`/`image` compression runs synchronously on the UI isolate | `StorageService` (already in your tech-debt list) | Move to an isolate — confirmed finding, keep on roadmap |
| L7 | `SCHEDULE_EXACT_ALARM`/`USE_EXACT_ALARM` permissions need Play-console justification | `AndroidManifest.xml` | Prepare the declaration, or downgrade to inexact reminders |
| L8 | `functions` engines say Node 22; CI/dev boxes on Node 20 build fine but emit warnings | `functions/package.json` | Pin with `.nvmrc` / `mise` to avoid "works on my machine" drift |

---

## ✅ What you're doing right (worth calling out)

- **`aiProxy` is genuinely well built:** key in Secret Manager only, Firebase-token auth, model allowlist (client can't dial up cost), transactional quotas with idempotency keys, **credit refunds when OpenAI fails**, token accounting per user, fail-closed on quota-check errors (except premium fail-open — deliberate), middle-out truncation with client-visible reporting, SSE with usage frames.
- **Merge flow is correct by design:** server-side `mergeAnonymousAccount` with idempotency markers, natural-key dedupe, storage-URL rewriting, legacy-collection consolidation, and — tellingly — an explicit *"NEVER copy isPremium"* guard. (C1 closes the hole this guard can't.)
- **AI output hygiene:** `AiResponseValidator` with verdict/confidence gating, schema versioning, non-food degradation to chat-only, JSON auto-repair, prompt-vocabulary regression tests.
- **Rules hygiene:** default-deny, per-user ownership, doc size caps, chat-message schema validation, server-only `daily_usage`/`counters`/`merges`.
- **Client hygiene:** zero `print()` in `lib/`, every debug backdoor (`setPremiumForTesting`, `resetLimitsForTesting`) gated behind `kDebugMode`, strict custom lint set, crash-reporting abstraction, 38 test files including widget tests and scoring regressions.
- **`tsc --noEmit` passes clean** on the functions backend.

---

## Recommended remediation order

1. **C1** rules fix (10 min, hot-deployable) → **C2** offset clamp → **C3** `counters/lifetime` move — these directly stop OpenAI-budget bleed.
2. **H1** Android RevenueCat key — restores the entire Android revenue path.
3. **M3** App Check + **M1** magic-link throttling — raises the cost of scripted abuse.
4. **M2** welcome-email hardening — protects SMTP reputation.
5. Low items as part of normal sprint hygiene; add **CI (L5)** so `flutter analyze`/`test` and `tsc` run per-PR.

---

## Disposition — 2026-09-10

**The project owner reviewed every finding and classified them ALL as intentional design decisions; no code fixes were requested or applied.** The findings have been re-registered as accepted risks in the repository, with blast radii and revisit triggers documented there:

| Audit item | Registered as |
|---|---|
| C1 self-grantable premium | R1 |
| C2 unvalidated `timezoneOffset` | R2 |
| C3 guest lifetime-quota reset via profile delete | R3 |
| H1/H2 Android purchases disabled, debug payment logging | R4 |
| M1 magic-link email relay | R5 |
| M2 welcome-email third-party/HTML injection | R6 |
| M3 no App Check | R7 |
| M4 merge caller-supplied `anonymousUid` | R8 |
| M5 health data to OpenAI | R9 |
| Low items | "Minor accepted items" table |

See **`GUTGOOD/docs/ACCEPTED_RISKS.md`** for the canonical register. Code comments and
docs that previously claimed "tamper-proof"/"server-enforced" behavior were corrected on
2026-09-10 to match this disposition (`ai_service.dart`, `usage_service.dart`,
`auth_firestore_service.dart`, `purchase_service.dart`, `firestore.rules`,
`ai_proxy.ts`, `usage.ts`, `auth.ts`, `lifecycle.ts`, `merge.ts`, `config.ts`, `index.ts`,
`email.ts`, `README.md`, `KNOWN_ISSUES.md`, `FIRESTORE_SCHEMA.md`, `PROJECT_OVERVIEW.md`,
`CODEBASE_MAP.md`, `FIREBASE_ARCHITECTURE.md`, `AI_AUDIT_AND_REFACTOR_PLAN.md`).

*Report generated 2026-09-09. All findings verified against commit `a3b7fd1`.*
