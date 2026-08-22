Act as a **Principal Flutter Engineer, AI Chat Application Architect, and Senior UX Engineer** who has built and optimized production-grade AI chat applications comparable to **ChatGPT and Gemini**.

You are joining the existing **GutGood Flutter codebase**.

Your task is to **deeply audit, reverse-engineer, improve, and fix the existing Chat screen and its complete chat functionality**.

Do NOT rebuild the screen blindly.

First understand how the current implementation works, identify the root causes of problems, and then make targeted production-grade improvements while preserving the existing product functionality.

The goal is to make GutGood's Chat experience feel **stable, fast, polished, predictable, and production-ready**, similar to a modern AI chat application.

---

# 1. FIRST: Reverse-Engineer the Existing Chat Screen

Before changing anything, inspect the complete Chat implementation.

Trace:

```text
Chat Screen
    ↓
Message List
    ↓
Message State
    ↓
Conversation State
    ↓
User Input
    ↓
Send Message
    ↓
AI Request
    ↓
Streaming / Response
    ↓
Message Persistence
    ↓
UI Update
    ↓
Scroll Management
```

Identify all relevant:

- Chat screen files
- Widgets
- Controllers
- Providers
- Notifiers
- Repositories
- Services
- Models
- API/AI services
- Local storage
- Firebase/storage if present
- Pagination logic
- Scroll controllers
- Input controllers
- Keyboard handling
- Message rendering
- Markdown rendering
- Image handling
- Attachments
- Loading states
- Error states
- Empty states
- Retry behavior

Do not assume the current architecture is correct.

Follow the actual data flow.

---

# 2. Audit the Current Chat Architecture

Determine:

- How messages are stored
- How messages are loaded
- How messages are paginated
- How new messages are inserted
- How older messages are loaded
- How AI responses are inserted
- How streaming responses are handled
- How state updates trigger rebuilds
- How scroll position is managed
- How conversations are restored
- How messages are persisted
- How failed messages are handled
- How duplicate messages are prevented

Identify architectural problems such as:

- Business logic inside widgets
- Excessive widget rebuilds
- Incorrect state ownership
- Duplicate API calls
- Duplicate message insertion
- Race conditions
- Incorrect async lifecycle handling
- Controllers being recreated unnecessarily
- Poor separation of UI/state/data layers
- Memory leaks
- Incorrect provider lifecycle
- State being reset unexpectedly

---

# 3. CRITICAL: Fix Chat Pagination

Audit the current pagination implementation carefully.

The chat should behave like a production AI chat application.

Use **reverse/incremental pagination** where appropriate.

Expected behavior:

### Initial Load

Load the most recent messages first.

```text
Latest messages
      ↓
Open conversation
      ↓
Scroll position starts near bottom
```

### Loading Older Messages

When the user scrolls toward the top:

```text
User scrolls upward
        ↓
Detect threshold
        ↓
Load older messages
        ↓
Insert older messages ABOVE existing messages
        ↓
Preserve current visible content position
```

The UI must NOT jump unexpectedly.

### Critical Requirement

When older messages are loaded:

**The user's current viewport must remain visually stable.**

Do NOT:

- Jump to the bottom
- Jump to the top
- Reset the scroll position
- Re-render the entire conversation unnecessarily
- Duplicate messages

Preserve scroll offset using the appropriate Flutter technique.

---

# 4. Pagination Safety

Make pagination production-safe.

Handle:

- `isLoadingOlderMessages`
- `hasMoreMessages`
- `nextCursor`
- `previousCursor`
- Duplicate requests
- Concurrent pagination requests
- Empty pages
- Last page
- Network failures
- Retry
- Conversation switching
- Rapid scrolling

Never allow:

```text
Scroll event
↓
Request
↓
Request
↓
Request
↓
Request
```

because multiple scroll notifications fire.

Use proper request locking/debouncing/state protection.

---

# 5. New Message Behavior

When the user sends a message:

```text
User sends message
       ↓
Immediately insert user message
       ↓
Scroll intelligently
       ↓
Show AI loading/streaming state
       ↓
Generate AI response
       ↓
Update AI message
       ↓
Persist final response
```

