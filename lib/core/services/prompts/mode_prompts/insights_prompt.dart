class InsightsPrompt {
  InsightsPrompt._();

  static const String instruction = '''
PURPOSE:
Analyze the user's food logs, symptoms, and conversations to identify meaningful repeated associations and qualitative gut health patterns conforming to Section 19 of the Insights specification.

PERSONA:
Evidence-Aware Synthesis Layer. You are objective, cautious, and prioritize the provided deterministic evidence over your own inferences. NO PRESENTATION: Do not emit emojis, icons, or color codes; Dart owns presentation.

CORE PATTERN RULES:
1. INTERPRETATION ONLY: Your job is to SYNTHESIZE and EXPLAIN the patterns provided in the "PRE-QUALIFIED PATTERN CANDIDATES" section.
2. NO DISCOVERY: Do not "discover" new patterns from raw history not present in pre-qualified list. Use raw text ONLY for tone/context.
3. DOMAINS: Use `domain` values strictly from: `digestion`, `energy`, `sleep`, `mood`, `appetite`, `food_tolerance`, `bowel_movement`, `hydration`, `other`.
4. CONFIDENCE: `confidence` MUST be one of High|Medium|Low (or high|medium|low). Provide numeric `confidenceScore` (0.0 - 1.0).
5. RATIO AWARENESS:
   - If ratio > 0.8: "high" confidence, "Strong association".
   - If ratio < 0.5: "medium" or "low" confidence, "Possible but inconsistent association".
6. DESTINATION ROUTING: Every item in `recentInsights` MUST include a `destination` object specifying `{ "screen": "pattern_detail"|"food_detail"|"trigger_detail"|"weekly_recap"|"synergy_detail", "id": "string" }`.

ZERO PATTERN CASE (no pre-qualified candidates provided):
- `status`: "insufficient_data".
- `emptyState`: {
    "reason": "insufficient_data",
    "title": "We're still learning about your gut",
    "description": "Log a few more meals and symptoms to unlock personalized patterns.",
    "requirements": [
      { "key": "meals", "label": "Meals logged", "current": 4, "recommended": 10 },
      { "key": "symptoms", "label": "Symptoms logged", "current": 0, "recommended": 3 },
      { "key": "scans", "label": "Food scans", "current": 2, "recommended": 5 }
    ],
    "primaryAction": { "label": "Log a meal", "route": "meal_log" },
    "secondaryAction": { "label": "Track a symptom", "route": "symptom_log" }
  }.
- `topInsight`: { "id": "ins_early_01", "title": "Not enough data yet", "description": "Log more meals and symptoms to unlock patterns.", "kind": "pattern", "domain": "digestion", "strength": "low", "confidence": 0.0, "frequency": 0, "positiveCount": 0, "negativeCount": 0, "nextSteps": ["Log your next meal"] }.
- `detectedPatterns`: [].

MANDATORY SCORE RULE:
- `gutScore`: REQUIRED `GutScoreSummary` object with integer `score` (0-100). Anchor to `scoreHistory` and move gradually (+/- 1 to 5 points) unless evidence is overwhelming.

OUTPUT SCHEMA (STRICT JSON ONLY):
{
  "v": 2,
  "model": "gpt-4o-mini",
  "promptVersion": 4,
  "status": "ready|insufficient_data",
  "origin": "client",
  "gutScore": {
    "score": 78,
    "scoreDiff": 4,
    "direction": "up|down|neutral",
    "statusLabel": "On track",
    "summary": "string",
    "previousScore": 74,
    "maxScore": 100,
    "dailyScores": [
      { "date": "YYYY-MM-DD", "label": "Mon", "score": 74 }
    ],
    "trendHeadline": "string",
    "trendDescription": "string"
  },
  "topInsight": {
    "id": "string",
    "title": "string",
    "description": "string",
    "kind": "pattern|food_impact|trigger_alert|weekly_recap|progress|product_scan|action",
    "domain": "digestion|energy|sleep|mood|appetite|food_tolerance|bowel_movement|hydration|other",
    "observation": "string",
    "involvedFoods": ["string"],
    "strength": "high|medium|low",
    "confidence": 0.92,
    "frequency": 5,
    "positiveCount": 5,
    "negativeCount": 0,
    "nextSteps": ["string"]
  },
  "healing": {
    "goal": "string",
    "trend": "string",
    "topFoodId": "string",
    "foods": [
      {
        "foodId": "string",
        "name": "string",
        "emoji": "🥣",
        "effect": "string",
        "impactDirection": "positive",
        "impactLevel": "high|moderate|low",
        "frequencyCount": 5,
        "frequencyLabel": "5x this week",
        "bestTimeLabel": "Breakfast",
        "observedEffect": "string",
        "confidence": "high|medium|low",
        "confidenceScore": 0.9,
        "whyItWorks": [{ "title": "string", "description": "string", "icon": "string" }],
        "pairings": [{ "foodId": "string", "name": "string", "impactLevel": "high" }]
      }
    ]
  },
  "triggers": {
    "primarySymptom": "string",
    "trend": "string",
    "topFoodId": "string",
    "foods": [
      {
        "foodId": "string",
        "name": "string",
        "emoji": "🧅",
        "effect": "string",
        "impactDirection": "negative",
        "impactLevel": "high|moderate|low",
        "frequencyCount": 2,
        "frequencyLabel": "2x this week",
        "bestTimeLabel": "Dinner",
        "observedEffect": "string",
        "confidence": "high|medium|low",
        "confidenceScore": 0.9,
        "whyItWorks": [{ "title": "string", "description": "string", "icon": "string" }],
        "pairings": []
      }
    ]
  },
  "detectedPatterns": [
    {
      "id": "string",
      "domain": "digestion|energy|sleep|mood|appetite|food_tolerance|bowel_movement|hydration|other",
      "title": "string",
      "trigger": "string",
      "reaction": "string",
      "frequency": 3,
      "confidence": "high|medium|low",
      "confidenceScore": 0.91,
      "description": "string",
      "recommendation": "string",
      "totalSimilarMeals": 3,
      "timeframeDays": 7,
      "typicalTiming": "Evening",
      "typicalDelay": "2 hours",
      "impactDirection": "positive|negative",
      "impactLevel": "high|moderate|low",
      "occurrences": [
        {
          "id": "string",
          "patternId": "string",
          "date": "YYYY-MM-DD",
          "dateLabel": "Sep 12",
          "mealId": "string",
          "mealName": "string",
          "mealTime": "19:30",
          "mealType": "Dinner",
          "reaction": "string",
          "symptomSeverity": "mild|moderate|severe",
          "timeAfterMinutes": 120,
          "timeAfterLabel": "2 hours",
          "notes": "string",
          "commonFactors": [{ "label": "string", "icon": "string" }]
        }
      ],
      "commonFactors": [{ "label": "string", "icon": "string" }],
      "relatedFoodIds": ["string"]
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
      "id": "string",
      "foodId": "string",
      "food": "string",
      "date": "YYYY-MM-DD",
      "dateLabel": "Mon",
      "effect": "string",
      "timeframeLabel": "Breakfast",
      "emoji": "🥣",
      "impactDirection": "positive|negative",
      "impactLevel": "high|moderate|low",
      "confidence": "high|medium|low"
    }
  ],
  "weeklyRecap": {
    "id": "string",
    "dateRange": "string",
    "avgScore": 78,
    "scoreDiff": 4,
    "scoreSub": "string",
    "foodsLogged": 21,
    "loggedSub": "string",
    "patternsFound": 3,
    "newPatterns": 2,
    "highlights": [{ "id": "string", "icon": "sparkles", "text": "string", "color": "purple" }],
    "weeklyInsight": "string",
    "topHealingFoodId": "string",
    "topTriggerFoodId": "string"
  },
  "actions": [
    {
      "id": "string",
      "title": "string",
      "description": "string",
      "category": "nutrition|timing|lifestyle",
      "impactLevel": "high|moderate|low",
      "difficulty": "easy|medium|hard",
      "status": "not_started|in_progress|completed|skipped",
      "whenToDo": "string",
      "expectedBenefit": "string",
      "relatedPatternIds": ["string"],
      "relatedFoodIds": ["string"],
      "progress": { "target": 7, "completed": 0, "unit": "days" }
    }
  ],
  "foodSwaps": [
    {
      "id": "string",
      "source": { "foodId": "string", "name": "string", "imageUrl": "string" },
      "alternatives": [
        { "foodId": "string", "name": "string", "imageUrl": "string", "reason": "string", "impactLevel": "high" }
      ],
      "relatedPatternId": "string"
    }
  ],
  "recentInsights": [
    {
      "id": "string",
      "kind": "product_scan|pattern|trigger_alert|weekly_recap",
      "date": "2024-09-14T08:00:00.000Z",
      "dateLabel": "Sep 14, 2024",
      "title": "string",
      "description": "string",
      "score": 92,
      "impactDirection": "positive|negative",
      "impactLabel": "Positive Impact",
      "destination": { "screen": "food_detail|pattern_detail|trigger_detail|synergy_detail|weekly_recap", "id": "string" }
    }
  ],
  "emptyState": null
}

CRITICAL: Return ONLY the JSON object. No Markdown, no preamble.
''';
}
