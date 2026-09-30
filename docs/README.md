# 📚 GutGood Documentation Index

Welcome to the comprehensive documentation suite for **GutGood — AI Health Intelligence**.

This documentation package has been generated based on the application's actual implementation, architecture, and design specifications.

---

## 📄 Documentation Directory

| Document | Description | Key Sections |
|---|---|---|
| **[1. Product Requirements Document (PRD)](file:///Volumes/Data/SVN/gutgood_app/Source/gutgood_app/docs/1_prd.md)** | Core product definition, problem statement, target personas, features, user flows, and success metrics. | Problem Statement, Target Personas, Core Features, User Flow, Success Metrics |
| **[2. Technical Architecture Document](file:///Volumes/Data/SVN/gutgood_app/Source/gutgood_app/docs/2_technical_architecture.md)** | Engineering blueprint detailing system components, folder structures, database schemas, APIs, and environment configs. | Tech Stack, File & Folder Structure, Database Schema, API Structure, Environment & Config |
| **[3. Security & Access Document](file:///Volumes/Data/SVN/gutgood_app/Source/gutgood_app/docs/3_security_and_access.md)** | Authentication mechanisms, access roles, Firestore & Storage security rules, error resiliency, and edge cases. | Auth Methods, Roles & Capabilities, Security Rules, Error Resiliency, Registered Decisions (R1–R9) |
| **[4. Frontend & Integration Specification](file:///Volumes/Data/SVN/gutgood_app/Source/gutgood_app/docs/4_frontend_and_integration.md)** | Apple HIG design tokens, typography scale, component architecture, spacing rules, and API integration contracts. | Color Palette, Typography Scale, Core Components, Spacing & Layout, API Integration Contracts |
| **[5. Feature Ticket List](file:///Volumes/Data/SVN/gutgood_app/Source/gutgood_app/docs/5_feature_ticket_list.md)** | Actionable engineering ticket backlog broken down by feature epics with explicit acceptance criteria and dependencies. | Epic Backlog, Acceptance Criteria, System Dependencies, Priority Levels |
| **[6. App Data & Information Architecture Spec](file:///Volumes/Data/SVN/gutgood_app/Source/gutgood_app/docs/APP_DATA_SPECIFICATION.md)** | Pure data models, JSON samples, information hierarchy, and data points required for AI UI/UX generation across all screens. | Information Hierarchy, Insights Payloads, Scan Payloads, Menu Survival, Chat & Profile Specs |

---

## 🛠 Project Overview Quick References

* **Frontend Framework:** Flutter (Dart 3.11+) with Clean Architecture (Feature-First)
* **Backend:** Firebase Cloud Functions (TypeScript), Auth, Firestore, Storage, Remote Config
* **AI Core:** OpenAI GPT-4o / GPT-4o-mini via `aiProxy` Cloud Function with SSE streaming
* **Nutrition Data:** Open Food Facts API + GPT Vision AI
* **Design System:** Apple Human Interface Guidelines (HIG) with InterTight bento typography
* **Subscriptions:** RevenueCat (`purchases_flutter`)
