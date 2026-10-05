part of 'debug_mock_data_service.dart';

/// Thirty-day pattern-rich debug fixture generation.

extension DebugMockThirtyDays on DebugMockDataService {
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
        'name': 'Strawberry Mint Drink',
        'brand': 'GutGood',
        'score': 70,
        'nutri': 'A',
        'nova': 1,
        'cat': 'food',
        'img': 'https://images.unsplash.com/photo-1551024709-8f23befc6f87?auto=format&fit=crop&w=800&q=80',
      },
      {
        'name': 'Meatball Rice Bowl',
        'brand': 'GutGood',
        'score': 85,
        'nutri': 'A',
        'nova': 1,
        'cat': 'food',
        'img': 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=800&q=80',
      },
      {'name': 'Vegetable Pizza', 'brand': 'Artisan Kitchen', 'score': 72, 'nutri': 'B', 'nova': 2, 'cat': 'food', 'img': pizzaPhoto},
      {
        'name': 'French Toast',
        'brand': 'Bistro 24',
        'score': 65,
        'nutri': 'C',
        'nova': 2,
        'cat': 'food',
        'img': 'https://images.unsplash.com/photo-1484723091739-30a097e8f929?auto=format&fit=crop&w=800&q=80',
      },
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
        commonFactors: const [
          CommonFactor(label: 'Early Dinner', icon: 'utensils'),
          CommonFactor(label: 'Evening', icon: 'moon'),
        ],
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
    final todayStart = DateTime(now.year, now.month, now.day);
    final currentWeekStart = todayStart.subtract(Duration(days: now.weekday % 7));
    final previousWeekStart = currentWeekStart.subtract(const Duration(days: 7));
    final previousWeekEnd = currentWeekStart.subtract(const Duration(microseconds: 1));
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    final bestDay = weekdays[previousWeekStart.add(const Duration(days: 2)).weekday - 1];

    final latestInsight = AIInsight(
      gutScore: 52,
      scoreDiff: '+4',
      healingSummary: const HealingSummary(
        goal: 'Microbiome Diversity',
        trend: 'Probiotic diversity up 40% this week.',
        foods: [
          InsightFood(foodId: 'h_kefir', name: 'Kefir', emoji: '🥛', imageUrl: berriesPhoto, effect: 'Boosts microbiome diversity and reduces inflammation.', impactLevel: 'high'),
          InsightFood(foodId: 'h_leafy', name: 'Leafy Greens', emoji: '🥬', imageUrl: applesPhoto, effect: 'Supports fiber intake and gut barrier.', impactLevel: 'high'),
          InsightFood(foodId: 'h_chicken', name: 'Chicken', emoji: '🍗', imageUrl: chickenPhoto, effect: 'Lean protein for gut repair.', impactLevel: 'medium'),
        ],
      ),
      triggerSummary: const TriggerSummary(
        primarySymptom: 'Bloating & Headaches',
        trend: 'Processed sodium late at night correlates with next-morning headaches.',
        foods: [
          InsightFood(foodId: 't_fries', name: 'French Fries', emoji: '🍟', imageUrl: friesThumb, effect: 'Dull headaches within 2h.', impactLevel: 'high'),
          InsightFood(foodId: 't_pizza', name: 'Pepperoni Pizza', emoji: '🍕', imageUrl: friesThumb, effect: 'Severe bloating within 3h.', impactLevel: 'high'),
        ],
      ),
      updatedAt: now,
      status: AIInsight.statusReady,
      origin: AIInsight.originClient,
      periodFrom: rangeStart,
      periodTo: now,
      evidence: InsightEvidence.fromPatterns(patterns, sampleSizes: const SampleSizes(meals: 42, symptoms: 15, scans: 14)),
      topInsight: const InsightSummary(
        title: 'High-fiber fermented foods are driving your recovery.',
        description: 'You\'ve logged probiotic-rich foods 9 times this week with zero reported bloating.',
        type: 'Behavioral',
        strength: 'High',
        involvedFoods: ['Kefir', 'Kimchi', 'Leafy Greens'],
        frequency: 9,
        evidenceRatio: 1.0,
      ),
      healingTrend: 'Probiotic diversity is up 40% this week.',
      healingFoods: const [
        HealingFood(name: 'Kefir', effect: 'Boosts microbiome diversity and reduces inflammation.', emoji: '🥛', imageUrl: berriesPhoto),
        HealingFood(name: 'Leafy Greens', effect: 'Supports fiber intake and gut barrier.', emoji: '🥬', imageUrl: applesPhoto),
        HealingFood(name: 'Chicken', effect: 'Lean protein for gut repair.', emoji: '🍗', imageUrl: chickenPhoto),
      ],
      triggerTrend: 'Late salty dinners correlate with your headaches.',
      triggerFoods: const [TriggerFood(name: 'French Fries', effect: 'Dull Headaches', emoji: '🍟', imageUrl: friesThumb, userImageUrl: friesThumb)],
      detectedPatterns: patterns,
      topHealing: const TopHighlight(
        food: 'Fermented Foods',
        effects: 'Excellent! Probiotics are stabilizing your gut barrier.',
        timeframe: 'this week',
        frequency: '9x this week',
        emoji: '🥛',
        whyPoints: ['Live strains like L. acidophilus support mucosal health', 'Reduces systemic inflammation markers in logs', 'Correlates with 30% higher reported energy levels'],
      ),
      topTrigger: const TopHighlight(
        food: 'Processed Sodium',
        effects: 'Watch out for late-night salty snacks.',
        timeframe: 'this week',
        frequency: '3x this week',
        emoji: '🧂',
        whyPoints: ['High salt intake disrupts gut osmotic balance', 'Nighttime spikes correlate with poor sleep reports', 'Often paired with inflammatory refined seed oils'],
      ),
      improving: const ImprovingBlock(
        headline: 'Your gut barrier score is up!',
        description: 'Consistent vegetable fiber and probiotic intake is stabilizing your digestion.',
        streakDays: 5,
        streakGoalDays: 7,
        encouragement: 'Keep it up — 2 more days to reach your weekly goal.',
        keyFoods: [
          KeyFoodDriver(name: 'Kefir', count: 5, delta: 4, emoji: '🥛'),
          KeyFoodDriver(name: 'Leafy Greens', count: 4, delta: 2, emoji: '🥬'),
          KeyFoodDriver(name: 'Kimchi', count: 3, delta: 2, emoji: '🥬'),
        ],
      ),
      watch: const WatchBlock(reactionTime: 'About 2 hours later', riskLevel: 'High', windowDays: 14),
      smartSwap: const SmartSwap(
        after: 'Baked Sweet Potato Fries',
        benefit: 'Far less refined oil & double the fiber',
        tip: 'Try swapping fries for baked sweet potato fries to protect your trend.',
        beforeEmoji: '🍟',
        afterEmoji: '🍠',
      ),
      foodImpacts: const [
        FoodImpact(food: 'Strawberry Mint Drink', dateLabel: 'Sat', effect: 'Hydration & energy boost', timeframeLabel: 'Post-workout', emoji: '🍓', impactType: 'positive'),
        FoodImpact(food: 'Meatball Rice Bowl', dateLabel: 'Sat', effect: 'Steady energy & satiety', timeframeLabel: 'Lunch', emoji: '🥣', impactType: 'positive'),
        FoodImpact(food: 'Vegetable Pizza', dateLabel: 'Fri', effect: 'Balanced plant fiber', timeframeLabel: 'Dinner', emoji: '🍕', impactType: 'positive'),
        FoodImpact(food: 'French Toast', dateLabel: 'Sun', effect: 'Morning carbohydrate boost', timeframeLabel: 'Breakfast', emoji: '🍞', impactType: 'positive'),
        FoodImpact(food: 'Kefir', dateLabel: 'Mon', effect: 'Microbiome support', timeframeLabel: 'Breakfast', emoji: '🥛', impactType: 'positive'),
        FoodImpact(food: 'Kefir', dateLabel: 'Tue', effect: 'Microbiome support', timeframeLabel: 'Breakfast', emoji: '🥛', impactType: 'positive'),
        FoodImpact(food: 'Kefir', dateLabel: 'Wed', effect: 'Microbiome support', timeframeLabel: 'Breakfast', emoji: '🥛', impactType: 'positive'),
        FoodImpact(food: 'Kefir', dateLabel: 'Thu', effect: 'Microbiome support', timeframeLabel: 'Breakfast', emoji: '🥛', impactType: 'positive'),
        FoodImpact(food: 'Kefir', dateLabel: 'Fri', effect: 'Microbiome support', timeframeLabel: 'Breakfast', emoji: '🥛', impactType: 'positive'),
        FoodImpact(food: 'Leafy Greens', dateLabel: 'Mon', effect: 'Fiber intake', timeframeLabel: 'Lunch', emoji: '🥬', impactType: 'positive'),
        FoodImpact(food: 'Leafy Greens', dateLabel: 'Tue', effect: 'Fiber intake', timeframeLabel: 'Lunch', emoji: '🥬', impactType: 'positive'),
        FoodImpact(food: 'Leafy Greens', dateLabel: 'Wed', effect: 'Fiber intake', timeframeLabel: 'Lunch', emoji: '🥬', impactType: 'positive'),
        FoodImpact(food: 'Leafy Greens', dateLabel: 'Thu', effect: 'Fiber intake', timeframeLabel: 'Lunch', emoji: '🥬', impactType: 'positive'),
        FoodImpact(food: 'Kimchi', dateLabel: 'Mon', effect: 'Probiotic boost', timeframeLabel: 'Dinner', emoji: '🥬', impactType: 'positive'),
        FoodImpact(food: 'Kimchi', dateLabel: 'Wed', effect: 'Probiotic boost', timeframeLabel: 'Dinner', emoji: '🥬', impactType: 'positive'),
        FoodImpact(food: 'Kimchi', dateLabel: 'Fri', effect: 'Probiotic boost', timeframeLabel: 'Dinner', emoji: '🥬', impactType: 'positive'),
        FoodImpact(food: 'Sourdough', dateLabel: 'Tue', effect: 'Prebiotic base', timeframeLabel: 'Breakfast', emoji: '🍞', impactType: 'positive'),
        FoodImpact(food: 'Sourdough', dateLabel: 'Thu', effect: 'Prebiotic base', timeframeLabel: 'Breakfast', emoji: '🍞', impactType: 'positive'),
        FoodImpact(food: 'Greek Yogurt', dateLabel: 'Mon', effect: 'Steady energy', timeframeLabel: 'Snack', emoji: '🥣', impactType: 'positive'),
        FoodImpact(food: 'French Fries', dateLabel: 'Tue', effect: 'Headache trigger', timeframeLabel: 'Dinner', emoji: '🍟', impactType: 'negative', imageUrl: friesThumb, userImageUrl: friesThumb),
      ],
      foodImpactBalance: const FoodImpactBalance(positivePercent: 81, neutralPercent: 12, negativePercent: 7, periodLabel: 'Last 4 weeks'),
      actionsList: const [
        InsightAction(
          id: 'act_01',
          title: 'Increase prebiotic vegetables',
          description: 'Add more leafy greens, onions, and garlic to support gut flora.',
          category: 'nutrition',
          whenToDo: 'With lunch or dinner',
          expectedBenefit: 'Improves gut microbiome diversity and reduces bloating risk.',
          impactLevel: 'high',
          difficulty: 'Easy',
        ),
        InsightAction(
          id: 'act_02',
          title: 'Maintain daily kefir intake',
          description: 'Keep up your 1 serving of kefir per day for steady probiotic support.',
          category: 'nutrition',
          whenToDo: 'Every morning with breakfast',
          expectedBenefit: 'Stabilizes gut mucosal barrier and supports smooth digestion.',
          impactLevel: 'high',
          difficulty: 'Easy',
        ),
      ],
      foodSwaps: const [
        FoodSwap(
          id: 'swap_01',
          source: SwapSource(foodId: 'f_fries', name: 'French Fries'),
          alternatives: [
            SwapAlternative(
              foodId: 'f_sweet_potato',
              name: 'Baked Sweet Potato Wedges',
              reason: 'Far less refined oil and double the fiber.',
              impactLevel: 'high',
              category: 'Sides',
              benefits: [
                SwapBenefit(title: 'Double Fiber', description: 'Supports healthy gut motility', icon: 'sprout'),
                SwapBenefit(title: 'Lower Fat', description: 'Gentle on stomach lining', icon: 'leaf'),
              ],
              whyBetterOption: 'Baking sweet potatoes avoids heavy frying oils while delivering prebiotic fiber and beta-carotene.',
              nutrition: SwapNutrition(calories: 220, protein: '4g', totalFat: '4g', fiber: '6g'),
            ),
            SwapAlternative(
              foodId: 'f_air_fried_zucchini',
              name: 'Air-Fried Zucchini Fries',
              reason: 'Crispy low-carb alternative made with minimal olive oil.',
              impactLevel: 'high',
              category: 'Sides',
              benefits: [
                SwapBenefit(title: 'Low Calorie', description: 'Prevents post-meal sluggishness', icon: 'flame'),
                SwapBenefit(title: 'High Hydration', description: 'Easy on digestion', icon: 'droplet'),
              ],
              whyBetterOption: 'Air frying zucchini gives a satisfying crunch without gut-irritating hydrogenated oils.',
              nutrition: SwapNutrition(calories: 140, protein: '3g', totalFat: '3g', fiber: '4g'),
            ),
            SwapAlternative(
              foodId: 'f_roasted_chickpeas',
              name: 'Crispy Roasted Chickpeas',
              reason: 'Prebiotic rich crunch high in plant protein and fiber.',
              impactLevel: 'moderate',
              category: 'Sides & Snacks',
              benefits: [
                SwapBenefit(title: 'Plant Protein', description: 'Keeps you full longer', icon: 'dumbbell'),
                SwapBenefit(title: 'Prebiotic Fiber', description: 'Feeds healthy gut flora', icon: 'shield'),
              ],
              whyBetterOption: 'Oven roasted chickpeas provide crunch paired with beneficial fibers that feed good gut bacteria.',
              nutrition: SwapNutrition(calories: 180, protein: '8g', totalFat: '4g', fiber: '7g'),
            ),
            SwapAlternative(
              foodId: 'f_kale_chips',
              name: 'Sea Salt Kale Chips',
              reason: 'Nutrient dense greens packed with antioxidants.',
              impactLevel: 'moderate',
              category: 'Snacks',
              benefits: [
                SwapBenefit(title: 'Antioxidant Rich', description: 'Reduces gut oxidative stress', icon: 'sparkles'),
                SwapBenefit(title: 'Light Digesting', description: 'Leaves stomach comfortable', icon: 'sun'),
              ],
              whyBetterOption: 'Lightly baked kale provides essential vitamins and minerals without heavy saturated fats.',
              nutrition: SwapNutrition(calories: 110, protein: '3g', totalFat: '5g', fiber: '3g'),
            ),
          ],
        ),
      ],
      weeklyRecap: WeeklyRecap(
        dateRange: '${previousWeekStart.month}/${previousWeekStart.day} - ${previousWeekEnd.month}/${previousWeekEnd.day}',
        periodFrom: previousWeekStart,
        periodTo: previousWeekEnd,
        gutScoreTrend: const [0, 48, 52, 0, 58, 60, 62],
        avgScore: 52,
        scoreSub: '5 of 7 days scored',
        summary: "You're trending upwards! Your probiotic consistency is making a visible impact.",
        bestDay: bestDay,
        foodsLogged: 42,
        loggedSub: 'Top 5% of active users!',
        highlights: const [
          RecapHighlight(icon: 'sparkles', text: 'Fermented foods logged 9x', color: 'green'),
          RecapHighlight(icon: 'zap', text: 'Stable energy on 85% of days', color: 'blue'),
          RecapHighlight(icon: 'alert-triangle', text: 'Late sodium linked to headaches', color: 'red'),
        ],
      ),
    );

    await _insightFirestoreService.saveInsights(latestInsight, useServerTimestamp: false);

    // --- SEED ACTIVE GUT EXPERIMENT DATA ---
    final expStart = now.subtract(const Duration(days: 3));
    final mockExperiment = GutExperiment(
      id: 'exp_mock_${now.millisecondsSinceEpoch}',
      actionId: 'act_01',
      title: '7-Day Dairy-Free Trial',
      hypothesis: 'Testing whether removing dairy for 7 days reduces skin flare-ups and bloating frequency.',
      targetDays: 7,
      startDate: expStart,
      endDate: expStart.add(const Duration(days: 7)),
      status: 'active',
      triggerFood: 'Dairy',
      baselineSymptomRate: 'high',
      checkIns: {
        '${expStart.year}-${expStart.month.toString().padLeft(2, '0')}-${expStart.day.toString().padLeft(2, '0')}': ExperimentDailyCheckIn(
          date: '${expStart.year}-${expStart.month.toString().padLeft(2, '0')}-${expStart.day.toString().padLeft(2, '0')}',
          adhered: true,
          hadSymptoms: false,
        ),
        '${expStart.add(const Duration(days: 1)).year}-${expStart.add(const Duration(days: 1)).month.toString().padLeft(2, '0')}-${expStart.add(const Duration(days: 1)).day.toString().padLeft(2, '0')}':
            ExperimentDailyCheckIn(
              date:
                  '${expStart.add(const Duration(days: 1)).year}-${expStart.add(const Duration(days: 1)).month.toString().padLeft(2, '0')}-${expStart.add(const Duration(days: 1)).day.toString().padLeft(2, '0')}',
              adhered: true,
              hadSymptoms: false,
            ),
        '${expStart.add(const Duration(days: 2)).year}-${expStart.add(const Duration(days: 2)).month.toString().padLeft(2, '0')}-${expStart.add(const Duration(days: 2)).day.toString().padLeft(2, '0')}':
            ExperimentDailyCheckIn(
              date:
                  '${expStart.add(const Duration(days: 2)).year}-${expStart.add(const Duration(days: 2)).month.toString().padLeft(2, '0')}-${expStart.add(const Duration(days: 2)).day.toString().padLeft(2, '0')}',
              adhered: false,
              hadSymptoms: true,
              notes: 'Had some cheese at dinner accidentally.',
            ),
      },
    );
    await _insightFirestoreService.saveActiveExperiment(mockExperiment);
    AppLogger.mock('Seeded mock active gut experiment: ${mockExperiment.title}');

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

}
