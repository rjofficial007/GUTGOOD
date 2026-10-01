# GutGood AI & Scanner Modes Overview

This document provides a comprehensive overview of all AI analysis modes, scanner modes, and prompt handlers implemented in the GutGood application. It explains their purpose, how they work, and what data they contain/output.

---

## 1. Scanner & Vision Modes

### 📸 Meal Snap Mode (`meal_snap_prompt.dart`)
- **Purpose**: Provides a comprehensive, personalized analysis of a photographed meal.
- **How It Works**: Combines image vision analysis with user profile metadata (goals, sensitivities, lifestyle, and cycle phase). It evaluates food processing level (NOVA groups 1–4), nutritional balance, and potential digestive triggers.
- **Key Contents**: NOVA classification, macronutrient breakdown, personalized gut impact score (1–100), ingredient audit, and actionable recommendations.

### 🔍 Ingredient Label Mode (`ingredients_label_prompt.dart`)
- **Purpose**: Evaluates packaged food ingredient and additive lists for sensitivity risks and gut barrier health.
- **How It Works**: Scans ingredient labels or ingredient text, cross-referencing against the user's specific food sensitivities and additive concern databases.
- **Key Contents**: Additive safety ratings, sensitivity warnings, emulsifier/preservative breakdown, and a clean-eating verdict.

### 🍽️ Restaurant Menu Mode (`restaurant_menu_prompt.dart`)
- **Purpose**: Recommends gut-friendly menu items from restaurant menu photographs.
- **How It Works**: Analyzes menu options against user goals and sensitivities, highlighting dishes that minimize inflammatory load and digestive strain.
- **Key Contents**: Best menu choices, modification tips (e.g., dressings on the side), and allergen/irritant warnings.

### 📦 Barcode Mode (`barcode_analysis_prompt.dart`)
- **Purpose**: Instant intelligence on packaged products scanned via barcode (Open Food Facts integration).
- **How It Works**: Queries product metadata and nutritional databases, calculating a Yuka-style score (60% nutritional quality, 30% processing/NOVA, 10% organic/additives).
- **Key Contents**: Nutri-Score, ingredient additives list, missing data explanations, and alternative product recommendations.

---

## 2. Intelligence & Synthesis Modes

### 🧠 Insights Synthesis Mode (`insights_prompt.dart`)
- **Purpose**: Builds personalized gut health patterns and bento dashboard feeds.
- **How It Works**: Triggered after the user completes baseline requirements (at least 3 food logs and 1 symptom log today). It analyzes repeated associations across canonical domains (`bloating`, `energy`, `headache`, `digestion`, `fullness`, `sleep`).
- **Key Contents**: Top insights, healing/trigger food summaries, detected pattern correlations with confidence scores, action steps, and better food swaps.

### 🩺 Health Assessment Mode (`health_assessment_prompt.dart`)
- **Purpose**: Evaluates general dietary habits and gut health readiness.
- **How It Works**: Synthesizes questionnaire or journal entries into holistic health insights without assigning premature numeric ratings.
- **Key Contents**: Habit evaluations, lifestyle recommendations, and foundational guidance.

### 📅 Meal Planning Mode (`meal_planning_prompt.dart`)
- **Purpose**: Generates custom gut-healthy meal plans.
- **How It Works**: Takes user dietary preferences, restrictions, and healing goals into account to generate structured daily or weekly meal options.
- **Key Contents**: Breakfast, lunch, dinner, and snack suggestions optimized for microbiome diversity and low inflammatory load.

### ⭐️ Meal Rating Mode (`meal_rating_prompt.dart`)
- **Purpose**: Scores logged meals deterministically and AI-assistively.
- **How It Works**: Computes score adjustments based on NOVA processing group, fiber/protein content, and user symptom reactions.
- **Key Contents**: Meal score (1–100), contributory factors breakdown, and explanatory notes.

### 🥗 Meal Swaps Mode (`meal_swaps_prompt.dart`)
- **Purpose**: Recommends better food alternatives to identified trigger or processed foods.
- **How It Works**: Pairs trigger foods with nutrient-dense, gut-friendly alternatives featuring nutritional comparisons, benefits, and category tags.
- **Key Contents**: Alternative meal name, hero image, nutrition highlights (calories, protein, fat, fiber), and "Why this may be a better option" rationale.

### 🤒 Symptom Analysis Mode (`symptom_analysis_prompt.dart`)
- **Purpose**: Investigates logged symptoms against recent meals and environmental factors.
- **How ItWorks**: Correlates symptom timing and severity with preceding food logs to help users identify potential patterns over time.
- **Key Contents**: Symptom summary, suspected contributory factors, and tracking recommendations.
