# 🌿 GutGood — AI Health Intelligence

**GutGood** is a premium, AI-powered gut health companion built with Flutter and Firebase. It leverages **OpenAI's GPT-4o-mini** and **GPT-4o** models, alongside the **Open Food Facts API**, to provide real-time personalized food swaps, hybrid barcode/label scanning, and dynamic health insights.

---

## 📚 Product & Technical Documentation Suite

Comprehensive architecture, product specifications, design tokens, security guides, data models, and feature ticket backlogs are located in the [`docs/`](file:///Volumes/Data/SVN/gutgood_app/Source/gutgood_app/docs) directory:

| Document | Description |
|---|---|
| **[📑 Docs Master Index](file:///Volumes/Data/SVN/gutgood_app/Source/gutgood_app/docs/README.md)** | Overview and index of all project documentation. |
| **[1. Product Requirements Document (PRD)](file:///Volumes/Data/SVN/gutgood_app/Source/gutgood_app/docs/1_prd.md)** | Problem statement, target personas, core features, user flows, and key success metrics. |
| **[2. Technical Architecture Specification](file:///Volumes/Data/SVN/gutgood_app/Source/gutgood_app/docs/2_technical_architecture.md)** | Engineering blueprint, directory layout, Firestore & SQLite database schemas, API contracts, and environment setup. |
| **[3. Security & Access Specification](file:///Volumes/Data/SVN/gutgood_app/Source/gutgood_app/docs/3_security_and_access.md)** | Auth methods, atomic guest migration, roles, Firestore/Storage security rules, error resiliency, and registered decisions (R1–R9). |
| **[4. Frontend & Integration Specification](file:///Volumes/Data/SVN/gutgood_app/Source/gutgood_app/docs/4_frontend_and_integration.md)** | Apple HIG design system port, Dynamic Type scale, `InterTight` bento typography, adaptive color tokens, and component contracts. |
| **[5. Feature Ticket List](file:///Volumes/Data/SVN/gutgood_app/Source/gutgood_app/docs/5_feature_ticket_list.md)** | Actionable engineering backlog across 5 core Epics with acceptance criteria, dependencies, and priority levels. |
| **[6. App Data & Information Architecture Spec](file:///Volumes/Data/SVN/gutgood_app/Source/gutgood_app/docs/APP_DATA_SPECIFICATION.md)** | Pure data models, JSON samples, information hierarchy, and data points required for AI UI/UX generation across all screens. |
| **[🔥 Firebase Setup & Deployment Guide](file:///Volumes/Data/SVN/gutgood_app/Source/gutgood_app/docs/FIREBASE_SETUP_GUIDE.md)** | Step-by-step setup guide for Firebase Auth, Firestore rules, Storage rules, Secret Manager, and Cloud Functions deployment. |

---

## ✨ Key Features

* **💬 AI-Powered Chat Assistant:** Chat naturally about your meals, symptoms, and gut health with persistent history and real-time streaming responses via Server-Sent Events (SSE).
* **🏷️ Passive Logging:** Automatic extraction of `[MEAL]`, `[SYMPTOM]`, and `[SCAN]` data from chat conversations using advanced tag-parsing UseCases.
* **📷 Hybrid Vision & Barcode Scanner:** Scan barcodes for instant nutrition data via Open Food Facts, or use Vision-AI to analyze ingredient labels, NOVA groups, and complex meal photos.
* **🍽️ Restaurant Survival Mode:** Upload a menu photo to receive instant, gut-friendly recommendations tailored to your specific goals and sensitivities.
* **🔄 Instant Food Swaps:** Receive personalized, healthier food alternatives based on your health profile and sensitivities.
* **📊 Dynamic Insights Dashboard:** AI-driven analysis of your habits, correlating meals with symptoms to identify triggers and healing foods with historical trend accuracy.
* **🧠 AI Personalization:** Deeply tailored recommendations and insights that evolve with your health journey, including biological "Body Rhythm" factors.
* **🌙 Cycle Syncing:** Optimize your gut health by aligning nutrition and lifestyle with your hormonal phases (for women).
* **💎 Premium Subscriptions:** Integrated with **RevenueCat** for seamless management of GutGood+ features, trial periods, and entitlement verification.

---

## 🛠 Tech Stack

* **Framework:** [Flutter](https://flutter.dev/) (Dart 3.11+)
* **Navigation:** [GoRouter](https://pub.dev/packages/go_router) (`StatefulShellRoute` architecture)
* **AI Engine:** [OpenAI API](https://openai.com/) (GPT-4o-mini / GPT-4o) via serverless `aiProxy` Cloud Function
* **Backend:** [Firebase](https://firebase.google.com/) (Auth, Firestore, Storage, Remote Config, Cloud Functions, Messaging)
* **Local Database:** `sqflite` (SQLite) for robust offline persistence and outbox queuing
* **Image Handling:** `flutter_image_compress` & `cached_network_image`
* **Monitoring:** Firebase Crashlytics & Analytics
* **Subscriptions:** [RevenueCat](https://www.revenuecat.com/) (`purchases_flutter`)
* **State Management:** [Provider](https://pub.dev/packages/provider) + `GetIt` Service Locator
* **Architecture:** Clean Architecture (Feature-First) with Repository & UseCase patterns

---

## 🏗️ Architecture & Security

### 🧱 Clean Architecture
The project follows a modular, feature-first structure ensuring high testability and separation of concerns:
- **Presentation:** UI widgets, Notifiers (`ChangeNotifier`), and state management.
- **Domain:** Pure business logic entities and UseCases (e.g., `ProcessChatTagUseCase`, `ProcessChatComposerUseCase`).
- **Data:** Repository implementations, data sources (Local SQLite + Remote Firestore), and DTO models.

### 🛡️ Security & Privacy
- **Account Protection:** Guarded against "silent account switches" to prevent accidental data loss during social login merges.
- **Atomic Data Merging:** Robust logic (`mergeAnonymousAccount` Cloud Function) to migrate guest (anonymous) data to permanent accounts without loss.
- **Secure Nonces:** Apple Sign-In implements SHA-256 hashed nonces for identity verification.
- **Safe Deletion:** Irreversible account deletion is sequenced via `deleteAccount` to ensure authentication removal *before* data destruction, preventing unrecoverable data-loss states.

### 💰 Cost & Performance Optimization
- **Vision Optimization:** Images are compressed locally to max 1024px before transmission to minimize token usage and latency.
- **Rolling Summarization:** Chat history uses a rolling summary approach, folding new information into existing context rather than re-processing full histories.
- **Fair Metering:** Usage counters (chats/scans) only increment on confirmed successful operations, enforcing daily free quotas server-side.

---

## 🎨 Design System

GutGood uses a centralized, unified component architecture conforming to the Apple Human Interface Guidelines (HIG):

* **Universal Scroll:** A unified `CustomScrollView` architecture across all screens ensures smooth, native-feeling scroll physics.
* **Standardized App Bar:** Standardized `GutAppBar` components with liquid frosted glass blur.
* **Unified Input:** `GutTextField` manages all input decorations, focus states, and typography.
* **Standardized Sections:** `GutSection` & `GutSectionCard` enforce a uniform 12pt rounded corner layout pattern with 0.5pt hairline borders.
* **Bento Feed:** Custom modular bento grid utilizing `InterTight` typography for health score & body pattern visualizations.

---

## 🚀 Quick Start & Deployment

```bash
# 1. Install Flutter Dependencies
flutter pub get

# 2. Configure Firebase
dart pub global activate flutterfire_cli
flutterfire configure            # Select project and target platforms

# 3. Deploy Cloud Functions & Database Security Rules
cd functions
npm ci
npm run build
firebase functions:secrets:set OPENAI_API_KEY   # Secret stored in Secret Manager
firebase deploy --only functions,firestore:rules,storage
cd ..

# 4. Analyze & Run
flutter analyze
flutter run
```

---

## 📂 Directory Structure

```text
gutgood_app/
├── docs/                     # Full Documentation Suite
│   ├── README.md             # Docs Master Index
│   ├── 1_prd.md              # Product Requirements Document
│   ├── 2_technical_architecture.md
│   ├── 3_security_and_access.md
│   ├── 4_frontend_and_integration.md
│   ├── 5_feature_ticket_list.md
│   ├── APP_DATA_SPECIFICATION.md # Data & Information Architecture Specification
│   └── FIREBASE_SETUP_GUIDE.md # Firebase Setup & Deployment Guide
│
├── functions/                # Firebase Cloud Functions (TypeScript)
│   ├── src/
│   │   ├── ai_proxy.ts       # OpenAI HTTPS proxy with streaming & quota guard
│   │   ├── auth.ts           # Magic link & delete account callables
│   │   ├── merge.ts          # Guest to permanent user account migration
│   │   └── lifecycle.ts      # User lifecycle triggers & 14-day cron cleanup
│   └── package.json
│
├── lib/                      # Flutter Application Codebase
│   ├── core/                 # Shared utilities, services, theme, and core widgets
│   ├── features/             # Feature modules (auth, chat, history, insights, scanner)
│   └── main.dart             # Application entry point
│
└── firebase_options.dart     # Auto-generated Firebase configuration
```

---

## 📄 License

This project is proprietary and confidential. Unauthorized copying of this file, via any medium, is strictly prohibited.
