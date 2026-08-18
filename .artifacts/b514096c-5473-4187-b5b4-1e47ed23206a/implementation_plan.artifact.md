# Implementation Plan - Food Scanner & History Optimization

Optimize the scanning and history logging logic to ensure only actual food products are persisted, and refine AI prompts for better accuracy and user experience.

## User Review Required

> [!IMPORTANT]
> - Added a `category` field to the `[SCAN]` JSON block to allow the AI to explicitly identify the type of scan (food, menu, label, etc.).
> - Modified `ScanResult.isLoggableProduct` to prioritize this new `category` field over string-based heuristics.

## Proposed Changes

### Core Logic & Models

#### [MODIFY] [schema_definitions.dart](file:///D:/Github/GUTGOOD/lib/core/services/prompts/schema_definitions.dart)
- Add `"category": "food|menu|label|packaging|non-food"` to `scanSchema`.
- Update `typeRules` to include the new `category` field.

#### [MODIFY] [scan_result.dart](file:///D:/Github/GUTGOOD/lib/core/models/scan_result.dart)
- Add `category` field to `ScanResult`.
- Update `fromMap` and `toMap` to handle `category`.
- Refine `isLoggableProduct` to use the `category` field for deterministic filtering.

### AI Prompts Optimization

#### [MODIFY] [mode_prompts.dart](file:///D:/Github/GUTGOOD/lib/core/services/prompts/mode_prompts.dart)
- Update `mealSnapInstruction`, `ingredientLabelInstruction`, and `barcodeAnalysisInstruction` to explicitly set the `category` field in the `[SCAN]` block.
- Refine instructions for `mealSnapInstruction` to focus more on meal composition and gut-health balance.
- Refine `ingredientLabelInstruction` to better handle additives and gums with evidence-aware language.

#### [MODIFY] [prompts.dart](file:///D:/Github/GUTGOOD/lib/core/services/prompts.dart)
- Update `_unknownVisionModeInstruction` to require the `category` field.
- Minor wording improvements to `chatSystemInstruction` for a more professional tone.

### Repositories & Services

#### [MODIFY] [scanner_repository_impl.dart](file:///D:/Github/GUTGOOD/lib/features/scanner/data/repositories/scanner_repository_impl.dart)
- Ensure `analyzeImageWithAi` handles potential parsing errors gracefully.
- Verify that `isLoggableProduct` correctly prevents non-food scans from hitting `scan_history` and `meal_log`.

## Verification Plan

### Automated Tests
- Run `flutter test test/features/chat/process_chat_tag_usecase_test.dart` (if applicable to check parsing).
- Create new unit tests for `ScanResult.isLoggableProduct` to verify category-based filtering.

### Manual Verification
- **Scenario 1: Food Photo**: Take a photo of a meal. Verify it appears in Chat, Scan History, and Meal Log.
- **Scenario 2: Ingredient Label**: Scan an ingredient label. Verify it appears in Chat for analysis but does NOT appear in Scan History or Meal Log.
- **Scenario 3: Restaurant Menu**: Scan a menu. Verify it gives recommendations in Chat but does NOT save a Scan Result or Meal.
- **Scenario 4: Barcode**: Scan a food barcode. Verify it is saved to Scan History.
