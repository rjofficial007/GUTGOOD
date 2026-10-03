# 1. Product Requirements Document (PRD)

> **Product Name:** GutGood — AI Health Intelligence  
> **Target Platform:** iOS & Android (Flutter)  
> **Current implementation alignment:** 2026-10-03
> **Document Purpose:** Define what we are building, who it is for, and why it matters to align product, engineering, and design teams.

---

## 1. Problem Statement

Modern dietary habits, ultra-processed foods (UPFs), hidden additives, and artificial emulsifiers are leading causes of chronic gut distress—including bloating, Irritable Bowel Syndrome (IBS), acid reflux, skin flare-ups, and unexplained fatigue.

Key user pain points:
* **Obscure Labels & Ingredients:** Traditional food labels are difficult to decipher, hiding gut irritants under complex chemical names and numbers (e.g., E407 Carrageenan, E466 CMC).
* **Calorie-Centric vs. Quality-Centric:** Existing nutrition apps focus exclusively on calories and macros, ignoring microbiome health, ingredient quality, NOVA classification, and individual food sensitivities.
* **Delayed Symptom Correlation:** Food-induced symptoms often peak 12 to 48 hours after consumption, making it nearly impossible for individuals to manually connect what they ate with how they feel.
* **Lack of Actionable Swaps:** Users are told what is "bad," but are rarely given instant, practical, and healthier food alternatives suited to their personal taste and health goals.

**GutGood solves this** by acting as an intelligent, personalized gut health companion that combines hybrid vision scanning, passive AI conversational logging, real-time symptom correlation, and instant food swaps.

---

## 2. Target Users & Needs

### Target Personas

| Persona | Core Needs | GutGood Solution |
|---|---|---|
| **1. The Sensitive Gut Sufferer** *(IBS, Bloating, Reflux)* | Needs to identify personal trigger foods, track symptom severity, and avoid hidden inflammatory additives. | Hybrid ingredient scanner, symptom log, correlation engine, and additive sensitivity warnings. |
| **2. The Clean Eater & Health Optimizer** | Seeks non-UPF foods, organic choices, clean labels, and high-quality nutrient density. | NOVA group classification, UPF detection score, and clean food swaps. |
| **3. The Hormonal & Cycle Syncing User** | Experiences fluctuating digestion based on menstrual cycle phases and needs tailored nutrition advice. | Cycle phase tracking (Follicular, Luteal, Menstrual, Ovulatory) with phase-specific gut health recommendations. |
| **4. The Dining-Out Explorer** | Needs quick guidance when eating at restaurants without triggering digestive distress. | "Restaurant Survival Mode" menu scanner that ranks menu items by gut safety. |

---

## 3. Core Features

### 3.1 Hybrid Barcode & Vision Scanner
* **Barcode Scanning:** Real-time barcode scanning via Open Food Facts database for instant product lookup, NOVA classification, and additive breakdown.
* **Ingredient Label Vision-AI:** Uses OpenAI GPT Vision to parse raw ingredient lists from photos when barcodes are missing or unavailable.
* **Meal Snap:** Vision-AI analysis of cooked or raw meals to identify ingredients, estimate gut impact, and log meals effortlessly.
* **Restaurant Menu Survival Mode:** Analyzes photographed restaurant menus, ranking dishes from safest to highest risk based on the user's profile.

### 3.2 AI Chat Companion & Passive Logging
* **Conversational Logging:** Users can naturally type or dictate what they ate or how they feel (e.g., *"Had a latte with oat milk and feel bloated now"*).
* **Automated Tag Parsing:** Custom UseCases parse conversations to extract structured `[MEAL]`, `[SYMPTOM]`, and `[SCAN]` entries automatically.
* **Persistent Streaming Chat:** Real-time Server-Sent Events (SSE) streaming responses backed by OpenAI models.

### 3.3 Dynamic Insights & Daily Gut Score
* **Gut Score Algorithm (0–100):** Daily score calculating food quality, symptom burden, fiber diversity, UPF ratio, and hydration.
* **Bento Grid Insights Dashboard:** Modular visual cards highlighting top trigger candidates, healing foods, body rhythm patterns, and active gut experiments.
* **Symptom Correlation Engine:** Algorithmic detection of recurring symptom flare-ups following specific ingredients over a 14-day rolling window.

### 3.4 Personalized Food Swaps
* **Instant Alternatives:** Recommends 1:1 healthier, less inflammatory swaps for scanned or logged products (e.g., swapping a high-additive cereal for a clean-ingredient granola).

### 3.5 Cycle Syncing Integration
* **Hormonal Phase Adaptation:** Adjusts gut recommendations and symptom sensitivity expectations according to the user's menstrual phase.

### 3.6 RevenueCat Premium Subscriptions (GutGood+)
* **Freemium Tier:** Free daily quotas for scans (5/day) and AI chat messages (10/day).
* **GutGood+ Premium:** Unlimited AI scanning, vision analysis, deep bento insights, and menu analysis.

---

## 4. User Flow

```
[Onboarding & Health Profile Setup]
        │
        ▼
[Main Shell Navigation]
 ├── 1. Scanner Mode (Barcode / Ingredient Label / Meal Snap / Menu)
 ├── 2. Insights Dashboard (Daily Gut Score, Body Patterns, Active Experiments)
 ├── 3. AI Companion Chat (Conversational Logging & Real-time Q&A)
 ├── 4. History & Journal (Scan History, Saved Foods, Symptom Timeline)
 └── 5. Profile & Settings (Goals, Sensitivities, Cycle Sync, Premium)
        │
        ▼
[Primary User Loop]
  Log Meal or Scan Product
        │
        ├──> Instant AI Health Score & Additive Warning
        ├──> Food Swap Suggestions Offered
        └──> Automatic Entry saved to Journal
        │
  Log Symptom (12-48h later)
        │
        ▼
[Correlation Engine Updates Gut Score & Triggers New AI Insight]
```

---

## 5. Success Metrics

| Metric | Target | Measurement Method |
|---|---|---|
| **User Retention (30-Day)** | > 40% active retention | Firebase Analytics Cohort Analysis |
| **Scan Resolution Rate** | > 95% successful scan parsing | Open Food Facts API + GPT Vision fallback logs |
| **AI Chat Latency** | < 2.0s Time-To-First-Token | Performance Monitoring on `aiProxy` Cloud Function |
| **Symptom Reduction Impact** | +15 point avg Gut Score increase in 30 days | User historical Gut Score records |
| **Paywall Conversion** | > 5% onboarding conversion | RevenueCat Purchase Events |

---

## 6. Current implementation alignment

The product behavior described above is implemented through a feature-first Flutter structure:

- Chat, Scanner, and Insights retain ownership of their orchestration, loading states, persistence decisions, and user-facing error flows.
- Shared AI infrastructure lives under `lib/core/ai/`; the feature layers depend on the `AiClient` contract rather than a concrete provider SDK.
- The active Insights feed uses semantic source names under `lib/features/insights/presentation/widgets/insight_feed/`. Historical `v2` schema/version values remain data terminology only.
- Product contracts—Firestore collections, serialized fields, AI envelopes, API payloads, quotas, and user-facing flows—remain unchanged by the source naming refactor.
