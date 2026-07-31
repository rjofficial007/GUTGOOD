# Authentication & Migration Flow

GutGood implements a frictionless, "Guest-First" authentication strategy that allows users to experience the core value proposition before committing to an account.

## 1. Anonymous Login
Every new user starts as an Anonymous guest.
- **Trigger:** First launch or "Continue as Guest" on Welcome Screen.
- **Implementation:** `AuthRepositoryImpl.signInAnonymously()`.
- **Logic:** Calls Firebase Auth `signInAnonymously`. Initializes a `UserProfile` with `displayName: "Guest"` and `onboarded: false`.

## 2. Permanent Sign-In Methods
Users can "secure" their account by linking to a provider:
- **Google Login:** `signInWithGoogle()` (using `google_sign_in`).
- **Apple Login:** `signInWithApple()` (using `sign_in_with_apple`).
- **Email/Password:** `signInWithEmailAndPassword()` or `signUpWithEmailAndPassword()`.
- **Magic Link:** `sendSignInLinkToEmail()` for passwordless login.

## 3. Account Linking (Upgrade)
When an anonymous user signs in with a permanent provider for the first time:
- **Implementation:** `_linkOrMerge(credential)` in `AuthRepositoryImpl`.
- **Success:** The permanent credential is linked to the existing anonymous UID. All data remains in place.

## 4. Account Merging (Conflict Resolution)
If a guest tries to link a provider that **already has an existing GutGood account**:
- **Error Code:** `credential-already-in-use`.
- **User Experience:** A "Merge Data" dialog appears, showing the existing account's email and the guest's local data.
- **The "Conflict" State:** The app holds the session in a pending state using `AppStateService.pendingMergeConflict`.

### The Merge Process
1. **Trigger:** User taps "Confirm & Merge" in the UI.
2. **Server-Side Call:** The app invokes the `mergeAnonymousAccount` Cloud Function.
3. **Cloud Function Logic:** 
    - Verifies the owner of both accounts.
    - Idempotently copies all subcollections (`chat_history`, `scan_history`, `meal_logs`, etc.) from the anonymous UID to the permanent UID.
    - Updates the permanent profile with any new onboarding data from the guest session.
    - Deletes the temporary guest profile.
4. **Client Recovery:** Upon success, the app resets its local state, logs into the permanent account, and refreshes the data stream.

## 5. Session Management
- **Persistence:** Auth state is persisted by the Firebase Auth SDK.
- **Fast-Path Check:** On app start, the `onboarded` flag is checked via `SharedPreferences` for immediate redirection, even before the full Firebase Auth object is ready.
- **Logout:** `signOut()` clears the Firebase session, resets the `AppStateService`, and redirects the user back to the Welcome Screen.

## 6. Security Guardrails
- **`_guardAgainstSilentAccountSwitch`:** Prevents a logged-in user from accidentally overwriting their session with another permanent account without explicit intent.
- **Merge Idempotency:** The `merges` subcollection in Firestore tracks successful migrations to prevent double-merging in case of network retries.
