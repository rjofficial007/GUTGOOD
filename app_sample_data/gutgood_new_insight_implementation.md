# GutGood — New Insights Implementation Specification

> Version: 3.0  
> Purpose: Production-ready specification for the redesigned GutGood **Insights** experience.  
> Scope: Data model, canonical pattern types, screen mapping, navigation, CTA behavior, mock data, and implementation rules.

---

# 1. Product Goal

The GutGood Insights feature analyzes the user's logged meals, symptoms, food scans, and self-reported outcomes to surface understandable recurring patterns.

The experience should answer four questions:

1. **What is happening?**
2. **What may be associated with it?**
3. **How strong is the pattern?**
4. **What can the user try next?**

Insights should be framed as observed associations from the user's own logs, not as medical diagnoses.

---

# 2. Canonical Insight Pattern Types

The new implementation supports exactly six canonical pattern types.

```text
bloating
energy
headache
digestion
fullness
sleep
```

## 2.1 Bloating Pattern

**Definition:** Foods or meals repeatedly followed by bloating.

Example:

```text
Fried foods → Bloating
3 similar occurrences
Typical delay: ~2 hours
Confidence: High
```

Typical reactions:

```text
bloating
abdominal fullness
distension
feeling puffy
```

---

## 2.2 Energy Pattern

**Definition:** Meals followed by feeling energized, tired, or sluggish.

Examples:

```text
Protein-rich breakfast → Steady afternoon energy
Heavy fried lunch → Sluggish afternoon
```

Typical reactions:

```text
energized
steady energy
tired
sluggish
energy crash
```

---

## 2.3 Headache Pattern

**Definition:** Repeated headaches after similar foods, meals, ingredients, or meal timing.

Example:

```text
Sugary afternoon snacks → Headache
3 similar occurrences
Typical delay: 1–3 hours
```

Typical reactions:

```text
mild headache
moderate headache
head pressure
throbbing headache
```

---

## 2.4 Digestion Pattern

**Definition:** Stomach discomfort, gas, bowel changes, or other digestion-related changes after meals.

Examples:

```text
Large fried dinner → Stomach discomfort
Fermented foods + fiber → Smoother digestion
```

Typical reactions:

```text
gas
stomach discomfort
cramping
constipation
loose stool
smooth digestion
bowel regularity
heaviness
```

---

## 2.5 Fullness Pattern

**Definition:** Foods or meals that consistently keep the user full versus hungry again quickly.

Examples:

```text
Oats + Greek yogurt → Full for 4 hours
Sugary cereal → Hungry again after 90 minutes
```

Typical reactions:

```text
stayed full
satisfied
hungry quickly
snacking urge
long-lasting satiety
```

---

## 2.6 Sleep Pattern

**Definition:** Connections between evening food, meal timing, portion size, and reported sleep quality.

Examples:

```text
Late heavy dinner → Poorer sleep
Early lighter dinner → Better sleep
```

Typical reactions:

```text
good sleep
poor sleep
restless sleep
difficulty falling asleep
woke during night
refreshed next morning
next-day tiredness
```

> Sleep patterns must only be generated when GutGood actually has sleep observations or user-reported sleep data. Meal timing alone is not enough to claim a sleep pattern.

---

# 3. Pattern Type vs Reaction

`patternType` and `reaction` are intentionally separate.

Correct:

```json
{
  "patternType": "energy",
  "trigger": "Protein-rich breakfast",
  "reaction": "Steady afternoon energy"
}
```

Correct:

```json
{
  "patternType": "bloating",
  "trigger": "Deep-fried dinner",
  "reaction": "Abdominal bloating"
}
```

Avoid:

```json
{
  "patternType": "digestion",
  "reaction": "energy"
}
```

The canonical pattern type determines the UI category.  
The reaction describes the user's observed outcome.

---

# 4. Root Insight Response

## `AIInsight`

```json
{
  "version": 3,
  "model": "insight-model",
  "promptVersion": 5,
  "status": "ready",
  "origin": "client",
  "generatedAt": "2026-09-18T08:30:00.000Z",
  "updatedAt": "2026-09-18T08:30:00.000Z",

  "period": {},
  "gutScore": {},
  "topInsight": null,

  "detectedPatterns": [],
  "healingFoods": [],
  "triggerFoods": [],
  "foodImpacts": [],

  "weeklyRecap": null,
  "weeklyRecapHistory": [],

  "evidence": {},
  "actions": [],
  "foodSwaps": [],
  "recentInsights": [],

  "emptyState": null
}
```

---

# 5. Core Enumerations

## `InsightPatternType`

```text
bloating
energy
headache
digestion
fullness
sleep
```

## `ConfidenceLevel`

```text
low
medium
high
```

## `ImpactDirection`

```text
positive
neutral
negative
```

## `ImpactLevel`

```text
low
moderate
high
```

## `InsightKind`

```text
pattern
food_impact
weekly_recap
progress
trigger
healing
action
synergy
```

## `ActionStatus`

```text
not_started
in_progress
completed
dismissed
```

---

# 6. Gut Score Model

## `GutScoreSummary`

Used by:

- For You
- Improving Trend
- Weekly Recap
- Your Next Steps

