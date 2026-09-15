import 'package:gutgood/core/data/additive_concern_db.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/services/firestore/chat_firestore_service.dart';
import 'package:gutgood/core/services/firestore/food_image_firestore_service.dart';
import 'package:gutgood/core/services/firestore/history_firestore_service.dart';
import 'package:gutgood/core/services/firestore/insight_firestore_service.dart';
import 'package:gutgood/core/services/purchase_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/yuka_score.dart';
import 'package:uuid/uuid.dart';

/// Service to generate pattern-rich mock data for testing.
class DebugMockDataService {
  DebugMockDataService({
    required HistoryFirestoreService historyFirestoreService,
    required InsightFirestoreService insightFirestoreService,
    required ChatFirestoreService chatFirestoreService,
    required PurchaseService purchaseService,
    required FoodImageService foodImageService,
  }) : _historyFirestoreService = historyFirestoreService,
       _insightFirestoreService = insightFirestoreService,
       _chatFirestoreService = chatFirestoreService,
       _purchaseService = purchaseService,
       _foodImageService = foodImageService;

  final HistoryFirestoreService _historyFirestoreService;
  final InsightFirestoreService _insightFirestoreService;
  final ChatFirestoreService _chatFirestoreService;
  final PurchaseService _purchaseService;
  final FoodImageService _foodImageService;

