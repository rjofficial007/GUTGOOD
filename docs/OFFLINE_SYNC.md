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

- **`InternetConnectionChecker`:** A core service that listens to connectivity changes.
- **`OfflineBanner`:** A global widget that slides down from the top when the device is offline, informing the user that AI features (Chat, Vision) are temporarily limited.
- **AI Fallback:** If a user tries to send a message while offline, the `ChatNotifier` returns a `ChatSendError.offline`, and the UI shows a "Retry" button rather than hanging indefinitely.

## 4. Conflict Resolution
Since all data is scoped to a specific `userId`, multi-device conflicts are rare. 
- **Last Write Wins:** Standard Firestore behavior is followed for profile updates.
- **Chronological Logs:** Meal and symptom logs are append-only, preventing data loss from concurrent writes on different devices.

## 5. Account Migration Sync
When a user merges an anonymous account into a permanent one:
1. The **Cloud Function** performs the heavy lifting on the server.
2. The **Client** resets its local session.
3. The **Firestore SDK** reconciles the local cache for the new UID during the initial data fetch.
