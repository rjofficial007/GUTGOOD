# GutGood Insights — Complete Data Specification, Screen Mapping & Mock Data

This document defines the production-ready data model for the complete **Insights** experience in the GutGood app. It expands the original `AIInsight` specification so the backend can support every Insights screen and drill-down shown in the current UI designs.

The model is designed to support:

- Multiple generated body patterns at the same time.
- Pattern domains such as digestion, energy, sleep, mood, appetite, and food tolerance.
- Positive/healing foods and negative/trigger foods.
- Food-level impact history.
- Pattern occurrences and meal/symptom drill-downs.
- Weekly recap and historical recap browsing.
- Evidence/confidence explanations.
- Actionable next steps and better food swaps.
- Empty/insufficient-data states.
- Recent insight history.

---

# 1. Core Insight Object

## `AIInsight`

`AIInsight` is the root object returned for the Insights experience. It aggregates model metadata, score/trend information, detected patterns, food intelligence, weekly recap, evidence, recommendations, and recent insight history.

```json
{
  "v": 2,
  "model": "gpt-4o-mini",
  "promptVersion": 4,
  "status": "ready",
  "origin": "client",
  "updatedAt": "2024-09-14T21:00:00.000Z",

  "period": {},
  "gutScore": {},
  "topInsight": {},
  "healing": {},
  "triggers": {},
  "detectedPatterns": [],
  "foodImpacts": [],
  "weeklyRecap": {},
  "weeklyRecapHistory": [],
  "evidence": {},
  "actions": [],
  "foodSwaps": [],
  "recentInsights": [],
  "emptyState": null
}
```

---

# 2. Enumerations / Suggested Constants

These values keep the UI scalable and allow one reusable screen to render different insight types.

## `PatternDomain`

```text
digestion
energy
sleep
mood
appetite
food_tolerance
bowel_movement
hydration
other
```

> Recommended UX rule: symptoms such as **bloating**, **heaviness**, **constipation**, **diarrhea**, or **smooth digestion** should usually be stored as reactions/outcomes, while the broader pattern type remains a domain such as `digestion`.

## `ConfidenceLevel`

```text
low
medium
high
```

## `ImpactLevel`

```text
low
moderate
high
```

## `ImpactDirection`

```text
positive
neutral
negative
```

## `InsightKind`

```text
pattern
food_impact
trigger_alert
weekly_recap
progress
product_scan
action
```

## `ActionStatus`

```text
not_started
in_progress
completed
skipped
```

---

# 3. Score & Trend Model

## `GutScoreSummary`

Used by:

- For You dashboard score hero
- Improving Trend screen
- Weekly Recap
- Your Next Steps header

```json
{
  "score": 78,
  "scoreDiff": 4,
  "direction": "up",
  "statusLabel": "On track",
  "summary": "Your gut health is improving with better food choices and more fermented foods.",
  "previousScore": 74,
  "maxScore": 100,
  "dailyScores": [
    { "date": "2024-09-08", "label": "Mon", "score": 74 },
    { "date": "2024-09-09", "label": "Tue", "score": 75 },
    { "date": "2024-09-10", "label": "Wed", "score": 76 },
    { "date": "2024-09-11", "label": "Thu", "score": 77 },
    { "date": "2024-09-12", "label": "Fri", "score": 78 },
    { "date": "2024-09-13", "label": "Sat", "score": 78 },
    { "date": "2024-09-14", "label": "Sun", "score": 78 }
  ],
  "trendHeadline": "Your gut barrier score is improving.",
  "trendDescription": "Consistent vegetable fiber intake is actively improving your gut barrier score."
}
```

---

# 4. Top Insight / Synergy Model

## `InsightSummary`

Used by:

- For You hero insight card
- Pattern detail
- Food Impact synergy section
- Synergy Detail screen

```json
{
  "id": "ins_synergy_01",
  "title": "Fiber & Fermentation Synergy",
  "description": "Consuming fermented foods alongside prebiotic fiber significantly reduces bloating episodes.",
  "kind": "pattern",
  "domain": "digestion",
  "observation": "Meals rich in kefir and whole grains correlate with high energy and smooth digestion.",
  "involvedFoods": [
    { "foodId": "food_kefir", "name": "Kefir" },
    { "foodId": "food_sourdough", "name": "Sourdough Toast" },
    { "foodId": "food_greek_yogurt", "name": "Greek Yogurt" },
    { "foodId": "food_kimchi", "name": "Kimchi" }
  ],
  "strength": "high",
  "confidence": 0.92,
  "frequency": 5,
  "positiveCount": 5,
  "negativeCount": 0,
  "nextSteps": [
    "Continue daily kefir intake",
    "Pair prebiotic veggies with lean protein"
  ],
  "imageUrl": "https://images.unsplash.com/photo-1488477181946-6428a0291777"
}
```

---

# 5. Healing & Trigger Food Models

## `HealingSummary`

Used by:

- For You — What's Improving
- Food Impact — Top Healing Foods
- Weekly Recap — Top Healing Food
- All Healing Foods

```json
{
  "goal": "Optimize digestion and eliminate afternoon bloating.",
  "trend": "Consistent vegetable fiber intake is actively improving your gut barrier score.",
  "foods": [],
  "topFoodId": "food_greek_yogurt"
}
```

## `TriggerSummary`

Used by:

- For You — Something to Watch
- Food Impact — Top Trigger Food
- Weekly Recap — Top Trigger Food
- Trigger Detail
- All Trigger Foods

```json
{
  "primarySymptom": "Mild bloating",
  "trend": "Fried and heavily processed foods consistently precede bloating by 2 hours.",
  "foods": [],
  "topFoodId": "food_onion_rings"
}
```

## `InsightFood`

Reusable for healing, trigger, top-food, and food-detail screens.

```json
{
  "foodId": "food_greek_yogurt",
  "name": "Greek Yogurt",
  "emoji": "🥣",
  "imageUrl": "https://images.unsplash.com/photo-1488477181946-6428a0291777",
  "userImageUrl": null,
  "foodScanId": "scan_yogurt_01",
  "effect": "Supports microbiome diversity",
  "impactDirection": "positive",
  "impactLevel": "high",
  "frequencyCount": 5,
  "frequencyLabel": "5x this week",
  "bestTimeLabel": "Breakfast",
  "observedEffect": "Optimized digestion",
  "confidence": "high",
  "confidenceScore": 0.91,
  "whyItWorks": [
    {
      "title": "Live probiotics",
      "description": "Contains beneficial bacteria that may support microbiome diversity.",
      "icon": "microbiome"
    },
    {
      "title": "High in protein",
      "description": "Helps support satiety and a balanced meal.",
      "icon": "protein"
    }
  ],
  "pairings": [
    { "foodId": "food_berries", "name": "Berries", "impactLevel": "high" },
    { "foodId": "food_granola", "name": "Granola", "impactLevel": "moderate" },
    { "foodId": "food_kefir", "name": "Kefir", "impactLevel": "high" },
    { "foodId": "food_leafy_greens", "name": "Leafy Greens", "impactLevel": "moderate" }
  ]
}
```