```json
{
  "score": 78,
  "maxScore": 100,
  "previousScore": 74,
  "scoreDiff": 4,
  "direction": "up",
  "statusLabel": "Improving",
  "summary": "Your recent logs show more positive digestion and energy responses.",
  "dailyScores": [
    { "date": "2026-09-12", "label": "Sat", "score": 73 },
    { "date": "2026-09-13", "label": "Sun", "score": 74 },
    { "date": "2026-09-14", "label": "Mon", "score": 75 },
    { "date": "2026-09-15", "label": "Tue", "score": 76 },
    { "date": "2026-09-16", "label": "Wed", "score": 77 },
    { "date": "2026-09-17", "label": "Thu", "score": 78 },
    { "date": "2026-09-18", "label": "Fri", "score": 78 }
  ]
}
```

---

# 7. Pattern Model

## `BodyPattern`

Every generated pattern uses the same reusable structure.

```json
{
  "id": "pat_bloating_001",
  "patternType": "bloating",

  "title": "Fried foods → Bloating",
  "trigger": "Deep-fried and heavily processed meals",
  "reaction": "Abdominal bloating",

  "description": "Deep-fried meals were repeatedly followed by bloating in your recent logs.",

  "frequency": 3,
  "totalSimilarMeals": 4,
  "timeframeDays": 14,

  "confidence": "high",
  "confidenceScore": 0.91,

  "impactDirection": "negative",
  "impactLevel": "high",

  "typicalTiming": "Dinner",
  "typicalDelayMinutes": 120,
  "typicalDelayLabel": "About 2 hours",

  "recommendation": "Try roasted, grilled, or steamed alternatives and compare how you feel.",

  "occurrenceIds": [
    "occ_001",
    "occ_002",
    "occ_003"
  ],

  "commonFactors": [
    {
      "label": "deep fried",
      "icon": "flame"
    },
    {
      "label": "high fat",
      "icon": "droplet"
    }
  ],

  "relatedFoodIds": [
    "food_onion_rings",
    "food_fries"
  ],

  "evidence": {
    "positiveMatches": 3,
    "negativeMatches": 0,
    "totalReviewedMeals": 4,
    "matchRatio": 0.75
  },

  "createdAt": "2026-09-18T08:30:00.000Z",
  "updatedAt": "2026-09-18T08:30:00.000Z"
}
```

---

# 8. Example Multiple Generated Patterns

A single insight response may contain many patterns at the same time.

```json
[
  {
    "id": "pat_bloating_001",
    "patternType": "bloating",
    "title": "Fried foods → Bloating",
    "trigger": "Deep-fried meals",
    "reaction": "Abdominal bloating",
    "frequency": 3,
    "confidence": "high",
    "confidenceScore": 0.91,
    "typicalDelayLabel": "About 2 hours"
  },
  {
    "id": "pat_energy_001",
    "patternType": "energy",
    "title": "Protein breakfast → Steady energy",
    "trigger": "Protein-rich breakfast",
    "reaction": "Steady afternoon energy",
    "frequency": 5,
    "confidence": "high",
    "confidenceScore": 0.88,
    "typicalDelayLabel": "4–6 hours"
  },
  {
    "id": "pat_headache_001",
    "patternType": "headache",
    "title": "Sugary snacks → Headache",
    "trigger": "High-sugar afternoon snacks",
    "reaction": "Mild headache",
    "frequency": 3,
    "confidence": "medium",
    "confidenceScore": 0.71,
    "typicalDelayLabel": "1–3 hours"
  },
  {
    "id": "pat_digestion_001",
    "patternType": "digestion",
    "title": "Fermented foods → Smoother digestion",
    "trigger": "Fermented foods with fiber",
    "reaction": "Smooth digestion",
    "frequency": 5,
    "confidence": "high",
    "confidenceScore": 0.90,
    "typicalDelayLabel": "Same day"
  },
  {
    "id": "pat_fullness_001",
    "patternType": "fullness",
    "title": "Oats + yogurt → Longer fullness",
    "trigger": "Oats with Greek yogurt",
    "reaction": "Stayed full for about 4 hours",
    "frequency": 4,
    "confidence": "high",
    "confidenceScore": 0.85,
    "typicalDelayLabel": "4 hours"
  },
  {
    "id": "pat_sleep_001",
    "patternType": "sleep",
    "title": "Late heavy dinner → Poorer sleep",
    "trigger": "Large meals after 9 PM",
    "reaction": "Restless sleep",
    "frequency": 4,
    "confidence": "medium",
    "confidenceScore": 0.72,
    "typicalDelayLabel": "Overnight"
  }
]
```

---

# 9. Pattern Occurrence Model

## `PatternOccurrence`

An occurrence is one concrete meal/outcome pair supporting a pattern.

```json
{
  "id": "occ_001",
  "patternId": "pat_bloating_001",

  "date": "2026-09-15",
  "dateLabel": "Sep 15",

  "mealId": "meal_001",
  "mealName": "Burger & Fries",
  "mealType": "Dinner",
  "mealTime": "20:05",
  "mealImageUrl": null,

  "reactionType": "bloating",
  "reaction": "Abdominal bloating",
  "severity": "moderate",

  "observedAt": "2026-09-15T22:00:00.000Z",
  "timeAfterMinutes": 115,
  "timeAfterLabel": "1 hr 55 min",

  "notes": "Felt very full and bloated later in the evening.",

  "commonFactors": [
    {
      "label": "deep fried",
      "icon": "flame"
    },
    {
      "label": "large portion",
      "icon": "plate"
    }
  ]
}
```

