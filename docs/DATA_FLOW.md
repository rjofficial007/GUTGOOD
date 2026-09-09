# Data Flow Architecture

This document describes how data moves through the GutGood application, from user interaction to cloud persistence and AI analysis.

## 1. Core Data Path (Unidirectional Flow)
GutGood follows a predictable flow for data mutations:

```mermaid
graph LR
    UI[Flutter Widget] --> Action[Notifier Action]
    Action --> Repo[Repository Implementation]
    Repo --> Service[Firebase Service]
    Service --> Firestore[Cloud Firestore]
    Firestore -- Listener --> UI
```

---

## 2. AI Chat Streaming & Intent Flow
The tokens move from OpenAI through a secure proxy, with dynamic persona switching.

```mermaid
sequenceDiagram
    participant UI as Chat View
    participant N as ChatNotifier
    participant IE as Intent Engine
    participant Repo as ChatRepository
    participant CF as Cloud Function (aiProxy)
    participant AI as OpenAI API

    UI->>N: Send Message
    N->>IE: Multi-Layered Intent Detection
    IE->>IE: 1. Local Keyword Match
    IE->>AI: 2. AI Intent Classifier
    N->>N: Select Mode Prompt (lib/core/services/prompts/mode_prompts/)
    N->>N: Optimize Payload (Strip Tags from History)
    N->>Repo: requestStream()
    Repo->>CF: HTTP POST (Auth Token + Optimized Payload)
    CF->>CF: Enforce Quotas & Security
    CF->>AI: GPT-4o Request
    AI-->>CF: SSE Tokens
    CF-->>Repo: SSE Tokens
    Repo-->>N: Yield tokens to Stream
    
    loop Per Token
        N->>N: Append chunk to buffer
        N->>N: Auto-Repair JSON (ModelUtils)
        N->>UI: NotifyListeners
    end
```

---

## 3. Food Scanning Data Flow
Resolving a physical product to a personalized health insight.

```mermaid
graph TD
    Cam[Camera/Gallery] --> Snap[Captured Image]
    Snap --> ScannerN[ScannerNotifier]
    
    subgraph "External Lookup"
        ScannerN --> OFF[Open Food Facts Service]
        OFF --> Raw[Raw Product Data]
    end
    
    subgraph "Personalization"
        Raw --> AI[AiService]
        AI --> SystemPrompt[Remote Config System Prompt]
        AI --> UserContext[Goals / Sensitivities / Cycle Phase]
    end
    
    AI --> Result[ScanResult Model]
    Result --> History[Save to scan_history]
    History --> UI[Display Result Screen]
```

---

## 4. Insight Generation Flow
Correlating logs into actionable patterns.

```mermaid
graph TD
    ML[Meal Logs] --> P[Pattern Engine]
    SL[Symptom Logs] --> P
    P --> Corr[Food-Symptom Correlations]
    Corr --> AI[AiService: Summarize]
    AI --> Insight[AIInsight Model]
    Insight --> View[Insights UI]
```

---

## 5. Offline & Synchronization
- **Write Path:** All Firestore writes (`set`, `update`, `delete`) are handled by the Firestore SDK, which queues them locally if the device is offline.
- **Read Path:** Snapshots are served from the local cache first, then merged with server updates.
- **Optimistic UI:** Feature Notifiers (like `ChatNotifier`) maintain a `Set<String> optimisticIds` to keep locally-created messages visible while Firestore background sync completes.

---

## 6. AI Turn Persistence Pipeline (Phase 2)

Both the chat path (`PersistAiResponseUseCase`) and the scanner path
(`ScannerRepositoryImpl.saveScanResult`) persist records through one shared
router, so their policies can no longer diverge:

```mermaid
graph TD
    T[Parsed AI Turn] --> V[AiResponseValidator]
    V -->|confidence < 0.6, non-food/uncertain verdict,<br/>unsupported envelope, model declined| CO[Chat-only: message renders,<br/>no history records]
    V -->|valid| P[DomainEventPersister]
    P -->|label/menu turn| CO
    P -->|scan + loggable| SH[(scan_history)]
    P -->|meal + consumption intent| JL[(journal_logs)]
    P -->|symptoms| JL
    P --> O[PersistOutcome:<br/>hydrated IDs + flags]
    O --> ChatBubble[Chat bubble embeds<br/>hydrated result]
```

- **Chat-only is a first-class outcome**, not an error: low-confidence,
  non-food, and label/menu turns render in chat but write no records.
- **Consumption gate:** a meal block is logged as EATEN only when the turn
  intent describes consumption (`MEAL_RATING`, `MEAL_RECOGNITION`,
  `COMPLETE_ANALYSIS`, legacy empty intent). Questions *about* food
  ("is this healthy?") show the meal in chat without creating a log.
- **Clock split:** writes stamp `createdAt` = log time (ordering clock);
  AI `time` estimates land in `occurredAt` + `occurredAtProvenance`.
  Readers display/correlate on `eventTime` (occurredAt ?? createdAt).
- **Prompt contract:** the model is asked for `"v": 1` and
  `"verdict": "food|non_food|uncertain"` on every `[GUTGOOD_DATA]` block
  (see `schema_definitions.dart`); missing fields are tolerated for
  backward compatibility.
