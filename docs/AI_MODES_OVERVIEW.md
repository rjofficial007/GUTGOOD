# GutGood AI & Scanner Modes Overview

**Current source alignment:** 2026-10-07
**Prompt source:** `lib/core/ai/prompts/` and feature-owned AI use cases
**AI boundary:** `lib/core/ai/client/`
**Feature orchestration:** Chat, Scanner, and Insights under `lib/features/`

This document describes the AI analysis modes, scanner modes, prompt handlers, structured protocol, and validation boundary implemented in GutGood. Prompt and schema source files live under `lib/core/ai/`; feature code selects and supplies context for each mode.

---

## 1. Scanner and vision modes

### 📸 Meal Snap Mode
**Source:** `lib/core/ai/prompts/mode_prompts/meal_snap_prompt.dart`
**Orchestration:** `lib/features/scanner/`

Provides a comprehensive, personalized analysis of a photographed meal. It combines image analysis with goals, sensitivities, lifestyle, and cycle phase, then evaluates processing level, nutritional balance, likely digestive triggers, and actionable recommendations.

### 🔍 Ingredient Label Mode
**Source:** `lib/core/ai/prompts/mode_prompts/ingredients_label_prompt.dart`
**Orchestration:** `lib/features/scanner/`

Evaluates packaged-food ingredient and additive lists against user sensitivities and the additive concern data under `lib/core/data/`. The structured result can include additive warnings, sensitivity matches, emulsifier/preservative detail, and a clean-eating verdict.

### 🍽️ Restaurant Menu Mode
**Source:** `lib/core/ai/prompts/mode_prompts/restaurant_menu_prompt.dart`
**Orchestration:** `lib/features/scanner/`

Analyzes photographed menus against user goals and sensitivities, ranking dishes and suggesting modifications such as dressing on the side or ingredient substitutions.

### 📦 Barcode Mode
**Source:** `lib/core/ai/prompts/mode_prompts/barcode_analysis_prompt.dart`
**Data source:** Open Food Facts through `lib/infrastructure/open_food_facts/off_service.dart`
**Orchestration:** `lib/features/scanner/`

Uses barcode/product metadata, ingredient analysis, NOVA data, additive concerns, and AI explanation to produce a scan result and possible swaps. Barcode cache and persistence remain Scanner-owned.

---

## 2. Chat and intent modes

### 🧭 Image classification
**Prompt:** `lib/core/ai/prompts/mode_prompts/image_classification_prompt.dart`
**Service:** `lib/core/ai/classification/ai_classifier_service.dart`

Resolves a known scanner mode from the UI hint when possible and classifies unknown/gallery images when a vision round trip is required.

### 🧭 Text intent detection
**Prompt:** `lib/core/ai/prompts/mode_prompts/intent_detection_prompt.dart`
**Service:** `AiClassifierService`

Uses local keyword fast paths for common intents and the AI classifier for misses. Canonical intent values are defined in `lib/core/ai/protocol/ai_constants.dart`.

### 💬 Chat instruction catalog
**Catalog:** `lib/core/ai/prompts/prompt_catalog.dart`
**Feature orchestration:** `lib/features/chat/`

Chat builds a system instruction from user profile, recent history, pinned entities, mode, intent, and structured schema rules. Streaming, context-window management, tag extraction, persistence, outbox handling, and UI state remain in Chat rather than in the shared prompt layer.

---

## 3. Intelligence and synthesis modes

### 🧠 Insights (deterministic client refresh)
**Use case:** `lib/features/insights/application/usecases/generate_insight_usecase.dart`
**Rules:** `lib/features/insights/data/services/pattern_engine_service.dart`
**Composer:** `lib/features/insights/domain/services/rule_based_insight_builder.dart`

The core Insights refresh reads stored journal data on the client, reuses the deterministic pattern engine and gut-score calculator, and upserts one `rule_based_latest` snapshot. Refresh makes no AI request and requires no Insights-generation Cloud Function. Separately, when rule-based observations exist in at least two areas, the user may tap **Explain these patterns with AI**. That optional request sends only the detected pattern summaries through the existing `aiProxy` (`usageType: system`) and asks for a cautious cross-pattern explanation plus one neutral follow-up logging question. It cannot change scores, counts, evidence labels, or detected patterns; raw chat, journal notes, and photos are not sent. The former full AI Insights-generation pipeline remains removed, while persisted legacy Insight fields remain readable. Chat and photo/scan interpretation remain AI-backed where they add value. Client refreshes run when the app is open or a supported client lifecycle event occurs; closed-app background generation is not guaranteed without a server-side trigger.

### 🩺 Health Assessment Mode
**Source:** `lib/core/ai/prompts/mode_prompts/health_assessment_prompt.dart`

Synthesizes questionnaire or journal information into holistic guidance without forcing unsupported numeric ratings.

### 📅 Meal Planning Mode
**Source:** `lib/core/ai/prompts/mode_prompts/meal_planning_prompt.dart`

Generates meal plans using dietary preferences, restrictions, health goals, and the shared schema rules.

### ⭐ Meal Rating Mode
**Source:** `lib/core/ai/prompts/mode_prompts/meal_rating_prompt.dart`

Explains meal quality using processing, fiber/protein, user context, and symptom reactions. Deterministic score and persistence rules remain owned by the feature/model layer.

### 🥗 Meal Swaps Mode
**Source:** `lib/core/ai/prompts/mode_prompts/meal_swaps_prompt.dart`

Recommends alternatives with nutrition, benefits, category, and grounding information. Chat and Scanner supply real product context where available.

### 🤒 Symptom Analysis Mode
**Source:** `lib/core/ai/prompts/mode_prompts/symptom_analysis_prompt.dart`

Analyzes symptoms alongside recent meals and timing to provide tracking guidance. The response validator and feature persistence gates prevent unsupported structured records from being silently saved.

---

## 4. Shared protocol and safety rules

- Shared formatting and safety rules: `general_rules_prompt.dart`, `prompt_formatting_rules.dart`, and `vision_safety_prompt.dart`.
- Structured schemas: `lib/core/ai/prompts/schema_definitions.dart`.
- Structured result model: `lib/core/ai/protocol/ai_analysis_result.dart`.
- Constants and version values: `lib/core/ai/protocol/ai_constants.dart`.
- Response sanitization and persistence gating: `lib/core/ai/validation/ai_response_validator.dart`.
- Network/auth/quota exceptions: `lib/core/ai/client/ai_exceptions.dart`.

Persisted schema/version values may contain historical `v2` terminology. There is no `v2` prompt or widget compatibility directory in the active source tree.
