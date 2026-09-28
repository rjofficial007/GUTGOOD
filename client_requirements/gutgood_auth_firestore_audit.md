# GutGood — Firebase Auth / Firestore Sync / Migration / Security Rules Audit

Reviewed: `auth_repository_impl.dart`, `auth_provider.dart`, `auth_bottom_sheets.dart`, `firestore_service.dart`,
`database_helper.dart`, `app_state_service.dart`, `usage_service.dart`, `purchase_provider.dart`, `app_router.dart`,
and the posted Firestore rules.

## 0. Severity summary

| # | Area | Issue | Severity |
|---|------|-------|----------|
| 1 | Rules | Client can write `isPremium` / `subscriptionStatus` / `daily_usage` counters directly → free premium / limit bypass | **Critical** |
| 2 | Merge | Client-side `mergeData()` reads/writes the anonymous user's subtree **after** the session has already switched to the permanent account → `PERMISSION_DENIED` under the posted rules | **Critical** |
| 3 | Merge | Auth session switches to the permanent account **before** the user confirms the merge → app kill / back-out = silent, unrecoverable data loss | **High** |
| 4 | Merge | `daily_usage` merge uses `FieldValue.increment` → **not idempotent**; a retried/partial merge double-counts usage | **High** |
| 5 | Delete | If `user.delete()` succeeds but `deleteAllUserData`/storage delete fails, Firestore/Storage data is orphaned forever (no client can ever reach it again) | **High** |
| 6 | Sync | No outbox/retry for chat/meal/symptom docs whose Firestore write failed (`firestoreId` stays null forever) | **Medium** |
| 7 | Sync | `FirestoreService` swallows exceptions and returns normally → callers believe writes succeeded | **Medium** |
| 8 | Router | `redirect` can fire mid-merge (auth already switched, merge sheet not yet resolved) → confusing navigation | **Medium** |
| 9 | Cleanup | Abandoned anonymous accounts' Firestore data is never pruned → storage/cost creep, GDPR "right to be forgotten" gap | **Medium** |
| 10 | Rules | No default-deny fallback, no size/shape validation, no App Check | **Low/Medium** |

---

## 1. Authentication & migration flow

### 1.1 The core architectural flaw: the session switches *before* the merge is confirmed

`_linkOrMerge` in `auth_repository_impl.dart`:

```dart
if (e.code == 'credential-already-in-use' || e.code == 'email-already-in-use') {
  _isMergingController.add(true);
  try {
    ...
    final permanentCredential = await _firebaseAuth.signInWithCredential(finalCredential);
    final permanentUser = permanentCredential.user!;

    if (anonymousUid != null && anonymousUid != permanentUser.uid) {
      throw AuthMergeConflictException(anonymousUid: anonymousUid, permanentUid: permanentUser.uid, ...);
    }
    return permanentUser;
  } finally {
    _isMergingController.add(false);
  }
}
```

`signInWithCredential` **replaces the current Firebase Auth session** immediately. Only *after* that does the code
throw `AuthMergeConflictException` to ask the UI to show the "merge or just log in" sheet.

Consequences:
- `GutAuthNotifier._authSub` fires with the *new, permanent* user before the merge sheet even renders.
- If the app is killed, backgrounded-and-evicted, or the user dismisses the sheet (not tapping either button),
  there is **no way to retry** — the exception object is gone, the anonymous session is gone, and the guest's
  chat/scan/symptom history is orphaned in Firestore/SQLite forever, with the UI just showing the permanent
  account's (older, un-merged) state as if nothing happened.
- `auth_bottom_sheets.dart` / `email_login_screen.dart` catch `confirmMerge()` failures and then call
  `_onAuthSuccess(context)` **anyway** ("We signed you in, but couldn't fully restore your previous data") —
  i.e. a failed merge is treated as a completed sign-in with no retry path.

**Fix (minimum viable, no backend change required):** persist the conflict *before* attempting the risky
sign-in, and make merge resumable:

```dart
// Right before signInWithCredential in the conflict branch:
await _prefs.setString('pending_merge_anon_uid', anonymousUid ?? '');
await _prefs.setString('pending_merge_provider', credential.providerId);

final permanentCredential = await _firebaseAuth.signInWithCredential(finalCredential);
...
// On success of confirmMerge() OR "just log in":
await _prefs.remove('pending_merge_anon_uid');
```

