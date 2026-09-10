# Accepted Risks — Intentional Design Decisions

> **Status of every item below: ACCEPTED by the project owner (recorded 2026-09-10).**
> These are deliberate trade-offs, not oversights. Code comments and docs reference
> items here by ID (`R1`…`R9`). If you are reading a claim elsewhere that a control
> is "tamper-proof" or "server-enforced", this document supersedes it.
>
> Practical takeaway for new engineers: **treat the free-tier/quota system as a soft
> paywall, not a security boundary.** Do not build on the assumption that any user
> presenting `isPremium: true` actually paid.

---

## R1 — Client-authoritative premium status

**Decision:** Premium is determined on-device by the RevenueCat SDK and mirrored into
`user_profiles/{uid}.isPremium` / `subscriptionStatus` by the client. Firestore rules
intentionally allow the client to write these fields (`isValidPremiumFields()` only
checks type consistency). There is no server-side RevenueCat verification.
(A webhook-based verification existed and was deliberately removed — see
`docs/AI_AUDIT_AND_REFACTOR_PLAN.md`, P2-12 reversion notes.)

**Blast radius:** Any user can set `isPremium: true` on their own profile (one REST
call with their own ID token) → backend quota checks treat them as premium →
**unlimited AI usage (GPT-4o/4o-mini) billed to us**, and all premium features unlock.
Exploitation requires ~15 minutes of technical skill, no app tampering.

**Why accepted:** Client-side premium keeps the backend simple; pre-launch abuse is a
non-issue. The quota counters themselves (`daily_usage/*`) remain server-write-locked,
so non-premium users still see a functioning paywall inside the app UI.

**Revisit when:** Public launch, first observed abuse, or whenever OpenAI spend
anomalies appear in the `tokens_in`/`tokens_out` counters. Fix path: RevenueCat
webhook (with verified secret) → server-stamped entitlement; rules lock the fields.

---

## R2 — `timezoneOffset` accepted unvalidated

**Decision:** `aiProxy` and `usage.ts` accept the client-supplied numeric
`timezoneOffset` as-is and use it to derive the daily quota document key
(`daily_usage/{localDate}`). No range clamping is applied.

**Blast radius:** A crafted request with an extreme offset (e.g. `99999`) mints a
fresh quota document with a zero counter → daily limits are effectively refillable
without any Firestore access. Also overwrites the stored profile offset.

**Why accepted:** Keeps quota day-boundaries aligned to the user's real local day
without a server timezone database; abuse overlaps R1's simpter fix path.

**Revisit when:** Alongside R1. Fix path: clamp to ±840 minutes at the proxy edge and
in `todayKey`/`getLocalDate`.

---

## R3 — Profile-root delete resets guest lifetime quota

**Decision:** Firestore rules allow any user to `delete` their own `user_profiles/{uid}`
document. Anonymous guest lifetime counters (`chat_count_lifetime`,
`scan_count_lifetime`) live on that root document.

**Blast radius:** A guest can delete their profile doc, re-onboard, and receive a fresh
2-action lifetime allowance, repeatedly. (The server-locked `daily_usage/*`
subcollection survives doc deletion, but lifetime fields do not.)

**Why accepted:** Self-service data deletion is desired for privacy; guest-tier
abuse capped at 2 actions per cycle is low-value.

**Revisit when:** R1/R2 remediation, or if guest abuse is observed. Fix path: move
lifetime counters into the server-locked `counters/` subcollection, or remove the
client delete in favor of a callable.

---

## R4 — Android purchases disabled; debug payment logging in production

**Decision:** `_googleApiKey` in `purchase_service.dart` is intentionally empty →
RevenueCat is not configured on Android; purchases/restore silently no-op there
(errors are caught and logged). `Purchases.setLogLevel(LogLevel.debug)` runs
unconditionally, and the API key is written to app logs.

**Blast radius:** No revenue on Android (intended); verbose payment internals in
release logs.

**Why accepted:** iOS-first rollout; Android store integration deferred.

**Revisit when:** Android launch. Fix: inject per-platform keyed via build config,
treat empty key as a hard configuration error, gate `LogLevel.debug` behind
`kDebugMode`, stop logging the key.

---

