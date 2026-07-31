# GutGood MVP: Project Instructions

## Project Overview
GutGood is an AI-powered food and body assistant designed to provide personalized nutritional intelligence. Unlike generic fitness apps, GutGood correlates user input (chat, scans, and logging) with biological responses (bloating, energy, cravings) to provide actionable health insights.

## Core MVP Features

### 1. Chat Screen (The Assistant)
- **Functionality:** Users can ask questions about food, gut health, cravings, bloating, specific ingredients, and body reactions.
- **Features:** - Text-based query interface.
    - Image upload support (for meal analysis).
    - AI-driven responses powered by OpenAI.

### 2. Food Scanner
- **Functionality:** Barcode scanning and product lookup.
- **Output:**
    - **Health Score:** Derived from product data.
    - **Flagged Ingredients:** Highlighting potential sensitivities.
    - **Impact Analysis:** How this specific item may affect the user based on their history.
    - **Better Swaps:** AI-recommended alternatives.

### 3. Insights Screen
- **Functionality:** Pattern recognition and trends.
- **Focus:** Visualizing data points like foods that trigger bloating, energy crashes, or sensitivity clusters over time.

### 4. Profile Screen
- **Functionality:** User data management.
- **Data Points:** Preferences, identified sensitivities, saved foods/scans, health goals, and personalization settings.

---

## Tech Stack
* **AI Engine:** OpenAI API (Chat, image analysis, ingredient interpretation, personalization).
* **Data Source:** Open Food Facts API (Barcode/product data, nutrition facts, ingredient lists).
* **Database & Auth:** Supabase (User accounts, logs, chat history, saved preferences).
* **Backend/Server:** A secure middle-tier server (e.g., Node.js/Python) to securely handle API keys, manage OpenAI/Open Food Facts interactions, and protect database queries.

---

## Data Flow (Core MVP)
1.  **User Input:** User performs an action (Type, Upload, or Scan).
2.  **Request Handling:** The mobile app sends data to the **Secure Backend**.
3.  **Data Enrichment:** The Backend fetches data from **Open Food Facts** (if a scan) or prepares context from **Supabase**.
4.  **AI Processing:** The Backend sends context and user query to **OpenAI** for analysis.
5.  **Storage:** The response and relevant data points are stored in **Supabase** to build a personalized user history.
6.  **Response:** The UI renders the final, personalized health intelligence.

---

## Development Priorities
1.  **Infrastructure:** Set up Supabase and the Secure Backend to ensure API keys are hidden and database access is secure.
2.  **Integration:** Implement Open Food Facts scanning and retrieval.
3.  **Prompt Engineering:** Fine-tune OpenAI prompts to prioritize "personalized health intelligence" over "generic nutritional data."
4.  **Insights Engine:** Implement basic pattern matching in the backend to display triggers in the Insights screen.

---