---

# 10. Outcome / Symptom Observation Model

Use a generalized observation model so the same system can support all six pattern types.

## `OutcomeObservation`

```json
{
  "id": "obs_001",
  "type": "energy",
  "value": "energized",
  "severity": null,
  "score": 8,
  "unit": null,
  "recordedAt": "2026-09-18T14:30:00.000Z",
  "source": "user",
  "notes": "Good steady energy after lunch."
}
```

Possible `type` values:

```text
bloating
energy
headache
digestion
fullness
sleep
```

Suggested values by type:

```text
bloating:
  none
  mild
  moderate
  severe

energy:
  energized
  steady
  tired
  sluggish
  crash

headache:
  none
  mild
  moderate
  severe

digestion:
  comfortable
  gas
  discomfort
  cramping
  constipation
  loose_stool
  regular

fullness:
  hungry_quickly
  satisfied
  very_full
  duration_minutes

sleep:
  excellent
  good
  fair
  poor
  restless
```

---

# 11. Food Intelligence Models

## `InsightFood`

```json
{
  "foodId": "food_greek_yogurt",
  "name": "Greek Yogurt",
  "emoji": "🥣",

  "imageUrl": null,
  "userImageUrl": null,
  "foodScanId": "scan_yogurt_01",

  "effect": "Associated with smoother digestion and steadier energy.",

  "impactDirection": "positive",
  "impactLevel": "high",

  "frequencyCount": 5,
  "frequencyLabel": "5x this week",

  "confidence": "high",
  "confidenceScore": 0.91,

  "relatedPatternIds": [
    "pat_energy_001",
    "pat_digestion_001",
    "pat_fullness_001"
  ]
}
```

---

## `FoodImpact`

```json
{
  "id": "impact_001",
  "foodId": "food_greek_yogurt",
  "food": "Greek Yogurt",

  "date": "2026-09-16",
  "dateLabel": "Wed",

  "mealId": "meal_010",
  "timeframeLabel": "Breakfast",

  "effect": "Steady energy and smooth digestion",

  "impactDirection": "positive",
  "impactLevel": "high",

  "confidence": "high",
  "confidenceScore": 0.88,

  "patternIds": [
    "pat_energy_001",
    "pat_digestion_001"
  ]
}
```

---

## `FoodImpactBalance`

```json
{
  "positivePercent": 68,
  "neutralPercent": 20,
  "negativePercent": 12,
  "periodLabel": "Last 4 weeks"
}
```

---

# 12. Top Insight / Synergy

## `InsightSummary`

```json
{
  "id": "ins_synergy_001",
  "title": "Fiber & Fermentation Synergy",

  "description": "Meals combining fermented foods with fiber were often followed by smoother digestion.",

  "patternType": "digestion",
  "observation": "Greek yogurt, kefir, whole grains, and vegetables appeared together in several positive digestion logs.",

  "involvedFoodIds": [
    "food_greek_yogurt",
    "food_kefir",
    "food_oats",
    "food_vegetables"
  ],

  "strength": "high",
  "confidenceScore": 0.92,

  "frequency": 5,
  "positiveCount": 5,
  "negativeCount": 0,

  "nextSteps": [
    "Continue including fermented foods",
    "Pair them with fiber-rich foods"
  ]
}
```

---

# 13. Weekly Recap

## `WeeklyRecap`

```json
{
  "id": "week_2026_09_12",

  "dateRange": "Sep 12 - Sep 18",
  "from": "2026-09-12T00:00:00.000Z",
  "to": "2026-09-18T23:59:59.000Z",

  "avgScore": 78,
  "scoreDiff": 4,

  "scoreSub": "More positive digestion and energy responses were logged this week.",

  "bestDay": {
    "date": "2026-09-17",
    "label": "Sep 17",
    "score": 82
  },

  "foodsLogged": 24,
  "symptomsLogged": 8,
  "outcomesLogged": 17,

  "patternsFound": 6,
  "newPatterns": 2,

  "patternTypeCounts": {
    "bloating": 1,
    "energy": 1,
    "headache": 1,
    "digestion": 1,
    "fullness": 1,
    "sleep": 1
  },

  "highlights": [
    {
      "id": "hl_001",
      "text": "Protein-rich breakfasts were followed by steadier energy on 5 days."
    },
    {
      "id": "hl_002",
      "text": "Late heavy dinners appeared before poorer sleep on 4 nights."
    }
  ],

  "topHealingFoodId": "food_greek_yogurt",
  "topTriggerFoodId": "food_onion_rings"
}
```

---

# 14. Evidence Model

## `InsightEvidence`

```json
{
  "period": {
    "from": "2026-09-12T00:00:00.000Z",
    "to": "2026-09-18T23:59:59.000Z",
    "dateRangeLabel": "Sep 12 - Sep 18"
  },

  "sampleSizes": {
    "meals": 24,
    "foodScans": 16,
    "outcomeObservations": 17,
    "bloatingLogs": 4,
    "energyLogs": 6,
    "headacheLogs": 3,
    "digestionLogs": 7,
    "fullnessLogs": 5,
    "sleepLogs": 5
  },

  "patternRefs": [
    {
      "id": "pat_bloating_001",
      "title": "Fried foods → Bloating",
      "confidence": "high"
    },
    {
      "id": "pat_energy_001",
      "title": "Protein breakfast → Steady energy",
      "confidence": "high"
    }
  ]
}
```

