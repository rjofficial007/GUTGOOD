# Project Overview: GutGood

GutGood is an AI-powered nutrition and gut health assistant designed to help users understand how food impacts their unique bodies. By combining advanced AI vision, real-time product data (Open Food Facts), and personalized health context (goals, sensitivities, cycle syncing), GutGood provides actionable insights into every meal.

## Purpose
The application aims to bridge the gap between "what we eat" and "how we feel" by providing a frictionless way to log food, track symptoms, and receive AI-driven advice tailored to the user's specific health profile.

## Main Features
- **Super Scanner:** Hybrid scanning engine supporting Barcode lookup (OFF API) and AI Vision (Label, Menu, and Meal analysis).
- **AI Chat Assistant:** A streaming conversational interface that provides nutritional advice, food swaps, and answers health-related queries.
- **Smart Logging:** Automatic extraction of meals and symptoms from chat messages using the `[MEAL]` and `[SYMPTOM]` tagging system.
- **Personalized Insights:** Weekly recaps and pattern detection that correlate food intake with physical symptoms and hormonal cycles.
- **Cycle Syncing:** Specialized nutritional advice tailored to the user's current menstrual cycle phase.
- **Privacy First:** Anonymous-first onboarding with secure data migration to permanent accounts.

## Technology Stack
- **Framework:** Flutter (3.11.0+)
- **Backend:** Firebase (Auth, Firestore, Cloud Functions, Storage)
- **AI Engine:** OpenAI GPT-4o / GPT-4o-mini (via secure Cloud Function proxy)
- **Payments:** RevenueCat (purchases_flutter) for subscription management
- **Product Data:** Open Food Facts API
- **Local Persistence:** SharedPreferences (Settings) and Firestore Persistence (Cache)

## Folder Structure
- `lib/core/`: Application-wide constants, models, services, and shared widgets.
- `lib/features/`: Feature-sliced architecture containing UI, business logic, and data layers for:
    - `auth/`: Authentication and account management.
    - `chat/`: Conversational AI interface.
    - `scanner/`: Barcode and vision scanning.
    - `insights/`: AI-generated reports and recaps.
    - `logs/`: Meal and symptom tracking UI.
    - `profile/`: User settings and health personalization.
- `functions/`: Firebase Cloud Functions (TypeScript) for secure server-side logic.

## Architecture & Design Patterns
- **Clean Architecture:** Separation into `data`, `domain`, and `presentation` layers.
- **State Management:** `Provider` with `ChangeNotifier` for reactive UI updates.
- **Dependency Injection:** `GetIt` for service localization and decoupling.
- **Feature-Based Routing:** `go_router` with nested shells for tab navigation.
