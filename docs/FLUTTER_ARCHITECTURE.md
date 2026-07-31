# Flutter Architecture

GutGood follows a **Feature-Based Clean Architecture** to ensure maintainability, testability, and clear separation of concerns.

## 1. Core Architecture Patterns

### Feature-Sliced Design
Each feature (e.g., `chat`, `scanner`, `auth`) is self-contained with the following layers:
- **Presentation:** Widgets, Screens, and `ChangeNotifier` Notifiers.
- **Domain:** Entities and Repository Interfaces (Usecases are used for complex logic like `SendMessageStreamUseCase`).
- **Data:** Repository Implementations, Data Sources (Firebase), and Models (Mappers).

### Dependency Injection (DI)
- Uses `get_it` as a service locator.
- Initialized in `injection_container.dart`.
- Decouples UI from concrete implementations, facilitating easy mocking for tests.

### State Management
- Uses the `Provider` package.
- Features are managed by `ChangeNotifier` subclasses (e.g., `GutAuthNotifier`, `ChatNotifier`).
- **Optimistic UI:** Local state is updated immediately (e.g., in Chat) while Firestore handles background synchronization.

---

## 2. Navigation & Routing
- **Library:** `go_router`.
- **Structure:** `StatefulShellRoute` with `IndexedStack` for the persistent bottom navigation bar.
- **Guards:** Global redirect logic in `app_router.dart` handles:
    - Auth state (Redirecting to Welcome if not logged in).
    - Onboarding state (Forcing completion before home access).
    - Merge state (Holding navigation while an account merge is pending).

---

## 3. UI & Theming
- **Material 3:** Modern, responsive design language.
- **Adaptive UI:** Custom `Responsive` utility for screen-size-agnostic layouts.
- **Theme Support:** `AppTheme` defines Light and Dark modes. `ThemeNotifier` manages user preference.
- **Animations:** Powered by `flutter_animate` for a polished UX.

---

## 4. Business Logic Layer (Services)
Core logic resides in the `lib/core/services/` directory, used across multiple features:
- **`AiService`:** Manages the communication with the `aiProxy` Cloud Function.
- **`FirestoreService`:** Abstracted interface for all database operations.
- **`PurchaseService`:** Wrapper for RevenueCat subscription logic.
- **`UsageService`:** Client-side check for daily quotas (Scans/Messages).
- **`InternetConnectionChecker`:** Monitors network status for offline UI triggers.

---

## 5. Offline Support & Local Cache
- **Firestore Persistence:** Enabled for all documents, allowing the app to function without an active internet connection.
- **SharedPreferences:** Used for simple key-value storage (e.g., `onboarded` flag, theme mode, local settings).
- **Offline Banner:** A global overlay that appears when the device loses connectivity.
