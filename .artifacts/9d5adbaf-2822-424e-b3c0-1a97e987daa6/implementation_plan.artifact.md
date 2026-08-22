# Implementation Plan: Enhancing Chat Integrity & Context Grounding

This plan addresses P2 recommendations from the audit report to improve the relationship between chat messages and logs, and to enhance AI context retention.

## Proposed Changes

### [Core Models]
Update models to track the chat message origin.

#### [MODIFY] [meal_log.dart](file:///D:/Github/GUTGOOD/lib/core/models/meal_log.dart)
- Add `chatMessageId` field.
- Update `fromMap`, `toMap`, and `copyWith`.

#### [MODIFY] [symptom_log.dart](file:///D:/Github/GUTGOOD/lib/core/models/symptom_log.dart)
- Add `chatMessageId` field.
- Update `fromMap`, `toMap`, and `copyWith`.

---

### [Features: Chat]
Wire up the `chatMessageId` during passive logging and use it for cleanup.

#### [MODIFY] [process_chat_tag_usecase.dart](file:///D:/Github/GUTGOOD/lib/features/chat/domain/usecases/process_chat_tag_usecase.dart)
- Update `call` to accept `chatMessageId`.
- Pass `chatMessageId` to `MealLog.fromMap` and `SymptomLog.fromMap` constructions.

#### [MODIFY] [chat_composer_notifier.dart](file:///D:/Github/GUTGOOD/lib/features/chat/presentation/providers/chat_composer_notifier.dart)
- Pass the AI message's `localId` to `_processChatTagUseCase`.

#### [MODIFY] [chat_history_notifier.dart](file:///D:/Github/GUTGOOD/lib/features/chat/presentation/providers/chat_history_notifier.dart)
- In `deleteMessage`, call `_historyFirestoreService.deleteLogsForMessage(msg.localId)` to ensure associated logs are removed.

---

### [Services]
Update Firestore and AI services for better integrity and grounding.

#### [MODIFY] [history_firestore_service.dart](file:///D:/Github/GUTGOOD/lib/core/services/firestore/history_firestore_service.dart)
- Add `deleteLogsForMessage(String chatMessageId)` method.
- Implementation should delete matching documents from `meal_logs` and `symptom_logs`.

#### [MODIFY] [ai_service.dart](file:///D:/Github/GUTGOOD/lib/core/services/ai_service.dart)
- Update `_historyToPayload` to fetch and include structured meal/symptom context in history turns.
- *Note*: This requires `AiServiceImpl` to have access to `HistoryFirestoreService` or for the context to be passed in. Given the current structure, I will add `mealContext` and `symptomContext` to `ChatMessage.toAiMap()`.

---

### [Core Utility]
#### [MODIFY] [chat_message.dart](file:///D:/Github/GUTGOOD/lib/core/models/chat_message.dart)
- Add optional `mealLogs` and `symptomLogs` to `ChatMessage` to store the structured data extracted during that turn.
- Update `toAiMap()` to include these logs as context.

## Verification Plan

### Manual Verification
1.  **Passive Logging & Deletion**:
    *   Send a message that triggers a meal log (e.g., "I ate an apple").
    *   Verify the meal log appears in the History screen.
    *   Delete the chat message.
    *   Verify the meal log is also removed from the History screen.
2.  **AI Context Grounding**:
    *   Report a meal and a symptom in chat.
    *   Ask a follow-up: "Based on what I just ate and felt, what do you think?"
    *   Verify AI acknowledges the structured details of the meal/symptom from the previous turn.
