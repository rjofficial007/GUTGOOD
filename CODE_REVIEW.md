# GutGood — Independent Code Review

**Reviewer:** Independent code review (Flutter + Firebase + Node)
**Scope:** Whole codebase — Flutter app (`lib/`), Cloud Functions (`functions/`), Firebase config/rules, docs.
**Date:** 2026-08-02
**Repo state audited:** commit `c70b0b7` ("feat: establish centralized design system and type-safe navigation")

> Note on the existing `AUDIT_REPORT.md`: it is a thorough self-report by whoever shipped the secure-proxy migration. I treated its claims as *hypotheses to verify*, not facts. Below I mark which claims held up and, more importantly, what it **missed**.

---

## TL;DR — Verdict

This is a **high-quality, production-shaped codebase**. The Clean-Architecture layout, the race-free optimistic chat, the server-side merge, and the "remove the OpenAI key from the device" migration are all genuinely well done. I independently compiled the Cloud Functions — **`tsc --noEmit` passes clean**, confirming the audit's build claim.

**But the headline security/cost story is not as airtight as the docs claim.** The single most important finding:

> **🔴 CRITICAL — The free-tier quota is bypassable, and the app's core feature (scanning) is effectively unmetered.** The server only meters requests tagged `usageType === 'chat' | 'scan'`. Every `generateContent` call (barcode scans, vision/label scans, insights) is sent with the **default `usageType: 'system'`**, which the server **never gates**. So the "3 scans/day" limit does not exist for the real scanner flow, and any client (including a freshly-created anonymous account, which needs no credentials) can get unlimited OpenAI completions by sending `usageType: 'system'`.

This directly contradicts the code comments (`scanner_notifier.dart`: *"the AI call itself is counted server-side by the aiProxy (type = 'scan')"*) and the audit's "tamper-proof server-side enforcement" claim.

Details and fixes below.

---

## 1. Findings NOT in the existing audit (the value-add)

### 🔴 F1 — Server quota gate only covers `chat`/`scan`; `system` (and anything else) is unmetered · **CRITICAL**

**Where**
- `functions/src/ai_proxy.ts:150-160`
  ```ts
  const usageType = body.usageType ?? (images.length > 0 ? 'scan' : 'chat');
  if (usageType === 'chat' || usageType === 'scan') {   // <-- the ONLY gate
     await checkAndConsume(...);
  }
  ```
- `lib/core/services/ai_service.dart:200` — `generateContent(..., String usageType = 'system')`

**Impact**
- Any authenticated caller (anonymous auth is trivially creatable — no email, no password) can send `usageType: 'system'` (or `'anything'`) and **bypass the free-tier gate entirely**. `max_tokens: 1200` is the only throttle, and there is **no rate limiting and no App Check**. This is a direct, cheap OpenAI-cost-exposure / abuse vector.
- It's not just a theoretical tampering path — the **legitimate app** already exercises it (see F2).

**Fix (server, defense in depth)**
1. Treat `usageType` as an enum and reject unknown values:
   ```ts
   const usageType = (body.usageType ?? (images.length > 0 ? 'scan' : 'chat')).toString();
   if (!['chat','scan','system'].includes(usageType)) {
     return fail(res, 400, 'invalid_argument', { message: 'Bad usageType.' });
   }
   ```
2. **Meter `system` too**, but with its own (generous) budget — e.g. fold summarize/insight into a separate `system_count` against a higher daily cap, or simply count it as `chat`. Background insights + summaries should not be free for a tampered client.
3. **Fail-closed**, not fail-open (see F3).
4. Enable **App Check** (already a documented recommendation) so anonymous-account farming is harder.

---

### 🔴 F2 — The primary Scanner flow (barcode + vision) is unmetered; the 3-scans/day limit is dead · **CRITICAL**

The `usageType` bug above has a concrete, in-app victim: **scanning**. `generateContent` defaults to `'system'`, and the two real scanner entry points don't override it:

| Caller | File:line | `usageType` sent | Metered? |
|---|---|---|---|
| Barcode scan (Scanner screen) | `scanner_repository_impl.dart:57` | *(default)* `'system'` | ❌ **No** |
| Vision/label/meal scan (Scanner screen) | `scanner_repository_impl.dart:75` | *(default)* `'system'` | ❌ **No** |
| Manual barcode entry | `manual_barcode_screen.dart:59` | `'scan'` (explicit) | ✅ Yes |
| Insights generation | `insight_repository_impl.dart:105` | *(default)* `'system'` | ❌ No |
| Chat (text or +images) | `ai_service.dart:111` | `'chat'`/`'scan'` | ✅ Yes |