Then, on app start (e.g. in `LinkService.init()` or `GutAuthNotifier` constructor), check for a leftover
`pending_merge_anon_uid` and — if the now-current user is the permanent account and is *not* anonymous —
re-surface the merge prompt (`AppStateService.setPendingMergeConflict(...)`) instead of silently dropping it.
This turns an unrecoverable bug into a "resume on next launch" flow.

### 1.2 Client-side merge cannot pass your own Security Rules

This is the most important structural problem. After the branch above, `AuthRepositoryImpl.confirmMerge()` →
`_performManualMerge()` calls:

```dart
await _firestoreService.mergeData(anonymousUid, permanentUid);
```

which does:

```dart
final fromDoc = _users.doc(fromUid); // the ANONYMOUS uid
...
final snapshot = await fromDoc.collection(collection).get(); // READ from anon subtree
```

But by this point (see 1.1) **the Firebase Auth client session is already `permanentUid`**. Under your posted
rules:

```
match /user_profiles/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
```

`request.auth.uid` is `permanentUid`, but `userId` in the path is `anonymousUid`. These don't match, so
**every read/write against the anonymous user's `user_profiles/{anonymousUid}` subtree will be rejected with
`PERMISSION_DENIED`.** In other words: **as written today, the client-side merge will throw on the very first
`fromDoc.collection(collection).get()` call in production**, not just in edge cases — this isn't a race, it's
guaranteed to fail for every non-trivial merge (any account with a same-provider conflict).

This is only *not* caught by your own testing if you always test with `linkWithCredential` succeeding directly
(same UID retained, no conflict) — the conflict branch is rarely exercised, but when it is, it always fails.

**This cannot be fixed with client-only Security Rules changes**, because you fundamentally need the
old session's read access *after* you've switched to the new session. The two correct fixes are:

**Option A (recommended): move the merge server-side.**
A callable Cloud Function, running with the Admin SDK (which bypasses Security Rules entirely), does the
whole migration atomically:

```ts
// functions/src/mergeAccount.ts
export const mergeAnonymousAccount = functions.https.onCall(async (data, context) => {
  if (!context.auth) throw new functions.https.HttpsError('unauthenticated', 'Sign in required');
  const permanentUid = context.auth.uid; // caller must BE the permanent account
  const { anonymousUid } = data;

  // Optional but recommended: verify anonymousUid was actually anonymous and
  // hasn't already been merged (idempotency guard, see 1.3).
  const anonUser = await admin.auth().getUser(anonymousUid).catch(() => null);
  if (!anonUser || !anonUser.providerData || anonUser.providerData.length > 0) {
    throw new functions.https.HttpsError('failed-precondition', 'Invalid source account');
  }

  const marker = admin.firestore().doc(`user_profiles/${permanentUid}/merges/${anonymousUid}`);
  if ((await marker.get()).exists) return { alreadyMerged: true }; // idempotent

  await admin.firestore().runTransaction(async (tx) => {
    // ... copy/merge subcollections using batched writes, then:
    tx.set(marker, { mergedAt: admin.firestore.FieldValue.serverTimestamp() });
  });

  await admin.auth().deleteUser(anonymousUid); // reclaim the old identity safely
  return { alreadyMerged: false };
});
```

The client calls this instead of doing the Firestore reads/writes itself:

```dart
final result = await FirebaseFunctions.instance
    .httpsCallable('mergeAnonymousAccount')
    .call({'anonymousUid': anonymousUid});
```

This also solves 1.4 (idempotency) and 1.1 (resumability — the function is safe to call again, it's a no-op
if `marker` already exists) in one place.

**Option B (client-only, weaker): don't switch sessions until the merge is done.**
Keep the anonymous session active, use a *second*, throwaway `FirebaseAuth` app instance (or REST calls) to
read the permanent account's data by minting a custom token server-side — this still needs a Cloud Function to
mint the token, so in practice you end up needing a backend anyway. **Option A is the only clean fix.**

If you truly cannot ship a Cloud Function right now, the stop-gap is: temporarily relax the rule to allow a
user to read/write a `user_profiles/{anyUid}` document **if** a matching, time-limited `merge_grants/{anonUid}`
doc (owned by `permanentUid`) exists — but this is meaningfully more complex and easier to get wrong than just
writing the Cloud Function, so it's listed only as a fallback.

