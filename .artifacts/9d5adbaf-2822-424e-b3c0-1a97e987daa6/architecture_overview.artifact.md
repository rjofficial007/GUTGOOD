# GutGood — Architecture & Data Flow Overview

## 🏗️ High-Level Architecture

GutGood follows **Clean Architecture** (Feature-First) on the frontend and leverages a **Serverless Firebase Backend**.

### 📱 Frontend (Flutter)
- **Framework:** Flutter (Clean Architecture)
- **State Management:** `Provider` (ChangeNotifier) for presentation state.
- **Dependency Injection:** `GetIt` for service and repository orchestration.
- **Navigation:** `GoRouter` with `StatefulShellRoute` for a persistent bottom navigation shell.
- **Persistence:** Firestore Persistence (primary) + SQLite (referenced in docs, but Firestore's native cache is the active implementation).

### ☁️ Backend (Firebase)
- **Authentication:** Firebase Auth (Supports Anonymous, Google, Apple, and Email/Magic Link).
- **Database:** Cloud Firestore (Hierarchical: `user_profiles/{uid}/[sub-collections]`).
- **Storage:** Firebase Storage (User-uploaded images/photos).
- **Functions:** Firebase Cloud Functions (Node.js/TypeScript).
- **AI Gateway:** `aiProxy` (HTTPS Function) acts as the secure, authenticated bridge to OpenAI.

---

## 🔄 Core Data Flows

### 1. AI Chat Flow (Streaming & Passive Logging)
The chat system is the central intelligence hub, using "Passive Logging" to extract data from natural conversation.

```mermaid
sequenceDiagram
    participant U as User
    participant P as Provider (ChatHistory)
    participant UC as SendMessageUseCase
    participant AI as aiProxy (Cloud Function)
    participant OAI as OpenAI API
    participant TAG as ProcessChatTagUseCase
    participant FS as Firestore

    U->>P: Type Message / Send
    P->>UC: Execute
    UC->>AI: POST /aiProxy (Firebase ID Token)
    AI->>OAI: Streaming Request (GPT-4o)
    OAI-->>AI: Token Streams
    AI-->>P: SSE (data: {"d":"..."})
    P->>TAG: Streamed Text
    TAG->>TAG: Detect [MEAL] | [SYMPTOM] | [SCAN]
    TAG->>FS: Async Log (if tag closed)
    P->>U: Update UI (Token by Token)
    TAG-->>P: Strip Tags for UI Display
```

### 2. Hybrid Scanner Flow
Combines deterministic barcode lookup with probabilistic AI vision analysis.

```mermaid
graph TD
    A[Scanner UI] --> B{Scan Type}
    B -- Barcode --> C[OFF Repository]
    C -- Success --> D[Open Food Facts API]
    C -- Not Found --> E[Vision Fallback]

    D --> F[aiProxy - Analyze Product]
    E --> G[aiProxy - Analyze Image]

    F --> H[ScanResult]
    G --> H

    H --> I[Save to scan_history]
    H --> J[Passive Meal Logging if applicable]
    I --> K[Display Results UI]
```

### 3. Usage Metering & Quotas
Enforces server-authoritative limits to prevent client-side bypassing.

```mermaid
sequenceDiagram
    participant C as Flutter Client
    participant AI as aiProxy
    participant U as Usage Logic (Admin SDK)
    participant FS as Firestore (daily_usage)

    C->>AI: Request AI Task
    AI->>U: checkAndConsume(uid, type)
    U->>FS: Transactional Read/Write
    FS-->>U: Allowed? (bool)
    U-->>AI: Allowed?
    AI-->>C: 429 Quota Exceeded (if denied)
    AI->>C: Proceed to OpenAI (if allowed)
```

## 🛡️ Security & Integrity Patterns

1. **Secret Management:** OpenAI keys are stored in **Cloud Secret Manager**, never exposed to the client or Remote Config.
2. **Identity-Bound Data:** Security rules ensure `request.auth.uid == userId` for all reads/writes.
3. **Atomic Merging:** A dedicated Cloud Function (`mergeAnonymousAccount`) uses Admin SDK to atomically move data when a guest upgrades to a permanent account, preventing data fragmentation.
4. **Idempotency:** Cloud Functions use `idempotencyKey` from the client to prevent duplicate operations (e.g., double streaks or duplicate chat messages) during network retries.