  Future<void> generateThirtyDaysData() async {
    AppLogger.mock('Generating 30 days of structured pattern-rich data...');

    // Set premium status to unlock pro features in mocks
    _purchaseService.setProStatusForDebug(true);

    final now = DateTime.now();

    // Track occurrences for pattern generation
    final pizzaOccurrences = <PatternOccurrence>[];
    final energyOccurrences = <PatternOccurrence>[];
    final headacheOccurrences = <PatternOccurrence>[];

    const oatsPhoto = 'https://images.unsplash.com/photo-1517673400267-0251440c45dc?auto=format&fit=crop&w=800&q=80';
    const shakePhoto = 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?auto=format&fit=crop&w=800&q=80';
    const espressoPhoto = 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=800&q=80';
    const saladPhoto = 'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=800&q=80';
    const pizzaPhoto = 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=800&q=80';
    const salmonPhoto = 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?auto=format&fit=crop&w=800&q=80';

    for (var i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = '${date.year}-${date.month}-${date.day}';

      // Patterns spread across 30 days for higher confidence
      final isPizzaDay = i % 4 == 0; // Bloating every 4 days
      final isEnergyDay = i % 3 == 0; // High Energy every 3 days
      final isHeadacheDay = i % 5 == 0; // Headache every 5 days
      final isDigestionDay = i % 7 == 0; // Digestion every 7 days
      final isFullnessDay = i % 2 == 0; // Fullness every 2 days
      final isSleepDay = i % 3 == 0 && i > 0; // Poor sleep linked to late eating
      final isDairyDay = i % 6 == 0; // Skin Flare-up linked to Dairy

      // --- LOG MEALS ---
      // Breakfast
      await _historyFirestoreService.logMeal(
        MealLog(
          items: isFullnessDay ? const ['Steel Cut Oats', 'Walnuts', 'Blueberries'] : const ['White Toast', 'Jam'],
          mealType: 'breakfast',
          photoUrl: isFullnessDay ? oatsPhoto : null,
          createdAt: DateTime(date.year, date.month, date.day, 8, 0),
          source: 'debug',
        ),
      );

      // Mid-Morning (Pattern triggers)
      if (isEnergyDay) {
        final time = DateTime(date.year, date.month, date.day, 10, 30);
        await _historyFirestoreService.logMeal(MealLog(items: const ['Whey Protein Shake', 'Banana'], mealType: 'snack', photoUrl: shakePhoto, createdAt: time, source: 'debug'));
        energyOccurrences.add(PatternOccurrence(date: dateStr, mealName: 'Whey Protein Shake', imageUrl: shakePhoto, reaction: 'High Energy', timeAfter: '1.5h'));
      }
      if (isHeadacheDay) {
        final time = DateTime(date.year, date.month, date.day, 9, 0);
        await _historyFirestoreService.logMeal(MealLog(items: const ['Double Espresso', 'Sugar Packet'], mealType: 'snack', photoUrl: espressoPhoto, createdAt: time, source: 'debug'));
        headacheOccurrences.add(PatternOccurrence(date: dateStr, mealName: 'Double Espresso', imageUrl: espressoPhoto, reaction: 'Headache', timeAfter: '2h'));
      }

      // Lunch
      await _historyFirestoreService.logMeal(
        MealLog(
          items: isDigestionDay ? const ['Spicy Street Tacos', 'Jalapeños', 'Corn Tortilla'] : const ['Grilled Chicken Salad', 'Vinaigrette', 'Avocado'],
          mealType: 'lunch',
          photoUrl: saladPhoto,
          createdAt: DateTime(date.year, date.month, date.day, 13, 0),
          source: 'debug',
        ),
      );

      // Dinner
      if (isPizzaDay) {
        final time = DateTime(date.year, date.month, date.day, 19, 0);
        await _historyFirestoreService.logMeal(MealLog(items: const ['Pepperoni Pizza', 'Garlic Bread', 'Soda'], mealType: 'dinner', photoUrl: pizzaPhoto, createdAt: time, source: 'debug'));
        pizzaOccurrences.add(PatternOccurrence(date: dateStr, mealName: 'Pepperoni Pizza', imageUrl: pizzaPhoto, reaction: 'Severe Bloating', timeAfter: '2.5h'));
      } else if (isDairyDay) {
        await _historyFirestoreService.logMeal(
          MealLog(items: const ['Creamy Pasta Carbonara', 'Parmesan Cheese'], mealType: 'dinner', createdAt: DateTime(date.year, date.month, date.day, 19, 30), source: 'debug'),
        );
      } else {
        await _historyFirestoreService.logMeal(
          MealLog(items: const ['Steamed Salmon', 'Broccoli', 'Brown Rice'], mealType: 'dinner', photoUrl: salmonPhoto, createdAt: DateTime(date.year, date.month, date.day, 19, 0), source: 'debug'),
        );
      }

      // Late Night
      if (isSleepDay) {
        await _historyFirestoreService.logMeal(MealLog(items: const ['Red Wine', 'Dark Chocolate'], mealType: 'snack', createdAt: DateTime(date.year, date.month, date.day, 22, 0), source: 'debug'));
      }

      // --- LOG SYMPTOMS (REACTIONS) ---

      // Morning Fullness Check
      if (isFullnessDay) {
        await _historyFirestoreService.logSymptom(
          SymptomLog(
            symptom: 'Sustained Fullness',
            severity: 1,
            energyLevel: 6,
            mood: 'Content',
            foodName: 'Steel Cut Oats',
            notes: 'Feeling satisfied long after breakfast.',
            createdAt: DateTime(date.year, date.month, date.day, 11, 30),
            source: 'debug',
          ),
        );
      }

      // Energy Spike
      if (isEnergyDay) {
        await _historyFirestoreService.logSymptom(
          SymptomLog(
            symptom: 'High Energy',
            severity: 2,
            energyLevel: 9,
            mood: 'Productive',
            foodName: 'Whey Protein Shake',
            imageUrl: shakePhoto,
            notes: 'Feeling very productive after morning shake.',
            createdAt: DateTime(date.year, date.month, date.day, 12, 0),
            source: 'debug',
          ),
        );
      }

      // Headache Check
      if (isHeadacheDay) {
        await _historyFirestoreService.logSymptom(
          SymptomLog(
            symptom: 'Headache',
            severity: 6,
            mood: 'Irritable',
            foodName: 'Double Espresso',
            imageUrl: espressoPhoto,
            notes: 'Dull ache behind eyes.',
            createdAt: DateTime(date.year, date.month, date.day, 11, 0),
            source: 'debug',
          ),
        );
      }

      // Digestion Check
      if (isDigestionDay) {
        await _historyFirestoreService.logSymptom(
          SymptomLog(
            symptom: 'Heartburn/Indigestion',
            severity: 5,
            foodName: 'Spicy Street Tacos',
            notes: 'Burning sensation in chest.',
            createdAt: DateTime(date.year, date.month, date.day, 15, 0),
            source: 'debug',
          ),
        );
      }

      // Bloating Check
      if (isPizzaDay) {
        await _historyFirestoreService.logSymptom(
          SymptomLog(
            symptom: 'Severe Bloating',
            severity: 8,
            mood: 'Uncomfortable',
            foodName: 'Pepperoni Pizza',
            imageUrl: pizzaPhoto,
            notes: 'Stomach feels like a balloon after pizza.',
            createdAt: DateTime(date.year, date.month, date.day, 21, 30),
            source: 'debug',
          ),
        );
      }

      // Skin Check
      if (isDairyDay) {
        await _historyFirestoreService.logSymptom(
          SymptomLog(
            symptom: 'Skin Flare-up',
            severity: 4,
            foodName: 'Creamy Pasta Carbonara',
            notes: 'Redness on cheeks noted.',
            createdAt: DateTime(date.year, date.month, date.day, 22, 30),
            source: 'debug',
          ),
        );
      }

      // Sleep Check (logged the next morning)
      if (isSleepDay) {
        final nextDay = date.add(const Duration(days: 1));
        await _historyFirestoreService.logSymptom(
          SymptomLog(symptom: 'Restless Sleep', severity: 4, sleep: 'Poor', notes: 'Woke up multiple times.', createdAt: DateTime(nextDay.year, nextDay.month, nextDay.day, 7, 0), source: 'debug'),
        );
      }
    }

    // --- GENERATE SCAN HISTORY ---
    final scanProducts = [
      {
        'name': 'Greek Yogurt',
        'brand': 'Chobani',
        'score': 62,
        'nutri': 'C',
        'nova': 1,
        'cat': 'food',
        'img': 'https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&w=800&q=80',
      },
      {
        'name': 'Matcha Latte',
        'brand': 'GutGood',
        'score': 75,
        'nutri': 'B',
        'nova': 1,
        'cat': 'food',
        'img': 'https://images.unsplash.com/photo-1536256263959-770b48d82b0a?auto=format&fit=crop&w=800&q=80',
      },
      {
        'name': 'Veggie Chips',
        'brand': 'Sensible Portions',
        'score': 58,
        'nutri': 'C',
        'nova': 3,
        'cat': 'food',
        'img': 'https://images.unsplash.com/photo-1566478989037-eec170784d0b?auto=format&fit=crop&w=800&q=80',
      },
      {
        'name': 'Dark Chocolate 85%',
        'brand': 'Lindt',
        'score': 45,
        'nutri': 'D',
        'nova': 2,
        'cat': 'food',
        'img': 'https://images.unsplash.com/photo-1549007994-cb92caebd54b?auto=format&fit=crop&w=800&q=80',
      },
      {'name': 'Frozen Pepperoni Pizza', 'brand': 'Digiorno', 'score': 30, 'nutri': 'E', 'nova': 4, 'cat': 'food', 'img': pizzaPhoto},
      {'name': 'Oat Milk', 'brand': 'Oatly', 'score': 55, 'nutri': 'C', 'nova': 2, 'cat': 'food', 'img': 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=800&q=80'},
      {
        'name': 'Diet Soda',
        'brand': 'Coca-Cola',
        'score': 48,
        'nutri': 'D',
        'nova': 4,
        'cat': 'food',
        'img': 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?auto=format&fit=crop&w=800&q=80',
      },
      {
        'name': 'Whole Grain Bread',
        'brand': 'Ezekiel 4:9',
        'score': 66,
        'nutri': 'B',
        'nova': 1,
        'cat': 'label',
        'img': 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=800&q=80',
      },
      {
        'name': 'Gastro Pub Menu',
        'brand': 'The Local',
        'score': 52,
        'nutri': 'C',
        'nova': 2,
        'cat': 'menu',
        'img': 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&w=800&q=80',
      },
      {
        'name': 'Granola Bar',
        'brand': 'Nature Valley',
        'score': 44,
        'nutri': 'D',
        'nova': 3,
        'cat': 'food',
        'img': 'https://images.unsplash.com/photo-1590080875515-8a3a8dc5735e?auto=format&fit=crop&w=800&q=80',
      },
      {
        'name': 'Oat Milk Creamer',
        'brand': 'Chobani',
        'score': 50,
        'nutri': 'C',
        'nova': 3,
        'cat': 'food',
        'img': 'https://images.unsplash.com/photo-1550583724-b2692b85b150?auto=format&fit=crop&w=800&q=80',
      },
      {
        'name': 'Canned Soup',
        'brand': 'Campbell\'s',
        'score': 40,
        'nutri': 'D',
        'nova': 3,
        'cat': 'food',
        'img': 'https://images.unsplash.com/photo-1547592180-85f173990554?auto=format&fit=crop&w=800&q=80',
      },
    ];

    for (var i = 0; i < scanProducts.length; i++) {
      final p = scanProducts[i];
      final img = p['img'] as String?;
      await _historyFirestoreService.saveToScanHistory(
        ScanResult(
          productName: p['name'] as String,
          brand: p['brand'] as String,
          score: p['score'] as int,
          impactType: (p['score'] as int) >= 50 ? ImpactType.positive : ImpactType.negative,
          impact: 'Foundation for Gut Score logic.',
          nutriscore: p['nutri'] as String,
          novaGroup: (p['nova'] as int).toString(),
          category: p['cat'] as String,
          imageUrl: img,
          userImageUrl: img,
          createdAt: now.subtract(Duration(hours: i * 8 + 3)),
          source: p['cat'] == 'food' ? 'barcode' : p['cat'] as String,
          isSaved: i < 5,
        ),
      );
    }

    // --- SHOWCASE SCANS: fully-detailed bad + good products for the Scan Results UI ---
    await _seedShowcaseScans(now);

    // --- GENERATE INSIGHTS & PATTERNS (mirrors the Insights feed story) ---
    // NOTE: real generation leaves imageUrl empty (see prompt); these URLs exist
    // only so the mock previews the photo-driven feed design.
    const friesPhoto = 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?auto=format&fit=crop&w=800&q=85';
    const berriesPhoto = 'https://images.unsplash.com/photo-1498557850523-fd3d118b962e?auto=format&fit=crop&w=500&q=85';
    const chickenPhoto = 'https://images.unsplash.com/photo-1532550907401-a500c9a57435?auto=format&fit=crop&w=500&q=85';
    const friesThumb = 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?auto=format&fit=crop&w=500&q=85';
    const applesPhoto = 'https://images.unsplash.com/photo-1567306226416-28f0efdc88ce?auto=format&fit=crop&w=500&q=85';
    String dayLabel(int daysAgo) {
      final d = now.subtract(Duration(days: daysAgo));
      return '${d.month}/${d.day}';
    }

    final patterns = [
      // HERO: highest evidence ratio -> hero card + photo panel.
      BodyPattern(
        type: BodyPattern.typeHeadache,
        trigger: 'Fast food',
        reaction: 'Headaches',
        frequency: 4,
        confidence: BodyPattern.confidenceHigh,
        description: 'Fast food shows up on days you report headaches.',
        involvedFoods: const ['Fast food', 'French Fries', 'Burger'],
        recommendation: 'Try swapping fries for a side salad twice a week and watch this trend.',
        updatedAt: now.toIso8601String(),
        occurrences: [
          PatternOccurrence(date: dayLabel(2), mealName: 'Burger & French Fries', imageUrl: friesPhoto, reaction: 'Headache', timeAfter: 'About 2 hours later'),
          PatternOccurrence(date: dayLabel(5), mealName: 'Chicken Nuggets & Fries', imageUrl: friesPhoto, reaction: 'Headache', timeAfter: 'About 1.5 hours later'),
          PatternOccurrence(date: dayLabel(9), mealName: 'Double Cheeseburger', imageUrl: friesPhoto, reaction: 'Headache', timeAfter: 'About 2.5 hours later'),
          PatternOccurrence(date: dayLabel(13), mealName: 'Fish & Chips', imageUrl: friesPhoto, reaction: 'Headache', timeAfter: 'About 2 hours later'),
        ],
        evidenceRatio: 1.0,
        positiveCount: 4,
        totalSimilarMeals: 4,
        timeframeDays: 14,
        commonFactors: const [
          CommonFactor(label: 'Fried foods', icon: 'utensils'),
          CommonFactor(label: 'Higher sodium', icon: 'droplet'),
        ],
      ),
      // REST card: sleep pattern outranks energy so the purple card shows sleep.
      BodyPattern(
        type: BodyPattern.typeSleep,
        trigger: 'Earlier dinners',
        reaction: 'Better Sleep',
        frequency: 5,
        confidence: BodyPattern.confidenceHigh,
        description: 'Your food choices may be supporting better sleep.',
        recommendation: 'Keep dinners before 8 PM to protect this trend.',
        updatedAt: now.toIso8601String(),
        evidenceRatio: 0.95,
        positiveCount: 5,
        totalSimilarMeals: 5,
        timeframeDays: 14,
      ),
      BodyPattern(
        type: BodyPattern.typeEnergy,
        trigger: 'Whey Protein & Banana',
        reaction: 'Productive Energy Spike',
        frequency: energyOccurrences.length,
        confidence: BodyPattern.confidenceHigh,
        description: 'You consistently report high energy levels after your morning protein shake.',
        involvedFoods: const ['Whey Protein Shake', 'Banana'],
        recommendation: 'Keep this as a staple for your productive mornings.',
        updatedAt: now.toIso8601String(),
        occurrences: energyOccurrences,
        evidenceRatio: 0.9,
        positiveCount: energyOccurrences.length,
        totalSimilarMeals: energyOccurrences.length + 2,
        timeframeDays: 14,
        commonFactors: const [CommonFactor(label: 'Morning', icon: 'sun')],
      ),
      BodyPattern(
        type: BodyPattern.typeBloating,
        trigger: 'Ultra-Processed Dough & Pepperoni',
        reaction: 'Severe Bloating',
        frequency: pizzaOccurrences.length,
        confidence: BodyPattern.confidenceHigh,
        description: 'Your logs show a very strong link between pepperoni pizza and significant bloating within 3 hours.',
        involvedFoods: const ['Pepperoni Pizza', 'Garlic Bread'],
        recommendation: 'Try a sourdough crust or skip the pepperoni to see if it reduces the reaction.',
        updatedAt: now.toIso8601String(),
        occurrences: pizzaOccurrences,
        evidenceRatio: 0.85,
        positiveCount: pizzaOccurrences.length,
        totalSimilarMeals: pizzaOccurrences.length,
        timeframeDays: 14,
        commonFactors: const [
          CommonFactor(label: 'Late Night', icon: 'moon'),
          CommonFactor(label: 'Processed Meat', icon: 'beef'),
        ],
      ),
      BodyPattern(
        type: 'sensitivity',
        trigger: 'Dairy & Aged Cheese',
        reaction: 'Skin Flare-up',
        frequency: 5,
        confidence: BodyPattern.confidenceModerate,
        description: 'We noticed periodic skin flare-ups following meals high in dairy or aged cheese.',
        involvedFoods: const ['Creamy Pasta Carbonara', 'Parmesan Cheese'],
        recommendation: 'Monitor your skin closely after dairy intake or try a 1-week elimination.',
        updatedAt: now.toIso8601String(),
        evidenceRatio: 0.8,
        positiveCount: 5,
        totalSimilarMeals: 6,
        timeframeDays: 14,
        commonFactors: const [CommonFactor(label: 'Dairy', icon: 'cheese')],
      ),
      BodyPattern(
        type: BodyPattern.typeHeadache,
        trigger: 'Caffeine & Refined Sugar',
        reaction: 'Dull Headache',
        frequency: headacheOccurrences.length,
        confidence: BodyPattern.confidenceModerate,
        description: 'Headaches often follow your double espresso when paired with sugar.',
        involvedFoods: const ['Double Espresso', 'Sugar Packet'],
        recommendation: 'Try reducing the sugar or drinking more water with your coffee.',
        updatedAt: now.toIso8601String(),
        occurrences: headacheOccurrences,
        evidenceRatio: 0.7,
        positiveCount: headacheOccurrences.length,
        totalSimilarMeals: headacheOccurrences.length + 3,
        timeframeDays: 14,
        commonFactors: const [CommonFactor(label: 'Dehydration', icon: 'droplet')],
      ),
    ];

    await _insightFirestoreService.savePatternData(patterns);

    final rangeStart = now.subtract(const Duration(days: 6));
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final bestDay = weekdays[now.subtract(const Duration(days: 2)).weekday - 1];

    final latestInsight = AIInsight(
      gutScore: 50,
      scoreDiff: '+6',
      updatedAt: now,
      status: AIInsight.statusReady,
      origin: AIInsight.originClient,
      periodFrom: rangeStart,
      periodTo: now,
      evidence: InsightEvidence.fromPatterns(patterns, sampleSizes: const SampleSizes(meals: 32, symptoms: 12, scans: 11)),
      topInsight: const InsightSummary(title: 'Meals with whole foods are showing up more often.', description: 'Keep it up! Real food makes a difference.', type: 'Behavioral', strength: 'High'),
      healingTrend: 'More fiber this week settled your digestion.',
      healingFoods: const [
        HealingFood(name: 'Berries', effect: 'Antioxidant boost', emoji: '🫐', imageUrl: berriesPhoto, userImageUrl: berriesPhoto),
        HealingFood(name: 'Chicken', effect: 'Lean protein', emoji: '🍗', imageUrl: chickenPhoto, userImageUrl: chickenPhoto),
        HealingFood(name: 'Apples', effect: 'Gentle fiber', emoji: '🍎', imageUrl: applesPhoto, userImageUrl: applesPhoto),
      ],
      triggerTrend: 'Late salty dinners lined up with your bloating.',
      triggerFoods: const [TriggerFood(name: 'French Fries', effect: 'Headaches', emoji: '🍟', imageUrl: friesThumb, userImageUrl: friesThumb)],
      detectedPatterns: patterns,
      topHealing: const TopHighlight(
        food: 'Fiber',
        effects: 'Great job! Higher fiber supports a happy gut.',
        timeframe: 'this week',
        frequency: '4x this week',
        emoji: '🥬',
        imageUrl: berriesPhoto,
        userImageUrl: berriesPhoto,
      ),
      topTrigger: const TopHighlight(
        food: 'Sodium',
        effects: 'Try earlier, lower-sodium options when possible.',
        timeframe: 'this week',
        frequency: '3x this week',
        emoji: '🧂',
        imageUrl: friesThumb,
        userImageUrl: friesThumb,
      ),
      foodImpacts: const [
        FoodImpact(food: 'Berries', dateLabel: 'Mon', effect: 'Steady energy', timeframeLabel: 'Breakfast', emoji: '🫐', impactType: 'positive', imageUrl: berriesPhoto, userImageUrl: berriesPhoto),
        FoodImpact(food: 'Chicken', dateLabel: 'Mon', effect: 'Lean protein', timeframeLabel: 'Lunch', emoji: '🍗', impactType: 'positive', imageUrl: chickenPhoto, userImageUrl: chickenPhoto),
        FoodImpact(food: 'Apples', dateLabel: 'Mon', effect: 'Gentle fiber', timeframeLabel: 'Snack', emoji: '🍎', impactType: 'positive', imageUrl: applesPhoto, userImageUrl: applesPhoto),
        FoodImpact(food: 'Berries', dateLabel: 'Tue', effect: 'Steady energy', timeframeLabel: 'Breakfast', emoji: '🫐', impactType: 'positive', imageUrl: berriesPhoto, userImageUrl: berriesPhoto),
        FoodImpact(food: 'French Fries', dateLabel: 'Tue', effect: 'Headaches', timeframeLabel: 'Dinner', emoji: '🍟', impactType: 'negative', imageUrl: friesThumb, userImageUrl: friesThumb),
        FoodImpact(food: 'Chicken', dateLabel: 'Wed', effect: 'Lean protein', timeframeLabel: 'Lunch', emoji: '🍗', impactType: 'positive', imageUrl: chickenPhoto, userImageUrl: chickenPhoto),
        FoodImpact(food: 'Apples', dateLabel: 'Wed', effect: 'Gentle fiber', timeframeLabel: 'Snack', emoji: '🍎', impactType: 'positive', imageUrl: applesPhoto, userImageUrl: applesPhoto),
        FoodImpact(food: 'Berries', dateLabel: 'Thu', effect: 'Steady energy', timeframeLabel: 'Breakfast', emoji: '🫐', impactType: 'positive', imageUrl: berriesPhoto, userImageUrl: berriesPhoto),
        FoodImpact(food: 'French Fries', dateLabel: 'Thu', effect: 'Headaches', timeframeLabel: 'Dinner', emoji: '🍟', impactType: 'negative', imageUrl: friesThumb, userImageUrl: friesThumb),
        FoodImpact(food: 'Chicken', dateLabel: 'Fri', effect: 'Lean protein', timeframeLabel: 'Dinner', emoji: '🍗', impactType: 'positive', imageUrl: chickenPhoto, userImageUrl: chickenPhoto),
        FoodImpact(food: 'Apples', dateLabel: 'Sat', effect: 'Gentle fiber', timeframeLabel: 'Snack', emoji: '🍎', impactType: 'positive', imageUrl: applesPhoto, userImageUrl: applesPhoto),
        FoodImpact(food: 'Berries', dateLabel: 'Sat', effect: 'Steady energy', timeframeLabel: 'Breakfast', emoji: '🫐', impactType: 'positive', imageUrl: berriesPhoto, userImageUrl: berriesPhoto),
        FoodImpact(food: 'French Fries', dateLabel: 'Sun', effect: 'Headaches', timeframeLabel: 'Lunch', emoji: '🍟', impactType: 'negative', imageUrl: friesThumb, userImageUrl: friesThumb),
      ],
      weeklyRecap: WeeklyRecap(
        dateRange: '${rangeStart.month}/${rangeStart.day} - ${now.month}/${now.day}',
        avgScore: 50,
        scoreSub: "You're making progress. Keep scanning to get a clearer picture.",
        bestDay: bestDay,
        foodsLogged: 32,
        loggedSub: 'Excellent consistency!',
        highlights: const [
          RecapHighlight(icon: 'sparkles', text: 'Fiber is up 4x this week', color: 'green'),
          RecapHighlight(icon: 'zap', text: 'Stable energy on whole-food days', color: 'blue'),
          RecapHighlight(icon: 'alert-triangle', text: 'Fast food linked to headaches', color: 'red'),
        ],
      ),
    );

    await _insightFirestoreService.saveInsights(latestInsight, useServerTimestamp: false);

    // --- 7-DAY CHART HISTORY (oldest -> newest; explicit dates order the bars) ---
    final pastScores = [38, 40, 39, 42, 41, 44];
    for (var d = 0; d < pastScores.length; d++) {
      await _insightFirestoreService.saveInsights(
        AIInsight(
          gutScore: pastScores[d],
          updatedAt: now.subtract(Duration(days: pastScores.length - d)),
        ),
        useServerTimestamp: false,
      );
    }

    // --- WATCH CARD ALERT (unread -> surfaces on the feed) ---
    await _insightFirestoreService.saveHealthAlert(
      HealthAlert(
        id: '',
        title: '3 of your highest-sodium meals were eaten after 7 PM.',
        message: 'Try earlier, lower-sodium options when possible.',
        type: 'trigger_warning',
        createdAt: now,
        isRead: false,
      ),
    );

    // --- CHAT HISTORY SEEDING ---
    await _seedMockChatHistory(now);

    AppLogger.mock('Complete 30-day history, detailed patterns, and weekly insights generated.');
  }

  Future<void> _seedMockChatHistory(DateTime now) async {
    AppLogger.mock('Seeding mock chat history...');
    final msg1Id = const Uuid().v4();
    final msg2Id = const Uuid().v4();

    // 1. User asks about a meal
    await _chatFirestoreService.saveMessage(
      ChatMessage(
        localId: msg1Id,
        role: 'user',
        text: 'I just had some Greek yogurt with blueberries for breakfast. How is that for my gut?',
        createdAt: now.subtract(const Duration(minutes: 15)),
        source: 'chat',
      ),
    );

    // 2. AI responds with analysis
    await _chatFirestoreService.saveMessage(
      ChatMessage(
        localId: msg2Id,
        role: 'ai',
        text:
            'Great choice! Greek yogurt is excellent for your gut. It provides live probiotic cultures that support your microbiome, and the blueberries add a nice dose of antioxidants and gentle fiber. \n\nI\'ve logged this as a positive meal for you.',
        createdAt: now.subtract(const Duration(minutes: 14)),
        source: 'chat',
        foodMentions: const ['Greek Yogurt', 'Blueberries'],
      ),
    );

    // 3. User asks about bloating
    final msg3Id = const Uuid().v4();
    await _chatFirestoreService.saveMessage(
      ChatMessage(localId: msg3Id, role: 'user', text: 'I feel a bit bloated after that pizza I had last night. Any advice?', createdAt: now.subtract(const Duration(minutes: 5)), source: 'chat'),
    );

    // 4. AI responds with symptom logging and advice
    final msg4Id = const Uuid().v4();
    await _chatFirestoreService.saveMessage(
      ChatMessage(
        localId: msg4Id,
        role: 'ai',
        text:
            'I\'m sorry to hear you\'re feeling uncomfortable. Bloating after pepperoni pizza is a pattern we\'ve noticed in your logs. \n\nTry drinking some warm ginger tea or taking a short walk to help with digestion. I\'ve noted the bloating in your symptoms.',
        createdAt: now.subtract(const Duration(minutes: 4)),
        source: 'chat',
        symptomMentions: const ['Bloating'],
      ),
    );
  }

  /// Seeds two fully-detailed showcase scans (low-score + high-score) on top of
  /// history so the rebuilt Scan Results UI can be previewed end to end:
  /// score breakdown, metric cards, working/watch rows, meaning card, swaps
  /// with + Add, tappable additives, ingredients, allergens and scan details.
  ///
  /// Scores come from the real scoring engine (`yuka_score.dart`), so the
  /// breakdown shown in the UI matches what a live scan would produce.
  Future<void> _seedShowcaseScans(DateTime now) async {
    int scoreFor({String? nutriscore, int? novaGroup, required NutrientData n, required List<String> items, bool organic = false}) => YukaScore.evaluate(
      nutriscore: nutriscore,
      energyKcal: n.calories,
      fiberG: n.fiber,
      proteinG: n.proteins,
      sugarG: n.sugars,
      saltG: n.salt,
      saturatedFatG: n.saturatedFat,
      additiveConcerns: AdditiveConcernDb.resolveAll(items),
      isOrganic: organic,
    ).score;

    // --- SHOWCASE 1: instant noodles (ultra-processed, additive-heavy) -> 28 ---
    const noodlesUrl = 'https://images.unsplash.com/photo-1569718212165-3a8278d5f624?auto=format&fit=crop&w=800&q=80';
    const noodlesHash = 'noodles_mock_hash'; // Usually sha256_16
    await _foodImageService.registerImage(hash: noodlesHash, storagePath: 'users/debug/food_images/$noodlesHash.jpg', downloadUrl: noodlesUrl);

    const noodlesNutrients = NutrientData(calories: 420, fat: 15, saturatedFat: 7, carbs: 62, sugars: 3, fiber: 5.2, proteins: 8, salt: 2.2);
    const noodlesItems = ['E621', 'E631', 'Palm Oil'];
    await _historyFirestoreService.saveToScanHistory(
      ScanResult(
        productName: 'Masala Instant Noodles',
        brand: 'Maggi',
        score: scoreFor(nutriscore: 'C', novaGroup: 4, n: noodlesNutrients, items: noodlesItems),
        impactType: ImpactType.negative,
        impact:
            'Tasty and convenient, but this is a classic ultra-processed mix: refined flour, palm oil and a heavy hand of sodium and flavour enhancers. Fine as an occasional craving, not as a staple.',
        nutriscore: 'C',
        novaGroup: '4',
        category: 'food',
        source: 'barcode',
        barcode: '8901030821232',
        servingSize: '70g pack (1 serving)',
        imageUrl: noodlesUrl,
        userImageUrl: noodlesUrl,
        nutrients: noodlesNutrients,
        additives: 'Contains flavour enhancers E621, E631 and palm oil.',
        additiveItems: noodlesItems,
        allergens: 'Gluten, Milk',
        ingredients: const [
          Ingredient(name: 'Refined Wheat Flour', impact: 'High-glycemic base, low fiber', colorName: 'red'),
          Ingredient(name: 'Palm Oil', impact: 'High in saturated fat', colorName: 'orange'),
          Ingredient(name: 'Salt', impact: 'High sodium per serving', colorName: 'orange'),
          Ingredient(name: 'Flavour Enhancers (E621, E631)', impact: 'Engineered umami hit', colorName: 'orange'),
          Ingredient(name: 'Dehydrated Vegetables', impact: 'Adds color, little fiber', colorName: 'gray'),
          Ingredient(name: 'Spices & Turmeric', impact: 'Real spice, tiny quantity', colorName: 'green'),
        ],
        impacts: const [ImpactDetail(title: 'Quick comfort energy', level: 'good', color: 'green')],
        swaps: const [
          ProductSwap(title: 'Whole Wheat Hakka Noodles', subtitle: 'Same craving, half the sodium', imageKeyword: 'whole wheat noodles', tag: 'Lower sodium'),
          ProductSwap(title: 'Moong Dal Khichdi', subtitle: 'One-pot comfort with real fiber', imageKeyword: 'moong dal khichdi', tag: 'High fiber'),
          ProductSwap(title: 'Veggie Oats Upma', subtitle: 'Ready in 10 minutes, kinder gut', imageKeyword: 'vegetable upma', tag: 'Whole grain'),
        ],
        cycleInsight: const CycleInsight(
          phase: 'Luteal',
          description: 'High-sodium foods can worsen bloating and cravings in your luteal phase. If noodles night happens, pair with water and something potassium-rich like a banana.',
          tags: [CycleTag(text: 'Bloating risk', icon: 'moon', color: 'pink')],
        ),
        createdAt: now,
        isSaved: true,
        nutritionEstimated: false,
      ),
    );

    // --- SHOWCASE 2: greek yogurt (clean label, high score) -> 72 ---
    const yogurtUrl = 'https://images.unsplash.com/photo-1488477181946-6428a0291777?auto=format&fit=crop&w=800&q=80';
    const yogurtHash = 'yogurt_mock_hash';
    await _foodImageService.registerImage(hash: yogurtHash, storagePath: 'users/debug/food_images/$yogurtHash.jpg', downloadUrl: yogurtUrl);

    const yogurtNutrients = NutrientData(calories: 95, fat: 6, saturatedFat: 5, carbs: 7, sugars: 5, fiber: 0, proteins: 9.5, salt: 0.3);
    await _historyFirestoreService.saveToScanHistory(
      ScanResult(
        productName: 'Greek Yogurt - Blueberry',
        brand: 'Epigamia',
        score: scoreFor(nutriscore: 'B', novaGroup: 1, n: yogurtNutrients, items: const []),
        impactType: ImpactType.positive,
        impact: 'A genuinely gut-friendly pick: live cultures, solid protein and modest sugar. The blueberry adds real fruit fiber. Just note the saturated fat if you eat several cups a day.',
        nutriscore: 'B',
        novaGroup: '1',
        category: 'food',
        source: 'barcode',
        barcode: '8908001234567',
        servingSize: '100g cup',
        imageUrl: yogurtUrl,
        userImageUrl: yogurtUrl,
        nutrients: yogurtNutrients,
        additives: 'No additives detected.',
        additiveItems: const [],
        allergens: 'Milk',
        ingredients: const [
          Ingredient(name: 'Milk', impact: 'Fermented into gut-friendly curd', colorName: 'green'),
          Ingredient(name: 'Live Cultures', impact: 'Probiotic strains for your microbiome', colorName: 'green'),
          Ingredient(name: 'Blueberry Pulp', impact: 'Real fruit fiber and color', colorName: 'green'),
          Ingredient(name: 'Sugar', impact: 'Added sugar, modest at 5g', colorName: 'orange'),
        ],
        impacts: const [
          ImpactDetail(title: 'Live probiotic cultures', level: 'positive', color: 'green'),
          ImpactDetail(title: 'High quality protein', level: 'good', color: 'green'),
        ],
        swaps: const [
          ProductSwap(title: 'Homemade Curd', subtitle: 'Zero added sugar, same cultures', imageKeyword: 'homemade curd bowl', tag: 'No added sugar'),
          ProductSwap(title: 'Masala Chaas', subtitle: 'Lighter, spiced, hydrating', imageKeyword: 'masala chaas', tag: 'Light'),
        ],
        cycleInsight: const CycleInsight(
          phase: 'Follicular',
          description: 'Protein-rich foods support your steady follicular-phase energy. A great post-workout choice this week.',
          tags: [CycleTag(text: 'Steady energy', icon: 'sun', color: 'green')],
        ),
        createdAt: now.subtract(const Duration(hours: 1)),
        isSaved: true,
        nutritionEstimated: false,
      ),
    );

    AppLogger.mock('Showcase scans seeded (noodles 28 + yogurt 72).');

    // --- SEED SAVED FOODS ---
    final savedItems = await _historyFirestoreService.getScanHistory(limit: 3);
    for (final item in savedItems) {
      await _historyFirestoreService.toggleSaveFood(item);
    }
    AppLogger.mock('Seeded ${savedItems.length} saved foods.');
  }

  /// 🟢 NEW: Generates an "Insufficient Data" state to test the Learning Grid UI.
  Future<void> generateInsufficientDataState() async {
    AppLogger.mock('Generating insufficient data state (Learning Grid)...');
    final now = DateTime.now();

    // Just enough to show some progress but not unlock (unlock is scans >= 3 OR (meals >= 3 && symptoms >= 1))
    await _historyFirestoreService.logMeal(MealLog(items: const ['Morning Oats'], mealType: 'breakfast', createdAt: now, source: 'debug'));
    await _historyFirestoreService.saveToScanHistory(
      ScanResult(
        productName: 'Sample Yogurt',
        brand: 'Brand',
        score: 70,
        createdAt: now,
        impactType: ImpactType.positive,
        impact: 'High protein and probiotics support gut health.',
        category: 'food',
        source: 'barcode',
      ),
    );

    // Generate an "insufficient" insight envelope
    final insight = AIInsight(
      gutScore: 0,
      updatedAt: now,
      status: AIInsight.statusInsufficientData,
      origin: AIInsight.originClient,
      evidence: const InsightEvidence(sampleSizes: SampleSizes(meals: 1, symptoms: 0, scans: 1), spanDays: 0),
    );

    await _insightFirestoreService.saveInsights(insight, useServerTimestamp: false);
    await _insightFirestoreService.savePatternData([]); // Clear patterns
    AppLogger.mock('Insufficient data state generated.');
  }
}
