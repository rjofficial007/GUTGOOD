# GutGood: changes made and how the app now works

Prepared on October 8, 2026 from the current application code and remaining workspace changes.

## 1. Scope and current status

This document describes the fixes retained from the recent Insights review and follow-up work. It also explains existing behavior needed to understand those fixes. It is not a claim that every feature discussed earlier in the conversation was newly implemented in this change set.

The main result is a more consistent path from confirmed food consumption and symptom records to Patterns, Food Impact, personal scores, and Weekly Recap. Routine Insight generation uses rules on the device and does not call AI.

At your request, the recent server subscription implementation was removed. Your previous RevenueCat subscription flow, client premium updates, backend premium checks, and Firestore subscription rules were restored. No subscription backend was deployed.

## 2. What I changed

| Area | Problem addressed | Change retained |
| --- | --- | --- |
| Food Impact | The rule-generated snapshot did not populate the data needed by Food Impact. | Build Food Impact rows and its balance from qualifying pattern occurrences. |
| Event dates | Recently entered records could refer to events outside the analysis period. | Filter actual meal/symptom event times as well as future log timestamps. |
| Meal and symptom timing | Missing or estimated times prevented reliable timing associations. | Add explicit date/time confirmation and optional symptom-to-meal selection in chat. |
| Scan consumption | Personal score calculations could use informational scans. | Score only eligible confirmed consumption, using the linked meal's eating time. |
| Older scan sources | A newly eaten meal could reference a product scanned before the analysis period. | Retrieve missing source scans by ID for confirmed journal meals and score refreshes. |
| History volume | A 150-record ceiling could discard valid evidence. | Page strict analysis history reads in batches of 150 until the query is complete. |
| Read failures | A failed history read could look like an empty history. | Propagate strict read failures so generation fails instead of publishing an empty replacement. |
| Snapshot consistency | Patterns and the main Insight could be saved or displayed from different refreshes. | Save both documents in one batch and display the snapshot's embedded patterns. |
| Score refresh | Reusing an existing same-week score could retain an old calculation. | Recalculate and save the current week during Insight refresh. |
| Evidence presentation | Food Impact and pattern details lacked useful evidence context. | Show reported observations, involved foods, readable dates, and association wording. |
| UI regression checks | Some widget expectations no longer matched the current UI and real score data. | Update affected fixtures/assertions and isolate an image-network dependency in the card test. |

## 3. What users experience

### Food and barcode scans

The existing consumption question remains the gate between scan information and a meal record:

1. The user scans food or a barcode and receives the analysis.
2. The chat asks whether they ate it.
3. **Yes, I ate it** now opens **When did you eat this?** with a date and time.
4. **Confirm time** records the chosen eating time and saves the confirmed meal.
5. Dismissing that sheet does not confirm the meal.
6. **Just checking** keeps the scan informational.

This adds a timing confirmation step to the existing consumption flow. It is no longer always a single tap from “Yes, I ate it” to saving.

Informational scans can still show their product analysis and rating. They do not qualify as consumed-food evidence merely because they were scanned. The score helper also rejects non-loggable scan types; an ingredients-label lookup by itself is not a scored meal.

### Chat meal and symptom records

Completed chat responses containing persisted meal or symptom records now expose timing actions. Unconfirmed records offer **Confirm meal time** or **Confirm symptom time**. Confirmed records show their date/time.

For a symptom, the user can choose a related confirmed meal. Without an explicit selection, the save flow can link the nearest earlier meal with user-confirmed timing within four hours. If no eligible meal exists, it leaves the link empty.

Confirmation updates the existing journal record rather than creating another record. The symptom's provenance becomes user-confirmed. Missing severity, mood, or sleep values are not invented by this timing action.

The picker supports dates within the previous year and rejects future times. Patterns still use their own 30-day analysis window.

### Logging a swap

**Log This Meal** on Swap Details uses the same timing sheet. The app records when the meal was eaten separately from when the journal entry was saved.

## 4. End-to-end data flow

```text
Food scan / explicit meal log / symptom check-in
    → save source data under the signed-in user's profile
    → confirm consumption and actual occurrence time where applicable
    → app data-change notification
    → debounced Insight refresh on the device
    → fetch recent meals, symptoms, scans, and required older scan sources
    → validate dates and consumption eligibility
    → calculate repeated meal-response observations
    → build Food Impact, current score, and Weekly Recap
    → save current score
    → atomically save the Insight snapshot and latest Patterns
    → Firestore listeners update the Insights screens
```

