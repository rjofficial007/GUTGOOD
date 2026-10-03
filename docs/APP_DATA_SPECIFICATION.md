# 📊 GutGood — Complete App Data & Information Architecture Specification

> **Current source alignment:** 2026-10-03
> **Document Purpose:** Pure data models, JSON payload samples, data relationships, and information hierarchy specifications for the GutGood application.
> **Use Case for AI/Engineers:** Feed this document into an AI or UI/UX generator to build data-driven screens with optimal information hierarchy without needing UI visual specifications.
> **Contract rule:** Persisted Firestore keys, serialized fields, and schema/version values remain stable contracts even when source class or folder names become semantic.

---

## 1. Data Information Hierarchy Principles

When generating UI/UX from this data, structure the hierarchy based on cognitive priority:

1. **Primary Data (Hero Focus):** Core metrics that require immediate user action or awareness (e.g., *Daily Gut Score*, *NOVA Group 1-4*, *Detected Food Trigger*, *Safety Rating*).
2. **Secondary Data (Context & Evidence):** Data explaining *why* the primary score/insight exists (e.g., *Time delay after meal*, *Problematic additives*, *Symptom severity rating*, *Swap score improvement*).
3. **Tertiary Data (Deep Dive / Collapsible):** In-depth information for curious users (e.g., *Full raw ingredient list*, *E-number chemical functions*, *Scientific citations*, *Clinical confidence rating*).
4. **Data Grouping Rule:**
   - Group Additives by **Risk Level** (*High Risk → Moderate Risk → Low Risk*).
   - Group Patterns by **Confidence & Frequency** (*High Confidence → Emerging Pattern*).
   - Group Menu Items by **Safety Tier** (*Green/Safe → Amber/Caution → Red/Avoid*).

---

## 2. Insights & Analytics Data Models

### 2.1 Daily Gut Score Data Payload
* **Purpose:** Drives the main health score dashboard and trend analysis.

```json
{
  "dailyGutScore": {
    "date": "2026-03-31",
    "score": 84,
    "maxScore": 100,
    "scoreBand": "EXCELLENT",
    "scoreBandOptions": ["EXCELLENT", "GOOD", "FAIR", "POOR"],
    "scoreDeltaVSYesterday": +3,
    "summaryNarrative": "Your gut health improved today due to zero ultra-processed food intake and high fiber variety.",
    "breakdownMetrics": {
      "foodQualityScore": 90,
      "upfRatioPercentage": 5.0,
      "fiberDiversityCount": 14,
      "targetFiberDiversity": 30,
      "hydrationLiters": 2.4,
      "targetHydrationLiters": 2.5,
      "symptomBurdenScore": 12
    },
    "historicalTrend": [
      { "day": "Mon", "score": 78 },
      { "day": "Tue", "score": 81 },
      { "day": "Wed", "score": 75 },
      { "day": "Thu", "score": 82 },
      { "day": "Fri", "score": 80 },
      { "day": "Sat", "score": 81 },
      { "day": "Sun", "score": 84 }
    ]
  }
}
```

* **Data Presentation Hierarchy:**
  - **Primary:** Score Number (`84`), Score Band (`EXCELLENT`), Summary Narrative.
  - **Secondary:** Breakdown Progress Bars (`foodQualityScore`, `upfRatioPercentage`, `fiberDiversityCount`).
  - **Tertiary:** 7-Day Historical Trend sparkline chart.

---

### 2.2 Detected Body Patterns Data Payload
* **Purpose:** Displays correlations between specific foods and delayed symptoms.

