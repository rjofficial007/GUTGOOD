# Known Issues & Technical Debt

This document tracks identified bugs, technical debt, and planned improvements to the GutGood codebase.

## 1. Technical Debt
- **Message Deduplication:** The `ChatNotifier` uses `optimisticIds` but the `localId` field in Firestore is not yet strictly enforced as a unique key in security rules.
- **AI Summary Strategy:** The `summarizeHistory` function currently runs after every 6 messages. A more efficient "window-based" approach or triggering only on significant context shifts could reduce API costs.
- **Image Compression:** Current image compression in `StorageService` is synchronous. For very large images, this could cause a brief frame drop. Consider moving to an isolate.

## 2. Known Limitations
- **Offline Vision:** AI Vision (Food/Menu/Label) requires an active internet connection to communicate with OpenAI. The UI correctly identifies this, but a "queued scan" feature is not yet implemented.
- **Meal Logs Aggregation:** The "Insights" engine identifies patterns but doesn't yet support complex multi-day correlations (e.g., "Symptoms occur 48 hours after eating dairy").
- **Currency Handling:** Subscription prices are currently hardcoded in UI strings. They should be dynamically fetched from the `purchases_flutter` package.

## 3. Recommended Improvements
- **Unit Testing:** While the Clean Architecture supports it, the current project has low unit test coverage for the `domain` and `data` layers.
- **Semantic Search:** Implementing a vector-based search for "Saved Foods" would allow users to find items based on concepts (e.g., "High protein snacks") rather than just name matches.
- **Cycle Sync Refinement:** The cycle phase calculation is currently manual. Integrating with HealthConnect/Apple Health for automated cycle data would improve UX.

## 4. TODOs in Code
- [ ] `AuthRepositoryImpl`: Further refine re-authentication logic for sensitive actions (account deletion).
- [ ] `FirestoreService`: Add batching support for `savePatternData` to reduce write operations.
- [ ] `AppRouter`: Refactor the `redirect` logic into a separate `Guard` class to reduce complexity.