### 1.3 Non-idempotent `daily_usage` merge

Inside `mergeData`, most subcollections are deduped by comparing content (`chat_history`, `meal_logs`,
`symptom_logs`) or are safe to overwrite by re-using the same doc ID (`scan_history`, `insights`,
`pattern_data`). `daily_usage` is the exception:

```dart
if (collection == 'daily_usage') {
  final Map<String, dynamic> increments = {};
  if (data.containsKey('chat_count')) increments['chat_count'] = FieldValue.increment(data['chat_count']);
  if (data.containsKey('scan_count')) increments['scan_count'] = FieldValue.increment(data['scan_count']);
  batch.set(targetRef, increments, SetOptions(merge: true));
}
```

If `mergeData` (or the whole `confirmMerge` flow) is invoked twice — which is exactly what your recovery UX
does today ("couldn't fully restore data" → user manually retries, or app auto-retries after a crash) — this
**adds the guest's daily chat/scan counts to the permanent account a second time**, which can wrongly trip the
free-tier paywall for a legitimate premium-adjacent user, or (worse) undercount if you ever flip the sign.

**Fix:** either (a) do this only inside the idempotent Cloud Function from 1.2 guarded by the `merges/{anonUid}`
marker doc, or (b) client-side, replace `increment` with a `set` under a per-source marker so re-running is a
no-op:

```dart
final mergeMarkerRef = toDoc.collection('_merge_markers').doc('daily_usage_$fromUid');
if (!(await mergeMarkerRef.get()).exists) {
  batch.set(targetRef, increments, SetOptions(merge: true));
  batch.set(mergeMarkerRef, {'mergedAt': FieldValue.serverTimestamp()});
}
```

### 1.4 Router race during merge

`AppRouter.redirect` reads `authNotifier.isAuthenticated` / `isAnonymous` and immediately redirects based on
`onboarded`. Because (per 1.1) the Firebase Auth session switches to the permanent account *before* the merge
sheet is resolved, `GutAuthNotifier` fires `notifyListeners()` (it listens to `authStateChanges`), which can
trigger `GoRouter`'s `refreshListenable` and redirect the user to `/home/chat` (if the permanent account was
already onboarded) while the merge-confirmation bottom sheet is still supposed to be showing over the login
screen.

**Fix:** hold the redirect while a merge is pending:

```dart
redirect: (context, state) async {
  final appState = sl<AppStateService>();
  if (appState.pendingMergeConflict.value != null || authNotifier.isMerging) {
    return null; // stay put until the user resolves the merge sheet
  }
  ...
}
```

---

## 2. Firestore sync layer

### 2.1 No outbox / retry for failed cloud writes

`insertMessage` (and the meal/symptom equivalents) do:

```dart
String? firestoreId = message.firestoreId;
if (syncToCloud && firestoreId == null) {
  firestoreId = await _firestoreService.saveMessage(message);
}
```

`FirestoreService.saveMessage` catches its own exceptions and returns `null` on failure:

```dart
} catch (e) {
  Log.error('FirestoreService: Error saving message', error: e);
  return null;
}
```

If this fails (offline for longer than the SDK's local cache write can bridge, permission hiccup during a
provider switch, etc.), the message is saved locally with `firestoreId: null` and **nothing ever retries it**.
`syncWithFirebase()` only *pulls* cloud → local by `time > lastSync`; it never *pushes* local rows with
`firestoreId == null` back up.

**Fix:** add a lightweight outbox pass to `syncWithFirebase()` (or a dedicated `pushPendingWrites()` called on
connectivity restore, `main.dart` already has `InternetConnectionChecker` — wire its `onConnectionRestored`
callback to it):

```dart
Future<void> pushPendingWrites() async {
  final uid = _currentUid;
  if (uid == null) return;
  final db = await database;

  final pendingMsgs = await db.query('chat_history', where: 'uid = ? AND firestoreId IS NULL', whereArgs: [uid]);
  for (final row in pendingMsgs) {
    final msg = ChatMessage.fromMap(row);
    final firestoreId = await _firestoreService.saveMessage(msg);
    if (firestoreId != null) {
      await db.update('chat_history', {'firestoreId': firestoreId}, where: 'id = ?', whereArgs: [row['id']]);
    }
  }
  // repeat for meal_logs / symptom_logs / scan_history
}
```

