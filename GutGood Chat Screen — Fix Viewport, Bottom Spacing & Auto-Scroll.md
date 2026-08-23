# GutGood Chat Screen — Production Chat UX Fix

Act as a **Principal Flutter Engineer and Chat Application UX Architect** who has built production-grade conversational interfaces similar to ChatGPT and Gemini.

Review the existing GutGood Chat screen implementation and fix the current **chat viewport, scrolling, bottom spacing, keyboard, pagination, loading, and message rendering behavior**.

I have attached a screenshot showing the current problem.

## CURRENT PROBLEMS

The current Chat screen has a large amount of unnecessary empty space between the latest AI response and the bottom composer.

The screen currently looks approximately like:

```text
┌─────────────────────────────┐
│ GUTGOOD                     │
│                             │
│ AI RESPONSE                 │
│                             │
│                             │
│                             │
│                             │
│                             │
│                             │
│        HUGE EMPTY SPACE     │
│                             │
│                             │
│ Suggested actions            │
│ ┌─────────────────────────┐ │
│ │ Ask anything...       ↑ │ │
│ └─────────────────────────┘ │
│                             │
│ Chat  Insights History Profile│
└─────────────────────────────┘
```

This is not the desired conversational layout.

There is also an unwanted automatic scroll when the AI response arrives.

---

# 1. CRITICAL REQUIREMENT — NO AUTO-SCROLL AFTER AI RESPONSE

This is a strict requirement.

### DO NOT automatically scroll when:

- AI starts responding
- AI streams a token/chunk
- AI response grows
- AI response finishes
- AI response is persisted
- Provider/state updates
- Message list rebuilds
- Firebase/backend response arrives
- AI loading changes to completed
- A delayed callback runs after AI completion

Do NOT use:

```dart
scrollController.animateTo(
  scrollController.position.maxScrollExtent,
);
```

or:

```dart
scrollController.jumpTo(
  scrollController.position.maxScrollExtent,
);
```

as a response-completion mechanism.

Also search for indirect implementations such as:

```dart
WidgetsBinding.instance.addPostFrameCallback(...)
```

combined with scrolling.

Search the COMPLETE codebase for:

```text
animateTo
jumpTo
maxScrollExtent
minScrollExtent
ensureVisible
ScrollController
addPostFrameCallback
Future.delayed
Timer
scrollTo
```

Find every place that can change the chat viewport.

Do not fix only the obvious scroll call.

---

# 2. AI RESPONSE MUST NOT FIGHT USER SCROLL

When the AI response is being generated:

```text
AI starts
 ↓
AI streams
 ↓
AI response grows
 ↓
AI completes
```

the user's viewport must remain under the user's control.

Do NOT continuously move the viewport as the response grows.

For example, NEVER do:

```dart
onChunk:
  scrollToBottom();
```

or:

```dart
setState(() {
  message += chunk;
});

scrollToBottom();
```

This creates:

- Scroll jumping
- Jitter
- Loss of reading position
- Poor conversational UX
- User losing manually selected position

---

# 3. IMPORTANT DISTINCTION — SEND VS AI RESPONSE

The desired behavior is:

### When USER sends a message

A controlled viewport adjustment may happen **only if necessary** to create a good reading position for the new conversation turn.

For example:

```text
User sends message
        ↓
User message inserted
        ↓
Position conversation appropriately
        ↓
AI response appears below/around the conversation
```

However:

### When AI response arrives

```text
AI response starts
        ↓
DO NOT AUTO-SCROLL

AI response streams
        ↓
DO NOT AUTO-SCROLL

AI response completes
        ↓
DO NOT AUTO-SCROLL
```

The final AI response must remain where the existing viewport naturally places it.

---

# 4. FIX THE HUGE EMPTY SPACE

The screenshot shows a large unnecessary blank area between the AI response and the bottom composer.

Find the root cause.

Do NOT simply reduce one random padding value.

Inspect:

- `Expanded`
- `Flexible`
- `Spacer`
- `SizedBox`
- `Container` heights
- `ConstrainedBox`
- `SliverFillRemaining`
- `mainAxisAlignment`
- `MainAxisSize`
- `SafeArea`
- bottom padding
- keyboard insets
- `MediaQuery`
- `viewInsets`
- `viewPadding`
- `ListView`
- `CustomScrollView`
- `SliverList`
- `SliverFillRemaining`
- message list constraints
- composer positioning
- bottom navigation positioning

Determine exactly why the chat content is being forced into the excessive vertical space.

---

# 5. CHAT CONTENT SHOULD USE NATURAL HEIGHT

The message list should not artificially stretch the conversation content to fill the entire remaining viewport.

Avoid layouts equivalent to:

```dart
Column(
  children: [
    Expanded(
      child: ...
    ),
  ],
)
```

when the internal message layout is causing the unwanted empty region.

Do not introduce a fixed height hack.

The chat should behave naturally based on the actual message content and available viewport.

---

# 6. COMPOSER MUST STAY PROPERLY ANCHORED

The bottom composer should remain attached to the appropriate bottom area of the chat interface.

Structure the screen logically:

