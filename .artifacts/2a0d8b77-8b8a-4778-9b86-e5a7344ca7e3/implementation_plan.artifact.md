# GutGood Professional Audit & Production Improvement Plan

This plan outlines the steps to improve the GutGood Flutter app to production quality, focusing on project structure, code quality, Firebase configuration, performance, and UI/UX consistency.

## User Review Required

> [!IMPORTANT]
> - **State Management**: The app uses `provider`. I will maintain this approach but optimize rebuilds.
> - **Navigation**: `go_router` is used. I will preserve the existing routes.
> - **Firebase**: I will review security rules but won't change data structures unless critical bugs are found.

## Proposed Changes

### 1. Project Structure & Organization

- **[MODIFY] [injection_container.dart](file:///D:/Github/GUTGOOD/lib/core/di/injection_container.dart)**: Organize dependency registration by layer or feature to improve readability.
- **[MODIFY] [app_strings.dart](file:///D:/Github/GUTGOOD/lib/core/constants/app_strings.dart)**: Evaluate splitting this file if it becomes too unwieldy (currently 53KB).

### 2. Code Quality & Clean Build Methods

- **[NEW] [chat_widgets.dart](file:///D:/Github/GUTGOOD/lib/features/chat/presentation/widgets/chat_widgets.dart)**: Extract private widgets from `chat_screen.dart` into a dedicated widgets file.
- **[MODIFY] [chat_screen.dart](file:///D:/Github/GUTGOOD/lib/features/chat/presentation/pages/chat_screen.dart)**: Clean up the main build method and utilize extracted widgets.
- **[MODIFY] [chat_bubble.dart](file:///D:/Github/GUTGOOD/lib/core/widgets/chat_bubble.dart)**: Refactor this large widget (26KB) into smaller, more manageable components.

### 3. Firebase Review

- **[MODIFY] [firestore.rules](file:///D:/Github/GUTGOOD/firestore.rules)**: Audit and tighten security rules for all collections.
- **[MODIFY] [storage.rules](file:///D:/Github/GUTGOOD/storage.rules)**: Ensure storage rules are secure and follow least privilege principles.

### 4. Performance Optimization

- **[MODIFY] [AppSizes](file:///D:/Github/GUTGOOD/lib/core/constants/app_sizes.dart)**: Ensure efficient access to responsive dimensions.
- **[AUDIT]**: Check for missing `const` constructors in common UI components.
- **[AUDIT]**: Review list views for proper use of `.builder` and `itemExtent`.

### 5. UI/UX & Design System

- **[MODIFY] [app_theme.dart](file:///D:/Github/GUTGOOD/lib/core/theme/app_theme.dart)**: Ensure all components (Buttons, Cards, TextFields) follow a unified design system.
- **[MODIFY] [gut_button.dart](file:///D:/Github/GUTGOOD/lib/core/widgets/gut_button.dart)**: Ensure consistent styling and touch targets.

## Verification Plan

### Automated Tests
- Run `flutter analyze` to ensure no linting errors.
- Run `flutter test` to verify existing functionality.

### Manual Verification
- Verify the chat flow (sending messages, attachments).
- Check the responsive layout on different screen sizes (emulators).
- Verify Firebase Auth (sign in/out).