### 2.2 Swallowed errors mask failures

Nearly every method in `FirestoreServiceImpl` does `try { ... } catch (e) { Log.error(...); return null/void; }`.
That's reasonable at the outermost boundary (don't crash the UI), but several *callers* treat the call as
having succeeded:

```dart
// auth_repository_impl.dart
await _firestoreService.updateUserProfile(profile);   // swallowed internally — always "succeeds" from here
await _databaseHelper.updateUserProfile(profile, syncToCloud: false);
...
await _prefs.setBool('onboarded', true);
```

If the Firestore write silently failed, the local DB and prefs still record `onboarded = true`/profile-saved,
so the app believes sync succeeded when the source of truth in the cloud doesn't have it — the next fresh
install / device will pull a stale cloud profile.

**Fix:** have the data-layer methods that matter for correctness (`saveUserProfile`, `updateUserProfile`,
`saveMessage`, `saveInsights`) rethrow (or return a `Result`/`bool`) instead of swallowing, and let call sites
decide (log + queue for retry vs. show a banner), rather than silently succeeding at both layers.

### 2.3 Orphaned anonymous data / no cleanup

- On explicit sign-out of a guest, only local data is cleared (`_databaseHelper.clearAllData()`); the anonymous
  Firebase Auth user and its Firestore subtree are left behind indefinitely.
- After a successful merge (1.2), the anonymous account's original documents are also never deleted (only
  copied) even in the *current* client-side implementation — meaning today, a successful merge still doubles
  your Firestore storage for that user going forward.

**Fix:**
- Cloud Function from 1.2 should `admin.auth().deleteUser(anonymousUid)` after a successful merge; add an
  Auth `onDelete` trigger (see 2.4) to cascade-clean Firestore/Storage for *any* deleted user, anonymous or not.
- Add a scheduled Cloud Function (e.g. daily) that finds anonymous users older than N days with no meaningful
  activity and deletes them + their data, to bound storage/cost growth from abandoned guest sessions.

### 2.4 Account deletion: orphan risk if the second step fails

`deleteAccount()`:

```dart
await user.delete();                              // 1. Auth account gone
await _firestoreService.deleteAllUserData(uid);    // 2. Firestore
await _storageService.deleteAllUserFiles(uid);     // 3. Storage
```

The comment correctly notes deleting the Auth user *first* avoids losing data if `requires-recent-login` fires
(good — if step 1 fails, nothing else has happened yet). But if step 1 succeeds and step 2 or 3 then fails
(network drop), you're left with **Firestore/Storage data that belongs to no one and that no client can ever
delete again** — the user is signed out the moment `user.delete()` succeeds, and your rules require
`request.auth.uid == userId`, which is now impossible to satisfy for that uid.

**Fix:** add an Auth `onDelete` Cloud Function trigger as the source of truth for cascade deletion, so client
failure at steps 2/3 doesn't matter — the account being gone is what guarantees the data eventually gets purged:

```ts
export const onUserDeleted = functions.auth.user().onDelete(async (user) => {
  await admin.firestore().recursiveDelete(admin.firestore().doc(`user_profiles/${user.uid}`));
  await admin.storage().bucket().deleteFiles({ prefix: `users/${user.uid}/` });
});
```

Keep the client-side calls too (fast path, immediate feedback to the user) — the Cloud Function is just the
guaranteed backstop.

---

## 3. Security Rules Review

### 3.1 Critical: clients can grant themselves premium / reset their own limits

Your rule is a blanket `allow read, write` on the whole `user_profiles/{userId}` document:

```
match /user_profiles/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
```

`UserProfile` includes `isPremium`, `subscriptionStatus`, `gutScore`, `streak` as plain fields on this same
document. Because the rule doesn't restrict *which fields* can be written, **any authenticated user (including
anonymous) can open the Firestore console/network layer or just call the SDK directly and write:**

```dart
FirebaseFirestore.instance.doc('user_profiles/$myUid').set({'isPremium': true}, SetOptions(merge: true));
```