---

# 6. Multiple Pattern Model

## `BodyPattern`

The model must support **multiple simultaneous patterns**. The Patterns list screen should render these as a reusable vertical list rather than assuming only one pattern exists.

Used by:

- Patterns listing
- Pattern detail
- Trigger detail
- Recent Insights
- Evidence
- Suggested-by-pattern recommendations

```json
{
  "id": "pat_digest_01",
  "domain": "digestion",
  "title": "Fried Foods → Bloating",
  "trigger": "Refined vegetable oils & fried batter",
  "reaction": "Abdominal fullness and bloating",
  "frequency": 3,
  "confidence": "high",
  "confidenceScore": 0.91,
  "description": "Deep-fried items consumed in the evening correlate with digestive discomfort.",
  "recommendation": "Swap fried sides for roasted or steamed alternatives.",
  "totalSimilarMeals": 3,
  "timeframeDays": 7,
  "typicalTiming": "Evening",
  "typicalDelay": "2 hours",
  "impactDirection": "negative",
  "impactLevel": "high",
  "occurrences": [],
  "commonFactors": [],
  "relatedFoodIds": ["food_onion_rings", "food_fried_chicken", "food_fries"]
}
```

### Example: Energy pattern

```json
{
  "id": "pat_energy_01",
  "domain": "energy",
  "title": "Protein Breakfast → Steady Energy",
  "trigger": "Protein-rich breakfast",
  "reaction": "Steady afternoon energy",
  "frequency": 5,
  "confidence": "high",
  "confidenceScore": 0.88,
  "description": "Higher-protein breakfasts correlate with steadier energy later in the day.",
  "recommendation": "Keep a protein source in breakfast most days.",
  "totalSimilarMeals": 5,
  "timeframeDays": 14,
  "typicalTiming": "Morning",
  "typicalDelay": "4–6 hours",
  "impactDirection": "positive",
  "impactLevel": "high",
  "occurrences": [],
  "commonFactors": [
    { "label": "protein rich", "icon": "protein" }
  ],
  "relatedFoodIds": ["food_greek_yogurt", "food_eggs"]
}
```

### Example: Sleep pattern

> Sleep patterns require the app/backend to actually collect or import sleep observations. If sleep data is unavailable, do not generate sleep patterns from meals alone.

```json
{
  "id": "pat_sleep_01",
  "domain": "sleep",
  "title": "Late Dinner → Poorer Sleep",
  "trigger": "Large meals after 8 PM",
  "reaction": "Lower sleep quality and next-day heaviness",
  "frequency": 4,
  "confidence": "medium",
  "confidenceScore": 0.72,
  "description": "Late, heavy meals correlate with poorer sleep observations.",
  "recommendation": "Aim to finish dinner 2–3 hours before bed.",
  "totalSimilarMeals": 4,
  "timeframeDays": 14,
  "typicalTiming": "After 8 PM",
  "typicalDelay": "Overnight",
  "impactDirection": "negative",
  "impactLevel": "moderate",
  "occurrences": [],
  "commonFactors": [
    { "label": "late meal", "icon": "moon" },
    { "label": "large portion", "icon": "plate" }
  ],
  "relatedFoodIds": []
}
```

---

# 7. Pattern Occurrence Model

## `PatternOccurrence`

Used by:

- Pattern Detail — Example Occurrences
- All Pattern Occurrences
- Trigger Detail — Recent Occurrences
- Meal & Symptom Detail

```json
{
  "id": "occ_001",
  "patternId": "pat_digest_01",
  "date": "2024-09-12",
  "dateLabel": "Sep 12",
  "mealId": "meal_001",
  "mealName": "Crispy Chicken Burger & Fries",
  "mealImageUrl": "https://images.unsplash.com/photo-1568901346375-23c9450c58cd",
  "mealTime": "19:30",
  "mealType": "Dinner",
  "reaction": "Abdominal bloating",
  "symptomId": "sym_001",
  "symptomSeverity": "mild",
  "timeAfterMinutes": 120,
  "timeAfterLabel": "2 hours",
  "notes": "Felt really full after this meal. Will try grilled next time.",
  "commonFactors": [
    { "label": "deep fried", "icon": "fries" },
    { "label": "refined oils", "icon": "oil" },
    { "label": "fast food", "icon": "burger" }
  ]
}
```

---

# 8. Meal & Symptom Detail Model

## `MealSymptomDetail`

Used by the Meal & Symptom Detail screen opened from an occurrence.

```json
{
  "occurrenceId": "occ_001",
  "meal": {
    "mealId": "meal_001",
    "name": "Crispy Chicken Burger & Fries",
    "date": "2024-09-12",
    "time": "19:30",
    "mealType": "Dinner",
    "imageUrl": "https://images.unsplash.com/photo-1568901346375-23c9450c58cd"
  },
  "matchedSymptom": {
    "symptomId": "sym_001",
    "name": "Abdominal bloating",
    "severity": "mild",
    "observedAt": "2024-09-12T21:30:00.000Z",
    "timeAfterMinutes": 120,
    "timeAfterLabel": "2 hours"
  },
  "matchedPatternId": "pat_digest_01",
  "confidence": "high",
  "commonFactors": [
    { "label": "Deep fried", "icon": "fries" },
    { "label": "Refined oils", "icon": "oil" },
    { "label": "Fast food", "icon": "burger" }
  ],
  "explanation": "Fried and high-fat foods can be harder to digest and may be associated with bloating in your logged history.",
  "suggestedSwapId": "swap_001",
  "note": "Felt really full after this meal. Will try grilled next time.",
  "relatedOccurrenceIds": ["occ_004", "occ_008"]
}
```

---

# 9. Food Impact Model

## `FoodImpact`

Used by:

- Food Impact main screen
- Recent Food Impacts
- Recent Insights
- Food Impact Detail

```json
{
  "id": "impact_001",
  "foodId": "food_greek_yogurt",
  "food": "Greek Yogurt",
  "date": "2024-09-09",
  "dateLabel": "Mon",
  "effect": "Optimized digestion",
  "timeframeLabel": "Breakfast",
  "emoji": "🥣",
  "impactDirection": "positive",
  "impactLevel": "high",
  "confidence": "high",
  "imageUrl": "https://images.unsplash.com/photo-1488477181946-6428a0291777",
  "userImageUrl": null,
  "mealId": "meal_yogurt_01",
  "patternIds": ["pat_energy_01", "pat_synergy_01"]
}
```

