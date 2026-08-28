# Implementation Plan - Display All Available Data in Result Screens

Ensuring that `ScanResultScreen`, `LabelResultScreen`, and `MenuResultScreen` display all available data from the `ScanResult` model, providing a comprehensive view for the user.

## Proposed Changes

### [Presentation Components]

#### [MODIFY] [scan_result_screen.dart](file:///D:/Github/GUTGOOD/lib/features/product_details/presentation/pages/scan_result_screen.dart)
- Integrate `AllergensSection` when `allergens` data is present.
- Integrate `CycleInsightSection` when `cycleInsight` data is present.
- Integrate `AdditivesSection` and `IngredientsSection` (common for packaged goods).
- Ensure `BetterSwapsCarousel` only shows if `swaps` is not empty (already handled, but will double-check).

#### [MODIFY] [label_result_screen.dart](file:///D:/Github/GUTGOOD/lib/features/product_details/presentation/pages/label_result_screen.dart)
- Integrate `AllergensSection`.
- Integrate `CycleInsightSection`.
- Integrate `NutritionFactsSection` if `nutrients` data is available.

#### [MODIFY] [menu_result_screen.dart](file:///D:/Github/GUTGOOD/lib/features/product_details/presentation/pages/menu_result_screen.dart)
- Integrate `AllergensSection`.
- Integrate `CycleInsightSection`.

#### [MODIFY] [scan_result_widgets.dart](file:///D:/Github/GUTGOOD/lib/features/product_details/presentation/widgets/scan_result_widgets.dart)
- Update `NutritionFactsSection` to display `servingSize` if available.
- Update `AirbnbHeroCard` to display the `badge` if present.

## Verification Plan

### Manual Verification
- Verify that each screen displays the new sections (Allergens, Cycle Insights, etc.) when the corresponding data is available in the `ScanResult`.
- Check `ScanResultScreen` with a product that has ingredients and additives.
- Check `LabelResultScreen` with a result that includes nutrition facts.
- Check `MenuResultScreen` with a result that includes cycle insights.
- Verify `servingSize` appears in the Nutrition Facts section.
- Verify `badge` appears in the Hero card.
