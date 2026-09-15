# GutGood Insight Data Specification & Mock Data

This document outlines the complete data schema, related screens, and comprehensive mock data for the **Insights** feature in the GutGood app.

## 1. Data Model Overview (`AIInsight`)

The `AIInsight` model aggregates data from chat history, meal logs, and symptoms to provide actionable gut-health insights.

### Key Components & Sub-Models
- **`AIInsight`**: Core model containing overall score, healing/trigger trends, detected patterns, weekly recap, and evidence.
- **`InsightSummary` (`topInsight`)**: High-level title, description, observation, involved foods, strength, next steps, and evidence ratios.
- **`BodyPattern` (`detectedPatterns`)**: Recurring digestion patterns, triggers, reactions, confidence levels, recommendations, and timeframes.
- **`TopHighlight` (`topHealing` / `topTrigger`)**: Summary of the top healing food or top trigger food of the week.
- **`FoodImpact` (`foodImpacts`)**: Per-food impact breakdown across days, timeframes, and effects.
- **`WeeklyRecap` (`weeklyRecap`)**: Summary for the week, including average score, best day, foods logged, and highlights.
- **`InsightEvidence` (`evidence`)**: Pattern references and sample sizes supporting the insights.

---

## 2. Related Screens & Bento Widgets

1. **Screen 01 — Bento Feed (`InsightBentoFeed`)**
   - Displays the **Score Hero card** (score, delta, sparkline/bars).
   - Top healing foods & top trigger culprits.
   - Curated body patterns and dietary synergy boost summaries.

2. **Screen 02 — Learning / Patterns Grid (`InsightBentoScreens`)**
   - Detailed breakdown of detected body patterns (`BodyPattern`), frequency, confidence, and recommended swaps.

3. **Screen 03 — Weekly Recap (`InsightBentoRecap`)**
   - 7-day rolling performance recap, best-performing day, score sub-text, and weekly highlights.

4. **Screen 04 — Synergy & Food Intelligence**
   - Body-food synergy metrics, positive vs negative food impact ratios.

---

## 3. Comprehensive Mock Data JSON

Below is a fully populated JSON object representing a valid `AIInsight` instance with all related fields and nested structures:

```json
{
  "v": 1,
  "model": "gpt-4o-mini",
  "promptVersion": 3,
  "gutScore": 78,
  "scoreDiff": "+4",
  "type": "Pattern",
  "confidenceLevel": "High",
  "triggerData": "[]",
  "topInsight": {
    "title": "Fiber & Fermentation Synergy",
    "description": "Consuming fermented foods alongside prebiotic fiber significantly reduces bloating episodes.",
    "type": "Pattern",
    "observation": "Meals rich in kefir and whole grains correlate with high energy and smooth digestion.",
    "involvedFoods": ["Kefir", "Sourdough Toast", "Greek Yogurt", "Kimchi"],
    "strength": "High",
    "nextSteps": ["Continue daily kefir intake", "Pair prebiotic veggies with lean protein"],
    "frequency": 5,
    "evidenceRatio": 0.92,
    "positiveCount": 5,
    "negativeCount": 0
  },
  "healingGoal": "Optimize digestion and eliminate afternoon bloating.",
  "healingTrend": "Consistent vegetable fiber intake is actively improving your gut barrier score.",
  "healingFoods": [
    {
      "name": "Greek Yogurt",
      "effect": "Supports microbiome diversity",
      "emoji": "🥣",
      "imageUrl": "https://images.unsplash.com/photo-1488477181946-6428a0291777",
      "userImageUrl": null,
      "foodScanId": "scan_yogurt_01"
    },
    {
      "name": "Kimchi",
      "effect": "Enhances gut flora vitality",
      "emoji": "🥬",
      "imageUrl": "https://images.unsplash.com/photo-1583225224483-90d7967817b9",
      "userImageUrl": null,
      "foodScanId": "scan_kimchi_01"
    }
  ],
  "triggerSymptom": "Mild bloating",
  "triggerFoods": [
    {
      "name": "Deep-Fried Onion Rings",
      "effect": "Slows gastric emptying & triggers bloating",
      "emoji": "🧅",
      "imageUrl": "https://images.unsplash.com/photo-1639024471283-03518883512d",
      "userImageUrl": null,
      "foodScanId": "scan_onion_01"
    }
  ],
  "triggerTrend": "Fried and heavily processed foods consistently precede bloating by 2 hours.",
  "detectedPatterns": [
    {
      "type": "digestion",
      "trigger": "Refined vegetable oils & fried batter",
      "reaction": "Abdominal fullness and bloating",
      "frequency": 3,
      "confidence": "High",
      "description": "Deep-fried items consumed in the evening correlate with digestive discomfort.",
      "recommendation": "Swap fried sides for roasted or steamed alternatives.",
      "totalSimilarMeals": 3,
      "timeframeDays": 7,
      "occurrences": [
        {
          "date": "Sep 12",
          "mealName": "Crispy Chicken Burger & Fries",
          "reaction": "Abdominal bloating",
          "timeAfter": "2 hours"
        },
        {
          "date": "Sep 13",
          "mealName": "Tempura Vegetables",
          "reaction": "Feeling heavy",
          "timeAfter": "1.5 hours"
        }
      ],
      "commonFactors": [
        { "label": "deep fried", "icon": "flame" }
      ]
    }
  ],
  "topHealing": {
    "food": "Greek Yogurt",
    "effects": "Steady energy & great digestion",
    "timeframe": "this week",
    "frequency": "5x this week",
    "foodScanId": "scan_yogurt_01",
    "userImageUrl": null
  },
  "topTrigger": {
    "food": "Deep-Fried Onion Rings",
    "effects": "Mild bloating",
    "timeframe": "this week",
    "frequency": "2x this week",
    "foodScanId": "scan_onion_01",
    "userImageUrl": null
  },
  "foodImpacts": [
    {
      "food": "Greek Yogurt",
      "dateLabel": "Mon",
      "effect": "Optimized digestion",
      "timeframeLabel": "Breakfast",
      "emoji": "🥣",
      "isPositive": true,
      "imageUrl": null,
      "userImageUrl": null
    },
    {
      "food": "Onion Rings",
      "dateLabel": "Tue",
      "effect": "Bloating",
      "timeframeLabel": "Dinner",
      "emoji": "🧅",
      "isPositive": false,
      "imageUrl": null,
      "userImageUrl": null
    }
  ],
  "weeklyRecap": {
    "dateRange": "Sep 08 - Sep 14",
    "avgScore": 78,
    "scoreSub": "Great improvement in fiber intake and probiotic diversity!",
    "bestDay": "Sep 11",
    "foodsLogged": 21,
    "loggedSub": "Consistent logging gives the AI high confidence in your patterns.",
    "highlights": [
      { "text": "Added fermented foods on 5 out of 7 days." },
      { "text": "Reduced sugary beverage intake by 50%." }
    ]
  },
  "period": {
    "from": "2024-09-08T00:00:00.000Z",
    "to": "2024-09-14T23:59:59.000Z"
  },
  "evidence": {
    "sampleSizes": {
      "meals": 21,
      "symptoms": 3,
      "scans": 15
    },
    "patternRefs": [
      { "id": "pat_01", "name": "Fermentation Synergy" }
    ]
  },
  "actions": [
    "Increase prebiotic vegetables",
    "Maintain daily kefir routine"
  ],
  "status": "ready",
  "origin": "client",
  "updatedAt": "2024-09-14T21:00:00.000Z"
}
```