So: **chat is metered; the dedicated Scanner — the app's flagship, and the most token-expensive (vision) feature — is not.** Scanning the *same* product via the manual screen counts, but via the camera it does not. The audit even added the `usageType: 'scan'` argument to `manual_barcode_screen.dart` but missed the repository layer that the main scanner uses.

Worse, the client-side fast path reinforces the hole: `UsageService.canScan()` reads `daily_usage.scan_count`, which never increments for the scanner path, so **`canScan()` always returns `true`** and the pre-scan paywall never appears.

**Fix (client — minimal, surgical)**
```dart
// scanner_repository_impl.dart:57
final aiResultStr = await _aiService.generateContent(
  prompt: prompt,
  systemInstruction: Prompts.barcodeAnalysisSystemInstruction,
  usageType: 'scan',          // <-- add
);

// scanner_repository_impl.dart:75
final aiResultStr = await _aiService.generateContent(
  imageBytes: imageBytes,
  systemInstruction: Prompts.visionAnalysisSystemInstruction(...),
  prompt: 'Analyze this ingredient label or meal photo ...',
  usageType: 'scan',          // <-- add
);
```
Then also apply F1 so a tampered client can't just lie about the value.

---

### 🟠 F3 — Quota check fails *open* on transient Firestore errors · **HIGH**

`functions/src/ai_proxy.ts:163-168`:
```ts
} catch (e) {
  // Fail-open ... so paying users are never blocked by a hiccup
  functions.logger.error('usage check failed; allowing request', e);
}
```
If Firestore is degraded, **every** request is allowed — i.e. unlimited unmetered usage for the duration of the outage. Combined with F1/F2 this widens the cost window. Availability-over-metering is a defensible *product* choice, but it should be deliberate and bounded, not silent.

**Fix:** either fail closed (return 503, let the client retry), or fail open **only for verified-premium users** (`isPremiumUser` already ran before the transaction) and fail closed for free/anonymous. At minimum, emit a high-severity alert metric here.

---


### 🟡 F5 — Daily-usage date key is computed in **UTC on the server** but **local time on the client** · **MEDIUM**

- Server: `functions/src/usage.ts` `todayKey()` → `new Date().toISOString().slice(0,10)` (UTC).
- Client: `firestore_service.dart` `getUsageToday()` and `usage_service.dart` `_getTodayUsage()` → `DateTime.now().toIso8601String().split('T')[0]` (device-local).

For a user in **IST (UTC+5:30)**, between 00:00–05:30 local the server writes to *yesterday's* (UTC) doc while the client reads *today's* (local) doc → the "X chats left today" indicator and `canChat()` are wrong (show 0 used). The authoritative server paywall still triggers correctly (server is internally consistent), so this is a UX/cosmetic bug — but for an India-first product (the PRD targets this market) it will be visibly off every night.

**Fix:** compute the day key the same way on both sides. Easiest is to do it **server-side only** (server already owns the doc id) and have the client *read whatever the server returns* rather than re-deriving the id. Or standardize on UTC on the client:
```dart
final date = DateTime.now().toUtc().toIso8601String().split('T')[0];
```

---


### 🟢 F7 — `deleteAccount()` calls client-side Storage cleanup *after* the Auth user is deleted (dead code) · **LOW**

`auth_repository_impl.dart` `deleteAccount()` calls `user.delete()` first, then `_storageService.deleteAllUserFiles(uid)`. But after `user.delete()`, `request.auth` is null, so the Storage rule `isOwner(userId)` rejects the deletion — the client call always fails (caught/logged). The real cleanup is the `onUserDeleted` trigger, so **functionally fine**, but the client call is misleading dead code and the ordering comment ("delete auth first … user still has their data") describes a re-auth concern, not what's happening.