## `FoodImpactBalance`

Used by Food Impact overview.

```json
{
  "positivePercent": 72,
  "neutralPercent": 18,
  "negativePercent": 10,
  "periodLabel": "Last 4 weeks"
}
```

---

# 10. Food Detail Model

## `FoodDetail`

Used when tapping Greek Yogurt, Kimchi, Onion Rings, etc.

```json
{
  "food": {},
  "weeklyFrequency": 5,
  "bestTime": "Breakfast",
  "observedEffect": "Optimized digestion",
  "confidence": "high",
  "whyItWorks": [],
  "history": [],
  "pairings": [],
  "relatedPatternIds": [],
  "recommendedNextStep": {
    "title": "Keep it in your morning routine",
    "description": "Keep adding it to support steady digestion.",
    "actionId": "act_002"
  }
}
```

## `FoodHistoryItem`

```json
{
  "id": "foodhist_001",
  "date": "2024-09-09",
  "dateLabel": "Mon, Sep 9",
  "mealType": "Breakfast",
  "effect": "Less bloating",
  "note": "Felt lighter after breakfast.",
  "impactDirection": "positive",
  "mealId": "meal_yogurt_01"
}
```

---

# 11. Weekly Recap Model

## `WeeklyRecap`

Used by Weekly Recap and Recap History.

```json
{
  "id": "week_2024_09_08",
  "dateRange": "Sep 08 - Sep 14",
  "from": "2024-09-08T00:00:00.000Z",
  "to": "2024-09-14T23:59:59.000Z",
  "avgScore": 78,
  "scoreDiff": 4,
  "scoreSub": "Great improvement in fiber intake and probiotic diversity!",
  "dailyScores": [72, 74, 76, 80, 82, 78, 78],
  "bestDay": {
    "date": "2024-09-11",
    "label": "Sep 11",
    "score": 82
  },
  "foodsLogged": 21,
  "loggedSub": "Consistent logging gives the AI high confidence in your patterns.",
  "patternsFound": 3,
  "newPatterns": 2,
  "highlights": [
    { "id": "hl_01", "text": "Added fermented foods on 5 out of 7 days." },
    { "id": "hl_02", "text": "Reduced sugary beverage intake by 50%." }
  ],
  "weeklyInsight": "Consistent vegetable fiber intake is actively improving your gut barrier score.",
  "topHealingFoodId": "food_greek_yogurt",
  "topTriggerFoodId": "food_onion_rings"
}
```

## `WeeklyRecapHistoryItem`

```json
{
  "id": "week_2024_09_01",
  "dateRange": "Sep 01 - Sep 07",
  "avgScore": 74,
  "scoreDiff": 2,
  "bestDayLabel": "Sep 06",
  "foodsLogged": 18,
  "summary": "More consistent logging and improved fiber intake."
}
```

---

# 12. Evidence Model

## `InsightEvidence`

Used by:

- Your Evidence
- Pattern Detail evidence section
- Food Impact synergy evidence
- Confidence explanation bottom sheet/screen

```json
{
  "period": {
    "from": "2024-09-08T00:00:00.000Z",
    "to": "2024-09-14T23:59:59.000Z",
    "dateRangeLabel": "Sep 08 - Sep 14"
  },
  "confidence": "high",
  "confidenceScore": 0.92,
  "sampleSizes": {
    "meals": 21,
    "symptoms": 3,
    "scans": 15,
    "sleepRecords": 0,
    "energyCheckIns": 5
  },
  "patternRefs": [
    { "id": "pat_synergy_01", "name": "Fiber & Fermentation Synergy" },
    { "id": "pat_digest_01", "name": "Fried Foods & Bloating" }
  ],
  "confidenceFactors": [
    {
      "key": "consistent_logging",
      "title": "Consistent logging",
      "description": "Meals have been logged regularly."
    },
    {
      "key": "repeated_outcomes",
      "title": "Repeated outcomes",
      "description": "Similar food exposures repeatedly show similar outcomes."
    },
    {
      "key": "complete_data",
      "title": "Complete data",
      "description": "Meals, symptoms, and scans provide a fuller picture."
    }
  ],
  "methodology": {
    "title": "How insights are formed",
    "steps": [
      {
        "order": 1,
        "title": "Meals logged",
        "description": "Foods, ingredients, meal timing, and meal context are analyzed."
      },
      {
        "order": 2,
        "title": "Symptoms matched",
        "description": "Timing and repeated relationships between meals and symptoms are evaluated."
      },
      {
        "order": 3,
        "title": "Patterns identified",
        "description": "Repeated associations are summarized into user-facing patterns."
      }
    ],
    "disclaimer": "Insights describe associations in your logged data and should not be treated as a medical diagnosis or proof of causation."
  }
}
```

---

# 13. Recommendations / Next Steps Model

## `InsightAction`

Used by:

- For You quick win
- Pattern Detail next steps
- Your Next Steps screen
- Action Detail
- Weekly Recap recommended actions

```json
{
  "id": "act_001",
  "title": "Increase prebiotic vegetables",
  "description": "Add more fiber-rich foods like leafy greens, onions, and garlic.",
  "category": "nutrition",
  "impactLevel": "high",
  "difficulty": "easy",
  "status": "not_started",
  "whenToDo": "Daily with meals",
  "expectedBenefit": "Higher fiber intake and less bloating",
  "relatedPatternIds": ["pat_synergy_01"],
  "relatedFoodIds": ["food_leafy_greens"],
  "progress": {
    "target": 7,
    "completed": 0,
    "unit": "days"
  }
}
```

### Example action list

```json
[
  {
    "id": "act_001",
    "title": "Increase prebiotic vegetables",
    "impactLevel": "high",
    "status": "not_started"
  },
  {
    "id": "act_002",
    "title": "Maintain daily kefir routine",
    "impactLevel": "moderate",
    "status": "not_started"
  },
  {
    "id": "act_003",
    "title": "Swap fried sides for roasted or steamed alternatives",
    "impactLevel": "high",
    "status": "not_started"
  },
  {
    "id": "act_004",
    "title": "Finish dinner 2–3 hours before bed",
    "impactLevel": "moderate",
    "status": "not_started"
  }
]
```

---

# 14. Better Food Swap Model

## `FoodSwap`

Used by:

- Trigger Detail — Plan Better Swaps
- Meal & Symptom Detail — Better Swap
- Better Swaps screen