```json
{
  "bodyPattern": {
    "patternId": "pat_pizza_bloating_001",
    "patternType": "FOOD_TRIGGER",
    "triggerFood": "Frozen Pepperoni Pizza",
    "reactionSymptom": "Severe Bloating & Gas",
    "confidenceLevel": "HIGH",
    "confidenceScorePercentage": 92,
    "averageTimeDelayHours": 2.5,
    "totalOccurrences": 6,
    "firstObservedDate": "2026-02-10",
    "lastObservedDate": "2026-03-28",
    "suspectedCulprits": [
      {
        "name": "Sodium Nitrite (E250)",
        "category": "Preservative",
        "reason": "Known gut mucosal irritant"
      },
      {
        "name": "Refined Wheat Flour",
        "category": "Gluten / FODMAP",
        "reason": "Rapid fermentation in small intestine"
      }
    ],
    "occurrencesList": [
      {
        "date": "2026-03-28",
        "time": "19:30",
        "mealName": "Late Night Pepperoni Pizza",
        "photoUrl": "https://images.unsplash.com/photo-1513104890138-7c749659a591",
        "symptomSeverity": 8,
        "timeAfterMeal": "2.5h"
      },
      {
        "date": "2026-03-20",
        "time": "20:00",
        "mealName": "Deep Dish Slice",
        "photoUrl": "https://images.unsplash.com/photo-1513104890138-7c749659a591",
        "symptomSeverity": 7,
        "timeAfterMeal": "2.0h"
      }
    ],
    "actionableRecommendation": "Eliminate processed meats containing E250 for 14 days or swap with sourdough crust pizza."
  }
}
```

* **Data Presentation Hierarchy:**
  - **Primary:** Trigger Food (`Frozen Pepperoni Pizza`), Reaction Symptom (`Severe Bloating & Gas`), Confidence Level (`HIGH / 92%`).
  - **Secondary:** Average Time Delay (`2.5 hours`), Suspected Culprit List, Occurrences Timeline.
  - **Tertiary:** Actionable Recommendation.

---

### 2.3 Food Swaps Data Payload
* **Purpose:** Shows healthier alternatives to inflammatory or ultra-processed foods.

```json
{
  "foodSwap": {
    "swapId": "swap_cereal_001",
    "originalFood": {
      "productName": "Super Sugar Crunchy Flakes",
      "brand": "Big Brand Co.",
      "novaGroup": 4,
      "gutScore": 32,
      "photoUrl": "https://images.openfoodfacts.org/original_cereal.jpg",
      "problematicIngredients": [
        "High Fructose Corn Syrup",
        "Artificial Red 40 Dye",
        "BHT (E321)"
      ]
    },
    "recommendedSwap": {
      "productName": "Organic Ancient Grain Granola",
      "brand": "Pure Gut Foods",
      "novaGroup": 1,
      "gutScore": 91,
      "photoUrl": "https://images.openfoodfacts.org/organic_granola.jpg",
      "keyBenefits": [
        "Zero artificial additives",
        "8g pre-biotic chicory root fiber",
        "Lightly sweetened with raw honey"
      ]
    },
    "gutScoreImprovementDelta": +59,
    "swapCategory": "Breakfast Cereal",
    "reasoningText": "Swapping a Group 4 UPF cereal with high dyes for an ancient grain granola reduces intestinal inflammation and adds 8g of prebiotic gut fuel."
  }
}
```

* **Data Presentation Hierarchy:**
  - **Primary:** Original vs. Recommended Product Name, Gut Score Delta (`+59 points`), NOVA Group Comparison (Group 4 → Group 1).
  - **Secondary:** Problematic Ingredients (Original) vs. Key Benefits (Swap).
  - **Tertiary:** Category & Reasoning Narrative.

---

### 2.4 Active Gut Experiments Data Payload
* **Purpose:** Guided multi-day dietary protocols testing personal gut tolerance.

```json
{
  "gutExperiment": {
    "experimentId": "exp_oat_milk_test",
    "title": "10-Day Seed Oil & Emulsifier Detox",
    "hypothesis": "Removing Sunflower Lecithin and Carboxymethylcellulose (E466) will reduce evening abdominal distension.",
    "durationDays": 10,
    "currentDay": 4,
    "status": "IN_PROGRESS",
    "statusOptions": ["NOT_STARTED", "IN_PROGRESS", "COMPLETED", "PAUSED"],
    "dailyInstruction": "Check all plant milk and salad dressing labels for E466 or Sunflower Lecithin.",
    "trackedMetric": "Evening Bloating Severity (1-10)",
    "baselineAvgSeverity": 7.2,
    "currentAvgSeverity": 3.8,
    "severityImprovementPercentage": -47.2,
    "dailyProgressLogs": [
      { "day": 1, "completed": true, "symptomSeverity": 7 },
      { "day": 2, "completed": true, "symptomSeverity": 5 },
      { "day": 3, "completed": true, "symptomSeverity": 4 },
      { "day": 4, "completed": true, "symptomSeverity": 3 }
    ]
  }
}
```

