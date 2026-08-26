# Implement Scan Result (Product Details) UI from Reference Image

This plan outlines the changes to `scan_result_screen.dart` and `scan_result_widgets.dart` to match the "Product Details" screen (right side) in the provided image.

## Proposed Changes

### [Presentation Layer]

#### [MODIFY] [scan_result_screen.dart](file:///D:/Github/GUTGOOD/lib/features/product_details/presentation/pages/scan_result_screen.dart)
- Remove `GutAppBar`.
- Wrap the main content in a `Stack` to support a floating back button and a persistent bottom action bar.
- Restructure the `SingleChildScrollView` content:
    - `ProductImageHeader`: Large image with floating decorative elements (simulated with `Stack` and `Positioned`).
    - `ProductInfoSection`: Title and `QuantitySelector`.
    - `ProductDescription`: Description text from `scanData`.
    - `DeliveryInfoRow`: Delivery time and icon.
    - Keep existing health-related sections (`ScanImpactSection`, `AdditivesSection`, etc.) below the main product details, styled to fit the new aesthetic.
- Add `ScanResultBottomBar` as a persistent footer.

#### [MODIFY] [scan_result_widgets.dart](file:///D:/Github/GUTGOOD/lib/features/product_details/presentation/widgets/scan_result_widgets.dart)
- **Update** `ScanHeroSection` (or replace with `ProductImageHeader`):
    - Implement the large image view with decorative elements (leaves, etc.).
    - Add a page indicator (dots).
- **Add** `QuantitySelector`: A small row with minus, quantity, and plus buttons.
- **Add** `DeliveryInfoRow`: Shows "Delivery Time" and a clock icon with time.
- **Add** `ScanResultBottomBar`: A floating or fixed bar containing the price, favorite button, and "Add to cart" button.
- **Update** existing widgets to use a cleaner, more spaced-out design consistent with the image.

## Verification Plan

### Manual Verification
- Verify the layout on different screen sizes using the emulator.
- Ensure the back button works and is positioned correctly over the background.
- Check that the bottom action bar stays at the bottom.
- Confirm the new widgets (`QuantitySelector`, `DeliveryInfoRow`, `ScanResultBottomBar`) render as expected.