```json
{
  "id": "swap_001",
  "source": {
    "foodId": "food_onion_rings",
    "name": "Deep-Fried Onion Rings",
    "imageUrl": "https://images.unsplash.com/photo-1639024471283-03518883512d"
  },
  "alternatives": [
    {
      "foodId": "food_roasted_veg",
      "name": "Roasted Vegetables",
      "imageUrl": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd",
      "reason": "Lower in added frying fat and may be easier to digest.",
      "impactLevel": "high"
    },
    {
      "foodId": "food_grilled_chicken",
      "name": "Grilled Chicken + Vegetables",
      "imageUrl": null,
      "reason": "Provides protein with less fried batter and oil.",
      "impactLevel": "high"
    }
  ],
  "relatedPatternId": "pat_digest_01"
}
```

---

# 15. Recent Insights Model

## `RecentInsightItem`

Used by Recent Insights / View All.

```json
{
  "id": "recent_001",
  "kind": "product_scan",
  "date": "2024-09-14T08:00:00.000Z",
  "dateLabel": "Sep 14, 2024",
  "title": "Organic Greek Yogurt & Berries",
  "description": "A source of protein and probiotics associated with positive digestion outcomes in your recent logs.",
  "score": 92,
  "impactDirection": "positive",
  "impactLabel": "Positive Impact",
  "imageUrl": "https://images.unsplash.com/photo-1488477181946-6428a0291777",
  "destination": {
    "screen": "food_detail",
    "id": "food_greek_yogurt"
  }
}
```

---

# 16. Empty / Insufficient Data Model

## `InsightEmptyState`

Used when the model cannot form reliable insights yet.

```json
{
  "reason": "insufficient_data",
  "title": "We're still learning about your gut",
  "description": "Log a few more meals and symptoms to unlock personalized patterns.",
  "requirements": [
    {
      "key": "meals",
      "label": "Meals logged",
      "current": 4,
      "recommended": 10
    },
    {
      "key": "symptoms",
      "label": "Symptoms logged",
      "current": 0,
      "recommended": 3
    },
    {
      "key": "scans",
      "label": "Food scans",
      "current": 2,
      "recommended": 5
    }
  ],
  "primaryAction": {
    "label": "Log a meal",
    "route": "meal_log"
  },
  "secondaryAction": {
    "label": "Track a symptom",
    "route": "symptom_log"
  }
}
```

---

# 17. Complete Screen Inventory & Data Mapping

The following screen set covers the current Insights UI and its drill-down behavior.

## Screen 01 — Insights / For You

### Purpose
Primary personalized overview.

### Uses
- `gutScore`
- `topInsight`
- `healing.trend`
- `triggers.trend`
- top foods
- quick-win action
- recent insight preview

### Main interactions
- `View Details` on Top Insight → **Screen 06 Pattern Detail / Synergy Detail**
- `See Details` on What's Improving → **Screen 09 Improving Trend**
- `See Details` on Something to Watch → **Screen 10 Trigger Detail**
- `View All` on Top Foods → **Screen 11 Top Foods This Week**
- `Explore Foods` → Food discovery / food ideas flow
- `View All` on Recent Insights → **Screen 12 Recent Insights**

---

## Screen 02 — Patterns

### Purpose
Scalable list of all detected patterns.

### Recommended layout
- Header: `Detected Patterns`
- Pattern count
- Date filter: `Last 7 Days`, `Last 14 Days`, `Last 30 Days`
- Domain chips:
  - All
  - Digestion
  - Energy
  - Sleep
  - Mood
  - Appetite

### Uses
- `detectedPatterns[]`

### Main interaction
Tap a pattern → **Screen 06 Pattern Detail**

---

## Screen 03 — Food Impact

### Purpose
Show positive vs neutral vs negative food effects.

### Uses
- `foodImpactBalance`
- `healing.foods[]`
- `triggers.foods[]`
- `topInsight`
- `foodImpacts[]`
- `actions[]`

### Main interactions
- Tap food → **Screen 13 Food Detail**
- `View All` recent food impacts → filtered **Screen 12 Recent Insights** or dedicated list
- Tap next-step card → **Screen 16 Action Detail**

---

## Screen 04 — Weekly Recap

### Purpose
7-day summary of progress.

### Uses
- `weeklyRecap`
- `gutScore.dailyScores`
- `evidence.sampleSizes`
- top healing food
- top trigger food

### Main interactions
- Previous/next week → load selected `weeklyRecapHistory` item
- History picker → **Screen 17 Weekly Recap History**
- Tap top food → **Screen 13 Food Detail**
- Tap trigger food → **Screen 10 Trigger Detail**

---

## Screen 05 — Synergy Detail

### Purpose
Deep dive into a positive multi-food pattern such as Fiber & Fermentation Synergy.

### Uses
- `topInsight`
- involved foods
- evidence ratio
- positive / negative counts
- next steps
- supporting evidence

### Main interactions
- `View All` involved foods → food list
- Tap food → **Screen 13 Food Detail**
- Tap next step → **Screen 16 Action Detail**
- Tap evidence → **Screen 15 Your Evidence**

---

## Screen 06 — Pattern Detail

### Purpose
Reusable detail template for digestion, energy, sleep, mood, appetite, etc.

### Uses
- selected `BodyPattern`
- `occurrences[]`
- `commonFactors[]`
- recommendation
- confidence

### Main interactions
- `View All` occurrences → **Screen 07 All Pattern Occurrences**
- Tap occurrence → **Screen 14 Meal & Symptom Detail**
- Tap recommendation → **Screen 18 Better Swaps** or **Screen 16 Action Detail**

---

## Screen 07 — All Pattern Occurrences

### Purpose
Chronological list of every occurrence supporting a selected pattern.

### Uses
- `BodyPattern.occurrences[]`

### Filters
- 7 days
- 30 days
- All

### Main interaction
Tap row → **Screen 14 Meal & Symptom Detail**

---

## Screen 08 — All Healing Foods / All Trigger Foods

### Purpose
Full food list when there are more foods than the overview can show.

### Uses
- `healing.foods[]`
- `triggers.foods[]`

### Filters
Healing / Good / Watch, or Positive / Negative.

### Main interaction
Tap food → **Screen 13 Food Detail**

---

## Screen 09 — Improving Trend

### Purpose
Explain score improvement and what contributed to it.

### Uses
- `gutScore.dailyScores`
- `gutScore.trendHeadline`
- `gutScore.trendDescription`
- contributing foods/habits
- weekly stats
- weekly highlights
- recommended actions

### Main interactions
- `View Food Impact` → **Screen 03 Food Impact**
- `See All` recommendations → **Screen 16 Your Next Steps**

---

## Screen 10 — Trigger Detail

### Purpose
Deep dive into a negative trigger pattern such as Fried Foods → Bloating.

### Uses
- selected negative `BodyPattern`
- related trigger foods
- occurrences
- symptom
- typical delay
- confidence
- recommendation