The existing notifier schedules data-change refreshes with a five-second debounce. It also supports screen/bootstrap and manual refresh paths, and prevents overlapping generation within that notifier instance. A profile with Insights disabled skips generation.

**This is client-driven generation.** These changes do not install a Cloud Function that recomputes Insights whenever Firestore changes while the app is closed.

### Relevant Firestore records

All paths below are beneath `user_profiles/{uid}`.

| Record | Purpose |
| --- | --- |
| `scan_history/{scanId}` | Source scan analysis, images, product data, and consumption state. |
| `journal_logs/{recordId}` | Typed meal or symptom with log time, occurrence time, provenance, and source/meal links. |
| `insights/rule_based_latest` | Current rule-generated snapshot, including Patterns, Food Impact, score summary, and Weekly Recap. |
| `pattern_data/latest` | Latest pattern collection for consumers of the separate Patterns document. |
| `gut_scores/{weeklyId}` | Weekly score record, daily scores, and scored-day indices. |

The stable Insight document is overwritten on refresh. Routine refreshes do not create a new AI history document each time.

## 5. Which data counts

Manual meal logs without a scan reference are treated as food the user logged as eaten. Scan-linked meals qualify when the meal has explicit consumption confirmation or its source scan is confirmed consumed. Legacy automatically created scan meals without confirmation are excluded.

A confirmed scan without a journal projection can use the existing scan-only fallback. Where a journal projection exists, shared linking helpers avoid counting the scan and meal as two food events.

For personal scoring, a scan explicitly marked `consumed: false` is excluded. A qualifying scan is projected onto the linked meal's event time for calculation; the scan's original saved timestamp is not rewritten.

### Dates and provenance

- `createdAt` describes when the record was logged.
- `occurredAt` describes when the user says the event happened.
- `eventTime` uses occurrence time when available, with the model's log-time fallback otherwise.
- User timing confirmation records `occurredAtProvenance: user`.
- Keyword-fallback symptoms are excluded from pattern corroboration until confirmed through the supported flow.

History queries currently select by `createdAt`. The pattern pipeline then checks event times against its rolling 30-day window. Pagination completes those queries; it does not change them into queries indexed directly by `occurredAt`.

Future records and out-of-window event times are rejected by the analysis filters. Calendar-day and week scoring uses the device's local time zone. Stored score period boundaries are converted to UTC.

## 6. How Patterns are computed

These thresholds and matching rules describe the current engine, including behavior that existed before this follow-up.

### Matching a reaction to a meal

The engine normalizes food names by lowercasing, trimming whitespace, and removing simple quantity prefixes. This groups variations such as `Pizza` and `2x Pizza`; it is not a complete ingredient ontology.

A stored meal link is authoritative unless explicit food context contradicts it. That linked path can qualify without the ordinary time-window requirement. For ordinary unlinked timing matches, both the meal and symptom require user-confirmed occurrence times, and the symptom must be at or after the meal within the detector's window.

| Detector | Ordinary matching window |
| --- | --- |
| Bloating | Up to 4 hours |
| Energy | Up to 4 hours |
| Headache | Up to 6 hours |
| Digestion | Up to 6 hours |
| Fullness | Up to 3 hours |
| Sleep | Separate dinner/sleep rule using confirmed times; earlier dinner is before 8 PM and late dinner is from 8 PM. |

The four-hour automatic journal-link window and the detector windows are separate rules. An explicit user-selected link is also distinct from automatic temporal matching.

### Evidence thresholds

- At least **two matching observations on two distinct dates** are needed to publish a pattern.
- At least **three observations on three distinct dates** receive the engine's medium-confidence label.
- Multiple logs on one day do not satisfy the distinct-day requirement.
- Related ingredients that always appear together can be collapsed into one combined exposure, reducing duplicate ingredient claims.
- Duplicate pattern evidence is collapsed before publication.

These labels are repeat-count heuristics. They are not statistical probabilities, medical confidence scores, controlled comparisons, or proof that a food caused a reaction.

The engine calculates from the complete fetched window, then stores at most **50 ranked patterns**, each with up to **30 recent occurrence previews**. Frequency and evidence thresholds are calculated before these preview limits.

An empty Patterns result remains valid when the data does not meet these rules. The changes do not force a pattern to appear just because there are several scans.

## 7. How Food Impact now works

The builder now uses qualifying positive or negative pattern occurrences to populate Food Impact.

