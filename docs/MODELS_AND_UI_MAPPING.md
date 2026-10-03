# GutGood Data Models, Mock Data & UI Mapping Guide

> **Current source alignment:** 2026-10-03
> **Canonical model paths:** `lib/core/models/` and `lib/core/ai/protocol/`
> **Canonical presentation paths:** `lib/features/insights/presentation/widgets/insight_feed/` and `lib/features/insights/presentation/widgets/bento/`

This document catalogs shared data models, AI protocol models, and their current presentation mapping, including proper mock data examples and source ownership.

---

## 1. Insights Models (`lib/core/models/insights/`)

### `AIInsight` (`ai_insight.dart`)
- **Purpose**: Root aggregate snapshot for daily gut health analysis, scores, trends, patterns, and recommendations. Includes `validTopTrigger` which filters out positive reactions (e.g. `energetic`, `boost`) from trigger alerts.
- **Constructor Reference**:
```dart
const AIInsight({
    this.id,
    this.firestoreId,
    this.uid,
    required this.gutScore,
    this.hasGutScore = true,
    this.gutScoreSummary,
    this.scoreDiff,
    this.topInsight,
    this.healingGoal,
    this.healingFoods = const [],
    this.healingTrend,
    this.healingSummary,
    this.triggerSymptom,
    this.triggerFoods = const [],
    this.triggerTrend,
    this.triggerSummary,
    this.detectedPatterns = const [],
    this.topTrigger,
    this.topHealing,
    this.foodImpacts = const [],
    this.foodImpactBalance,
    this.weeklyRecap,
    this.weeklyRecapHistory = const [],
    this.type = 'Pattern',
    this.confidenceLevel = 'Moderate',
    this.triggerData,
    required this.updatedAt,
    this.schemaVersion = AiVersions.schemaVersion,
    this.periodFrom,
    this.periodTo,
    this.evidence,
    this.actions = const [],
    this.actionsList = const [],
    this.foodSwaps = const [],
    this.model,
    this.promptVersion,
    this.status = AIInsight.statusReady,
    this.expiresAt,
    this.origin,
    this.improving,
    this.watch,
    this.smartSwap,
});
```
- **Comprehensive Mock Data Example**:
```dart
final mockCompleteInsight = AIInsight(
  gutScore: 82,
  scoreDiff: '+4',
  updatedAt: DateTime.now(),
  healingGoal: 'Increase soluble fiber',
  triggerSymptom: 'bloating',
  topHealing: const TopHighlight(
    food: 'Chia seeds',
    effects: 'Boosted soluble fiber to 28g/day.',
    timeframe: 'This week',
    frequency: '5x',
    emoji: '🥑',
  ),
  topTrigger: const TopHighlight(
    food: 'Late Iced Coffee',
    effects: 'Delayed deep sleep by 38m.',
    timeframe: 'Past 3 PM',
    frequency: '3x',
    emoji: '☕',
  ),
  healingFoods: const [
    HealingFood(name: 'Chia seeds', effect: 'High fiber', emoji: '🥑'),
    HealingFood(name: 'Salmon', effect: 'Omega-3', emoji: '🐟'),
  ],
  triggerFoods: const [
    TriggerFood(name: 'French Fries', effect: 'Sodium', emoji: '🍟'),
  ],
  detectedPatterns: [
    BodyPattern(
      type: 'bloating',
      trigger: 'Fried Foods',
      reaction: 'Bloating & Gas',
      frequency: 3,
      confidence: 'High',
      description: 'Fried foods are associated with post-meal bloating within 2 hours.',
      evidenceRatio: 0.85,
      updatedAt: DateTime.now().toIso8601String(),
    ),
  ],
  foodSwaps: [
    FoodSwap(
      id: 'swap_1',
      source: const SwapSource(foodId: 'f_1', name: "Double Cheeseburger"),
      alternatives: [
        SwapAlternative(
          foodId: 'alt_1',
          name: 'Grilled Chicken Sandwich',
          reason: 'Higher in protein, lower in saturated fat.',
          category: 'Burgers & Sandwiches',
          nutrition: const SwapNutrition(calories: 350, protein: '32g', totalFat: '6g', fiber: '2g'),
          benefits: [
            const SwapBenefit(title: 'Higher Protein', description: 'Helps keep you full longer', icon: 'dumbbell'),
            const SwapBenefit(title: 'Lower Fat', description: 'Easier on your digestion', icon: 'leaf'),
          ],
        ),
        SwapAlternative(
          foodId: 'alt_2',
          name: 'Turkey Lettuce Wrap',
          reason: 'Low-fat, low-carb option minimizing heaviness.',
          category: 'Burgers & Sandwiches',
          nutrition: const SwapNutrition(calories: 240, protein: '28g', totalFat: '5g', fiber: '1g'),
          benefits: [
            const SwapBenefit(title: 'Light Digesting', description: 'Prevents post-meal sluggishness', icon: 'sun'),
          ],
        ),
        SwapAlternative(
          foodId: 'alt_3',
          name: 'Baked Fish Burger',
          reason: 'Oven-baked white fish rich in digestible lean protein.',
          category: 'Burgers & Sandwiches',
          nutrition: const SwapNutrition(calories: 310, protein: '26g', totalFat: '7g', fiber: '3g'),
          benefits: [
            const SwapBenefit(title: 'Lean Protein', description: 'Gentle on stomach lining', icon: 'shield'),
          ],
        ),
        SwapAlternative(
          foodId: 'alt_4',
          name: 'Quinoa & Roasted Chickpea Patty',
          reason: 'Prebiotic rich plant protein supporting gut motility.',
          category: 'Bowls & Patties',
          nutrition: const SwapNutrition(calories: 380, protein: '16g', totalFat: '8g', fiber: '9g'),
          benefits: [
            const SwapBenefit(title: 'Prebiotic Fiber', description: 'Feeds healthy gut flora', icon: 'sprout'),
          ],
        ),
      ],
    ),
  ],
);
```
- **UI Display**: Drives the **Insights Tab** (`InsightsScreen`), rendering the semantic `InsightsFeed` from `lib/features/insights/presentation/widgets/insight_feed/` alongside the Bento feed (`InsightBentoFeed`).