---

# 15. Confidence Rules

Suggested display thresholds:

```text
High:
  confidenceScore >= 0.80

Medium:
  confidenceScore >= 0.60 and < 0.80

Low:
  confidenceScore < 0.60
```

The confidence score should consider:

```text
number of matching occurrences
number of similar meals reviewed
consistency of reaction
quality/completeness of user logs
timing consistency
contradictory observations
recency
```

Example conceptual formula:

```text
confidence =
  occurrence_strength
  × consistency
  × data_quality
  × timing_relevance
  × contradiction_penalty
```

The exact formula may remain backend-specific.

---

# 16. Pattern Generation Rules

A pattern should not be created from one isolated event.

Recommended minimum:

```text
High-confidence candidate:
  3+ matching occurrences

Medium-confidence candidate:
  2+ matching occurrences with strong timing similarity

Low-confidence observation:
  may be stored internally
  should not necessarily appear as a prominent user-facing pattern
```

Generation flow:

```text
Meal Logged
    ↓
Food / Ingredient Features Extracted
    ↓
Outcome Logged
    ↓
Match Meal → Outcome by Time Window
    ↓
Find Similar Meal / Food Factors
    ↓
Group Similar Repeated Associations
    ↓
Calculate Confidence
    ↓
Create / Update BodyPattern
```

---

# 17. Pattern-Specific Time Windows

Suggested starting windows:

```text
Bloating:
  0–6 hours after meal

Energy:
  30 minutes–8 hours after meal

Headache:
  30 minutes–12 hours after meal

Digestion:
  0–24 hours after meal

Fullness:
  30 minutes–8 hours after meal

Sleep:
  evening meal through next morning
```

These are matching windows for product logic, not medical diagnostic rules.

---

# 18. Pattern Deduplication

Do not create multiple near-identical cards such as:

```text
Fried foods → Bloating
French fries → Bloating
Fried dinner → Bloating
Deep-fried foods → Bloating
```

Instead merge related evidence into a stronger parent pattern:

```text
Fried foods → Bloating
```

with common factors:

```text
deep fried
high fat
large portion
evening meal
```

Create a separate pattern only when the trigger or reaction is meaningfully different.

---

# 19. Pattern Ranking

The Patterns screen may contain many patterns.

Recommended ranking:

```text
1. confidence
2. recency
3. frequency
4. impact strength
5. whether the pattern is newly discovered
```

Do not permanently pin one pattern as the hero pattern.

The full Patterns screen should remain scalable to:

```text
1 pattern
6 patterns
20+ patterns
```

---

# 20. Screen Architecture

The redesigned Insights experience contains the following screens.

---

## Screen 01 — Insights / For You

Purpose:

```text
Quick personalized overview.
```

Content:

```text
Gut Score
score change
top insight
what is improving
something to watch
top healing food
top trigger
recent patterns
recent insights
quick next step
```

Primary navigation:

```text
For You
Patterns
Food Impact
Weekly Recap
```

CTAs:

```text
View Details
See Pattern
View All
See Why
```

---

## Screen 02 — Patterns

Purpose:

```text
Show every AI-generated pattern.
```

Header:

```text
Detected Patterns
6 patterns found
```

Filters:

```text
All
Bloating
Energy
Headache
Digestion
Fullness
Sleep
```

Each card shows:

```text
pattern icon
pattern type
title
short description
frequency
confidence
typical timing/delay
recommendation preview
View Pattern →
```

Use a vertical list instead of a fixed 1-large + 2-small layout.

---

## Screen 03 — Pattern Detail

Reusable for all six pattern types.

Content:

```text
pattern type
title
trigger
reaction
confidence
frequency
timeframe
typical delay
description

Why we noticed this
common factors
example occurrences
recommendation
evidence summary
related foods
```

CTAs:

```text
View All Occurrences
View Evidence
Plan Better Swaps
```

---

## Screen 04 — All Pattern Occurrences

Content:

```text
pattern title
date-range filter
occurrence count

occurrence list:
  date
  meal
  reaction
  severity
  time after meal
  common factors
```

Filters:

```text
7 Days
30 Days
All
```

Tap occurrence:

```text
→ Meal & Outcome Detail
```

---

## Screen 05 — Meal & Outcome Detail

This replaces a symptom-only detail screen because patterns now include energy, fullness, and sleep.

Content:

```text
meal image
meal name
meal time
meal type

observed outcome
outcome severity / score
time between meal and outcome

matched pattern
confidence
common factors

user notes
related occurrences
```

CTA:

```text
See Suggested Swap
```

---

## Screen 06 — Food Impact

Content:

```text
positive / neutral / negative impact balance

top healing foods
top trigger foods
recent food impacts
food synergy
```

CTAs:

```text
View All Healing Foods
View All Trigger Foods
View Food
See Synergy
```

---

## Screen 07 — Food Detail

Reusable for any food.

Content:

```text
food image
food name
overall impact
confidence
frequency

observed effects
related pattern types

why it may be helping / triggering
history
pairings
recommended next step
```

---

## Screen 08 — All Healing Foods

Content:

```text
positive foods
impact level
frequency
associated outcomes
confidence
```

Sort:

```text
Highest Impact
Most Frequent
Recently Observed
```

---

