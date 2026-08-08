# JSON Migration Guide

This guide lists required changes to migrate from tag-based responses to
structured JSON.

## ai_proxy.ts

Current file length: 321 lines.

-   Replace `json_object` with JSON Schema when supported.
-   Add temperature 0.2.
-   Increase max_tokens for image analysis.
-   Return only structured JSON.

## process_chat_tag_usecase.dart

Current file length: 281 lines.

-   Make JSON parsing the primary path.
-   Keep legacy tag parsing only temporarily.
-   Validate JSON before decoding.
-   Rename class in future to ProcessStructuredResponseUseCase.

## prompts.dart

Current file length: 456 lines.

-   Rewrite system prompt to require ONLY JSON.
-   Remove \[SCAN\]/\[MEAL\]/\[SYMPTOM\] tags.
-   Define `message` and `logs` schema.
-   Include scan_history, meal_logs, symptom_logs objects.

## send_message_stream_usecase.dart

Current file length: 21 lines.

-   Add `stream-json` mode.
-   Buffer streamed chunks until valid JSON.
-   Handle malformed JSON gracefully.

## Common JSON Response

``` json
{
  "message":"...",
  "logs":[{"collection":"scan_history","data":{}}]
}
```