### Main interactions
- `View All` occurrences → **Screen 07 All Pattern Occurrences**
- Tap occurrence → **Screen 14 Meal & Symptom Detail**
- `Plan Better Swaps` → **Screen 18 Better Swaps**
- Tap related trigger food → **Screen 13 Food Detail**

---

## Screen 11 — Top Foods This Week

### Purpose
Full weekly food grid.

### Uses
- healing foods
- good/neutral foods
- trigger foods

### Filters
- All
- Healing
- Good
- Watch

### Main interaction
Tap food → **Screen 13 Food Detail**

---

## Screen 12 — Recent Insights

### Purpose
Chronological history of generated insight items.

### Uses
- `recentInsights[]`

### Filters
- All
- Patterns
- Scans
- Weekly

### Main interaction
Each row routes according to `destination.screen` + `destination.id`.

---

## Screen 13 — Food Detail / Food Impact Detail

### Purpose
Reusable screen for a selected food.

### Uses
- `InsightFood`
- food history
- pairings
- related patterns
- next step

### Main interactions
- `View All` history → food history list
- `View All` pairings → pairing list
- `Log Again` → meal log
- Tap related pattern → **Screen 06 Pattern Detail**

---

## Screen 14 — Meal & Symptom Detail

### Purpose
Explain why one logged meal is associated with a symptom/pattern.

### Uses
- `MealSymptomDetail`

### Main interactions
- `Plan Better Choice` → **Screen 18 Better Swaps**
- Edit note → edit note flow
- `View All` related occurrences → **Screen 07 All Pattern Occurrences**

---

## Screen 15 — Your Evidence

### Purpose
Explain why the app is confident in the insights.

### Uses
- `evidence`

### Main interactions
- Tap pattern reference → **Screen 06 Pattern Detail**
- Tap info icon → **Screen 19 Evidence Methodology**
- `See Food Ideas` → food ideas flow
- `Get Tips` → action/recommendation flow

---

## Screen 16 — Your Next Steps

### Purpose
Show personalized recommendations generated from insights.

### Uses
- `actions[]`

### Main interactions
- Tap recommendation → **Screen 20 Action Detail**
- `Start My Plan` → marks selected actions as in progress

---

## Screen 17 — Weekly Recap History

### Purpose
Browse previous weekly summaries.

### Uses
- `weeklyRecapHistory[]`

### Main interaction
Tap week → load selected recap in **Screen 04 Weekly Recap**

---

## Screen 18 — Better Swaps

### Purpose
Suggest alternatives for trigger foods/meals.

### Uses
- `foodSwaps[]`

### Main interactions
- Save swap
- Log alternative
- Tap alternative → **Screen 13 Food Detail**

---

## Screen 19 — Evidence Methodology / Confidence Explanation

### Purpose
Explain what confidence means and how evidence is generated.

### Uses
- `evidence.methodology`
- `evidence.confidenceFactors`

### Required content
- How meals, symptoms, scans, and optional sleep/energy observations are used.
- Difference between association and causation.
- Confidence labels and their meaning.
- Data completeness guidance.

---

## Screen 20 — Action Detail

### Purpose
Drill into one recommendation.

### Uses
- selected `InsightAction`

### Suggested sections
- Why this action was suggested
- Related patterns
- When to do it
- Expected benefit
- Progress
- Start / Complete / Skip controls

---

## Screen 21 — Empty / Insufficient Data State

### Purpose
Shown when no reliable insight can be generated yet.

### Uses
- `emptyState`

### Main interactions
- Log a meal
- Track a symptom

---

# 18. Recommended Navigation Map

```text
Insights
├── For You
│   ├── Top Insight / Synergy Detail
│   ├── Improving Trend
│   ├── Trigger Detail
│   ├── Top Foods This Week
│   │   └── Food Detail
│   └── Recent Insights
│       ├── Pattern Detail
│       ├── Food Detail
│       ├── Trigger Detail
│       └── Weekly Recap
│
├── Patterns
│   └── Pattern Detail
│       ├── All Pattern Occurrences
│       │   └── Meal & Symptom Detail
│       ├── Better Swaps
│       └── Action Detail
│
├── Food Impact
│   ├── Food Detail
│   ├── All Healing Foods
│   ├── All Trigger Foods
│   ├── Synergy Detail
│   └── Your Next Steps
│
└── Weekly Recap
    ├── Weekly Recap History
    ├── Food Detail
    ├── Trigger Detail
    └── Your Evidence
        └── Evidence Methodology
```

---

# 19. Complete Mock `AIInsight` JSON