`UsageService.isPremium()` checks (in priority order) the in-memory `PurchaseService`, then the **local DB
profile** (which gets its `isPremium` from exactly this Firestore doc via `syncWithFirebase()`), then
SharedPreferences. A user who sets `isPremium: true` in Firestore directly will, after the next sync, be
treated as premium by the app with **no RevenueCat purchase at all**. Similarly, `daily_usage/{date}` has the
same blanket write rule, so a free user can simply reset `chat_count`/`scan_count` to 0 whenever they hit the
paywall.

This is a monetization-bypass bug, not just a theoretical security nitpick — it should be treated as P0.

**Fix — lock down the fields that must only ever be set by trusted server code:**

```
function isOwner(userId) {
  return request.auth != null && request.auth.uid == userId;
}

function unchangedOrAbsent(field) {
  return !(field in request.resource.data) ||
         (field in resource.data && request.resource.data[field] == resource.data[field]);
}

match /user_profiles/{userId} {
  allow read: if isOwner(userId);

  allow create: if isOwner(userId)
    && request.resource.data.get('isPremium', false) == false
    && request.resource.data.get('subscriptionStatus', 'free') == 'free';

  allow update: if isOwner(userId)
    && unchangedOrAbsent('isPremium')
    && unchangedOrAbsent('subscriptionStatus')
    && unchangedOrAbsent('gutScore')
    && unchangedOrAbsent('streak');

  allow delete: if isOwner(userId);
  ...
}
```

`isPremium`/`subscriptionStatus` should only ever be written by a RevenueCat webhook → Cloud Function (Admin
SDK, bypasses rules). `gutScore`/`streak` are currently written by the client after AI insight generation
(`InsightRepositoryImpl.generateNewInsight`) — ideally that also moves server-side eventually, but at minimum
don't let it be spoofed independent of an actual insight write; if you're not ready to move insight generation
server-side yet, you can instead scope the lock to just `isPremium`/`subscriptionStatus` first (highest-value
fix) and revisit `gutScore`/`streak` later.

For `daily_usage`, since the client legitimately needs to increment it, restrict to increment-shaped writes
only:

```
match /daily_usage/{docId} {
  allow read: if isOwner(userId);
  allow create: if isOwner(userId)
    && request.resource.data.keys().hasOnly(['chat_count', 'scan_count'])
    && request.resource.data.chat_count is int && request.resource.data.chat_count <= 1
    && request.resource.data.scan_count is int && request.resource.data.scan_count <= 1;
  allow update: if isOwner(userId)
    && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['chat_count', 'scan_count'])
    && request.resource.data.chat_count <= resource.data.chat_count + 1
    && request.resource.data.scan_count <= resource.data.scan_count + 1;
}
```

This still lets a determined attacker increment by +1 repeatedly to "use up" nothing meaningful, but blocks the
one-shot reset-to-zero / arbitrary-value exploit. The durable fix long-term is a callable Cloud Function
(`incrementUsage`) as the only writer, with the client only ever reading `daily_usage`.

### 3.2 No support path for the merge (ties back to §1.2)

As written, there is no rule that could let the client itself perform the anonymous → permanent merge safely
— and there shouldn't be one added for that purpose. The correct fix is Cloud Functions using the Admin SDK
(which is not subject to these rules at all), as described in §1.2. Don't try to "fix" this by loosening
`request.auth.uid == userId`.

### 3.3 No default-deny fallback / no size guard

Firestore's implicit default is deny, so this isn't a live hole, but it's worth adding explicitly for
defense-in-depth and to make future rule edits safer by construction:

```
match /{document=**} {
  allow read, write: if false;
}
```
(placed after all the specific matches).

Also worth adding a coarse payload-size guard to prevent abuse/cost blowups from oversized documents, e.g. on
`chat_history`/`meal_logs`/`scan_history` writes:

```
allow write: if isOwner(userId) && request.resource.size() < 1 * 1024 * 1024;
```

### 3.4 Recommend Firebase App Check

None of the above rules can distinguish "your real app" from a scripted client hitting the Firestore REST API
directly with a valid (even anonymous) auth token. Enabling **App Check** (Play Integrity / DeviceCheck) and
requiring it in rules (`request.app != null` — actually enforced at the project/rule level via console toggle,
or `firebase.rules` `request.auth.token.firebase` checks aren't quite right; App Check enforcement is configured
per-service in the console, not purely in rules text) meaningfully raises the bar against exactly this kind of
direct-API abuse, and is a cheap addition given the paywall-bypass risk in §3.1.