```text
┌───────────────────────────┐
│ App Header                │
├───────────────────────────┤
│                           │
│ Chat viewport             │
│                           │
│ Messages                  │
│                           │
│                           │
├───────────────────────────┤
│ Suggested actions         │
│                           │
│ Message composer          │
├───────────────────────────┤
│ Bottom navigation         │
└───────────────────────────┘
```

The composer should NOT create a giant artificial gap above itself.

---

# 7. BOTTOM INSET / SAFE AREA

Audit the bottom spacing carefully.

The screenshot suggests the bottom portion may have incorrect handling of:

- Safe area
- Navigation bar
- Keyboard inset
- Bottom navigation height
- Composer padding

Do not stack multiple bottom insets accidentally.

Look for patterns such as:

```dart
SafeArea(
  child: Padding(
    padding: EdgeInsets.only(
      bottom: MediaQuery.of(context).padding.bottom,
    ),
  ),
)
```

which can accidentally apply the same inset twice.

Also inspect:

```dart
MediaQuery.of(context).viewInsets.bottom
MediaQuery.of(context).padding.bottom
MediaQuery.of(context).viewPadding.bottom
```

Use each only for the purpose it is actually intended for.

---

# 8. KEYBOARD BEHAVIOR

The chat must work correctly when the keyboard opens.

Test:

```text
Keyboard closed
 ↓
Normal chat

Keyboard opens
 ↓
Composer moves above keyboard
 ↓
Chat viewport remains correct

Keyboard closes
 ↓
Chat returns to correct layout
```

Do not create a giant blank region after keyboard dismissal.

Do not permanently add keyboard height as bottom padding.

Do not force the chat to the bottom when the keyboard opens unless absolutely required by the intended UX.

---

# 9. MESSAGE LIST BOUNDARIES

The message list should have clear boundaries.

Verify:

```text
Header
 ↓
Chat List
 ↓
Composer
 ↓
Bottom Navigation
```

The list should not accidentally extend behind:

- Composer
- Suggested actions
- Bottom navigation
- System navigation area

unless intentional.

Use appropriate bottom padding so the last message is readable without creating excessive empty space.

---

# 10. LAST MESSAGE SPACING

The latest AI response should have a reasonable amount of space before the composer.

It should look approximately like:

```text
AI response

[small / intentional spacing]

Suggested actions

[composer]
```

NOT:

```text
AI response















[huge empty region]

Suggested actions
[composer]
```

Do not use arbitrary large bottom padding.

Any bottom content inset must have a clear reason.

---

# 11. SUGGESTED PROMPTS

The suggestion chips shown above the composer should participate naturally in the chat layout.

They should:

- Appear only when appropriate
- Not create excessive vertical spacing
- Scroll horizontally if necessary
- Not push the composer incorrectly
- Not alter message scroll position unexpectedly

When AI responds, do not reposition the message list just because suggestion chips appear/disappear.

---

# 12. MESSAGE RENDERING

Audit the message list itself.

Verify:

- User message
- AI message
- AI streaming state
- Failed response
- Retry
- Attachments
- Images
- Markdown
- Long responses
- Short responses
- Multiple messages

All messages should use natural content height.

Avoid fixed message heights.

---

# 13. AI STREAMING

During streaming:

```text
AI message:
"Your meal looks..."
```

then:

```text
"Your meal looks balanced..."
```

then:

```text
"Your meal looks balanced, but..."
```

The message widget should grow naturally.

The growing widget must NOT force:

```dart
scrollController.animateTo(...)
```

or:

```dart
jumpTo(...)
```

The existing viewport must remain stable.

---

# 14. PAGINATION

Review chat pagination while fixing the layout.

When loading older messages:

```text
User scrolls upward
        ↓
Load older messages
        ↓
Insert messages above existing messages
        ↓
Preserve the user's exact viewport
```

Do NOT allow pagination to jump the user.

Do not reset:

```dart
controller.jumpTo(0)
```

after loading older messages unless the position is explicitly restored to the equivalent content position.

Use proper scroll-position preservation.

---

# 15. INITIAL CHAT LOAD

When opening an existing conversation:

Load the correct messages and position the viewport appropriately.

Do not:

1. Render
2. Scroll
3. Render again
4. Scroll again
5. Load data
6. Scroll again

Avoid multiple competing scroll operations.

There should be a clear, deterministic initial positioning strategy.

---

# 16. NEW CONVERSATION

For an empty/new chat:

```text
Header

Welcome / empty state

Suggested prompts

Composer
```

There should be no unnecessary giant empty region caused by the message list.

---

# 17. EMPTY STATE

Review the empty chat state.

Ensure it does not interfere with the normal message list layout.

The empty state should be intentionally designed rather than relying on:

```dart
Spacer()
```

or arbitrary vertical positioning.

---

# 18. STATE MANAGEMENT

Review whether rebuilds are causing the scroll position or layout to reset.

Check:

- Provider rebuilds
- Riverpod state changes
- `setState`
- Stream updates
- Firebase listeners
- AI streaming updates
- Message list replacement
- List key changes
- Widget key changes

Make sure rebuilding the message list does NOT create a new `ScrollController`.