## R5 — Magic-link endpoint has no rate limiting

**Decision:** `sendCustomMagicLink` (callable) requires no authentication and has no
per-email/per-IP throttling or App Check.

**Blast radius:** Anyone (any script — no app required) can trigger unlimited
GutGood-branded sign-in emails to arbitrary addresses through our SMTP account →
sender-reputation damage, potential spam-blacklisting.

**Why accepted:** Login flows must be callable pre-auth; simplicity during early
launch.

**Revisit when:** Public launch or first abuse. Fix path: per-email/IP counters
(e.g. 3/email/hour), App Check, email-format validation.

---

## R6 — Welcome-email trigger reads client-writable profile fields

**Decision:** `onProfileWritten` takes the recipient `email`, `displayName`
(unescaped in the HTML body), `isAnonymous`, and the `welcomeEmailSent` idempotency
flag from the client-writable profile document.

**Blast radius:** A user can send welcome emails branded as GutGood to third-party
addresses (set `email` to a victim), including injected HTML via `displayName`, and
re-trigger by toggling `welcomeEmailSent` — through our own SMTP.

**Why accepted:** Flow simplicity; bounded annoyance rather than data breach.

**Revisit when:** Public launch. Fix path: read the recipient from
`admin.auth().getUser(uid)` (server-trusted), HTML-escape `displayName`, rules-lock
the `welcomeEmailSent*` fields.

---

## R7 — No Firebase App Check

**Decision:** App Check is not enabled on Functions, Firestore, or Storage.

**Blast radius:** Any script can mint a Firebase ID token (the API key in
`google-services.json` / `GoogleService-Info.plist` is public-by-design) and call
`aiProxy`/callables directly — raising the ceiling on automated, multi-account
abuse of R1/R2/R3/R5.

**Why accepted:** Added integration complexity; compensating limits exist
(per-account quotas for the app-using majority).

**Revisit when:** Public launch, or concurrently with R1. Fix path: Play Integrity /
App Attest / DeviceCheck, then enforce on Functions + Firestore + Storage.

---

## R8 — `mergeAnonymousAccount` lacks proof of anonymous-account ownership

**Decision:** The callable verifies the caller is a permanent account and the source
is anonymous, but does not cryptographically verify the caller owned the anonymous
session; it accepts a caller-supplied `anonymousUid`.

**Blast radius:** Anyone who learns another guest's `anonymousUid` (leaks via
logs/analytics/device backups) can absorb that guest's data into their own account
and delete the guest account. Anonymous UIDs are high-entropy and not enumerable, so
practical exposure is low.

**Why accepted:** No low-friction possession-proof primitive exists in the
credential-conflict flow; risk-rated low.

**Revisit when:** Any reported account-takeover signal. Fix path: pre-switch marker
doc written by the anonymous session, or a short-lived custom claim.

---

## R9 — Health-adjacent data proxied to OpenAI

**Decision:** Meal photos, symptoms, and cycle data are sent through `aiProxy` to
OpenAI (minimized: compressed images, rolling summaries, no API key on-device).

**Blast radius:** Compliance/privacy exposure for health-adjacent personal data
(GDPR-sensitive category) rather than a technical exploit.

**Why accepted:** Core product functionality; OpenAI API terms in effect.

**Revisit when:** Before scaling/marketing claims. Fix path: confirm OpenAI
zero-retention/DPA terms, update privacy policy and consent copy.

---

## Minor accepted items (from the same audit)

| Item | Note |
|---|---|
| Storage `contentType` spoofable | Owner-only reads bound the impact; `generateFoodThumb` already decodes with `sharp`. |
| Secondary profile fields client-writable | `longestStreak`, `timezoneOffset`, `welcomeEmailSent`, `lastProcessedWarningTime` — cosmetic only. |
| Committed `google-services.json`/plist | Public-by-design Firebase client config; real security must come from rules (which this doc bounds). |
| No CI pipeline | 38 test files exist but nothing enforces them per-PR — add GitHub Actions when convenient. |

---

*Source findings: independent audit of commit `a3b7fd1` (see `GUTGOOD_AUDIT.md`),
re-classified as intentional/accepted by the project owner on 2026-09-10.*
