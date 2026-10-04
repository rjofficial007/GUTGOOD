# 📚 GutGood Documentation Index

**Status:** Current source alignment updated 2026-10-03
**Source of truth:** The Flutter application under `lib/`, Firebase Functions under `functions/`, and Firebase deployment files at the repository root.

Firebase initialization remains in `lib/app/bootstrap.dart`. Shared Firebase adapters live under `lib/infrastructure/firebase/`; feature repositories and orchestration remain under `lib/features/`.

This documentation describes the current GutGood product and implementation. The source tree uses semantic feature names and direct canonical imports. Standalone forwarding/deprecated compatibility files have been removed; persisted field names and schema/version values remain unchanged where they are data contracts.

---

## 📄 Product and engineering documents

| Document | Description |
|---|---|
| [1. Product Requirements](1_prd.md) | Product problem, users, feature behavior, flows, and success metrics. |
| [2. Technical Architecture](2_technical_architecture.md) | Current folder structure, dependency direction, persistence, APIs, and configuration. |
| [3. Security & Access](3_security_and_access.md) | Authentication, authorization, Firebase rules, AI proxy security, and resiliency. |
| [4. Frontend & Integration](4_frontend_and_integration.md) | Design tokens, component ownership, UI contracts, and external integrations. |
| [5. Feature Ticket List](5_feature_ticket_list.md) | Feature backlog, acceptance criteria, dependencies, and implementation status. |
| [AI Modes Overview](AI_MODES_OVERVIEW.md) | Canonical AI prompt modes, classification, validation, and scanner orchestration. |
| [App Data Specification](APP_DATA_SPECIFICATION.md) | Persisted data models, structured AI envelopes, and screen data requirements. |
| [Models and UI Mapping](MODELS_AND_UI_MAPPING.md) | Domain model, mock data, and presentation mapping. |
| [Firebase Setup Guide](FIREBASE_SETUP_GUIDE.md) | Firebase project, rules, secrets, Functions, and emulator setup. |

## 📐 Architecture and review records

| Document | Description |
|---|---|
| [Architecture Refactor Report](ARCHITECTURE_REFACTOR_REPORT.md) | Detailed behavior-preserving refactor record and validation history. |
| [Application Codebase Guide](APP_CODEBASE_GUIDE.md) | Practical walkthrough of startup, architecture, DI, feature flows, persistence, notifications, and navigation. |
| [Senior Engineering Architecture Review](SENIOR_ENGINEERING_ARCHITECTURE_REVIEW.md) | Risk assessment, dependency review, scalability concerns, and follow-up plan. |

## 🎨 Visual references

| Document | Description |
|---|---|
| [GutGood Screen Gallery](GUTGOOD_SCREENS.html) | Static screen gallery covering launch, chat, insights, history, scanner, profile, and overlays. |
| [Insights Gallery](INSIGHTS.html) | Static visual reference for the semantic Insights feed, Bento cards, states, and loading views. |

---

## 🧭 Current code map

```text
firebase.json                 # Firebase CLI project/deployment configuration
.firebaserc                   # Firebase project aliases
firestore.rules               # Firestore security rules
storage.rules                 # Cloud Storage security rules
functions/                    # Firebase Cloud Functions
lib/
├── app/                         # Bootstrap, grouped DI, router, theme
├── core/
│   ├── ai/                      # Shared AI client, proxy, prompts, protocol, validation
│   ├── constants/               # App constants and string catalogs
│   ├── data/                    # Shared reference data
│   ├── di/                      # GetIt handle only
│   ├── errors/                  # SDK-neutral failure types
│   ├── models/                  # Shared domain/persistence models
│   ├── router/                  # Route values and navigation ports
│   ├── services/                # Shared app state, configuration, and policies
│   ├── theme/                   # Shared design tokens and extensions
│   ├── utils/                   # Pure and platform-adjacent helpers
│   └── widgets/                 # Core-only reusable widgets
├── infrastructure/
│   ├── ai/                      # Concrete AI proxy implementation
│   ├── firebase/                # Shared Firebase adapters and Firestore services
│   │   └── firestore/
│   ├── open_food_facts/         # Open Food Facts/Dio adapter
│   ├── payments/                # RevenueCat purchase adapter
│   └── platform/                # Device, connectivity, app, and platform adapters
└── features/
    ├── auth/
    ├── chat/
    ├── history/
    ├── insights/                # application, data, domain, presentation
    ├── onboarding/
    ├── product_details/
    ├── profile/
    └── scanner/
```

### AI boundary

- Contract: `lib/core/ai/client/ai_client.dart`
- Proxy implementation: `lib/infrastructure/ai/ai_proxy_client.dart`
- Shared protocol, prompts, and validation: `lib/core/ai/`
- Prompt catalog and schemas: `lib/core/ai/prompts/`
- Structured result and constants: `lib/core/ai/protocol/`
- Response validation: `lib/core/ai/validation/`
- Feature orchestration: Chat, Scanner, and Insights under `lib/features/`

### Insights naming

The active Insights presentation uses semantic names:

- `lib/features/insights/presentation/widgets/insight_feed/`
- `InsightsFeed`
- `InsightFeedDerivations`
- `lib/core/models/insights/insight_blocks.dart`
- `lib/features/insights/application/usecases/`

Terms such as `v2` that remain in persisted schemas, API versions, or migration documentation are contract terminology, not source-folder names.

---

## 🧪 Validation

Static repository validation covers package-local imports, relative imports, `part` relationships, feature-domain dependency direction, duplicate typed DI registrations, and stale compatibility-path references. Run it with:

```bash
python3 tool/check_architecture.py
```

Full analyzer, test, and platform-build validation must still be run in an environment with Dart and Flutter installed.