The scroll controller should have an appropriate lifecycle.

Avoid:

```dart
build() {
  final controller = ScrollController();
}
```

if that is currently happening.

---

# 19. DO NOT RECREATE THE MESSAGE LIST

Ensure streaming updates do not unnecessarily recreate the entire conversation list.

Avoid architecture that causes:

```text
Every AI token
 ↓
Entire list recreated
 ↓
Scroll position recalculated
 ↓
Viewport jumps
```

Use stable keys and appropriate state management.

---

# 20. SCROLL POSITION PRESERVATION

The scroll position must remain stable during:

- AI streaming
- AI completion
- Provider rebuild
- Firebase update
- Message persistence
- Pagination
- Refresh
- Image loading
- Markdown layout changes

The user should never feel that the application is "fighting" their scroll.

---

# 21. REMOVE MAGIC NUMBERS

Search for things such as:

```dart
alignment: 0.12
```

and arbitrary:

```dart
SizedBox(height: 300)
```

or:

```dart
padding: EdgeInsets.only(bottom: 250)
```

or:

```dart
animateTo(... + 500)
```

Do not blindly remove them.

First determine why they exist.

Replace them with layout-aware logic when appropriate.

---

# 22. RESPONSIVE BEHAVIOR

Test the chat on:

- Small Android phone
- Large Android phone
- Different aspect ratios
- Different text sizes
- Keyboard open
- Keyboard closed
- Long AI response
- Short AI response
- Image response
- Multiple messages

Do not optimize only for the screenshot's exact dimensions.

---

# 23. PERFORMANCE

While fixing the issue, ensure:

- No excessive rebuilds
- No repeated scroll commands
- No unnecessary layout passes
- No unnecessary database calls
- No repeated pagination calls
- No image loading loops
- No controller recreation
- No memory leaks

---

# 24. FINAL EXPECTED UX

The final chat should behave like a polished modern AI chat application while respecting the GutGood-specific requirement.

### User sends message

```text
User message
        ↓
Conversation positioned appropriately
        ↓
AI response begins
```

### AI responds

```text
AI response grows
        ↓
Viewport remains stable
```

### AI finishes

```text
AI response complete
        ↓
NO automatic scroll
        ↓
User remains in control
```

### User manually scrolls

```text
User scrolls
        ↓
Application respects position
```

### Older messages load

```text
Pagination
        ↓
Older messages inserted
        ↓
Viewport preserved
```

---

# 25. ACCEPTANCE CRITERIA

The implementation is complete only when:

- [ ] Huge blank space below the chat response is removed.
- [ ] Composer is positioned correctly.
- [ ] Bottom navigation does not create accidental extra spacing.
- [ ] Safe-area padding is correct.
- [ ] Keyboard behavior is correct.
- [ ] AI response does NOT automatically scroll the chat.
- [ ] AI streaming does NOT automatically scroll the chat.
- [ ] AI completion does NOT automatically scroll the chat.
- [ ] Provider rebuilds do NOT reset scroll position.
- [ ] Firebase/backend updates do NOT reset scroll position.
- [ ] Message persistence does NOT reset scroll position.
- [ ] Pagination does NOT jump the viewport.
- [ ] Older messages load without losing the user's position.
- [ ] New messages render correctly.
- [ ] Long AI responses render correctly.
- [ ] Short AI responses do not create excessive whitespace.
- [ ] Empty state is correctly positioned.
- [ ] Suggested prompts do not create layout problems.
- [ ] Composer remains usable above the keyboard.
- [ ] No unnecessary `animateTo(maxScrollExtent)` remains.
- [ ] No delayed auto-scroll workaround remains.
- [ ] No magic spacing values are being used to hide the problem.
- [ ] Existing chat functionality remains intact.

---

# 26. IMPORTANT — DO NOT BREAK EXISTING FUNCTIONALITY

Do not rewrite the entire chat screen unnecessarily.

First identify the root cause.

Then make the **smallest clean architectural changes necessary**.

Preserve:

- Existing message functionality
- AI functionality
- Streaming
- Chat persistence
- Pagination
- Attachments
- Image uploads
- Suggested prompts
- Retry
- Navigation
- Firebase/backend integration
- Existing design system

Only change what is required to fix the layout, scrolling, and viewport behavior.

---

# FINAL ENGINEERING REQUIREMENT

Do not solve this with:

```dart
Future.delayed(...)
```

```dart
animateTo(maxScrollExtent)
```

```dart
jumpTo(maxScrollExtent)
```

```dart
SizedBox(height: 300)
```

or arbitrary padding.

**Find the actual root cause of the viewport and scroll behavior.**

The final architecture should make the chat behave predictably:

> **The user controls the viewport. AI responses must never unexpectedly move it. The message content should occupy only the space it actually needs, and the composer should remain correctly anchored without creating artificial empty space.**

After implementation, explain:

1. **Root cause of the large bottom space**
2. **Root cause of the unwanted auto-scroll**
3. **Files/components changed**
4. **Scroll behavior before vs after**
5. **How pagination preserves position**
6. **How keyboard/safe-area handling was fixed**
7. **How you verified that existing functionality was not broken**