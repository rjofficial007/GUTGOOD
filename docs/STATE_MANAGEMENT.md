# State Management

GutGood uses **Provider** combined with **ChangeNotifier** for state management. This approach provides a clean, reactive bridge between the business logic (Repositories/Services) and the UI.

## 1. The Notifier Pattern
Each major feature is governed by a dedicated `ChangeNotifier` class.

### Key Notifiers:
- **`GutAuthNotifier`:** Manages authentication state (`isAuthenticated`, `isAnonymous`, `isMerging`). Triggers global router redirects.
- **`ChatNotifier`:** Manages the conversational state. Handles message history, attachment previews, and streaming token accumulation.
- **`ScannerNotifier`:** Tracks scanning progress (`isProcessing`) and the latest `ScanResult`.
- **`ProfileNotifier`:** Manages user health settings (Goals, Sensitivities) and the onboarding process.
- **`InsightsNotifier`:** Manages the loading and caching of AI-generated health recaps.
- **`PurchaseProvider`:** Reflects the user's subscription status from RevenueCat.

---

## 2. State Ownership & Scoping
Notifiers are provided at the root of the application via `MultiProvider` in `main.dart`. This ensures that data like authentication and profile settings are available globally across all screens.

```dart
runApp(
  MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => sl<GutAuthNotifier>()),
      ChangeNotifierProvider(create: (_) => sl<ProfileNotifier>()),
      ChangeNotifierProvider(create: (_) => sl<ChatNotifier>()),
      // ...
    ],
    child: const GutGoodApp(),
  ),
);
```

---

## 3. Event Flow & UI Updates
1. **User Action:** The user taps a button (e.g., "Send Message").
2. **Method Call:** The UI calls a method on the Notifier (`chatNotifier.send(...)`).
3. **Internal Logic:** The Notifier performs logic, updates private fields (e.g., `_isLoading = true`), and calls `notifyListeners()`.
4. **Reactive UI:** Widgets using `context.watch<ChatNotifier>()` or `Consumer<ChatNotifier>` automatically rebuild with the new state.

---

## 4. Race-Free Optimistic Updates
To provide a "snappy" feel despite network latency, features like Chat use an optimistic state strategy:
- A message is added to the local `_messages` list immediately with a `localId`.
- A temporary `optimisticId` set tracks these "pending" messages.
- When the server-side snapshot arrives via Firestore, the Notifier compares `localId`s and seamlessly replaces the optimistic message with the authoritative server version.

---

## 5. Dependency Graph
Notifiers depend on Repository interfaces, which are injected via `GetIt`. This allows the Notifier to remain agnostic of the underlying data source (e.g., whether data comes from a local cache or a remote API).

**Example:**
`ChatNotifier` -> `ChatRepository` -> `FirestoreService` & `AiService`.
