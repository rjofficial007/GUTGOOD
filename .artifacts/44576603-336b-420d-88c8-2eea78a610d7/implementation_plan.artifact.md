# Implementation Plan — Production-Grade Chat Architecture & UX Audit

Deeply audit, refactor, and improve the GutGood Chat experience to meet production-grade standards (stable, fast, polished, and predictable).

## User Review Required

> [!IMPORTANT]
> - **Scroll Behavior Change**: I will be moving from the current "Manual Anchoring" (using `GlobalKey` and `RenderAbstractViewport`) to a standard **Reverse List Architecture** (`reverse: true`). This is the idiomatic Flutter approach for chats and automatically handles most anchoring and keyboard issues.
> - **Pagination Strategy**: I will replace the current "Full Stream Re-fetch" pagination with a **Hybrid Incremental Pagination**. The latest messages will stay on a stream for real-time updates, while older messages will be fetched via one-time queries to prevent UI flickering and unnecessary re-fetches.
> - **UI Unification**: I found duplicate `MessageListView` implementations. I will unify them into a single, clean component.

## Proposed Changes

### Core Chat Architecture & State

#### [MODIFY] [chat_history_notifier.dart](file:///D:/Github/GUTGOOD/lib/features/chat/presentation/providers/chat_history_notifier.dart)
- Implement **Incremental Pagination**:
    - Add a `loadOlderMessages()` method that uses `startAfter` queries.
    - Merge older messages into the `_messages` list instead of clearing it.
    - Handle `hasMoreMessages` state.
- Refine **Stream Management**:
    - Keep a smaller, stable limit for the real-time stream (e.g., 20-30 messages).
    - Decouple initial load from background synchronization.
- Improve **Deduplication**:
    - Ensure `localId` is strictly used for matching optimistic vs. server messages to prevent "ghost" duplicates.

#### [MODIFY] [chat_composer_notifier.dart](file:///D:/Github/GUTGOOD/lib/features/chat/presentation/providers/chat_composer_notifier.dart)
- Optimize **Streaming Updates**:
    - Ensure the 60ms flush timer doesn't trigger unnecessary rebuilds of the entire list.
    - Implement a `isGenerating` state that widgets can listen to selectively.
- Enhance **Error Recovery**:
    - Make `retryMessage` more robust by ensuring all context (images, original prompt) is preserved.
    - Add idempotent checks for sending.

---

### UI & UX Improvements

#### [MODIFY] [chat_screen.dart](file:///D:/Github/GUTGOOD/lib/features/chat/presentation/pages/chat_screen.dart)
- **Primary Refactor**:
    - Set `reverse: true` on the main message list.
    - Remove `_anchorSpaceEnabled` and `_scrollToLatestUser` logic.
    - Implement a simple `ScrollController` listener for "Jump to Latest" logic.
- **Smart Auto-scroll**:
    - Automatically scroll to bottom only if the user is within a small threshold of the bottom.
    - Respect user scroll position if they have scrolled up to read history.
- **Cleanup**:
    - Unify `_MessageListView` and `_MessageSliverList` into the existing `MessageListView` component (or vice versa).
    - Clean up the `build` method to be more declarative.

#### [MODIFY] [chat_components.dart](file:///D:/Github/GUTGOOD/lib/features/chat/presentation/widgets/chat_components.dart)
- **Loading Experience**:
    - Replace the full-screen `ChatShimmerLoading` with a skeleton UI that matches the message bubbles.
    - Add a `TopLoadingIndicator` (visually top, functionally end of reversed list) for pagination.
- **Empty State**:
    - Refine `ChatEmptyState` to better match the "onboarding-style" requirements.
- **Message List Performance**:
    - Use `findChildIndexCallback` correctly in `SliverChildBuilderDelegate` for efficient list updates.
    - Ensure `AnimatedChatItem` doesn't cause excessive repaints.

#### [MODIFY] [message_list_view.dart](file:///D:/Github/GUTGOOD/lib/features/chat/presentation/widgets/message_list_view.dart)
- Update to be the primary, production-grade list component.
- Support the new reverse architecture and pagination triggers.

---

### Stability & Safety

#### [MODIFY] [chat_firestore_service.dart](file:///D:/Github/GUTGOOD/lib/core/services/firestore/chat_firestore_service.dart)
- Add `getOlderMessages({required int limit, required DateTime before})` to support incremental pagination.

## Verification Plan

### Automated Tests
- `test/features/chat/chat_history_notifier_test.dart`: Test incremental pagination and message merging.
- `test/features/chat/chat_composer_notifier_test.dart`: Test streaming logic and error handling.
- `test/features/chat/chat_pagination_test.dart`: Verify scroll position stability during pagination.

### Manual Verification
1.  **Pagination Test**: Scroll to the top of a long conversation. Verify that older messages load smoothly without the viewport jumping.
2.  **Streaming Test**: Send a message and verify the AI response scrolls intelligently (auto-scroll when at bottom, stay put when scrolled up).
3.  **Deduplication Test**: Send multiple rapid messages and check for duplicates.
4.  **Network Resilience**: Toggle airplane mode during a stream and verify the retry behavior.
5.  **Initial Load**: Open a new conversation and verify the shimmer effect follows the message bubble layout.
6.  **Responsive Test**: Check the chat layout on a tablet/wide screen to ensure it doesn't stretch awkwardly.
