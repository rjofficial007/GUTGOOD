# Fix End-to-End Data Flow for Insights and Scan Results

Review and fix the end-to-end data flow from AI prompts to UI rendering for the Insights and Scan Result screens. The primary issues are parsing mismatches between the AI's structured JSON response and the app's model factories.

## User Review Required

> [!IMPORTANT]
> The AI prompt schemas for product scanning will be standardized to ensure consistent parsing across barcode and vision modes.

## Proposed Changes

### [Scanner Feature]

#### [MODIFY] [scanner_repository_impl.dart](file:///D:/Github/GUTGOOD/lib/features/scanner/data/repositories/scanner_repository_impl.dart)
- Update `analyzeProductWithAi` to correctly extract scan data from the `logs` array in the AI response.
- Update `analyzeImageWithAi` to correctly extract scan data from the `logs` array.
- Standardize how `swaps` and other metadata are merged into the final `ScanResult`.

### [Core Services]

#### [MODIFY] [prompts.dart](file:///D:/Github/GUTGOOD/lib/core/services/prompts.dart)
- Standardize `barcodeAnalysisSystemInstruction` and `visionAnalysisSystemInstruction` to use the same nested structure for `swaps` (placing them inside the `scan_history` data object) to match the `ScanResult` model's expectations.

### [Insights Feature]

#### [MODIFY] [insight_repository_impl.dart](file:///D:/Github/GUTGOOD/lib/features/insights/data/repositories/insight_repository_impl.dart)
- Verify and ensure `generateNewInsight` correctly handles the AI response and maps it to `AIInsight`. (Already looks mostly correct, but will double-check during execution).

## Verification Plan

### Automated Tests
- Run existing scanner and insight repository tests if available.
- `flutter test test/features/scanner/scanner_repository_test.dart`

### Manual Verification
- Perform a barcode scan and verify the Scan Result screen shows correct product name, brand, score, and ingredients.
- Perform a label/meal scan and verify the results.
- Trigger an insight generation (if enough data exists) and verify the Insights screen data mapping.