## Screen 09 — All Trigger Foods

Content:

```text
trigger foods
associated outcome
frequency
typical delay
confidence
related patterns
```

---

## Screen 10 — Trigger Detail

Content:

```text
trigger food / meal
associated reactions
frequency
typical delay
recent occurrences
common factors
related pattern
recommendation
```

---

## Screen 11 — Synergy Detail

Content:

```text
synergy title
foods involved
observed outcome
positive matches
negative matches
confidence
frequency
suggested combinations
```

---

## Screen 12 — Weekly Recap

Content:

```text
date range
average score
score delta
daily score chart
best day
foods logged
outcomes logged
patterns found
top healing food
top trigger
weekly highlights
weekly insight
```

CTA:

```text
View Previous Weeks
```

---

## Screen 13 — Weekly Recap History

Content:

```text
week cards
date range
average score
score change
foods logged
patterns found
short summary
```

Tap week:

```text
→ Weekly Recap
```

---

## Screen 14 — Improving Trend

Content:

```text
score trend chart
current score
previous score
change
trend explanation
contributors
```

Possible contributor cards:

```text
more fiber
more fermented foods
less fried food
better logging consistency
```

---

## Screen 15 — Recent Insights

Content:

```text
chronological insight feed
```

Possible cards:

```text
new pattern
pattern strengthened
food impact
weekly recap
progress
trigger
healing
```

Each card must include a destination ID.

---

## Screen 16 — Your Evidence

Content:

```text
data period
meals analyzed
outcomes logged
food scans
patterns supported
confidence overview
pattern evidence cards
```

CTA:

```text
How Confidence Works
```

---

## Screen 17 — Evidence / Confidence Explanation

Can be a full screen or bottom sheet.

Content:

```text
What High / Medium / Low means
What data contributes
Why more logging helps
How contradictory logs reduce confidence
Correlation vs causation explanation
```

---

## Screen 18 — Your Next Steps

Content:

```text
recommended actions
why each action exists
related pattern
priority
status
```

Possible actions:

```text
Try roasted instead of fried sides
Keep protein in breakfast
Finish dinner earlier
Pair yogurt with fiber
Track headaches after afternoon snacks
```

---

## Screen 19 — Action Detail

Content:

```text
action title
why recommended
related pattern
supporting evidence
suggested frequency
how to try it
progress
```

Actions:

```text
Start
Mark Complete
Dismiss
```

---

## Screen 20 — Better Swaps

Content:

```text
original food
suggested alternative
why suggested
related pattern
expected benefit
```

Example:

```text
Onion Rings
↓
Roasted Potatoes

Reason:
Your recent fried-food meals were often followed by bloating.
```

Actions:

```text
Save Swap
Log Alternative
```

---

## Screen 21 — Empty / Insufficient Data

Shown when GutGood cannot generate reliable insights yet.

Example:

```text
We're still learning about you.

Meals logged        4
Outcomes logged     1
Food scans          2

Keep logging meals and how you feel.
We'll surface patterns when there's enough repeated evidence.
```

CTAs:

```text
Log a Meal
Log How I Feel
```

---

# 21. Screen Navigation Map

```text
Insights / For You
│
├── Patterns
│   ├── Pattern Detail
│   │   ├── All Occurrences
│   │   │   └── Meal & Outcome Detail
│   │   ├── Your Evidence
│   │   └── Better Swaps
│   │
│   └── Pattern Type Filters
│       ├── Bloating
│       ├── Energy
│       ├── Headache
│       ├── Digestion
│       ├── Fullness
│       └── Sleep
│
├── Food Impact
│   ├── Food Detail
│   ├── All Healing Foods
│   ├── All Trigger Foods
│   │   └── Trigger Detail
│   └── Synergy Detail
│
├── Weekly Recap
│   └── Weekly Recap History
│
├── Improving Trend
├── Recent Insights
├── Your Evidence
│   └── Confidence Explanation
│
└── Your Next Steps
    ├── Action Detail
    └── Better Swaps
```

---

# 22. CTA / Routing Matrix

| Source | CTA | Destination |
|---|---|---|
| For You score card | View Trend | Improving Trend |
| For You top insight | View Details | Pattern Detail / Synergy Detail |
| For You pattern preview | View Pattern | Pattern Detail |
| For You recent insight | View | Destination from `targetType` |
| Patterns card | View Pattern | Pattern Detail |
| Pattern Detail | View All Occurrences | All Pattern Occurrences |
| Pattern Detail | View Evidence | Your Evidence |
| Pattern Detail | Plan Better Swaps | Better Swaps |
| Occurrence | View Details | Meal & Outcome Detail |
| Food Impact food card | View Food | Food Detail |
| Food Impact | View All Healing | All Healing Foods |
| Food Impact | View All Triggers | All Trigger Foods |
| Food Impact synergy | See Details | Synergy Detail |
| Weekly Recap | Previous Weeks | Weekly Recap History |
| Evidence | How Confidence Works | Confidence Explanation |
| Next Step | See Details | Action Detail |
| Action Detail | Find Better Swap | Better Swaps |

---

# 23. Recent Insight Model

## `RecentInsight`

```json
{
  "id": "recent_001",

  "kind": "pattern",
  "patternType": "energy",

  "title": "Protein breakfast → Steady energy",
  "subtitle": "This pattern appeared in 5 recent breakfasts.",

  "createdAt": "2026-09-18T08:30:00.000Z",

  "targetType": "pattern",
  "targetId": "pat_energy_001"
}
```