---

## 3. Scanner & Product Analysis Data Models

### 3.1 Barcode & Label Scan Result Payload
* **Purpose:** Data returned after scanning a packaged food barcode or ingredient label photo.

```json
{
  "scanResult": {
    "scanId": "scan_890123456789",
    "barcode": "0041220576122",
    "productName": "Ultra Creamy Oat Milk",
    "brand": "Popular Dairy Free Co.",
    "photoUrl": "https://images.openfoodfacts.org/oatmilk.jpg",
    "scanMode": "BARCODE",
    "scanModeOptions": ["BARCODE", "INGREDIENT_LABEL", "MEAL_SNAP", "MENU_SURVIVAL"],
    "overallGutHealthScore": 48,
    "overallSafetyRating": "FAIR",
    "novaGroup": 4,
    "novaGroupName": "Ultra-Processed Food (UPF)",
    "additivesSummary": {
      "totalAdditivesCount": 4,
      "highRiskCount": 1,
      "moderateRiskCount": 2,
      "lowRiskCount": 1
    },
    "additivesDetailList": [
      {
        "code": "E407",
        "name": "Carrageenan",
        "riskLevel": "HIGH",
        "functionalCategory": "Thickener / Stabilizer",
        "healthConcern": "Clinical studies associate Carrageenan with colitis, intestinal permeability, and gut barrier degradation."
      },
      {
        "code": "E412",
        "name": "Guar Gum",
        "riskLevel": "MODERATE",
        "functionalCategory": "Emulsifier",
        "healthConcern": "May cause excess gas and rapid bacterial fermentation in sensitive bowel syndrome."
      },
      {
        "code": "E300",
        "name": "Ascorbic Acid (Vitamin C)",
        "riskLevel": "LOW",
        "functionalCategory": "Antioxidant",
        "healthConcern": "Safe dietary antioxidant with minimal gut disruption."
      }
    ],
    "ingredientList": [
      "Oat base (filtered water, oats)",
      "Sunflower oil",
      "Dipotassium phosphate",
      "Carrageenan (E407)",
      "Guar gum (E412)",
      "Sea salt"
    ],
    "nutritionalProfile": {
      "servingSize": "240 ml",
      "calories": 120,
      "totalFatGrams": 5.0,
      "saturatedFatGrams": 0.5,
      "totalCarbsGrams": 16.0,
      "addedSugarsGrams": 7.0,
      "proteinGrams": 2.0,
      "dietaryFiberGrams": 1.0
    },
    "aiGutVerdictNarrative": "While dairy-free, this oat milk contains Carrageenan (E407) and industrial seed oils making it a Group 4 Ultra-Processed Food that may aggravate gut lining inflammation."
  }
}
```

* **Data Presentation Hierarchy:**
  - **Primary:** Product Title, Brand, Gut Health Score (`48/100`), Safety Rating (`FAIR`), NOVA Group (`Group 4 UPF`).
  - **Secondary:** Additives Risk Breakdown (1 High, 2 Moderate, 1 Low), AI Gut Verdict Narrative.
  - **Tertiary:** Full Additive Concern Descriptions, Ingredient List, Nutritional Fact Panel.

---

### 3.2 Meal Snap Vision Data Payload
* **Purpose:** Data returned when photographing a cooked or restaurant meal.

```json
{
  "mealSnapResult": {
    "snapId": "snap_salmon_salad_88",
    "photoUrl": "https://storage.googleapis.com/gutgood/meals/salmon_salad.jpg",
    "identifiedDishName": "Wild Salmon & Avocado Quinoa Bowl",
    "estimatedMealType": "LUNCH",
    "estimatedInflammatoryRisk": "LOW",
    "gutScoreImpact": +18,
    "identifiedIngredients": [
      { "name": "Wild Atlantic Salmon", "category": "Healthy Protein / Omega-3", "gutBenefit": "Reduces intestinal mucosal inflammation" },
      { "name": "Avocado", "category": "Healthy Monounsaturated Fat", "gutBenefit": "Supports nutrient absorption" },
      { "name": "Quinoa", "category": "Complex Grain / Fiber", "gutBenefit": "Prebiotic fuel for Bifidobacteria" },
      { "name": "Baby Spinach", "category": "Leafy Green", "gutBenefit": "High phytonutrient density" }
    ],
    "potentialHiddenSensitivities": [
      { "item": "Creamy Dressing", "risk": "May contain soybean oil or artificial emulsifiers" }
    ],
    "dietaryTags": ["GLUTEN_FREE", "DAIRY_FREE", "HIGH_FIBER", "ANTI_INFLAMMATORY"]
  }
}
```

