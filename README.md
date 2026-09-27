# 🌿 GutGood — AI Health Intelligence

**GutGood** is a premium, AI-powered gut health companion built with Flutter and Firebase. It leverages **OpenAI's GPT-4o-mini** and **GPT-4o** models, alongside the **Open Food Facts API**, to provide real-time personalized food swaps, hybrid barcode/label scanning, and dynamic health insights.

---

## ✨ Key Features

* **💬 AI-Powered Chat Assistant:** Chat naturally about your meals, symptoms, and gut health with persistent history and real-time streaming responses.
* **🏷️ Passive Logging:** Automatic extraction of `[MEAL]`, `[SYMPTOM]`, and `[SCAN]` data from chat conversations using advanced tag-parsing UseCases.
* **📷 Hybrid Vision & Barcode Scanner:** Scan barcodes for instant nutrition data via Open Food Facts, or use Vision-AI to analyze ingredient labels and complex meal photos.
* **🍽️ Restaurant Survival Mode:** Upload a menu photo to receive instant, gut-friendly recommendations tailored to your specific goals.
* **🔄 Instant Food Swaps:** Receive personalized, healthier food alternatives based on your health profile and sensitivities.
* **📊 Dynamic Insights Dashboard:** AI-driven analysis of your habits, correlating meals with symptoms to identify triggers and healing foods with historical trend accuracy.
* **🧠 AI Personalization:** Deeply tailored recommendations and insights that evolve with your health journey, including biological "Body Rhythm" factors.
* **🌙 Cycle Syncing:** Optimize your gut health by aligning nutrition and lifestyle with your hormonal phases (for women).
* **💎 Premium Subscriptions:** Integrated with **RevenueCat** for seamless management of GutGood+ features, trial periods, and entitlement verification.

---

## 🛠 Tech Stack

* **Framework:** [Flutter](https://flutter.dev/) (Dart)
* **Navigation:** [GoRouter](https://pub.dev/packages/go_router) (StatefulShellRoute architecture)
* **AI Engine:** [OpenAI API](https://openai.com/) (GPT-4o-mini / GPT-4o) via `openai_dart`
* **Backend:** [Firebase](https://firebase.google.com/) (Auth, Firestore, Storage, Remote Config)
* **Local Database:** `sqflite` (SQLite) for robust offline persistence
* **Image Handling:** `flutter_image_compress` & `cached_network_image`
* **Monitoring:** Firebase Crashlytics & Analytics
* **Subscriptions:** [RevenueCat](https://www.revenuecat.com/)
* **State Management:** [Provider](https://pub.dev/packages/provider)
* **Architecture:** Clean Architecture (Feature-First) with Repository & UseCase patterns

---

## 🏗️ Architecture & Security

### 🧱 Clean Architecture
The project follows a modular, feature-first structure ensuring high testability and separation of concerns:
- **Presentation:** UI widgets, Notifiers (ChangeNotifier), and state management.
- **Domain:** Pure business logic entities and UseCases (e.g., `ProcessChatTagUseCase`).
- **Data:** Repository implementations, data sources (Local SQLite + Remote Firestore), and DTO models.

### 🛡️ Security & Privacy
- **Account Protection:** Guarded against "silent account switches" to prevent accidental data loss during social login merges.
- **Atomic Data Merging:** Robust logic to migrate guest (anonymous) data to permanent accounts without loss.
- **Secure Nonces:** Apple Sign-In implements SHA-256 hashed nonces for identity verification.
- **Safe Deletion:** Irreversible account deletion is sequenced to ensure authentication removal *before* data destruction, preventing unrecoverable data-loss states.

### 💰 Cost & Performance Optimization
- **Vision Optimization:** Images are compressed locally and sent with specialized, lean vision instructions to minimize token usage and latency.
- **Rolling Summarization:** Chat history uses a rolling summary approach, folding new information into existing context rather than re-processing full histories.
- **Fair Metering:** Usage counters (chats/scans) only increment on confirmed successful operations, ensuring a fair experience for all users.

---

## 🎨 Design System

GutGood uses a centralized, unified component architecture to ensure UI consistency:

* **Universal Scroll:** A unified `CustomScrollView` architecture across all screens ensures smooth, native-feeling scroll physics and eliminates "ghost scrolling" artifacts.
* **Standardized App Bar:** Standardized `GutAppBar` components ensure a clean, cohesive visual identity.
* **Unified Input:** `GutTextField` manages all input decorations, focus states, and typography.
* **Standardized Sections:** `GutSection` & `GutSectionCard` enforce a uniform layout pattern with optimized spacing.
* **Visual Trends:** `GutTrendSparkline` provides lightweight, high-performance data visualization for health scores.

---

## 🚀 Production Readiness

- **Observability:** Full integration with **Firebase Crashlytics** for real-time error reporting and **Analytics** for user funnel tracking.
- **Diagnostic Logging:** A centralized `Log` utility that forwarded warnings and errors to Crashlytics in production while providing verbose debug info in development.
- **Update Management:** Integrated with `upgrader` and **Remote Config** for automated update prompts and mandatory "Force Update" control.
- **User Feedback:** Built-in **In-App Review** triggers to capture platform-native user feedback and improve store visibility.
- **Accessibility:** 
    - Unclamped **Dynamic Type** support allowing the app UI to scale with OS font settings.
    - Integrated `Semantics` and `Tooltip` labels for screen reader compatibility.

---

## 🚀 Getting Started

```bash
# 1. Dependencies
flutter pub get

# 2. Firebase wiring — generates lib/firebase_options.dart
dart pub global activate flutterfire_cli
flutterfire configure            # select the Firebase project / platforms

# 3. Backend
cd functions
npm ci
firebase functions:secrets:set OPENAI_API_KEY   # never shipped to devices
firebase deploy --only functions
firebase deploy --only firestore:rules,firestore:indexes,storage
cd ..

# 4. Verify
flutter analyze && flutter test
```

**Notes**

- `lib/firebase_options.dart` is generated and git-ignored. **Without it the project and the test suite will not compile** — step 2 is mandatory on a fresh clone.
- Remote Config keys (defaults are safe if unset): `openai_model` (`gpt-4o-mini`), `ai_proxy_url`, `is_force_update`.
- The OpenAI key lives in Secret Manager only; all AI traffic goes through the `aiProxy` Cloud Function.
- Daily free-tier limits are enforced server-side (`functions/src/config.ts`).

## 📂 Project Structure

```text
lib/
├── core/                     # Core utilities and shared logic
│   ├── constants/            # App-wide constants (Assets, Strings, Sizes)
│   ├── database/             # Local database (SQLite) implementation
│   ├── di/                   # Dependency injection (GetIt)
│   ├── router/               # Centralized GoRouter configuration
│   ├── services/             # Infrastructure services (AI, Sync, Notifications)
│   ├── theme/                # Global theme, AppPalette, and ColorScheme
│   ├── utils/                # Helper functions, extensions, and haptics
│   └── widgets/              # Reusable UI components (Sections, Inputs, Buttons)
├── features/                 # Feature-specific modules
│   ├── auth/                 # Authentication & Onboarding
│   ├── chat/                 # AI Assistant & Tag parsing UseCases
│   ├── history/              # Scan history & Saved Foods
│   ├── insights/             # Health analytics & Trend visualization
│   ├── profile/              # User settings & Goals
│   └── scanner/              # Barcode & Vision-AI scanning
├── main.dart                 # App entry point
└── firebase_options.dart      # Firebase configuration
```

---

## 📄 License

This project is proprietary and confidential. Unauthorized copying of this file, via any medium, is strictly prohibited.
