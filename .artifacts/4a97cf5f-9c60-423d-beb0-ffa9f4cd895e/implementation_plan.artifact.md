# Redesign Profile Header

Complete redesign of the `ProfileHeader` widget to move away from `ModernInsightCard` and provide a more comprehensive, modern profile overview.

## User Review Required

> [!IMPORTANT]
> The redesign will include new statistics (Goals, Sensitivities, Lifestyle) and explicit Edit/Logout buttons that were previously not visible in the `ModernInsightCard` implementation.

## Proposed Changes

### Core Widgets

#### [MODIFY] [profile_header.dart](file:///D:/Github/GUTGOOD/lib/core/widgets/profile_header.dart)
- Replace `ModernInsightCard` with a custom-designed `Container`.
- Implement a 3-column stats section for Goals, Sensitivities, and Lifestyle.
- Add a dedicated "Edit Profile" button and "Logout" icon.
- Enhance the Profile Picture section with a Premium badge overlay.
- Use a clean, dark-themed aesthetic matching the app's palette.

## Verification Plan

### Manual Verification
- Verify the layout on different screen sizes (using the `responsive.dart` utilities).
- Ensure all taps (`onImageTap`, `onEditTap`, `onLogoutTap`) are working.
- Check the display of the Premium badge based on `isPremium`.
- Confirm stats are displayed correctly.
