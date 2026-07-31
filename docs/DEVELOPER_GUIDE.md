# Developer Guide

Welcome to the GutGood development team! This guide will help you understand the patterns used in the project so you can contribute effectively.

## 1. Adding a New Feature
Always follow the **Feature-Sliced Clean Architecture**:

1. **Create Feature Folders:** `lib/features/new_feature/{data, domain, presentation}`.
2. **Define Entity:** Create a plain Dart class in `domain/entities`.
3. **Interface Repository:** Define an abstract class in `domain/repositories`.
4. **Implement Repository:** Create the concrete implementation in `data/repositories` using `FirestoreService` or `AiService`.
5. **Create Notifier:** Implement a `ChangeNotifier` in `presentation/providers` to manage the feature's state.
6. **Register in DI:** Add your repository and notifier to `lib/core/di/injection_container.dart`.
7. **Add UI:** Create screens in `presentation/pages` and register them in `app_router.dart`.

## 2. Working with AI
All AI logic should go through the `AiService`.
- **Streaming:** Use `aiService.streamChat` for conversational features.
- **One-shot:** Use `aiService.analyzeImage` for vision tasks.
- **Prompts:** Avoid hardcoding prompts in the code. Use `lib/core/services/prompts.dart` or, preferably, add them to **Firebase Remote Config**.

## 3. Database Operations
- **NEVER** call `FirebaseFirestore.instance` directly in a Widget or Notifier.
- **ALWAYS** use the `FirestoreService` interface. This ensures consistency and makes testing easier.
- If you need a new collection, update the `FirestoreService` interface and its implementation.

## 4. Authentication & User Context
- Access the current user via `GutAuthNotifier`.
- If a feature requires the user's UID, pass it from the Notifier to the Repository.
- Respect the `isPremium` flag to show/hide paywalls.

## 5. UI Standards
- Use `context.appColorScheme` and `AppTextStyles` for all styling.
- Use `Gap` widgets for spacing (e.g., `Gap.h16`, `Gap.w20`).
- Use `Responsive.init(context)` in your `build` method to ensure layout scales correctly on different devices.

## 6. Testing & Quality
- **Logging:** Use the `Log` utility (e.g., `Log.i()`, `Log.e()`) instead of `print()`.
- **Error Handling:** Wrap all external service calls (Firebase, API) in `try-catch` blocks and handle failures gracefully in the UI.
- **Linting:** Run `flutter lints` and ensure all warnings are resolved before submitting a PR.
