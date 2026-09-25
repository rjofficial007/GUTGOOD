Bug review — 2026-09-24

Reviewed Flutter saved-food state, chat parsing and persistence, cached scan
hydration, and the existing analyzer/test baseline. Existing feature and cleanup
work was preserved. No cloud deployment or physical-device validation was done.

Fixed:

- Saved foods persisted in the singleton across account changes. Session reset
  now clears them immediately, invalidates pending reads/writes, and auth changes
  reload the current account.
- Saved-food reads could overwrite newer results or notify a disposed provider.
  Requests now check their generation and disposal state. Failed refreshes end
  loading without throwing an unhandled asynchronous error.
- Bookmark matching used exact names while persistence normalizes names and
  barcode whitespace. The provider now uses the same savedFoodKey function.
- Saving triggered two reads. It now sends one update notification and awaits
  the resulting refresh.
- Legacy replies containing multiple structured tags were consumed by the
  raw-JSON fallback after its first scan object, dropping later meal/symptom
  records. Tagged replies now reach the legacy parser.
- Cached scans minted a new scan ID without creating that document. Slim chat
  previews therefore could not reload details. Cache hits retain the original
  document reference while creating a new chat turn.
- Cached scores were recomputed but retained an old explanation. Cache hits now
  refresh the explanation; fresh photo scans retain their authored narrative.

Regression coverage adds eight saved-food tests and checks cached scan references
after ChatMessage serialization. Existing parser/version and cache-scoring tests
cover the other fixes.

The initial full test baseline had 314 passes and 12 failures. Remaining baseline
failures outside these fixes concern the OFF cache fixture, seven Insights widget
assertions, scanner save notification counts, and the obsolete fat chat-document
assertion in widget_test.dart. These are not claimed as resolved by this review.

Final validation: 324 tests passed, 10 baseline failures remain, and no new test
failures were introduced. Flutter analysis reports the same 19 existing
info-level diagnostics, with no errors or warnings. The modified code passes
the whitespace diff check.