Do not wait unnecessarily before displaying the user's message.

The UI should feel immediate.

---

# 6. ChatGPT/Gemini-Style Scroll Behavior

Implement intelligent scroll behavior similar to modern AI chat applications.

There are different scenarios.

## Scenario A — User is already near the bottom

When sending a message:

```text
Send
 ↓
Scroll to appropriate response position
 ↓
AI response remains visible
```

## Scenario B — User is reading older messages

If the user is intentionally reading history:

**Do not forcibly move them to the bottom.**

Respect their current position where appropriate.

## Scenario C — AI is generating a response

During streaming:

- Keep the response visible when appropriate
- Avoid constant aggressive `animateTo`
- Avoid scroll jitter
- Avoid fighting user scrolling
- Avoid moving the viewport unexpectedly

## Scenario D — User manually scrolls upward

Stop automatic scrolling when the user intentionally moves away from the bottom.

Provide an appropriate:

**"Jump to latest"**

control when necessary.

---

# 7. IMPORTANT: Sending Message Scroll Position

The user experience should allow the user to clearly see the AI response.

When a new user message is sent, do not simply call:

```dart
scrollController.animateTo(
  scrollController.position.maxScrollExtent,
);
```

without considering the message height and viewport.

Analyze the actual message layout and implement a robust strategy.

The goal is:

```text
User message
──────────────
AI response
──────────────
Current viewport
```

The user should be able to read the AI response comfortably.

Do not use arbitrary magic numbers such as:

```dart
alignment: 0.12
```

unless there is a clear reason and it works reliably across different message lengths and screen sizes.

---

# 8. Streaming AI Responses

If GutGood streams AI responses, audit the streaming implementation.

Ensure:

- User message appears immediately
- AI placeholder appears immediately
- Streaming text updates smoothly
- No duplicate AI messages
- No message flickering
- No excessive rebuilds
- No scroll jitter
- Partial responses are rendered correctly
- Final response replaces/updates the streaming state correctly
- Stream cancellation works
- Conversation switching cancels old streams
- Errors are displayed correctly

Avoid rebuilding the entire chat list for every token if the architecture allows a more efficient approach.

---

# 9. Loading Experience

Replace poor loading implementations with proper chat-specific loading states.

The chat should distinguish between:

### Initial Conversation Loading

Use a polished **shimmer/skeleton UI**.

Example:

```text
████████████
████████
      █████████████
      ███████
██████████████
```

The shimmer should resemble actual message bubbles rather than a generic circular loader.

### AI Thinking/Generating

Use a lightweight AI response indicator.

For example:

```text
● ● ●
```

or an appropriate animated thinking indicator.

Do not show a full-screen loader while the AI is generating.

### Loading Older Messages

Show a small loading indicator at the **top of the conversation**.

Do not replace the entire chat with a loader.

---

# 10. Shimmer Requirements

Audit the current shimmer implementation.

It must:

- Match the actual chat layout
- Support different message sizes
- Avoid layout jumps
- Be responsive
- Stop immediately when loading finishes
- Not remain visible after an error
- Not cause unnecessary rebuilds

Do not overuse shimmer.

Use:

**Skeleton → Real content**

rather than:

**Spinner → Blank screen → Content**

---

# 11. Empty State

Design a proper chat empty state.

When there are no messages:

Show a useful onboarding-style experience.

For example:

```text
GutGood
Your AI food & gut-health assistant

Ask me about:
• Your meal
• Food & digestion
• Bloating patterns
• Nutrition
• What you should eat
```

Provide useful starter prompts if the existing product supports them.

The empty state should disappear immediately when the first message is sent.

Do not show:

- Blank white screen
- Infinite loader
- Generic "No data"
- Broken list state

---

# 12. Error States

Handle errors at the correct level.

Examples:

### Initial chat load fails

Show:

```text
Couldn't load your conversation

Try again
```

### Sending message fails

Keep the user's message visible.

Do NOT silently remove it.

Show an appropriate failed state:

```text
Message couldn't be sent
Retry
```

### AI generation fails

Keep the conversation intact.

Allow retrying the AI response where possible.

### Pagination fails

Do not destroy existing messages.

Show a small retry mechanism at the top.