```json
{
  "v": 2,
  "model": "gpt-4o-mini",
  "promptVersion": 4,
  "status": "ready",
  "origin": "client",
  "updatedAt": "2024-09-14T21:00:00.000Z",

  "period": {
    "from": "2024-09-08T00:00:00.000Z",
    "to": "2024-09-14T23:59:59.000Z"
  },

  "gutScore": {
    "score": 78,
    "scoreDiff": 4,
    "direction": "up",
    "statusLabel": "On track",
    "summary": "Your gut health is improving with better food choices and more fermented foods.",
    "previousScore": 74,
    "maxScore": 100,
    "dailyScores": [
      { "date": "2024-09-08", "label": "Mon", "score": 74 },
      { "date": "2024-09-09", "label": "Tue", "score": 75 },
      { "date": "2024-09-10", "label": "Wed", "score": 76 },
      { "date": "2024-09-11", "label": "Thu", "score": 77 },
      { "date": "2024-09-12", "label": "Fri", "score": 78 },
      { "date": "2024-09-13", "label": "Sat", "score": 78 },
      { "date": "2024-09-14", "label": "Sun", "score": 78 }
    ],
    "trendHeadline": "Your gut barrier score is improving.",
    "trendDescription": "Consistent vegetable fiber intake is actively improving your gut barrier score."
  },

  "topInsight": {
    "id": "ins_synergy_01",
    "title": "Fiber & Fermentation Synergy",
    "description": "Consuming fermented foods alongside prebiotic fiber significantly reduces bloating episodes.",
    "kind": "pattern",
    "domain": "digestion",
    "observation": "Meals rich in kefir and whole grains correlate with high energy and smooth digestion.",
    "involvedFoods": [
      { "foodId": "food_kefir", "name": "Kefir" },
      { "foodId": "food_sourdough", "name": "Sourdough Toast" },
      { "foodId": "food_greek_yogurt", "name": "Greek Yogurt" },
      { "foodId": "food_kimchi", "name": "Kimchi" }
    ],
    "strength": "high",
    "confidence": 0.92,
    "frequency": 5,
    "positiveCount": 5,
    "negativeCount": 0,
    "nextSteps": [
      "Continue daily kefir intake",
      "Pair prebiotic veggies with lean protein"
    ],
    "imageUrl": "https://images.unsplash.com/photo-1488477181946-6428a0291777"
  },

  "healing": {
    "goal": "Optimize digestion and eliminate afternoon bloating.",
    "trend": "Consistent vegetable fiber intake is actively improving your gut barrier score.",
    "topFoodId": "food_greek_yogurt",
    "foods": [
      {
        "foodId": "food_greek_yogurt",
        "name": "Greek Yogurt",
        "emoji": "🥣",
        "imageUrl": "https://images.unsplash.com/photo-1488477181946-6428a0291777",
        "userImageUrl": null,
        "foodScanId": "scan_yogurt_01",
        "effect": "Supports microbiome diversity",
        "impactDirection": "positive",
        "impactLevel": "high",
        "frequencyCount": 5,
        "frequencyLabel": "5x this week",
        "bestTimeLabel": "Breakfast",
        "observedEffect": "Optimized digestion",
        "confidence": "high",
        "confidenceScore": 0.91,
        "whyItWorks": [
          {
            "title": "Live probiotics",
            "description": "Contains beneficial bacteria that may support microbiome diversity.",
            "icon": "microbiome"
          },
          {
            "title": "High in protein",
            "description": "Helps support satiety and a balanced meal.",
            "icon": "protein"
          }
        ],
        "pairings": [
          { "foodId": "food_berries", "name": "Berries", "impactLevel": "high" },
          { "foodId": "food_granola", "name": "Granola", "impactLevel": "moderate" },
          { "foodId": "food_kefir", "name": "Kefir", "impactLevel": "high" },
          { "foodId": "food_leafy_greens", "name": "Leafy Greens", "impactLevel": "moderate" }
        ]
      },
      {
        "foodId": "food_kimchi",
        "name": "Kimchi",
        "emoji": "🥬",
        "imageUrl": "https://images.unsplash.com/photo-1583225224483-90d7967817b9",
        "userImageUrl": null,
        "foodScanId": "scan_kimchi_01",
        "effect": "Enhances gut flora vitality",
        "impactDirection": "positive",
        "impactLevel": "high",
        "frequencyCount": 4,
        "frequencyLabel": "4x this week",
        "bestTimeLabel": "Lunch",
        "observedEffect": "Smooth digestion",
        "confidence": "high",
        "confidenceScore": 0.87,
        "whyItWorks": [],
        "pairings": []
      }
    ]
  },

  "triggers": {
    "primarySymptom": "Mild bloating",
    "trend": "Fried and heavily processed foods consistently precede bloating by 2 hours.",
    "topFoodId": "food_onion_rings",
    "foods": [
      {
        "foodId": "food_onion_rings",
        "name": "Deep-Fried Onion Rings",
        "emoji": "🧅",
        "imageUrl": "https://images.unsplash.com/photo-1639024471283-03518883512d",
        "userImageUrl": null,
        "foodScanId": "scan_onion_01",
        "effect": "Associated with slower digestion and bloating in your logs",
        "impactDirection": "negative",
        "impactLevel": "moderate",
        "frequencyCount": 2,
        "frequencyLabel": "2x this week",
        "bestTimeLabel": "Dinner",
        "observedEffect": "Mild bloating",
        "confidence": "high",
        "confidenceScore": 0.90,
        "whyItWorks": [],
        "pairings": []
      }
    ]
  },

  "detectedPatterns": [
    {
      "id": "pat_digest_01",
      "domain": "digestion",
      "title": "Fried Foods → Bloating",
      "trigger": "Refined vegetable oils & fried batter",
      "reaction": "Abdominal fullness and bloating",
      "frequency": 3,
      "confidence": "high",
      "confidenceScore": 0.91,
      "description": "Deep-fried items consumed in the evening correlate with digestive discomfort.",
      "recommendation": "Swap fried sides for roasted or steamed alternatives.",
      "totalSimilarMeals": 3,
      "timeframeDays": 7,
      "typicalTiming": "Evening",
      "typicalDelay": "2 hours",
      "impactDirection": "negative",
      "impactLevel": "high",
      "occurrences": [
        {
          "id": "occ_001",
          "patternId": "pat_digest_01",
          "date": "2024-09-12",
          "dateLabel": "Sep 12",
          "mealId": "meal_001",
          "mealName": "Crispy Chicken Burger & Fries",
          "mealImageUrl": "https://images.unsplash.com/photo-1568901346375-23c9450c58cd",
          "mealTime": "19:30",
          "mealType": "Dinner",
          "reaction": "Abdominal bloating",
          "symptomId": "sym_001",
          "symptomSeverity": "mild",
          "timeAfterMinutes": 120,
          "timeAfterLabel": "2 hours",
          "notes": "Felt really full after this meal. Will try grilled next time.",
          "commonFactors": [
            { "label": "deep fried", "icon": "fries" },
            { "label": "refined oils", "icon": "oil" },
            { "label": "fast food", "icon": "burger" }
          ]
        },
        {
          "id": "occ_002",
          "patternId": "pat_digest_01",
          "date": "2024-09-13",
          "dateLabel": "Sep 13",
          "mealId": "meal_002",
          "mealName": "Tempura Vegetables",
          "mealImageUrl": null,
          "mealTime": "20:00",
          "mealType": "Dinner",
          "reaction": "Feeling heavy",
          "symptomId": "sym_002",
          "symptomSeverity": "mild",
          "timeAfterMinutes": 90,
          "timeAfterLabel": "1.5 hours",
          "notes": null,
          "commonFactors": [
            { "label": "deep fried", "icon": "fries" }
          ]
        }
      ],
      "commonFactors": [
        { "label": "deep fried", "icon": "fries" },
        { "label": "refined oils", "icon": "oil" }
      ],
      "relatedFoodIds": ["food_onion_rings", "food_fries", "food_fried_chicken"]
    },
    {
      "id": "pat_energy_01",
      "domain": "energy",
      "title": "Protein Breakfast → Steady Energy",
      "trigger": "Protein-rich breakfast",
      "reaction": "Steady afternoon energy",
      "frequency": 5,
      "confidence": "high",
      "confidenceScore": 0.88,
      "description": "Higher-protein breakfasts correlate with steadier energy later in the day.",
      "recommendation": "Keep a protein source in breakfast most days.",
      "totalSimilarMeals": 5,
      "timeframeDays": 14,
      "typicalTiming": "Morning",
      "typicalDelay": "4–6 hours",
      "impactDirection": "positive",
      "impactLevel": "high",
      "occurrences": [],
      "commonFactors": [
        { "label": "protein rich", "icon": "protein" }
      ],
      "relatedFoodIds": ["food_greek_yogurt"]
    },
    {
      "id": "pat_sleep_01",
      "domain": "sleep",
      "title": "Late Dinner → Poorer Sleep",
      "trigger": "Large meals after 8 PM",
      "reaction": "Lower sleep quality and next-day heaviness",
      "frequency": 4,
      "confidence": "medium",
      "confidenceScore": 0.72,
      "description": "Late, heavy meals correlate with poorer sleep observations.",
      "recommendation": "Aim to finish dinner 2–3 hours before bed.",
      "totalSimilarMeals": 4,
      "timeframeDays": 14,
      "typicalTiming": "After 8 PM",
      "typicalDelay": "Overnight",
      "impactDirection": "negative",
      "impactLevel": "moderate",
      "occurrences": [],
      "commonFactors": [
        { "label": "late meal", "icon": "moon" },
        { "label": "large portion", "icon": "plate" }
      ],
      "relatedFoodIds": []
    }
  ],

  "foodImpactBalance": {
    "positivePercent": 72,
    "neutralPercent": 18,
    "negativePercent": 10,
    "periodLabel": "Last 4 weeks"
  },

  "foodImpacts": [
    {
      "id": "impact_001",
      "foodId": "food_greek_yogurt",
      "food": "Greek Yogurt",
      "date": "2024-09-09",
      "dateLabel": "Mon",
      "effect": "Optimized digestion",
      "timeframeLabel": "Breakfast",
      "emoji": "🥣",
      "impactDirection": "positive",
      "impactLevel": "high",
      "confidence": "high",
      "imageUrl": "https://images.unsplash.com/photo-1488477181946-6428a0291777",
      "userImageUrl": null,
      "mealId": "meal_yogurt_01",
      "patternIds": ["pat_energy_01", "ins_synergy_01"]
    },
    {
      "id": "impact_002",
      "foodId": "food_onion_rings",
      "food": "Onion Rings",
      "date": "2024-09-10",
      "dateLabel": "Tue",
      "effect": "Bloating",
      "timeframeLabel": "Dinner",
      "emoji": "🧅",
      "impactDirection": "negative",
      "impactLevel": "moderate",
      "confidence": "high",
      "imageUrl": "https://images.unsplash.com/photo-1639024471283-03518883512d",
      "userImageUrl": null,
      "mealId": "meal_003",
      "patternIds": ["pat_digest_01"]
    }
  ],

  "weeklyRecap": {
    "id": "week_2024_09_08",
    "dateRange": "Sep 08 - Sep 14",
    "from": "2024-09-08T00:00:00.000Z",
    "to": "2024-09-14T23:59:59.000Z",
    "avgScore": 78,
    "scoreDiff": 4,
    "scoreSub": "Great improvement in fiber intake and probiotic diversity!",
    "dailyScores": [72, 74, 76, 80, 82, 78, 78],
    "bestDay": {
      "date": "2024-09-11",
      "label": "Sep 11",
      "score": 82
    },
    "foodsLogged": 21,
    "loggedSub": "Consistent logging gives the AI high confidence in your patterns.",
    "patternsFound": 3,
    "newPatterns": 2,
    "highlights": [
      { "id": "hl_01", "text": "Added fermented foods on 5 out of 7 days." },
      { "id": "hl_02", "text": "Reduced sugary beverage intake by 50%." }
    ],
    "weeklyInsight": "Consistent vegetable fiber intake is actively improving your gut barrier score.",
    "topHealingFoodId": "food_greek_yogurt",
    "topTriggerFoodId": "food_onion_rings"
  },

  "weeklyRecapHistory": [
    {
      "id": "week_2024_09_01",
      "dateRange": "Sep 01 - Sep 07",
      "avgScore": 74,
      "scoreDiff": 2,
      "bestDayLabel": "Sep 06",
      "foodsLogged": 18,
      "summary": "More consistent logging and improved fiber intake."
    }
  ],

  "evidence": {
    "period": {
      "from": "2024-09-08T00:00:00.000Z",
      "to": "2024-09-14T23:59:59.000Z",
      "dateRangeLabel": "Sep 08 - Sep 14"
    },
    "confidence": "high",
    "confidenceScore": 0.92,
    "sampleSizes": {
      "meals": 21,
      "symptoms": 3,
      "scans": 15,
      "sleepRecords": 4,
      "energyCheckIns": 5
    },
    "patternRefs": [
      { "id": "ins_synergy_01", "name": "Fiber & Fermentation Synergy" },
      { "id": "pat_digest_01", "name": "Fried Foods & Bloating" },
      { "id": "pat_energy_01", "name": "Protein Breakfast & Energy" },
      { "id": "pat_sleep_01", "name": "Late Dinner & Sleep" }
    ],
    "confidenceFactors": [
      {
        "key": "consistent_logging",
        "title": "Consistent logging",
        "description": "Meals have been logged regularly."
      },
      {
        "key": "repeated_outcomes",
        "title": "Repeated outcomes",
        "description": "Similar food exposures repeatedly show similar outcomes."
      },
      {
        "key": "complete_data",
        "title": "Complete data",
        "description": "Meals, symptoms, scans, and other observations provide a fuller picture."
      }
    ],
    "methodology": {
      "title": "How insights are formed",
      "steps": [
        {
          "order": 1,
          "title": "Meals logged",
          "description": "Foods, ingredients, meal timing, and meal context are analyzed."
        },
        {
          "order": 2,
          "title": "Symptoms matched",
          "description": "Timing and repeated relationships between meals and symptoms are evaluated."
        },
        {
          "order": 3,
          "title": "Patterns identified",
          "description": "Repeated associations are summarized into user-facing patterns."
        }
      ],
      "disclaimer": "Insights describe associations in your logged data and should not be treated as a medical diagnosis or proof of causation."
    }
  },

  "actions": [
    {
      "id": "act_001",
      "title": "Increase prebiotic vegetables",
      "description": "Add more fiber-rich foods like leafy greens, onions, and garlic.",
      "category": "nutrition",
      "impactLevel": "high",
      "difficulty": "easy",
      "status": "not_started",
      "whenToDo": "Daily with meals",
      "expectedBenefit": "Higher fiber intake and less bloating",
      "relatedPatternIds": ["ins_synergy_01"],
      "relatedFoodIds": ["food_leafy_greens"],
      "progress": { "target": 7, "completed": 0, "unit": "days" }
    },
    {
      "id": "act_002",
      "title": "Maintain daily kefir routine",
      "description": "Keep up your daily kefir for continued gut support.",
      "category": "nutrition",
      "impactLevel": "moderate",
      "difficulty": "easy",
      "status": "not_started",
      "whenToDo": "1 serving per day",
      "expectedBenefit": "Better digestion and gut balance",
      "relatedPatternIds": ["ins_synergy_01"],
      "relatedFoodIds": ["food_kefir"],
      "progress": { "target": 7, "completed": 0, "unit": "days" }
    },
    {
      "id": "act_003",
      "title": "Swap fried sides for roasted or steamed alternatives",
      "description": "Reduce foods that may trigger bloating.",
      "category": "nutrition",
      "impactLevel": "high",
      "difficulty": "easy",
      "status": "not_started",
      "whenToDo": "When eating out or at home",
      "expectedBenefit": "Less bloating and happier digestion",
      "relatedPatternIds": ["pat_digest_01"],
      "relatedFoodIds": ["food_onion_rings"],
      "progress": { "target": 3, "completed": 0, "unit": "swaps" }
    },
    {
      "id": "act_004",
      "title": "Finish dinner 2–3 hours before bed",
      "description": "Give your gut time to digest before sleep.",
      "category": "timing",
      "impactLevel": "moderate",
      "difficulty": "medium",
      "status": "not_started",
      "whenToDo": "2–3 hours before sleep",
      "expectedBenefit": "Fewer bloating episodes and improved sleep",
      "relatedPatternIds": ["pat_sleep_01"],
      "relatedFoodIds": [],
      "progress": { "target": 5, "completed": 0, "unit": "days" }
    }
  ],

  "foodSwaps": [
    {
      "id": "swap_001",
      "source": {
        "foodId": "food_onion_rings",
        "name": "Deep-Fried Onion Rings",
        "imageUrl": "https://images.unsplash.com/photo-1639024471283-03518883512d"
      },
      "alternatives": [
        {
          "foodId": "food_roasted_veg",
          "name": "Roasted Vegetables",
          "imageUrl": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd",
          "reason": "Lower in added frying fat and may be easier to digest.",
          "impactLevel": "high"
        },
        {
          "foodId": "food_grilled_chicken",
          "name": "Grilled Chicken + Vegetables",
          "imageUrl": null,
          "reason": "Provides protein with less fried batter and oil.",
          "impactLevel": "high"
        }
      ],
      "relatedPatternId": "pat_digest_01"
    }
  ],

  "recentInsights": [
    {
      "id": "recent_001",
      "kind": "product_scan",
      "date": "2024-09-14T08:00:00.000Z",
      "dateLabel": "Sep 14, 2024",
      "title": "Organic Greek Yogurt & Berries",
      "description": "A source of protein and probiotics associated with positive digestion outcomes in your recent logs.",
      "score": 92,
      "impactDirection": "positive",
      "impactLabel": "Positive Impact",
      "imageUrl": "https://images.unsplash.com/photo-1488477181946-6428a0291777",
      "destination": {
        "screen": "food_detail",
        "id": "food_greek_yogurt"
      }
    },
    {
      "id": "recent_002",
      "kind": "pattern",
      "date": "2024-09-13T20:00:00.000Z",
      "dateLabel": "Sep 13, 2024",
      "title": "Fiber & Fermentation Synergy",
      "description": "Fermented foods + prebiotic fiber significantly reduce bloating episodes.",
      "score": null,
      "impactDirection": "positive",
      "impactLabel": "High Confidence",
      "imageUrl": "https://images.unsplash.com/photo-1583225224483-90d7967817b9",
      "destination": {
        "screen": "synergy_detail",
        "id": "ins_synergy_01"
      }
    },
    {
      "id": "recent_003",
      "kind": "trigger_alert",
      "date": "2024-09-12T21:30:00.000Z",
      "dateLabel": "Sep 12, 2024",
      "title": "Deep-Fried Onion Rings",
      "description": "May trigger abdominal fullness and bloating.",
      "score": null,
      "impactDirection": "negative",
      "impactLabel": "Watch",
      "imageUrl": "https://images.unsplash.com/photo-1639024471283-03518883512d",
      "destination": {
        "screen": "trigger_detail",
        "id": "pat_digest_01"
      }
    }
  ],

  "emptyState": null
}
```