Supported `targetType` values:

```text
pattern
food
weekly_recap
action
synergy
trend
evidence
```

---

# 24. Action Model

## `InsightAction`

```json
{
  "id": "action_001",

  "title": "Try roasted instead of fried sides",

  "description": "Compare your bloating response after choosing roasted or steamed sides.",

  "status": "not_started",
  "priority": "high",

  "relatedPatternIds": [
    "pat_bloating_001"
  ],

  "suggestedFrequency": "Try 3 times over the next 7 days",

  "reason": "Three recent fried meals were followed by bloating.",

  "createdAt": "2026-09-18T08:30:00.000Z"
}
```

---

# 25. Better Swap Model

## `FoodSwap`

```json
{
  "id": "swap_001",

  "original": {
    "foodId": "food_onion_rings",
    "name": "Onion Rings"
  },

  "alternative": {
    "foodId": "food_roasted_potatoes",
    "name": "Roasted Potatoes"
  },

  "reason": "Fried foods were repeatedly followed by bloating in your logs.",

  "relatedPatternId": "pat_bloating_001",

  "expectedBenefit": "Lets you compare a lower-fat cooking method with your usual response.",

  "saved": false
}
```

---

# 26. Data Required to Support Each Pattern

## Bloating

Required source data:

```text
meal
meal time
foods / ingredients
bloating observation
observation time
severity if available
```

---

## Energy

Required source data:

```text
meal
meal time
foods / ingredients
energy observation
energy state / score
observation time
```

---

## Headache

Required source data:

```text
meal
meal time
foods / ingredients
headache observation
headache severity
observation time
```

---

## Digestion

Required source data:

```text
meal
meal time
foods / ingredients
digestion observation
gas / discomfort / bowel response
observation time
```

---

## Fullness

Required source data:

```text
meal
meal time
foods / ingredients
fullness / hunger observation
time until hunger returns
```

---

## Sleep

Required source data:

```text
evening meal
meal time
foods / ingredients
portion information if available
bed time
sleep observation / sleep score
wake time if available
```

---

# 27. Logging UX Required for Pattern Quality

The insight engine becomes much more useful when the app supports lightweight outcome logging.

Suggested quick-check controls:

```text
How do you feel?

Bloating:
None / Mild / Moderate / Severe

Energy:
Energized / Steady / Tired / Sluggish

Headache:
None / Mild / Moderate / Severe

Digestion:
Comfortable / Gas / Discomfort / Other

Fullness:
Still hungry / Satisfied / Very full
+ optional "Hungry again" timestamp

Sleep:
Great / Good / Fair / Poor
```

The user should not be required to answer every category every time.

---

# 28. Empty and Partial States

## No Insights Yet

```text
We're still learning from your logs.
```

## Only One Pattern

Do not show empty category sections.

Show:

```text
1 pattern found
```

and render only that card.

## No Pattern for Selected Filter

Example:

```text
No Sleep patterns yet.

Keep logging evening meals and sleep quality.
We'll show a pattern here when we have enough repeated evidence.
```

## Missing Sleep Data

Do not infer sleep quality.

Show:

```text
Track sleep quality to unlock meal & sleep insights.
```

---

# 29. Loading State

Skeleton sections:

```text
score hero
top insight
2–3 pattern cards
food impact cards
weekly recap preview
```

Do not show fake pattern names while loading.

---

# 30. Error State

```text
We couldn't refresh your insights.

Your existing insights are still available.
```

Actions:

```text
Try Again
```

If cached data exists, keep it visible.

---

# 31. Insight Language Rules

Preferred wording:

```text
"was often followed by"
"appeared alongside"
"was associated with"
"in your recent logs"
"we noticed"
"may be worth comparing"
```

Avoid definitive medical wording:

```text
"causes"
"diagnoses"
"proves"
"you are intolerant to"
"this food is dangerous"
```

Example:

Preferred:

```text
Fried meals were often followed by bloating in your recent logs.
```

Avoid:

```text
Fried food causes your bloating.
```

---

# 32. UI Pattern Configuration

The app can map each pattern type to UI metadata.

```json
{
  "bloating": {
    "label": "Bloating",
    "icon": "bloating"
  },
  "energy": {
    "label": "Energy",
    "icon": "bolt"
  },
  "headache": {
    "label": "Headache",
    "icon": "head"
  },
  "digestion": {
    "label": "Digestion",
    "icon": "stomach"
  },
  "fullness": {
    "label": "Fullness",
    "icon": "bowl"
  },
  "sleep": {
    "label": "Sleep",
    "icon": "moon"
  }
}
```

Colors should follow the global GutGood design system rather than hard-coding unique business logic around colors.

---

# 33. Recommended Flutter Model Shape

```dart
enum InsightPatternType {
  bloating,
  energy,
  headache,
  digestion,
  fullness,
  sleep,
}

enum ConfidenceLevel {
  low,
  medium,
  high,
}

enum ImpactDirection {
  positive,
  neutral,
  negative,
}

class BodyPattern {
  final String id;
  final InsightPatternType patternType;

  final String title;
  final String trigger;
  final String reaction;
  final String description;

  final int frequency;
  final int totalSimilarMeals;
  final int timeframeDays;

  final ConfidenceLevel confidence;
  final double confidenceScore;

  final ImpactDirection impactDirection;

  final String? typicalTiming;
  final int? typicalDelayMinutes;
  final String? typicalDelayLabel;

  final String recommendation;

  final List<String> occurrenceIds;
  final List<PatternFactor> commonFactors;
  final List<String> relatedFoodIds;
}
```

