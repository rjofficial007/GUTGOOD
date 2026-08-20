# Project Overview: GutGood

GutGood is an AI-powered nutrition and gut health assistant designed to help users understand how food impacts their unique bodies. By combining advanced AI vision, real-time product data (Open Food Facts), and personalized health context (goals, sensitivities, cycle syncing), GutGood provides actionable insights into every meal.

## Purpose
The application aims to bridge the gap between "what we eat" and "how we feel" by providing a frictionless way to log food, track symptoms, and receive AI-driven advice tailored to the user's specific health profile.

## Main Features
- **Super Scanner:** Hybrid scanning engine supporting Barcode lookup (OFF API) and AI Vision (Label, Menu, and Meal analysis).
- **AI Chat Assistant:** A multi-layered conversational interface (Local Keywords + AI Classifier) that provides nutritional advice, food swaps, and answers health-related queries.
- **Smart Logging:** Automatic extraction of meals and symptoms from chat messages using the `[MEAL]` and `[SYMPTOM]` tagging system.
- **Advanced AI Modes:** Specialized analysis for Symptom Correlation, Product Comparison, and Meal Planning.
- **Personalized Insights:** Weekly recaps and pattern detection that correlate food intake with physical symptoms and hormonal cycles, backed by a rolling `chatSummary`.
- **Cycle Syncing:** Specialized nutritional advice tailored to the user's current menstrual cycle phase.
- **Reliability:** Robust JSON parsing with "auto-repair" logic to handle truncated or malformed AI responses.
- **Privacy First:** Anonymous-first onboarding with secure data migration to permanent accounts.

## Technology Stack
- **Framework:** Flutter (3.11.0+)
- **Backend:** Firebase (Auth, Firestore, Cloud Functions, Storage)
- **AI Engine:** OpenAI GPT-4o / GPT-4o-mini via a secure Cloud Function proxy (`aiProxy`) with server-side quota enforcement.
- **AI Architecture:** Modular prompt engine with dedicated intent-specific logic in `lib/core/services/prompts/mode_prompts/`.
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