Each row contains the recorded meal name, reported reaction, date, timing label, and available meal image. Repeated references to the same meal/symptom pair are deduplicated using their IDs. When IDs are missing, the fallback key uses date, meal name, reaction, and pattern type.

Rows are sorted by date and limited to the most recent **50**. The balance percentages use the positive and negative counts in that displayed set. Neutral is zero in this builder because a missing reaction is not converted into a neutral observation.

For example, six positive and four negative displayed observations yield 60% positive and 40% negative. This describes reported observations in the selected evidence; it does not mean 60% of all food eaten was beneficial.

Food Impact can still be empty if no qualifying patterns exist, their direction is unsupported, or their occurrence lists are empty. A scan's product rating alone does not create a Food Impact row.

## 8. How the personal Gut Score works

The formula was retained; the main change is which food records enter it and which date they belong to.

```text
Daily score = round(average rating of eligible consumed scans)
              − symptom penalty
              + logging bonus
Final value is clamped to 0–100.
```

The current implementation skips positive reactions when applying penalties. Each remaining symptom contributes 3 points for severity below 4, 6 points for severity 4–6, or 9 points for severity 7 and above. Missing severity defaults to the mild branch. The total penalty is capped at 30.

The bonus helper adds two points per unique confirmed food-logging day, capped at 10. During daily score calculation it receives a single day's data, so a scored day ordinarily gets a two-point bonus.

A day without an eligible consumed scan has no score. Its stored chart slot is zero, while `scoredDayIndices` distinguishes that empty slot from a genuinely measured zero. Manual meals and symptoms alone do not create a score under this formula.

The weekly headline is the rounded mean of scored daily values, including genuine scored zeros and excluding empty days. Weeks run **Sunday through Saturday**.

The current week is recalculated during Insight refresh. Previously stored historical weeks are not automatically backfilled.

The arithmetic is deterministic, but an input scan rating may still come from an AI food analysis. The personal score therefore is not a clinically validated measurement or a wholly AI-independent source dataset.

## 9. Weekly Recap and screen behavior

The existing recap selects the previous completed Sunday–Saturday week on most days. On Saturday it uses the current week through the current time. The current score and recap therefore may cover different periods intentionally.

| Screen area | Data shown |
| --- | --- |
| For You | The saved rule snapshot's summary, current score, and available evidence. |
| Patterns | Embedded patterns from that same rule snapshot, with occurrence evidence and involved foods. |
| Food Impact | The newly populated reported meal-response rows and observation balance. |
| Weekly Recap | The selected recap week's counts, daily score series, and measured-day summary. |

The feed's score-change fallback now uses the actual supplied score series. Pattern detail cards show involved foods. Sleep occurrence dates use sortable ISO dates with a separate readable label.

## 10. Saves, failures, and user isolation

Strict analysis reads now fetch server pages of 150 documents with document cursors. Equal timestamps do not cause the next page to skip records. Removing the old total cap increases Firestore reads for users with larger histories.

If these reads fail or the device is offline, generation reports a refresh failure and keeps the prior dashboard rather than treating unavailable history as empty evidence. This does not promise that every unrelated app read or write has the same offline policy.

The main Insight and `pattern_data/latest` are committed in one Firestore batch. The dashboard also uses the Insight's embedded Patterns to avoid mixing two listener emissions from different versions. A failed Insight save now propagates to the generation caller.

The score is saved separately before that batch. Score and Insight are therefore **not one all-or-nothing transaction**. A score save can succeed while the subsequent Insight save fails.

Timing and consumption actions check the active user and current chat message. An action from a cleared chat cannot silently write into the replacement chat. Insight saves check the snapshot's UID against the active user. These guards reduce session-switch mistakes; they do not constitute a fresh audit of every storage path in the application.

New-pattern notifications continue to respect notification preferences and use a per-user, per-day notification marker.

## 11. AI usage after these changes

Routine Patterns, Food Impact construction, score arithmetic, and recap calculation do not call AI. They operate on saved data.

The existing optional AI explanation remains a user-requested operation over saved findings. It is separate from automatic refresh, and its save checks that the underlying snapshot has not changed.

Food-photo analysis, conversational chat, and AI-generated swap recommendations retain their existing AI paths. This work does not remove those API calls or redesign their prompts.

## 12. Subscription changes removed

The rollback removed the newly added server entitlement module, RevenueCat callable and webhook exports, associated secrets/setup instructions, entitlement check script, protected subscription-field changes, and new client verification calls.

The original auth/profile-writing behavior, purchase-provider behavior, premium quota lookup, and corresponding auth-test setup were restored. The Functions build passed after rollback. No RevenueCat server setup is required by the remaining Insights changes.