**Fix:** drop the client-side `deleteAllUserFiles`/`deleteAllUserData` calls (they're no-op stubs anyway) and rely on the trigger; or move them *before* `user.delete()`. Document that the trigger is authoritative.

---



### 🟢 F9 — Hygiene / minor

- **Both `dio` and `http`** are depended on (`pubspec.yaml`); `http` appears used only for `AppService` device checks. Consolidate to one client.
- **Pinned (no-caret) versions** for `device_info_plus`, `package_info_plus`, `share_plus` vs caret-everywhere-else — makes version solving brittle across the team.
- **`aiProxy` CORS is `Access-Control-Allow-Origin: '*'`** (`ai_proxy.ts` `setCors`). Harmless for a mobile caller, but combined with no App Check it's an open invitation if a web client ever pointed here. Restrict to known origins if a web client is ever added.
- **`summarizeHistory`** truncates the prompt at `MAX_TEXT_CHARS=8000` (`ai_proxy.ts buildOpenAIMessages`), so very long histories get a degraded summary. Acceptable, but worth a note.
- **Large committed HTML mockups** (`app-flow.html` 267 KB, `GUTGOOD APP FLOW.html` 105 KB, `gutgood_all_screens.html` 46 KB) bloat the repo history; consider LFS or moving to `docs/`/gitignore.
- **Test coverage is thin** (5 tests, all on `ChatMessage`). The Clean-Architecture boundaries are begging for repository/use-case unit tests with fakes — `KNOWN_ISSUES.md` already owns this.

---

## 2. What I **verified as TRUE** from the existing `AUDIT_REPORT.md`

These held up under independent inspection (lending weight to the rest of the review):

- ✅ **OpenAI key is gone from the device.** `api_constants.dart` and `remote_config_service.dart` carry no key; `openai_dart` is not in `pubspec.yaml`; all AI traffic goes through `aiProxy` with a Firebase ID token. PRD §3d is satisfied.
- ✅ **Cloud Functions actually exist and compile.** `functions/` is present, `firebase.json` registers functions + storage + firestore, and **`tsc --noEmit` exits 0** (I ran it). `index.ts` exports all four endpoints.
- ✅ **Server-side merge is atomic + idempotent** (marker doc, content-addressed dedupe, per-source `daily_usage` fold, Storage URL rewrite). Sound design.
- ✅ **`daily_usage` is client read-only** (`firestore.rules`: `allow write: if false`) — the "reset your own counters" bypass is closed.
- ✅ **Crashlytics is wired** (`main.dart`: `FlutterError.onError` + `PlatformDispatcher.instance.onError`, release-gated).
- ✅ **Chat streaming is coalesced** (`Timer.periodic 60ms` in `chat_provider.dart`) and the optimistic-vs-snapshot merge is genuinely race-safe.
- ✅ **`scanner_notifier.dart` no longer increments usage client-side** — the double-counting is gone (the irony being it now under-counts: see F2).
- ✅ **Tests are real**, not the Flutter template counter test.

## 3. What the audit **overstated / got wrong**

- ❌ *"Server-side free-tier enforcement (429 → client shows paywall) … tamper-proof"* — **only true for chat**. Scans (F2) and any `usageType: 'system'` request (F1) are unmetered. Not tamper-proof.
- ❌ *"the AI call itself is counted server-side by the aiProxy (type = 'scan')"* (`scanner_notifier.dart`) — **false** for the repository path the scanner uses; it's `'system'`.
- ⚠️ *"Image bytes released after upload"* — mostly true, but `_lastSentImages` deliberately retains the last turn's bytes for Regenerate until the next send/reset. Bounded, but the absolute claim is slightly off.

---

## 4. Prioritized action list

| # | Severity | Action | Effort |
|---|---|---|---|
| 1 | 🔴 | **F2:** pass `usageType: 'scan'` from the two scanner repository methods. | 2 lines |
| 2 | 🔴 | **F1:** whitelist `usageType`, meter `system` (or fold into chat), reject unknown. | small |
| 3 | 🟠 | **F3:** fail closed (or fail-open only for verified premium) on usage-check errors. | small |
| 5 | 🟠 | **App Check** on Firestore/Storage/Functions (console). | small (console) |
| 6 | 🟡 | **F5:** unify the daily-usage day key (UTC both sides, or server-derived). | small |
| 8 | 🟢 | F7–F9 hygiene (dead delete calls, RC log level, http/dio, repo bloat, tests). | small |

Items **1 and 2 are quick wins with outsized impact** — they restore the free-tier enforcement the product was designed around, and they close the cheapest abuse path. I'd ship those before launch and treat App Check + (optionally) server-side entitlement verification as the durable fix.

---

*Review based solely on reading and compiling the committed source. Running the app/Flutter tests requires a Firebase project + emulator not available in this environment; the functions `tsc` build was executed and passed.*
