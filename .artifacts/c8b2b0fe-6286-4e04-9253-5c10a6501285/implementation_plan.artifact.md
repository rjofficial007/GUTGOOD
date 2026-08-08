# Fix Data Flow for Insights and Scan Result Screens

Review and fix the end-to-end data flow from AI prompts to UI rendering for the Insights and Scan Result screens. Recent changes in prompts have caused data mapping and parsing issues.

## User Review Required

> [!IMPORTANT]
> The AI response format for scans is being standardized to use the `logs` collection pattern, which matches the Chat implementation. This ensures consistency but requires updates to the `ScannerRepository`.

## Proposed Changes

### Core Services

#### [MODIFY] [prompts.dart](file:///D:/Github/GUTGOOD/lib/core/services/prompts.dart)
- Update `visionAnalysisSystemInstruction` and `barcodeAnalysisSystemInstruction` to explicitly request impact titles: "Blood Sugar", "Inflammation", "Digestibility", and "Satiety".
- Standardize the JSON schema in instructions to ensure consistent nesting.

### Features: Scanner

#### [MODIFY] [scanner_repository_impl.dart](file:///D:/Github/GUTGOOD/lib/features/scanner/data/repositories/scanner_repository_impl.dart)
- Fix `analyzeProductWithAi` to parse the nested `logs[0].data` structure.
- Fix `analyzeImageWithAi` to parse the nested `logs[0].data` structure and remove reliance on legacy `[SCAN]` tags.

### Core Models

#### [MODIFY] [ai_insight.dart](file:///D:/Github/GUTGOOD/lib/core/models/ai_insight.dart)
- Ensure `AIInsight.fromMap` robustly handles both flat and nested JSON structures to maintain backward compatibility with old logs while supporting new AI responses.

### Features: Insights

#### [MODIFY] [insight_repository_impl.dart](file:///D:/Github/GUTGOOD/lib/features/insights/data/repositories/insight_repository_impl.dart)
- Verify and refine the `generateNewInsight` flow to ensure all fields required by the `InsightsScreen` are correctly populated.

## Verification Plan

### Manual Verification
- **Scan Barcode**: Perform a barcode scan and verify the Scan Result screen displays the score, impact markers (Blood Sugar, etc.), nutrients, and ingredients correctly.
- **Vision Scan**: Perform a meal/label scan from the chat and verify it renders correctly as a `ScanResult` card.
- **Generate Insights**: Trigger a new insight generation and verify the Insights dashboard reflects the new data (Gut Score, Healing/Trigger foods, Patterns).
- **Empty States**: Verify that empty/loading states are shown correctly when no data is available.
