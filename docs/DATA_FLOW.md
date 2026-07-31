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

## 2. AI Chat Streaming Flow
The most complex data flow in the app is the token-by-token streaming of AI responses.

```mermaid
sequenceDiagram
    participant UI as Chat View
    participant N as ChatNotifier
    participant Repo as ChatRepository
    participant CF as Cloud Function (Proxy)
    participant AI as OpenAI API

    UI->>N: Send Message
    N->>N: Create Optimistic Message
    N->>Repo: requestStream()
    Repo->>CF: HTTP POST (Bearer Token)
    CF->>AI: GPT-4o Stream Request
    AI-->>CF: SSE Tokens
    CF-->>Repo: SSE Tokens
    Repo-->>N: Yield tokens to Stream
    
    loop Per Token
        N->>N: Append chunk to buffer
        N->>N: Throttle UI update (60ms)
        N->>UI: NotifyListeners (Update Markdown)
    end
    
    N->>Repo: persistMessage()
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
