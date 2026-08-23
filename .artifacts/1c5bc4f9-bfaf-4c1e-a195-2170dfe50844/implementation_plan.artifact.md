# Fix Scan History Persistence and Retrieval

Restore reliable Scan History functionality by making the data model more resilient to AI-generated type mismatches, optimizing the persistence flow, and aligning the architecture with working Meal/Symptom logs.

## User Review Required

> [!IMPORTANT]
> The fix involves changing how numeric fields are parsed from Firestore. Existing documents with "stringified" numbers will now be handled correctly instead of causing the history screen to fail.

## Proposed Changes

### Core Models & Utilities

#### [MODIFY] [model_utils.dart](file:///D:/Github/GUTGOOD/lib/core/utils/model_utils.dart)
- Add `parseNum` helper to safely handle both `num` and `String` inputs from AI/Firestore.

#### [MODIFY] [scan_result.dart](file:///D:/Github/GUTGOOD/lib/core/models/scan_result.dart)
- Update `isLoggableProduct` to be more lenient for photo-based scans (`source == 'food'`).
- Add `chatMessageId` field to maintain relationship with chat history.
- Ensure `props` includes `time` for correct equality checks.

#### [MODIFY] [scan_result_details.dart](file:///D:/Github/GUTGOOD/lib/core/models/scan_result_details.dart)
- Update `NutrientData.fromMap` and `Ingredient.fromMap` to use `ModelUtils.parseNum`.

---

### Firestore Services

#### [MODIFY] [history_firestore_service.dart](file:///D:/Github/GUTGOOD/lib/core/services/firestore/history_firestore_service.dart)
- Optimize `saveToScanHistory` to move the `isFoodSaved` check into a non-blocking path or optimize it.
- Ensure `chatMessageId` is persisted in the document.
- Fix `getScanHistory` to safely handle document IDs and mapping.

---

### Repositories & UseCases

#### [MODIFY] [scanner_repository_impl.dart](file:///D:/Github/GUTGOOD/lib/features/scanner/data/repositories/scanner_repository_impl.dart)
- Pass `chatMessageId` to `saveToScanHistory`.

#### [MODIFY] [process_chat_tag_usecase.dart](file:///D:/Github/GUTGOOD/lib/features/chat/domain/usecases/process_chat_tag_usecase.dart)
- Ensure consistent persistence logic between `MEAL` and `SCAN` tags.
- Await critical Firestore writes instead of using `unawaited`.

---

### UI & Providers

#### [MODIFY] [history_notifier.dart](file:///D:/Github/GUTGOOD/lib/features/history/presentation/providers/history_notifier.dart)
- Add defensive error handling in `refreshScans` to prevent total failure if one document is corrupt.

## Verification Plan

### Automated Tests
- Run `test/features/scanner/scanner_repository_test.dart` to verify persistence logic.
- Run `test/features/chat/process_chat_tag_usecase_test.dart`.

### Manual Verification
1. **Barcode Scan**: Perform a barcode scan and verify it appears in "AI Scan History".
2. **Photo Scan**: Take a photo of food and verify it appears in BOTH "AI Scan History" and "Daily Meal Journal".
3. **Passive Chat**: Mention food in chat and verify the generated `[SCAN]` tag (if any) is persisted.
4. **App Restart**: Verify data survives app restart.
5. **Corrupt Data Test**: Manually edit a Firestore document to have `"calories": "100"` (String) and verify the History screen still loads other items.
