# 📊 How Insights are Generated

The GutGood Insights engine is the "Brain" of the application. It uses a combination of deterministic data processing and advanced AI to identify patterns between what you eat and how you feel.

---

## 🚀 The Generation Lifecycle

Insights are not generated on every message. To ensure high accuracy and professional-grade analysis, the system follows these rules:

1.  **Generation Frequency**: Insights are generated at most **once every 24 hours**. This prevents "noise" and allows enough new data to accumulate.
2.  **Minimum Data Threshold**: The engine only starts once you have logged:
    *   At least **3 Scans** OR
    *   At least **3 Meal Logs AND 1 Symptom Log**.
3.  **Data Persistence**: Generated insights are saved to Firestore and cached locally for instant access.

---

## 📥 Data Streams

The engine aggregates data from five primary sources:

| Stream | Description |
| :--- | :--- |
| **Filtered Chat History** | Messages from the last 7 days that specifically mention food or symptoms. |
| **Structured Meal Logs** | A history of items you've explicitly logged as "eaten." |
| **Symptom Logs** | Records of bloating, energy, pain, etc., with severity ratings. |
| **Structured Scans** | Detailed ingredient and processing data from barcodes and labels. |
| **Score History** | The last 6 calculated Gut Scores to ensure continuity. |

---

## 🧠 The Pattern Engine

GutGood currently analyzes **6 Core Patterns**:
1.  **Bloating** (Requires at least 2 relevant repeated events)
2.  **Energy** (Requires at least 3 relevant logs)
3.  **Headache** (Requires at least 3 relevant logs)
4.  **Digestion** (Requires at least 3 relevant logs)
5.  **Fullness** (Requires at least 3 relevant logs)
6.  **Sleep** (Requires at least 3 relevant logs)

### Confidence Levels:
*   **< 60%**: No insight generated.
*   **60–79%**: Insufficient evidence; pattern is tracked but not surfaced.
*   **80%+**: A "Pattern Card" is generated for the UI.

---

## 📈 Gut Score Calculation Logic

The **Gut Score (0-100)** is a UI heuristic, not a medical measurement. It is calculated using the following priority:

1.  **Baseline**: Starts with the weighted average of your recent product scan scores.
2.  **Deductions**: Reduced for repeated high-severity symptoms or highly processed food patterns.
3.  **Additions**: Increased for goal-aligned behaviors (e.g., hitting fiber goals) and whole-food patterns.
4.  **Continuity**: To prevent jarring jumps, the score generally remains within **15 points** of your previous score unless massive new evidence exists.

---

## 🤖 AI Persona & Language

The final narrative is written by the **Evidence-Aware Food and Behavior Pattern Analyst**.

### Strict Language Rules:
*   **Observational**: Uses "Your history shows..." or "There may be an association..."
*   **Non-Medical**: NEVER uses "causes," "cures," or "diagnoses."
*   **Non-Alarmist**: NEVER uses fear-based terms like "toxic" or "damaging."

### Priority Order:
1.  Repeated food + symptom association (High Priority).
2.  Ingredient/additive observations from scan data.
3.  Goal-based progress (e.g., "You're consistently choosing high-fiber foods").
4.  Hormonal cycle-related observations (if Cycle Sync is enabled).
