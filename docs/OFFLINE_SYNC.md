# Offline Support & Synchronization

GutGood is designed to be "Offline-First" for logging and history, ensuring users can record their food and symptoms even without a data connection (e.g., in remote areas or basements).

## 1. Firestore Offline Persistence
We leverage Cloud Firestore's native persistence engine.
- **Enabled in:** `lib/core/di/injection_container.dart`.
- **Configuration:** `Settings(persistenceEnabled: true, cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED)`.
- **Behavior:** All reads are served from the local cache immediately. Writes are queued and synchronized automatically when the connection returns.

## 2. Optimistic UI Updates
For a seamless user experience, we don't wait for server confirmation to update the UI.

### Chat Implementation:
1. When a message is sent, it is added to the Notifier's list with a `localId`.
2. The UI renders this message instantly.
3. The background sync process saves it to Firestore.
4. When the server snapshot arrives, the `localId` is used to replace the optimistic entry with the authoritative server version without a UI flicker.

## 3. Connectivity Awareness
The app monitors network status to adjust its behavior and inform the user.

- **`InternetConnectionChecker`:** A core service that probes real reachability (TCP to 1.1.1.1 / 8.8.4.4, ports 53 then 443 — some networks filter DNS but pass HTTPS). It probes immediately on start so a cold start offline resolves in seconds, then polls every 10s with 2-failure hysteresis before reporting loss. `checkConnection()` (also called on app resume) reports both directions, with one retry before declaring offline.
- **`OfflineBanner`:** A global widget that slides down from the top when the device is offline, informing the user that AI features (Chat, Vision) are temporarily limited.
- **AI Fallback:** If a user tries an AI action while offline, the composer reports `ChatSendError.offline` and the UI shows a snackbar rather than hanging indefinitely. Pure-text sends instead enter the outbox (§7); image sends keep the draft (memory + prefs, survives restarts) for a manual retry. Regenerate / retry / see-more-swaps taps while offline also report `offline` instead of silently doing nothing.
- **Cause-aware errors:** `isOfflineError()` classifies socket/timeout/Dio failures so scanner and insights surfaces say "you're offline" (`ScannerNotifier.lastErrorWasOffline`) instead of "product not found" / generic failure copy.

## 4. Image Turns: Deduped, Non-Blocking, Retried (P1-3a + §E-lite)
The Storage upload used to gate the AI turn and re-upload every photo. Now:

1. The user message is saved immediately (durable, with local bytes).
2. The reply streams from in-memory bytes.
3. **Hash dedup:** uploads hash the compressed bytes (`sha256_16`) and store at `users/{uid}/food_images/{hash}.jpg`, with a prefs URL cache (cap 200). Retries, regenerates, and re-scans of the same photo never re-upload. Legacy timestamp-named objects keep working (stored URLs are absolute).
4. **Upload outbox:** a failed upload persists bytes (cache dir) + index entry (prefs) and retries on turn-complete, reconnect, and app start — poison entries drop after 10 attempts, missing files drop gracefully.
5. **Recovery hydration:** URLs merge into the in-memory message when present, else patch the Firestore doc directly (doc id == localId). A settled-without-URLs message keeps its local bytes session-locally (pass-A semantics).

Known edges: pending bytes live in the cache dir (expendable — the OS may purge them, and those entries drop); multi-image restart recovery is last-wins per flush (the UI caps at one attachment per turn). The orphan sweeper lives in §8 now that the registry exists.

## 5. Conflict Resolution
Since all data is scoped to a specific `userId`, multi-device conflicts are rare. 
- **Last Write Wins:** Standard Firestore behavior is followed for profile updates.
- **Chronological Logs:** Meal and symptom logs are append-only, preventing data loss from concurrent writes on different devices.

## 6. Offline Text Outbox
Pure-text sends while offline are accepted into a prefs-backed FIFO outbox (`ChatOutboxService`, restart-safe) and shown as `Queued` bubbles — the send returns `ChatSendError.queued` (acceptance, not failure) and the composer clears.

- **Flush triggers:** connectivity false→true edge, composer init with pending entries, and after every completed turn (covers busy-interrupted flushes). Manual trigger: tapping a queued bubble.
- **Correctness:** entries dequeue only after a fully successful turn. Failed attempts are rolled back (attempt messages + partial logs deleted) and re-parked under the same message id, so nothing is lost or duplicated — including across the checker's cold-start grace window.
- **Boundaries:** image turns never queue (bytes don't belong in prefs); quota failures stop the flush and stay queued for a later trigger; session reset drops the outbox (entries belong to the old account).

## 7. Account Migration Sync
When a user merges an anonymous account into a permanent one:
1. The **Cloud Function** performs the heavy lifting on the server.
2. The **Client** resets its local session.
3. The **Firestore SDK** reconciles the local cache for the new UID during the initial data fetch.

## 8. Food-Image Registry: Thumbs, Links, Lifecycle (full §E)
Every uploaded photo gets a registry doc at `user_profiles/{uid}/food_images/{sha256_16}` answering three questions: which chat/meal/scan docs reference it (`links`), where its 320px thumb lives (`thumbUrl`), and whether anything still needs it (`linkCount`).

- **Uploads:** Storage keeps a 1024px/q80 original at the idempotent hash path (§4 dedup unchanged). Registration is best-effort and never blocks the turn.
- **Thumbs:** `generateFoodThumb` (Storage trigger, `sharp`) derives the 320px thumb into `food_images/thumbs/` and backfills `thumbPath/thumbUrl/width/height/bytes`. Only hash-named objects are processed — legacy timestamp files are skipped. The chat strip (`RegistryThumbImage`) prefers the thumb and falls back to the full URL for any failure; full-URL fallbacks are never cached as thumbs.
- **Links:** chat hydration links under the message doc id; meal/scan saves link inside `HistoryFirestoreService` (the single choke point both the chat persister and the scanner repo funnel through). Link ops are idempotent single-doc transactions with a denormalized `linkCount` and a `lastUnlinkedAt` grace anchor.
- **Unlink/delete:** deleting a chat message unlinks its `imageHashes` (URL-parse fallback for pre-registry messages); `deleteLogsForMessage` unlinks meal/scan photos before the batch deletes the docs naming them. The daily `sweepUnlinkedFoodImages` cron deletes docs at `linkCount == 0` past the 30-day `max(createdAt, lastUnlinkedAt)` grace — single-field query, no composite index. Docs without a known age (and legacy objects with no doc at all) are never swept.
- **Offline:** links/unlinks are plain Firestore writes, so they ride the SDK's offline persistence like everything else; the registry service is failure-tolerant (log-and-continue) and never breaks a turn.