---

# 34. Suggested API Endpoints

The exact API style may differ, but the feature should support equivalent operations.

```text
GET /insights
GET /insights/patterns
GET /insights/patterns/:patternId
GET /insights/patterns/:patternId/occurrences

GET /insights/food-impact
GET /insights/foods/:foodId

GET /insights/weekly-recap
GET /insights/weekly-recap/history

GET /insights/evidence
GET /insights/actions
GET /insights/swaps

POST /insights/actions/:actionId/start
POST /insights/actions/:actionId/complete
POST /insights/swaps/:swapId/save
```

Recommended query parameters:

```text
patternType
from
to
limit
cursor
sort
confidence
```

Example:

```text
GET /insights/patterns?patternType=energy&from=2026-09-01&to=2026-09-18
```

---

# 35. Complete Mock `AIInsight`

```json
{
  "version": 3,
  "model": "insight-model",
  "promptVersion": 5,

  "status": "ready",
  "origin": "client",

  "period": {
    "from": "2026-09-12T00:00:00.000Z",
    "to": "2026-09-18T23:59:59.000Z"
  },

  "gutScore": {
    "score": 78,
    "maxScore": 100,
    "previousScore": 74,
    "scoreDiff": 4,
    "direction": "up",
    "statusLabel": "Improving"
  },

  "topInsight": {
    "id": "ins_synergy_001",
    "title": "Fiber & Fermentation Synergy",
    "description": "Meals combining fermented foods with fiber were often followed by smoother digestion.",
    "patternType": "digestion",
    "strength": "high",
    "confidenceScore": 0.92,
    "frequency": 5
  },

  "detectedPatterns": [
    {
      "id": "pat_bloating_001",
      "patternType": "bloating",
      "title": "Fried foods → Bloating",
      "trigger": "Deep-fried meals",
      "reaction": "Abdominal bloating",
      "frequency": 3,
      "totalSimilarMeals": 4,
      "timeframeDays": 14,
      "confidence": "high",
      "confidenceScore": 0.91,
      "impactDirection": "negative",
      "typicalTiming": "Dinner",
      "typicalDelayMinutes": 120,
      "typicalDelayLabel": "About 2 hours",
      "recommendation": "Try roasted or steamed alternatives."
    },
    {
      "id": "pat_energy_001",
      "patternType": "energy",
      "title": "Protein breakfast → Steady energy",
      "trigger": "Protein-rich breakfast",
      "reaction": "Steady afternoon energy",
      "frequency": 5,
      "totalSimilarMeals": 6,
      "timeframeDays": 14,
      "confidence": "high",
      "confidenceScore": 0.88,
      "impactDirection": "positive",
      "typicalTiming": "Breakfast",
      "typicalDelayMinutes": 300,
      "typicalDelayLabel": "4–6 hours",
      "recommendation": "Keep a protein source in breakfast."
    },
    {
      "id": "pat_headache_001",
      "patternType": "headache",
      "title": "Sugary snacks → Headache",
      "trigger": "High-sugar afternoon snacks",
      "reaction": "Mild headache",
      "frequency": 3,
      "totalSimilarMeals": 5,
      "timeframeDays": 21,
      "confidence": "medium",
      "confidenceScore": 0.71,
      "impactDirection": "negative",
      "typicalTiming": "Afternoon",
      "typicalDelayMinutes": 120,
      "typicalDelayLabel": "1–3 hours",
      "recommendation": "Try a lower-sugar snack and compare."
    },
    {
      "id": "pat_digestion_001",
      "patternType": "digestion",
      "title": "Fermented foods → Smoother digestion",
      "trigger": "Fermented foods with fiber",
      "reaction": "Smooth digestion",
      "frequency": 5,
      "totalSimilarMeals": 6,
      "timeframeDays": 14,
      "confidence": "high",
      "confidenceScore": 0.90,
      "impactDirection": "positive",
      "typicalTiming": "Any meal",
      "typicalDelayLabel": "Same day",
      "recommendation": "Continue pairing fermented foods with fiber."
    },
    {
      "id": "pat_fullness_001",
      "patternType": "fullness",
      "title": "Oats + yogurt → Longer fullness",
      "trigger": "Oats with Greek yogurt",
      "reaction": "Stayed full for about 4 hours",
      "frequency": 4,
      "totalSimilarMeals": 5,
      "timeframeDays": 14,
      "confidence": "high",
      "confidenceScore": 0.85,
      "impactDirection": "positive",
      "typicalTiming": "Breakfast",
      "typicalDelayMinutes": 240,
      "typicalDelayLabel": "About 4 hours",
      "recommendation": "Keep this combination when you want longer-lasting fullness."
    },
    {
      "id": "pat_sleep_001",
      "patternType": "sleep",
      "title": "Late heavy dinner → Poorer sleep",
      "trigger": "Large meals after 9 PM",
      "reaction": "Restless sleep",
      "frequency": 4,
      "totalSimilarMeals": 6,
      "timeframeDays": 21,
      "confidence": "medium",
      "confidenceScore": 0.72,
      "impactDirection": "negative",
      "typicalTiming": "After 9 PM",
      "typicalDelayLabel": "Overnight",
      "recommendation": "Try finishing dinner earlier and compare your sleep."
    }
  ],

  "healingFoods": [
    {
      "foodId": "food_greek_yogurt",
      "name": "Greek Yogurt",
      "emoji": "🥣",
      "effect": "Associated with smoother digestion and steadier energy.",
      "impactDirection": "positive",
      "impactLevel": "high",
      "frequencyCount": 5,
      "frequencyLabel": "5x this week",
      "confidence": "high",
      "confidenceScore": 0.91
    }
  ],

  "triggerFoods": [
    {
      "foodId": "food_onion_rings",
      "name": "Onion Rings",
      "emoji": "🧅",
      "effect": "Frequently appeared before bloating.",
      "impactDirection": "negative",
      "impactLevel": "high",
      "frequencyCount": 3,
      "frequencyLabel": "3x recently",
      "confidence": "high",
      "confidenceScore": 0.89
    }
  ],

  "weeklyRecap": {
    "id": "week_2026_09_12",
    "dateRange": "Sep 12 - Sep 18",
    "avgScore": 78,
    "scoreDiff": 4,
    "foodsLogged": 24,
    "outcomesLogged": 17,
    "patternsFound": 6,
    "newPatterns": 2
  },

  "evidence": {
    "sampleSizes": {
      "meals": 24,
      "foodScans": 16,
      "outcomeObservations": 17
    }
  },

  "actions": [
    {
      "id": "action_001",
      "title": "Try roasted instead of fried sides",
      "status": "not_started",
      "relatedPatternIds": [
        "pat_bloating_001"
      ]
    },
    {
      "id": "action_002",
      "title": "Keep protein in breakfast",
      "status": "not_started",
      "relatedPatternIds": [
        "pat_energy_001"
      ]
    }
  ],

  "foodSwaps": [
    {
      "id": "swap_001",
      "originalFoodId": "food_onion_rings",
      "alternativeFoodId": "food_roasted_potatoes",
      "relatedPatternId": "pat_bloating_001"
    }
  ],

  "recentInsights": [
    {
      "id": "recent_001",
      "kind": "pattern",
      "patternType": "energy",
      "title": "Protein breakfast → Steady energy",
      "subtitle": "This pattern appeared in 5 recent breakfasts.",
      "targetType": "pattern",
      "targetId": "pat_energy_001"
    }
  ],

  "emptyState": null,

  "generatedAt": "2026-09-18T08:30:00.000Z",
  "updatedAt": "2026-09-18T08:30:00.000Z"
}
```