---

# 20. Backend / API Recommendations

The UI can be powered either by one large `AIInsight` payload or by smaller endpoints. For production, smaller endpoints are usually easier to cache and paginate.

Suggested API surface:

```text
GET /insights/overview
GET /insights/patterns?domain=digestion&period=7d
GET /insights/patterns/:patternId
GET /insights/patterns/:patternId/occurrences
GET /insights/food-impact
GET /insights/foods/:foodId
GET /insights/foods/healing
GET /insights/foods/triggers
GET /insights/weekly-recap?week=2024-09-08
GET /insights/weekly-recap/history
GET /insights/recent
GET /insights/evidence
GET /insights/actions
GET /insights/actions/:actionId
GET /insights/swaps?patternId=pat_digest_01
GET /insights/occurrences/:occurrenceId
```

Recommended write actions:

```text
POST /insights/actions/:actionId/start
POST /insights/actions/:actionId/complete
POST /insights/actions/:actionId/skip
POST /insights/swaps/:swapId/save
PATCH /insights/occurrences/:occurrenceId/note
```

---

# 21. Important Product Rules

1. **Never assume only one pattern exists.** `detectedPatterns` must be an array and the UI must scale to many patterns.
2. **Use broad domains for pattern type.** Keep `digestion`, `energy`, `sleep`, etc. as domains; keep `bloating`, `heaviness`, `steady energy`, etc. as reactions/outcomes.
3. **Do not generate unsupported sleep or energy patterns.** Only generate them when the app has actual source observations for sleep/energy.
4. **Confidence should be evidence-driven.** Store both a label and numeric confidence score.
5. **Pattern cards and detail screens should be reusable.** Do not create separate hard-coded screen types for every pattern domain.
6. **Every list item should carry a destination ID.** This makes `View`, `See Details`, `View All`, and recent insight routing deterministic.
7. **Use empty state instead of fabricated insight.** If evidence is weak, show the insufficient-data state.
8. **Health insights should be phrased as associations/correlations, not diagnoses or guaranteed causal claims.**

---

# 22. Final Screen Coverage Checklist

- [x] Insights / For You
- [x] Patterns
- [x] Food Impact
- [x] Weekly Recap
- [x] Synergy Detail
- [x] Pattern Detail
- [x] All Pattern Occurrences
- [x] All Healing Foods
- [x] All Trigger Foods
- [x] Improving Trend
- [x] Trigger Detail
- [x] Top Foods This Week
- [x] Recent Insights
- [x] Food Detail / Food Impact Detail
- [x] Meal & Symptom Detail
- [x] Your Evidence
- [x] Your Next Steps
- [x] Weekly Recap History
- [x] Better Swaps
- [x] Evidence Methodology / Confidence Explanation
- [x] Action Detail
- [x] Empty / Insufficient Data State

This version of the specification now covers the complete Insights navigation and data requirements represented in the current GutGood UI designs.
