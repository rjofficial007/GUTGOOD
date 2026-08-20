# Codebase Map

This document explains the organization and responsibilities of the folders and major files in the GutGood repository.

## 1. `/lib` - Application Source
The heart of the Flutter application, following a Clean Architecture structure.

### `/lib/core` - The Shared Foundation
- `constants/`: App-wide strings, icons, sizes, and API endpoint definitions.
- `di/`: The `injection_container.dart` which wires up all dependencies using `GetIt`.
- `models/`: Domain models (Mappers) used across multiple features (e.g., `ScanResult`, `UserProfile`).
- `router/`: The `app_router.dart` defining all screen paths and redirection logic.
- **`services/`**: Concrete implementations of core system logic (AI, Firestore, Storage, Usage).
    - **`prompts/`**: The modular AI prompt engine.
        - **`mode_prompts/`**: Dedicated files for every AI intent (Rating, Swaps, Planning, etc.).
- **`theme/`**: Material 3 theme definitions and the `ThemeNotifier`.
- **`utils/`**: Reusable helpers for date-time, logging, responsiveness, and data parsing.
    - **`model_utils.dart`**: Robust JSON parsing with "auto-repair" logic for truncated LLM responses.
- **`widgets/`**: Shared UI components like buttons, inputs, loaders, and the global `OfflineBanner`.

### `/lib/features` - Feature-Sliced Modules
- `auth/`: Handles Login, Signup, Social Auth, and Account Merging.
- `chat/`: The AI Assistant interface, streaming logic, and message history.
- `home/`: The `MainShell` which coordinates the bottom navigation.
- `insights/`: AI report generation, weekly recaps, and history.
- `logs/`: UI for manual meal and symptom check-ins.
- `profile/`: User settings, health personalization (Goals/Sensitivities), and subscription status.
- `scanner/`: The hybrid Barcode/Vision scanner implementation.
- `welcome/`: Splash screen and initial landing page.
- `onboarding/`: The 5-step personalization wizard.
- `product_details/`: Detailed drill-down screens for scanned items and nutrition facts.

---

## 2. `/functions` - Backend Logic
Firebase Cloud Functions written in TypeScript.
- `src/ai_proxy.ts`: Secure OpenAI gateway with auth and quota enforcement.
- `src/merge.ts`: Atomic collection migration logic for account upgrades.
- `src/lifecycle.ts`: Automated cleanup and GDPR-compliant deletion triggers.
- `src/usage.ts`: Server-side logic for daily usage tracking.

---

## 3. `/assets` - Static Resources
- `fonts/`: Custom typography.
- `images/`: App icons, illustrations, and placeholders.

---

## 4. Root Configuration Files
- `pubspec.yaml`: Project metadata and dependencies.
- `firestore.rules`: Security rules governing database access.
- `storage.rules`: Security rules governing file access.
- `firebase.json`: Configuration for Cloud Functions, Hosting, and Emulators.
- `analysis_options.yaml`: Linting rules for Dart code quality.
