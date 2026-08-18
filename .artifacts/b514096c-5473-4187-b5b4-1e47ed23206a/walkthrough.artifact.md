# Walkthrough - Fixing "Better Swaps" Card Rendering

I have resolved the issue where Asking for "better swaps" would return raw text and tags instead of rendering the horizontal `SwapItContainer` card.

## Changes Made

### 1. Robust Tag Parsing
- **[ProcessChatTagUseCase](file:///D:/Github/GUTGOOD/lib/features/chat/domain/usecases/process_chat_tag_usecase.dart)**:
    - Replaced the basic, error-prone `_extractJson` method with the project's robust `ModelUtils.extractJson` which uses balanced-bracket scanning.
    - This ensures that `[SWAPS]` tags are correctly parsed even if the JSON block contains nested structures or extra whitespace, which is common in AI stream deltas.
    - Fixed a double-decoding bug in the `SWAPS` tag handler.

### 2. AI Prompt Reinforcement
- **[Prompts](file:///D:/Github/GUTGOOD/lib/core/services/prompts.dart)**:
    - Added an explicit "ALWAYS output the [SWAPS] block" instruction to the Swap Request intent.
    - This forces the model to include structured data whenever product names are suggested, triggering the UI card.

### 3. UI Redesign & Consistency
- **[SwapItContainer](file:///D:/Github/GUTGOOD/lib/core/widgets/swap_it_container.dart)**: Refined the container to follow the new premium Black & White high-contrast design system.
- **[ScanResultInlineCard](file:///D:/Github/GUTGOOD/lib/core/widgets/scan_result_inline_card.dart)**: Updated the "View Full Report" button with a technical arrow icon and bold typography for a more professional feel.

## Verification

The system now correctly:
1. Detects the `[SWAPS]` tag in the incoming AI stream.
2. Truncates the conversational text to hide the raw JSON block.
3. Decodes the JSON list into `ProductSwap` models.
4. Renders the high-contrast `SwapItContainer` below the chat bubble.