---

### 3.3 Restaurant Menu "Survival Mode" Data Payload
* **Purpose:** Data generated when scanning a restaurant menu photo.

```json
{
  "menuSurvivalResult": {
    "restaurantName": "Italian Trattoria",
    "scannedPhotoUrl": "https://storage.googleapis.com/gutgood/menus/menu_01.jpg",
    "totalItemsAnalyzed": 12,
    "userProfileContextApplied": {
      "sensitivities": ["lactose", "carrageenan", "heavy_garlic"],
      "primaryGoal": "eliminate_bloating"
    },
    "rankedDishes": [
      {
        "rank": 1,
        "dishName": "Grilled Sea Bass with Wilted Greens",
        "safetyTier": "SAFE_GREEN",
        "gutScoreEstimate": 92,
        "ingredientsToEnjoy": ["Sea Bass", "Olive Oil", "Lemon", "Spinach"],
        "customModificationRequest": "Ask chef to grill with olive oil instead of butter."
      },
      {
        "rank": 2,
        "dishName": "Chicken Marsala",
        "safetyTier": "CAUTION_AMBER",
        "gutScoreEstimate": 64,
        "ingredientsToEnjoy": ["Chicken Breast", "Mushrooms"],
        "ingredientsToCaution": ["Heavy Cream sauce", "Garlic butter"],
        "customModificationRequest": "Request sauce on the side and limit portion to 2 tablespoons."
      },
      {
        "rank": 3,
        "dishName": "Four-Cheese Fettuccine Alfredo",
        "safetyTier": "AVOID_RED",
        "gutScoreEstimate": 25,
        "rejectionReason": "Contains heavy lactose, refined wheat, and high saturated fat which strongly trigger bloating."
      }
    ]
  }
}
```

* **Data Presentation Hierarchy:**
  - **Primary:** Ranked Dishes grouped by Safety Tier (*Green → Amber → Red*), Dish Name, Gut Score Estimate.
  - **Secondary:** Custom Modification Request (How to order safely).
  - **Tertiary:** Ingredients List & Rejection Reasons.

---

## 4. Journal, History & Log Data Models

### 4.1 Meal Log Payload
```json
{
  "mealLog": {
    "logId": "log_meal_10928",
    "timestamp": "2026-03-31T13:15:00Z",
    "mealType": "LUNCH",
    "mealTypeOptions": ["BREAKFAST", "LUNCH", "DINNER", "SNACK"],
    "items": ["Grilled Chicken Breast", "Steamed Broccoli", "Brown Rice"],
    "photoUrl": "https://storage.googleapis.com/gutgood/meals/lunch.jpg",
    "source": "CHAT_PASSIVE_TAG",
    "associatedScanId": "scan_890123456789"
  }
}
```

### 4.2 Symptom Log Payload
```json
{
  "symptomLog": {
    "logId": "log_symp_55412",
    "timestamp": "2026-03-31T15:45:00Z",
    "symptomType": "Abdominal Bloating",
    "symptomCategory": "DIGESTIVE",
    "severityRating": 7,
    "severityScale": "1 (Mild) to 10 (Severe)",
    "onsetDelayMinutesAfterMeal": 150,
    "userNotes": "Felt uncomfortable tightness in lower stomach shortly after lunch."
  }
}
```

---

## 5. AI Chat Companion Data Models

### 5.1 Chat Message Payload (with Extracted Tags)
```json
{
  "chatMessage": {
    "messageId": "msg_998124",
    "sender": "ASSISTANT",
    "senderOptions": ["USER", "ASSISTANT"],
    "timestamp": "2026-03-31T14:02:00Z",
    "markdownContent": "I've logged your lunch! The **Grilled Salmon Bowl** is an excellent anti-inflammatory choice (+18 Gut Score). However, watch out for the creamy dressing if you are sensitive to seed oils.",
    "attachmentUrl": "https://storage.googleapis.com/gutgood/chat/user_upload.jpg",
    "extractedTags": [
      {
        "tagType": "MEAL",
        "extractedData": {
          "mealType": "LUNCH",
          "items": ["Grilled Salmon Bowl", "Avocado", "Quinoa"]
        }
      },
      {
        "tagType": "SYMPTOM",
        "extractedData": {
          "symptomType": "Mild Gas",
          "severity": 2
        }
      }
    ]
  }
}
```

