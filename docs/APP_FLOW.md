# Application Flow

This document outlines the primary user journeys and logical flows within the GutGood application.

## 1. App Launch & Initialization
The app starts with an authentication check and initialization of core services (Crashlytics, Versioning, Device Info).

```mermaid
graph TD
    Start((Launch)) --> Init[Initialize Firebase & GetIt]
    Init --> AuthCheck{Is Authenticated?}
    
    AuthCheck -- No --> Welcome[Welcome Screen]
    AuthCheck -- Yes --> OnboardingCheck{Is Onboarded?}
    
    OnboardingCheck -- No --> Onboarding[Onboarding Flow]
    OnboardingCheck -- Yes --> Home[Home / Chat Screen]
    
    Welcome --> AnonLogin[Anonymous Login]
    AnonLogin --> Onboarding
```

---

## 2. Onboarding Flow
Personalization happens during onboarding. Users select goals, sensitivities, and lifestyle factors.

```mermaid
graph TD
    Start[Goals Selection] --> Sens[Sensitivities]
    Sens --> Life[Lifestyle]
    Life --> Cycle[Cycle Sync Opt-in]
    Cycle --> AI[AI Personalization Prep]
    AI --> Paywall[Subscription / Paywall]
    Paywall --> Finish((Home))
```

---

## 3. Authentication & Account Migration
Users can start anonymously and later link their data to a permanent account (Google, Apple, or Email).

```mermaid
graph TD
    Guest[Guest User] --> Upgrade[Link Account Button]
    Upgrade --> Select[Choose Provider]
    Select --> Link{Link Success?}
    
    Link -- Yes --> Success[Account Permanent]
    Link -- Conflict[Credential in Use] --> Merge[Show Merge Dialog]
    
    Merge -- Confirm --> CloudMerge[Trigger mergeAnonymousAccount Function]
    CloudMerge --> ReInit[Reset Local State]
    ReInit --> Success
```

---

## 4. Food Scanner Flow
The "Super Scanner" handles multiple input types and resolves them to a unified `ScanResult`.

```mermaid
graph TD
    Open[Open Scanner] --> Mode{Select Mode}
    
    Mode -- Barcode --> ScanB[Scan Barcode]
    ScanB --> OFF[Open Food Facts Lookup]
    OFF -- Found --> AI[AI Analysis & Personalization]
    OFF -- Not Found --> Vision[Fallback to AI Vision]
    
    Mode -- Menu/Label/Food --> Snap[Capture Photo]
    Snap --> Vision
    
    Vision --> Result[Unified Scan Result Screen]
    Result --> Log[Optional: Log as Meal]
```

---

## 5. AI Chat & Message Tagging
The chat interface streams AI responses and automatically extracts actionable data.

```mermaid
sequenceDiagram
    participant User
    participant Notifier
    participant Proxy as Cloud Function Proxy
    participant AI as OpenAI
    participant DB as Firestore

    User->>Notifier: Send message (text/image)
    Notifier->>DB: Save User Message (Optimistic)
    Notifier->>Proxy: Stream Request
    Proxy->>AI: GPT-4o Request
    AI-->>Proxy: Streaming Tokens
    Proxy-->>Notifier: Chunked Text
    
    loop Parsing
        Notifier->>Notifier: Check for [MEAL] or [SYMPTOM] tags
        Notifier->>DB: Auto-log meal/symptom if tag complete
    end
    
    Notifier-->>User: Display Formatted Markdown
```

---

## 6. Insights & Recaps
The app periodically generates insights based on the user's logs.

```mermaid
graph TD
    Logs[Meal & Symptom Logs] --> Trigger[Weekly Timer / Manual Request]
    Trigger --> Engine[Pattern Engine Service]
    Engine --> AI[AI Synthesis]
    AI --> Recap[Weekly Recap Screen]
    Recap --> History[Insights History]
```