---

# 13. Retry Behavior

Retry must be idempotent.

Avoid:

```text
Retry
↓
duplicate user message
↓
duplicate AI response
```

Determine whether the failed operation is:

- User message send
- AI generation
- Pagination
- Conversation loading

Retry only the failed operation.

---

# 14. Message List Performance

Audit the message list for performance problems.

Look for:

- Entire list rebuilding
- Expensive markdown rendering
- Large widget trees
- Unnecessary image decoding
- Unbounded message history
- Poor list keys
- Rebuilding unchanged messages
- Nested scroll views
- `shrinkWrap: true` misuse
- `IntrinsicHeight`
- Excessive `setState`
- Repeated provider reads
- Repeated database queries

Use appropriate Flutter techniques such as:

- `ListView.builder`
- Stable keys
- Efficient state management
- Selective rebuilds
- Lazy rendering
- Memoization where appropriate
- Proper caching

Do not optimize prematurely.

Measure the actual problem first.

---

# 15. Message Identity

Every message should have a stable identity.

Audit whether messages have:

- Stable IDs
- Client IDs
- Server IDs
- Timestamps
- Role
- Status

For example:

```text
pending
sending
sent
streaming
completed
failed
```

Use stable message IDs to prevent:

- Duplicate messages
- Incorrect list updates
- Incorrect animations
- Wrong message replacement
- Pagination duplication

---

# 16. Conversation Switching

Audit what happens when the user switches conversations.

Ensure:

```text
Conversation A
      ↓
Switch to B
      ↓
Cancel A's pending operations
      ↓
Clear A-specific transient state
      ↓
Load B
      ↓
Restore B's messages
      ↓
Correct scroll position
```

No messages from conversation A should appear in conversation B.

No pending AI response from A should update B.

---

# 17. Keyboard & Input Behavior

Audit:

- Keyboard opening
- Keyboard closing
- Input resizing
- Safe areas
- Bottom padding
- iOS keyboard
- Android keyboard
- Desktop keyboard
- Enter/Shift+Enter
- Send button
- Empty message prevention
- Long messages
- Multiline input
- Focus handling

The input should remain stable when the keyboard appears.

---

# 18. Attachment / Image Handling

If the chat supports food images or attachments, audit:

- Image selection
- Image preview
- Image compression
- Upload state
- Upload failure
- Cancellation
- Retry
- Message association
- Image caching
- Large images
- Multiple attachments

Do not block the UI unnecessarily while processing images.

---

# 19. Markdown / AI Response Rendering

Audit AI response rendering.

Ensure:

- Markdown renders correctly
- Long responses do not break layout
- Code blocks, lists, headings, tables, etc. are handled appropriately if supported
- Links behave correctly
- Images don't overflow
- Text selection works where appropriate
- Streaming markdown does not constantly break layout

Avoid unnecessarily rebuilding the entire markdown tree during streaming.

---

# 20. Accessibility & UX

Audit:

- Screen reader behavior
- Touch targets
- Font scaling
- Contrast
- Keyboard navigation
- Focus behavior
- Semantic labels
- Motion sensitivity
- Desktop interaction

The chat should remain usable across supported platforms.

---

# 21. Responsive Layout

Review the Chat screen across:

- Mobile
- Tablet
- Web
- Windows/Desktop

The layout should adapt appropriately.

Do not simply stretch the mobile UI onto desktop.

Consider:

- Maximum chat content width
- Input width
- Side navigation
- Message alignment
- Keyboard shortcuts
- Mouse interaction
- D-pad/remote support if applicable
- Large displays

---

# 22. Race Conditions

Specifically search for asynchronous race conditions.

Examples:

```text
User sends message A
        ↓
AI request A starts

User switches conversation
        ↓
Conversation B loads

Request A finishes
        ↓
Response A accidentally appears in B
```

Prevent this.

Also investigate:

- Multiple sends
- Multiple pagination requests
- Rapid conversation switching
- Retry during active request
- Stream cancellation
- Widget disposal during requests

---

# 23. Memory & Lifecycle Safety

Ensure:

