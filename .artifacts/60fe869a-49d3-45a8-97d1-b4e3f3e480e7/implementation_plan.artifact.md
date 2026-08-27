# Support Rich Meal Analysis in Chat

The backend now emits a rich `meal` block within `[GUTGOOD_DATA]`, containing nutritional balance, safe bets, and missing elements. This plan integrates these fields into the `MealLog` model and creates a dedicated `MealAnalysisInlineCard` for the chat interface.

## User Review Required

> [!NOTE]
> The `MealLog` model will be expanded with optional fields like `balance`, `workingWell`, and `missingOrCouldAdd`. These fields will be primarily populated by AI analysis.

## Proposed Changes

### Core Models

#### [MODIFY] [meal_log.dart](file:///D:/Github/GUTGOOD/lib/core/models/meal_log.dart)
- Add `balance` (Map), `workingWell` (List), `missingOrCouldAdd` (List), `sensitivityNotes` (List), and `summary` (String) fields.
- Update `fromMap`, `toMap`, and `copyWith` to handle these new fields.
- Ensure `items` can handle the new object structure `{"name": "...", "confidence": ..., "observation": "..."}` by extracting just the names or storing the full objects.

### UI Components

#### [NEW] [meal_analysis_inline_card.dart](file:///D:/Github/GUTGOOD/lib/core/widgets/meal_analysis_inline_card.dart)
- Create a new widget to display the rich meal analysis.
- Include sections for "Nutritional Balance", "Safe Bets", and "Improvements".
- Follow the design language of `ScanResultInlineCard`.

#### [MODIFY] [chat_bubble.dart](file:///D:/Github/GUTGOOD/lib/core/widgets/chat/chat_bubble.dart)
- Pass `mealLogs` (or a single `mealLog`) to `ChatBubble`.
- Render `MealAnalysisInlineCard` if a rich meal log is present.
- Handle cases where both `scanData` and `mealLogs` are present (render both or prioritize based on intent).

### Chat Logic

#### [MODIFY] [chat_message.dart](file:///D:/Github/GUTGOOD/lib/core/models/chat_message.dart)
- Ensure the `mealLogs` field in `ChatMessage` correctly captures the rich data from the `AiAnalysisResult`.

## Verification Plan

### Manual Verification
- Simulate a chat message containing the `[GUTGOOD_DATA]` block provided in the backend dump.
- Verify that the `MealAnalysisInlineCard` renders correctly within the `ChatBubble`.
- Check that the "Nutritional Balance" indicators (Protein, Fiber, Fat) show the correct levels (High/Good/Low).
- Verify that "Safe Bets" and "Better with..." lists are displayed.
