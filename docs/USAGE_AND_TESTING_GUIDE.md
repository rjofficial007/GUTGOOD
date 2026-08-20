# 🌿 GutGood — Usage & Testing Guide

This guide provides instructions on how to use the GutGood app's core features and how to verify their functionality during development and QA.

---

## 📱 Core Features Usage

### 1. Onboarding & Personalization
*   **How to Use**: Complete the initial onboarding flow. Select at least one **Health Goal** (e.g., "Improve Digestion") and one **Sensitivity** (e.g., "Dairy").
*   **What it affects**: The AI assistant uses this profile to ground its advice. For example, if you have a "Dairy" sensitivity, it will flag dairy ingredients in scans.

### 2. AI Chat & Intent-Based Analysis
*   **How to Use**: Go to the **Chat** tab. Type naturally about your food. The app uses an **AI Intent Engine** to dynamically swap personas and instructions.
*   **Feature Modes**:
    *   **Meal Overview**: "I'm having a chicken salad." (Triggers identification and friendly tips).
    *   **Meal Rating**: "Rate my lunch" or "How did I do?" (Triggers a numeric score out of 10).
    *   **Health Assessment**: "Is this healthy?" or "Is this balanced?" (Triggers a "why" based evaluation without a score).
    *   **Meal Swaps**: "What should I change?" or "Alternatives for this?" (Suggests specific improvements).
    *   **Symptom Analysis**: "Why am I bloated?" or "Explain this headache." (Clinical Investigative Analyst persona).
    *   **Product Comparison**: "Coke vs Pepsi: which is better for me?" (Comparative Food Analyst persona).
    *   **Meal Planning**: "What should I eat for dinner tonight?" (Strategic Meal Architect persona).
    *   **Full Analysis**: "Tell me everything about this meal." (Triggers the complete nutrition report).
*   **Passive Logging**: Simply mention a symptom like "I feel bloated" or a food "I ate pizza" to see the `[SYMPTOM]` or `[MEAL]` tags automatically saved to your history.

### 3. Professional Vision Analysis
The app uses specialized personas for different image sources. To ensure high reliability, **Specialized Vision Sources bypass generic AI intent detection** to prevent payload timeouts and persona drift.
*   **Barcode Mode**: **Product Data Intelligence Specialist**. Transforms Open Food Facts data into gut-health metrics.
*   **Meal Snap**: **Elite Nutrition Coach**. Focuses on the "GutGood Trio" (Protein + Fiber + Healthy Fats) for metabolic balance.
*   **Ingredient Label**: **Clinical Food Scientist**. Performs a deep audit of additives, gums, and emulsifiers.
*   **Restaurant Survival**: **Strategic Survival Guide**. Recommends the top 3 best options with ordering "Tips" (e.g., "Sauce on the side").
*   **Gallery Uploads**: Automatically mapped to the **Elite Nutrition Coach** persona for instant, high-energy meal feedback.

### 4. Insights & Long-Term Memory
*   **Rolling History Summary**: The app maintains a 2-3 sentence rolling summary of your entire history (goals, food patterns, symptoms). This is updated every 6-10 messages.
*   **Insights Dashboard**: Correlates your data to find "Healing Foods" and "Trigger Symptoms." It calculates a dynamic **Gut Score** (0-100) based on scan quality and symptom severity. See [INSIGHTS_GENERATION.md](./INSIGHTS_GENERATION.md) for a technical deep-dive into the pattern engine and score logic.

---

## 🧪 Testing & Verification

### 1. Testing Intent Detection & Payload Optimization
Verify that GutGood understands *what* you are asking for while remaining fast and error-free.
*   **Test Case A (Local Keywords)**: Ask "Give me a grade for this."
    *   *Expected Result*: Instant response starting with "**Your plate looks...**". Verify in logs that AI intent detection was **bypassed** for this common phrase.
*   **Test Case B (Payload Stripping)**: Mention a food/symptom to generate a large `[TAG]` block, then ask a follow-up question.
    *   *Expected Result*: Response should be fast. Verify in logs (`ChatNotifier: Sending intent detection prompt`) that the history context **does not** contain raw JSON blocks, preventing `502 Bad Gateway` errors.
*   **Test Case C (Vision Priority)**: Upload a restaurant menu photo.
    *   *Expected Result*: AI should immediately adopt the **Strategic Survival Guide** persona. Verify no `[MEAL]` tag is emitted.

### 2. Testing Tag Parsing & Persistence
*   **Step**: Say "I had sushi and now my stomach hurts."
*   **Verification**: 
    1. Check the console logs (filter: `AI_STREAM_RESULT`) for `[MEAL]` and `[SYMPTOM]` JSON blocks.
    2. Ensure the AI emitted **closing tags** (e.g., `[/MEAL]`).
    3. Navigate to the **History Hub**. Verify that "Sushi" and "Stomach Pain" are logged.

### 3. Testing Persona Consistency
*   **Step**: Take a photo of a restaurant menu.
*   **Verification**: 
    1. Greeting should be high-energy and personalized to the dining experience.
    2. Recommendations must follow the `[Emoji] **Dish Name**` format.
    3. **CRITICAL**: Verify NO structured tags (`[SCAN]`, etc.) are emitted in Menu mode.

### 4. Testing Summarization & Memory
*   **Step**: Mention a "Gluten" sensitivity in chat, then talk for 10 messages.
*   **Verification**: 
    1. Check `lib/core/services/ai_service.dart` logs for "History summary generated".
    2. Ask "What are my main concerns lately?" The AI should recall the sensitivity even if it has "aged out" of the recent message window.

---

## 🛠 Developer Tools
*   **Logs**: Filter by `GUTGOOD` or `AI_STREAM_RESULT` in your IDE/Logcat to see raw AI payloads and intent detection results.
*   **Reset Data**: You can reset your local database and session via the **Profile > Settings > Debug Tools** (if enabled in development builds).
