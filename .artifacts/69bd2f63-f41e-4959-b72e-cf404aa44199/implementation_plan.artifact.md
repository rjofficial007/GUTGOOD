# Dynamic Styling for ModernGutScoreCard

Refactor `ModernGutScoreCard` to dynamically change its background and accent colors based on the gut score, while aligning its visual style with other cards on the dashboard by using `BentoCard`.

## Proposed Changes

### [insights] Feature Component

#### [MODIFY] [modern_gut_score_card.dart](file:///D:/Github/GUTGOOD/lib/features/insights/presentation/widgets/modern_gut_score_card.dart)
- Replace the hardcoded dark background with a dynamic color based on the score and theme.
- Wrap the card content in `BentoCard` to match the dashboard's design system (border, shadow, radius).
- Refine `_statusColor` (renaming to `_accentColor` for clarity) and add a `_getBackgroundColor` method.
- Update text and icon colors to ensure contrast against the new dynamic backgrounds.
- Ensure the `GaugePainter` uses the dynamic accent color.

## Logic for Dynamic Colors
- **Score >= 70 (Good/Excellent):**
  - Accent: `AppPalette.green`
  - Background (Light): `AppPalette.greenSoft` or `AppPalette.greenPastel`
  - Background (Dark): `AppPalette.green.withAlpha(30)`
- **Score >= 50 (Fair):**
  - Accent: `AppPalette.orange`
  - Background (Light): `AppPalette.orangeSoft`
  - Background (Dark): `AppPalette.orange.withAlpha(30)`
- **Score < 50 (Poor):**
  - Accent: `AppPalette.red`
  - Background (Light): `AppPalette.redSoft`
  - Background (Dark): `AppPalette.red.withAlpha(30)`

## Verification Plan

### Manual Verification
- Verify the `ModernGutScoreCard` appearance on the Insights Dashboard with different scores (e.g., 90, 65, 30).
- Check contrast and readability in both Light and Dark modes.
- Confirm the card's border and shadow match other cards like `PhysicalGoalCard`.
