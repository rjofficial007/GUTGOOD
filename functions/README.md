# GutGood Cloud Functions

Secure backend mandated by the PRD (§3d): the OpenAI API key never ships to a
device, and free-tier limits are enforced server-side. Privileged data writes
(account merge, cascade delete) happen only here via the Admin SDK.

**Premium model:** managed entirely on-device with the RevenueCat SDK
(`purchases_flutter`). The app mirrors the entitlement into
`user_profiles/{uid}.isPremium` (+ `subscriptionStatus`) so it is available
cross-device and to the `aiProxy` quota check. There is intentionally **no
server-side RevenueCat integration** (no webhook, no REST verification).

## Functions

| Function | Type | Purpose |
|---|---|---|
| `aiProxy` | HTTPS (POST) | Proxies chat/vision/JSON requests to OpenAI. Enforces Firebase auth + free-tier limits transactionally. Streams responses as SSE. |
| `mergeAnonymousAccount` | Callable | Atomic, idempotent anonymous→permanent data migration; deletes the old guest identity. |
| `onUserDeleted` | Auth trigger | Cascade-deletes `user_profiles/{uid}` and `users/{uid}/` storage (guaranteed backstop). |
| `cleanupAnonymousUsers` | Scheduled (daily 03:00 UTC) | Deletes guest accounts with no activity for 14 days (cost + GDPR hygiene). |

## Setup

```bash
cd functions
npm install
npm run build
```

### Secrets (required)

```bash
firebase functions:secrets:set OPENAI_API_KEY
```

That is the only secret the backend needs.

## Deploy

```bash
firebase deploy --only functions
```

## Emulator

The Flutter app supports `--dart-define=USE_FIREBASE_EMULATOR=true`, which points
Auth, Firestore, Functions and Storage at the local emulator suite:

```bash
npm run serve   # from functions/ — starts functions, firestore, auth, storage emulators
```