## 13. Verification already performed

Before the subscription rollback, **147 affected Flutter tests passed**, and a full `flutter analyze` reported no issues. The Functions build and the then-present entitlement checks also passed.

The affected checks included consumption filtering, eating-date score bucketing, older source-scan retrieval, atomic Insight/Pattern writes, pagination across 151 equal-timestamp records, explicit timing confirmation/dismissal, future-time rejection, and stale chat timing actions.

After removing subscription changes, the **Functions build passed again**, the restored subscription files matched their previous Git versions, and diff whitespace checks passed. The full Flutter suite was not rerun after that rollback. The removed entitlement check is no longer part of the project.

This document adds no runtime changes. These checks are not a claim of live Firebase deployment, production-data migration, emulator security-rule coverage, or a complete physical-device walkthrough.

## 14. Remaining limitations and follow-up items

1. **Historical data:** Old score documents need an explicit backfill if you want them recalculated under confirmed-consumption rules. Missing historical eating times cannot be recovered reliably without user input.
2. **Closed-app refresh:** Insight generation runs in the client. There is no new server job keeping results fresh while the app is closed.
3. **Multiple devices:** Per-notifier generation guards do not serialize separate devices. The Insight batch does not use a server input revision to reject every older computation. Existing score freshness checks also rely on device calculation timestamps.
4. **Time-zone changes:** Scoring uses the device's current local calendar. Travel or clock changes are not modeled with an immutable per-event time-zone history by this work.
5. **Evidence strength:** Repeat-count rules do not control for other foods, sleep, stress, medication, portions, or incomplete symptom reporting. The UI must continue to describe observations as associations.
6. **Different symptom filters:** Keyword-fallback exclusion is a pattern rule. The score penalty routine does not apply that same provenance filter, and missing severity still takes the mild penalty branch. These behaviors were not rewritten here.
7. **Input query boundaries:** Completing a `createdAt` query is not equivalent to indexing the full journal by event time. Unusual imported records with older creation times and newly relevant occurrence times need further consideration.
8. **Preview limits:** Food Impact balance reflects its retained observation preview, not a population-wide or complete-history percentage. Pattern evidence previews are also capped.
9. **Confirmation UX:** The added eating-time sheet is an extra step. It should be checked on a device with the actual scan, barcode, symptom, and swap flows before release.

## 15. Main source files

- [Consumption eligibility and source linking](/Volumes/Data/SVN/gutgood_app/Source/gutgood_app/lib/core/models/journal/food_event_linking.dart)
- [Date/time confirmation sheet](/Volumes/Data/SVN/gutgood_app/Source/gutgood_app/lib/core/widgets/journal_event_sheet.dart)
- [Chat confirmation persistence](/Volumes/Data/SVN/gutgood_app/Source/gutgood_app/lib/features/chat/presentation/providers/chat_history_notifier.dart)
- [Confirmed scan meal persistence](/Volumes/Data/SVN/gutgood_app/Source/gutgood_app/lib/features/logs/data/services/domain_event_persister.dart)
- [Insight generation flow](/Volumes/Data/SVN/gutgood_app/Source/gutgood_app/lib/features/insights/application/usecases/generate_insight_usecase.dart)
- [Pattern rules and thresholds](/Volumes/Data/SVN/gutgood_app/Source/gutgood_app/lib/features/insights/data/services/pattern_engine_service.dart)
- [Food Impact and snapshot builder](/Volumes/Data/SVN/gutgood_app/Source/gutgood_app/lib/features/insights/domain/services/rule_based_insight_builder.dart)
- [Score and recap calculations](/Volumes/Data/SVN/gutgood_app/Source/gutgood_app/lib/core/services/gut_score_calculator_service.dart)
- [History pagination and score refresh](/Volumes/Data/SVN/gutgood_app/Source/gutgood_app/lib/infrastructure/firebase/firestore/history_firestore_impl.dart)
- [Insight and Pattern batch save](/Volumes/Data/SVN/gutgood_app/Source/gutgood_app/lib/infrastructure/firebase/firestore/insight_firestore_service.dart)
- [Dashboard snapshot selection](/Volumes/Data/SVN/gutgood_app/Source/gutgood_app/lib/features/insights/data/repositories/insight_repository_impl.dart)
- [Automatic refresh and optional AI explanation](/Volumes/Data/SVN/gutgood_app/Source/gutgood_app/lib/features/insights/presentation/providers/insights_notifier.dart)