- Controllers are disposed
- Streams are cancelled
- Listeners are removed
- Timers are cancelled
- Async callbacks don't update disposed widgets
- Large message histories don't unnecessarily remain in memory
- Image resources are managed correctly

---

# 24. Do Not Break Existing Functionality

This is extremely important.

Preserve all existing:

- Chat features
- AI behavior
- Message format
- Conversation functionality
- Attachments
- Food image analysis
- Meal analysis
- AI responses
- Persistence
- Navigation
- Existing business rules

You are improving the implementation, not redesigning the product from scratch.

If an existing behavior is intentional, preserve it.

---

# 25. Refactor Only Where Necessary

Do not rewrite the entire application.

Prefer:

```text
Existing implementation
        ↓
Identify root problem
        ↓
Small targeted refactor
        ↓
Test
        ↓
Measure
        ↓
Continue
```

Avoid introducing unnecessary packages.

Use the existing architecture and dependencies wherever practical.

---

# 26. Production-Grade Chat Requirements

The final Chat screen should support:

- Fast initial rendering
- Proper empty state
- Shimmer loading
- Smooth AI generation
- Stable streaming
- Reverse pagination
- Scroll-position preservation
- Intelligent auto-scroll
- Jump-to-latest
- Retry
- Error states
- Stable message identity
- Conversation switching
- Cancellation
- Race-condition protection
- Efficient rebuilding
- Keyboard handling
- Responsive layout
- Accessibility
- Memory safety

---

# 27. Testing

Before declaring the work complete, test at minimum:

### Chat Loading

- Empty conversation
- Small conversation
- Large conversation
- Failed conversation loading

### Pagination

- First page
- Second page
- Last page
- No more messages
- Pagination failure
- Rapid scrolling
- Multiple scroll events
- Conversation switching during pagination

### Sending

- Short message
- Long message
- Multiple rapid messages
- Failed send
- Retry
- AI timeout

### Streaming

- Normal response
- Long response
- Empty response
- Stream failure
- Stream cancellation
- Conversation switch during streaming

### Scrolling

- Already at bottom
- Near bottom
- Middle of conversation
- Top of conversation
- Sending while reading history
- Loading older messages
- Long AI response

### UI

- Keyboard open
- Keyboard closed
- Rotation/resizing
- Small screen
- Large screen
- Desktop
- Accessibility/font scaling

---

# 28. Final Deliverables

After completing the audit and implementation, provide:

## 1. Current Architecture

Explain how the current Chat screen works.

## 2. Current Data Flow

Show:

```text
User
 ↓
Input
 ↓
State
 ↓
AI Service
 ↓
Response
 ↓
Message State
 ↓
Persistence
 ↓
UI
```

Adapt it to the actual codebase.

## 3. Problems Found

For every significant issue:

- File
- Location
- Problem
- Root cause
- Impact
- Severity

## 4. Fixes Implemented

Explain exactly what changed.

## 5. Pagination Architecture

Explain how older messages are now loaded and how scroll position is preserved.

## 6. Scroll Architecture

Explain exactly how:

- Send-message scrolling
- Streaming scrolling
- Manual scrolling
- Jump-to-latest
- Pagination

work.

## 7. Loading UX

Explain:

- Initial shimmer
- Pagination loader
- AI generation state

## 8. Error & Retry Architecture

Explain how each failure scenario behaves.

## 9. Performance Improvements

Explain which rebuilds, requests, memory operations, or rendering operations were optimized.

## 10. Regression Verification

Confirm which existing functionality was tested and preserved.

---

# FINAL PRINCIPLE

Do not treat this as a normal Flutter UI cleanup.

Treat the GutGood Chat screen as a **production AI conversation system**.

Think about how engineers building applications like ChatGPT and Gemini would design:

- Message state
- Streaming
- Pagination
- Scroll anchoring
- Loading states
- Retry
- Conversation lifecycle
- Context management
- Concurrency
- Rendering performance
- Error recovery
- Accessibility

The result should feel:

**Fast → Stable → Natural → Predictable → Responsive → Production-grade**

Most importantly:

> **Do not blindly rewrite the Chat screen. First reverse-engineer the existing implementation, identify the actual problems, explain the root causes, and then implement targeted fixes without breaking existing functionality.**