### `BodyPattern` (`body_pattern.dart`)
- **Purpose**: Observed association between a trigger and a reaction across canonical domains (`bloating`, `energy`, `headache`, `digestion`, `fullness`, `sleep`). Positive patterns (e.g. `energetic`) are filtered out from "Something to Watch" via `InsightValues.isPositiveReaction`.
- **Mock Data Example**:
```dart
final mockPattern = BodyPattern(
  type: 'bloating',
  trigger: 'Fried Foods',
  reaction: 'Bloating & Gas',
  frequency: 3,
  confidence: 'High',
  description: 'Fried foods are associated with post-meal bloating within 2 hours.',
  evidenceRatio: 0.85,
  updatedAt: DateTime.now().toIso8601String(),
);
```
- **UI Display**: Rendered as glowing Arc Pattern cards (`ArcPatternCard`) and organized in the Pattern Grid (`PatternGrid`).

### `FoodSwap`, `SwapAlternative`, `SwapBenefit`, `SwapNutrition` (`food_swap.dart`)
- **Purpose**: Recommends gut-friendly food alternatives for trigger foods, complete with benefit highlights, category tags, and nutrition facts (Calories, Protein, Fat, Fiber).
- **UI Display**: 
  - `BetterSwapsScreen`: 2x2 grid of alternative swap cards with images, benefit pills, category filter pills, and `+ Try This Swap` buttons.
  - `SwapDetailScreen`: Detailed view with hero image, 3 feature highlight pills, nutrition breakdown, and `Log This Meal` action button.

### `FoodImpact` (`ai_insight_details.dart`)
- **Purpose**: Records individual food impact events. Automatically normalizes positive reactions (e.g. `energetic`, `refreshed`, `boost`) to `impactType = 'positive'`.
- **Mock Data Example**:
```dart
final mockFoodImpact = FoodImpact(
  food: 'Tacos',
  dateLabel: 'Mon',
  effect: 'energetic',
  timeframeLabel: 'Lunch',
  emoji: '🌮',
  impactType: 'positive',
);
```
- **UI Display**: Food impact timeline tiles and history summaries.

---

## 2. Journal & Logging Models (`lib/core/models/journal/`)

### `MealLog` (`meal_log.dart`)
- **Purpose**: Records food items, meal photographs, and meal type.
- **Mock Data Example**:
```dart
final mockMealLog = MealLog(
  id: 'meal_1',
  mealName: 'Berry Oatmeal Bowl',
  mealType: 'Breakfast',
  imageUrl: 'https://images.unsplash.com/...',
  timestamp: DateTime.now(),
);
```
- **UI Display**: Journal timeline feed and meal history screens (`ScanHistoryScreen`).

### `SymptomLog` (`symptom_log.dart`)
- **Purpose**: Records user-reported symptoms, severity levels, and timestamps.
- **Mock Data Example**:
```dart
final mockSymptomLog = SymptomLog(
  id: 'sym_1',
  symptomName: 'Bloating',
  severity: 'Mild',
  timestamp: DateTime.now(),
);
```
- **UI Display**: Symptom tracking lists and pattern correlation views.

---

## 3. Scanner & Scan Models (`lib/core/models/scans/`)

### `ScanResult` & `ScanResultDetails` (`scan_result.dart`, `scan_result_details.dart`)
- **Purpose**: Comprehensive audit of a scanned product (NOVA processing group, Nutri-Score, additives, ingredients, gut impact verdict).
- **Mock Data Example**:
```dart
final mockScanResult = ScanResult(
  scanId: 'scan_1',
  productName: 'Organic Greek Yogurt',
  novaGroup: NovaGroup.group1,
  nutriScore: 'A',
  gutImpactScore: 92,
  impactType: 'positive',
  summary: 'Unprocessed probiotic dairy supporting gut barrier health.',
);
```
- **UI Display**: Super Scanner screen (`SuperScannerScreen`), Scan Result View (`ScanResultView`), and scan history lists.

---

## 4. User Models (`lib/core/models/user/`)

### `UserProfile` (`user_profile.dart`)
- **Purpose**: User configuration containing dietary goals, food sensitivities, lifestyle habits, and cycle phase.
- **Mock Data Example**:
```dart
final mockUserProfile = UserProfile(
  uid: 'user_123',
  displayName: 'Alex Smith',
  goals: ['Reduce bloating', 'Improve energy'],
  sensitivities: ['Dairy', 'Gluten'],
  lifestyle: ['Active', 'Low stress'],
  cyclePhase: 'Follicular',
);
```
- **UI Display**: Profile screen (`ProfileScreen`), preference toggles, and dynamically injected into AI prompt contexts (`ModePrompts`).

---

## 5. Canonical ownership notes

- `AiAnalysisResult` is defined in `lib/core/ai/protocol/ai_analysis_result.dart` and exported through the shared `core/models/models.dart` barrel.
- Insight blocks are defined in `lib/core/models/insights/insight_blocks.dart`; the source tree uses this semantic path directly.
- Feed-specific view models and deterministic derivations are owned by `lib/features/insights/presentation/widgets/insight_feed/`.
- Bento-specific widgets remain under `lib/features/insights/presentation/widgets/bento/`.
- Persisted `v`/schema-version fields and historical AI payload values remain unchanged. Source naming is semantic and does not add a `v2` presentation directory.