### 3.5 Rewritten rules (full)

```firestore
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {

    function isOwner(userId) {
      return request.auth != null && request.auth.uid == userId;
    }

    function unchangedOrAbsent(field) {
      return !(field in request.resource.data) ||
             (field in resource.data && request.resource.data[field] == resource.data[field]);
    }

    match /user_profiles/{userId} {
      allow read: if isOwner(userId);

      allow create: if isOwner(userId)
        && request.resource.data.get('isPremium', false) == false
        && request.resource.data.get('subscriptionStatus', 'free') == 'free'
        && request.resource.size() < 200 * 1024;

      allow update: if isOwner(userId)
        && unchangedOrAbsent('isPremium')
        && unchangedOrAbsent('subscriptionStatus')
        && request.resource.size() < 200 * 1024;

      allow delete: if isOwner(userId);

      match /chat_history/{docId} {
        allow read, write: if isOwner(userId) && request.resource.size() < 512 * 1024;
        allow delete: if isOwner(userId);
      }

      match /scan_history/{docId} {
        allow read, write: if isOwner(userId) && request.resource.size() < 512 * 1024;
        allow delete: if isOwner(userId);
      }

      match /meal_logs/{docId} {
        allow read, write: if isOwner(userId) && request.resource.size() < 256 * 1024;
        allow delete: if isOwner(userId);
      }

      match /symptom_logs/{docId} {
        allow read, write: if isOwner(userId) && request.resource.size() < 256 * 1024;
        allow delete: if isOwner(userId);
      }

      match /insights/{docId} {
        allow read, write: if isOwner(userId) && request.resource.size() < 512 * 1024;
        allow delete: if isOwner(userId);
      }

      match /daily_usage/{docId} {
        allow read: if isOwner(userId);
        allow create: if isOwner(userId)
          && request.resource.data.keys().hasOnly(['chat_count', 'scan_count'])
          && request.resource.data.chat_count is int && request.resource.data.chat_count <= 1
          && request.resource.data.scan_count is int && request.resource.data.scan_count <= 1;
        allow update: if isOwner(userId)
          && request.resource.data.diff(resource.data).affectedKeys().hasOnly(['chat_count', 'scan_count'])
          && request.resource.data.chat_count <= resource.data.chat_count + 1
          && request.resource.data.scan_count <= resource.data.scan_count + 1;
      }

      match /pattern_data/{docId} {
        allow read, write: if isOwner(userId) && request.resource.size() < 512 * 1024;
      }

      // Idempotency markers written only by the mergeAnonymousAccount Cloud Function
      // (Admin SDK writes bypass rules; this just blocks clients from faking a "merged" marker).
      match /merges/{anonUid} {
        allow read: if isOwner(userId);
        allow write: if false;
      }
    }

    // Explicit default-deny for anything not matched above.
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

## 4. Prioritized action plan

**P0 (ship first, highest risk/lowest effort ratio):**
1. Lock `isPremium` / `subscriptionStatus` / `daily_usage` writes in Security Rules (§3.1, §3.5) — pure rules
   change, no app release required, closes the monetization-bypass hole immediately.
2. Add the default-deny fallback (§3.3) — zero risk, ships with the same rules deploy.

**P1 (needs a small Cloud Functions project):**
3. `mergeAnonymousAccount` callable function (§1.2) — fixes the guaranteed-failure merge path and, as a side
   effect, makes the merge idempotent (§1.3) and safely resumable.
4. Auth `onDelete` cascade-delete trigger (§2.4) — closes the orphaned-data risk on account deletion.
5. Persist `pending_merge_anon_uid` before switching sessions + resume-on-launch (§1.1) — bridges the gap until
   #3 ships, and is good defense-in-depth afterward (network drop mid-call, etc.).

**P2 (robustness/cost hygiene):**
6. Outbox/retry pass for chat/meal/symptom/scan writes with `firestoreId == null` (§2.1), wired to
   `InternetConnectionChecker`'s reconnect callback.
7. Stop swallowing exceptions in the Firestore write paths that gate correctness (§2.2).
8. Scheduled cleanup of stale anonymous accounts (§2.3).
9. Router: suppress redirects while a merge conflict is pending (§1.4).
10. Enable Firebase App Check (§3.4).
