# Implementation Plan - Minimalist HERO B&W Redesign

Redesign the `AIPersonalizationOnboardingPage` into a bold, text-only experience inspired by high-end setup screens. This version focuses on high-contrast typography and cinematic transitions, removing all graphic elements to emphasize the "Personalization" narrative.

## User Review Required

> [!IMPORTANT]
> - **Visual Identity**: Strict **Black and White** scheme. No brand colors (Lime/Purple) or graphics (Circles/Orbs) will be used.
> - **Centered HERO Typography**: The status messages will be the sole focus, positioned in the dead center of the screen using `context.displayLg`.
> - **3D Flip Transition**: Text will transition using a sophisticated 3D X-axis flip effect.
> - **Layout Stability**: Completely replacing the existing layout structure to resolve the `debugNeedsLayout` assertion. Using a clean `Stack` or `Column` with `MainAxisAlignment.center`.

## Proposed Changes

### [Aesthetic Redesign]

#### [MODIFY] [ai_personalization_onboarding_page.dart](file:///D:/Github/GUTGOOD/lib/features/onboarding/presentation/widgets/ai_personalization_onboarding_page.dart)
- **Remove Graphics**: Delete the `_buildNeuralGutCore`, `_LiquidBlob`, and `_MinimalRing` logic.
- **Root Layout**:
    - Use `SafeArea` + `Padding`.
    - Implement a `Column` with `crossAxisAlignment: CrossAxisAlignment.start`.
    - Keep the top Header (Title/Subtitle) crisp and opaque.
- **Centered Hero Text**:
    - Place an `Expanded` widget with `Center` containing the `AnimatedSwitcher`.
    - Use `context.displayLg` with `FontWeight.w900` for the status messages.
    - Set `textAlign: TextAlign.center`.
- **3D Flip Transition**:
    - Update `transitionBuilder` to use a `Matrix4` X-axis rotation.
    - Use `Curves.easeOutBack` for a premium, springy feel.
- **Success State**:
    - Redesign the success state to be a simple, bold text reveal or a high-contrast check icon centered in the same space.

## Verification Plan

### Manual Verification
- Verify the **Red Screen Error** is resolved.
- Confirm the status text is perfectly centered and uses the 3D flip effect.
- Ensure the B&W contrast is maintained in both Light and Dark modes.
- Walk through the transition to verify it feels like a "premium moment."