---

## 6. User Profile, Cycle Sync & Quota Data Models

### 6.1 User Health Profile & Cycle Sync Payload
```json
{
  "userProfile": {
    "uid": "usr_998215412",
    "email": "user@example.com",
    "isPremium": true,
    "healthGoals": [
      "Reduce Chronic Bloating",
      "Eliminate Ultra-Processed Foods",
      "Improve Digestion & Regularity"
    ],
    "sensitivities": [
      "Lactose",
      "Carrageenan (E407)",
      "High FODMAPs",
      "Artificial Dyes"
    ],
    "cycleSyncData": {
      "enabled": true,
      "currentPhase": "LUTEAL",
      "phaseOptions": ["FOLICULAR", "OVULATORY", "LUTEAL", "MENSTRUAL"],
      "cycleDay": 22,
      "hormonalGutImpactSummary": "Progesterone peak in the Luteal phase slows intestinal transit time, increasing risk of bloating and constipation.",
      "phaseNutritionAdvice": "Increase warm water intake, magnesium-rich foods (dark chocolate, pumpkin seeds), and cooked root vegetables."
    },
    "usageQuotas": {
      "dailyScansUsed": 2,
      "dailyScansLimit": 5,
      "dailyChatsUsed": 4,
      "dailyChatsLimit": 10,
      "isUnlimited": true
    }
  }
}
```

---

## 7. Summary Table: Data Points Required per Screen

| Screen Name | Primary Data Points Needed | Secondary Data Points Needed | Tertiary / Collapsible Data |
|---|---|---|---|
| **Daily Insights Dashboard** | Daily Gut Score (0-100), Score Band, Daily Summary Narrative | Food Quality Score, UPF Ratio %, Fiber Count, Hydration | 7-Day Historical Score Sparkline |
| **Pattern Detail Screen** | Trigger Food Name, Symptom Name, Confidence Score % | Average Time Delay (hrs), Suspected Ingredients | Occurrences Timeline List (Dates, Photos, Severities) |
| **Food Swap Screen** | Original Product Name vs Swap Product Name, Score Delta (+59) | Original Additives vs Swap Benefits | Category, Detailed Swap Reasoning |
| **Scan Result Screen** | Product Title, Brand, Gut Score (0-100), NOVA Group (1-4) | Additives Risk Summary, AI Verdict Narrative | Full Additive Concern List (E-numbers), Ingredient List |
| **Menu Survival Screen** | Ranked Dishes List (Grouped by Safe/Caution/Avoid) | Custom Ordering Modification Request | Rejection Reasons, Ingredients to Avoid |
| **Meal/Symptom Journal** | Date/Time, Meal Type / Symptom Name, Severity Rating (1-10) | Photo Thumbnail, Onset Delay | User Personal Notes, Associated Scans |
| **AI Companion Chat** | Message Markdown Content, Sender Role, Extracted Tag Chips | Image Attachment, Timestamp | Raw Tag Payload details |

---

## 8. Canonical source mapping

| Data responsibility | Current source |
|---|---|
| Unified structured AI response | `lib/core/ai/protocol/ai_analysis_result.dart` (`AiAnalysisResult`) |
| AI constants, intent values, image modes, schema versions | `lib/core/ai/protocol/ai_constants.dart` |
| Structured response validation | `lib/core/ai/validation/ai_response_validator.dart` |
| Insight blocks and serialized insight payloads | `lib/core/models/insights/insight_blocks.dart` and `lib/core/models/insights/ai_insight.dart` |
| Shared model barrel | `lib/core/models/models.dart` |
| Semantic Insights presentation data | `lib/features/insights/presentation/widgets/insight_feed/insight_feed_derivations.dart` |
| Scanner mode model | `lib/core/models/scans/scanner_mode.dart` |

The current application source tree contains only canonical model and protocol paths; export-only compatibility files are not retained. Historical schema/version values remain readable through the canonical models.