---

# 36. Implementation Checklist

## Backend

- [ ] Support all six canonical pattern types.
- [ ] Keep `patternType`, `trigger`, and `reaction` separate.
- [ ] Store concrete occurrences behind every pattern.
- [ ] Support positive and negative patterns.
- [ ] Calculate confidence from repeated evidence.
- [ ] Merge near-duplicate patterns.
- [ ] Never generate sleep patterns without sleep observations.
- [ ] Return IDs for all drill-down destinations.
- [ ] Support historical weekly recaps.
- [ ] Support pagination for long occurrence and recent-insight lists.

## Flutter

- [ ] Create `InsightPatternType` enum.
- [ ] Create reusable `PatternCard`.
- [ ] Create reusable `PatternDetailScreen`.
- [ ] Add filters for all six pattern types.
- [ ] Replace fixed pattern-grid assumptions with a scalable list.
- [ ] Create generic Meal & Outcome Detail screen.
- [ ] Create reusable Food Detail screen.
- [ ] Add route handling by `targetType` + `targetId`.
- [ ] Add loading, empty, partial, and error states.
- [ ] Keep confidence visible but secondary to the insight itself.

## AI / Insight Generation

- [ ] Require repeated evidence before creating a user-facing pattern.
- [ ] Record both supporting and contradictory occurrences.
- [ ] Use association language rather than causal claims.
- [ ] Generate short titles suitable for cards.
- [ ] Generate a clear recommendation only when supported by the pattern.
- [ ] Avoid duplicate pattern titles for the same underlying behavior.
- [ ] Recalculate confidence when new logs arrive.
- [ ] Retire or weaken stale patterns when newer data contradicts them.

---

# 37. Final Canonical Pattern Taxonomy

Use this taxonomy consistently across:

```text
backend
AI prompt
JSON
Flutter enum
filter chips
pattern cards
pattern detail
evidence
weekly recap
recent insights
analytics
```

Canonical values:

```text
bloating
energy
headache
digestion
fullness
sleep
```

Display labels:

```text
Bloating
Energy
Headache
Digestion
Fullness
Sleep
```

No additional pattern type should be introduced without explicitly updating this contract.

---

# 38. Final UX Principle

The Insights experience should scale naturally whether the AI discovers:

```text
1 pattern
6 patterns
20 patterns
```

The UI should therefore be built around:

```text
reusable cards
filters
reusable detail screens
evidence-backed drill-downs
clear navigation IDs
progressive disclosure
```

The user should always be able to move from:

```text
Insight
  ↓
Why did GutGood notice this?
  ↓
Which meals/outcomes support it?
  ↓
What can I try next?
```

That is the core interaction model for the new GutGood Insights implementation.
