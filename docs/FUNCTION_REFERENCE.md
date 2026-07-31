# Function Reference: Key Business Logic

This document details the most critical functions within the GutGood codebase that handle the core features.

## 1. `ChatNotifier.send()`
**Location:** `lib/features/chat/presentation/providers/chat_provider.dart`

| Aspect | Detail |
| --- | --- |
| **Purpose** | Orchestrates a multi-modal (text + image) AI chat turn. |
| **Parameters** | `text` (String), `hiddenContext` (String?), `source` (String?). |
| **Data Flow** | Saves local message -> Uploads images to Storage -> Starts SSE stream via `aiProxy`. |
| **Side Effects** | Updates `optimisticIds` for race-free UI; triggers `_precomputeSummary`. |
| **Error Handling** | Checks `ChatSendError` (Offline, Busy, Quota). |

---

## 2. `ScannerNotifier.processBarcode()`
**Location:** `lib/features/scanner/presentation/providers/scanner_notifier.dart`

| Aspect | Detail |
| --- | --- |
| **Purpose** | Resolves a barcode into an AI-analyzed product result. |
| **Parameters** | `barcode` (String), `capturedImage` (Uint8List?). |
| **Data Flow** | OFF API lookup -> AI Analysis (`analyzeProductWithAi`) -> Firestore save. |
| **Uses** | `ScannerRepository`, `OffService`, `AiService`. |

---

## 3. `AuthRepositoryImpl.confirmMerge()`
**Location:** `lib/features/auth/data/repositories/auth_repository_impl.dart`

| Aspect | Detail |
| --- | --- |
| **Purpose** | Triggers the server-side migration of data from Guest to Permanent account. |
| **Parameters** | `anonymousUid` (String), `permanentUid` (String). |
| **Mechanism** | Calls `mergeAnonymousAccount` HTTPS Callable Cloud Function. |
| **Side Effects** | Calls `_finalizeAuth` to sync profile; resets local session. |

---

## 4. `ProcessChatTagUseCase.call()`
**Location:** `lib/features/chat/domain/usecases/process_chat_tag_usecase.dart`

| Aspect | Detail |
| --- | --- |
| **Purpose** | Parses AI stream text for `[MEAL]` and `[SYMPTOM]` tags in real-time. |
| **Logic** | Uses Regex to extract content between tags; invokes `FirestoreService.logMeal/logSymptom`. |
| **Persistence** | Ensures tags are only processed once per message to avoid duplicate logs. |

---

## 5. `AiServiceImpl.streamChat()`
**Location:** `lib/core/services/ai_service.dart`

| Aspect | Detail |
| --- | --- |
| **Purpose** | Manages the SSE (Server-Sent Events) connection to the AI Proxy. |
| **Security** | Attaches the Firebase ID Token to the request header; Proxy verifies UID. |
| **Returns** | `Stream<String>` of text tokens. |

---

## 6. `FirestoreServiceImpl.saveToScanHistory()`
**Location:** `lib/core/services/firestore_service.dart`

| Aspect | Detail |
| --- | --- |
| **Purpose** | Adds a product to the user's history with deduplication logic. |
| **Deduplication** | Checks if the `barcode` already exists; if so, updates the `timestamp` to move it to the top. |
| **Collections** | `scan_history`. |
