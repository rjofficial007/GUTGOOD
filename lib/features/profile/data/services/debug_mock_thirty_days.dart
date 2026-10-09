part of 'debug_mock_data_service.dart';

/// Thirty-day pattern-rich debug fixture generation.

extension DebugMockThirtyDays on DebugMockDataService {
  Future<void> generateThirtyDaysData() async {
    AppLogger.mock('Generating 30 days of structured pattern-rich data...');

    final now = DateTime.now();

    const oatsPhoto = 'https://images.unsplash.com/photo-1517673400267-0251440c45dc?auto=format&fit=crop&w=800&q=80';
    const shakePhoto = 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?auto=format&fit=crop&w=800&q=80';
    const espressoPhoto = 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?auto=format&fit=crop&w=800&q=80';
    const saladPhoto = 'https://images.unsplash.com/photo-1540420773420-3366772f4999?auto=format&fit=crop&w=800&q=80';
    const pizzaPhoto = 'https://images.unsplash.com/photo-1513104890138-7c749659a591?auto=format&fit=crop&w=800&q=80';
    const salmonPhoto = 'https://images.unsplash.com/photo-1467003909585-2f8a72700288?auto=format&fit=crop&w=800&q=80';

    for (var i = 0; i < 30; i++) {
      final date = DateTime(now.year, now.month, now.day - i);
      // Anchor the fixture pattern to the calendar date so rerunning after
      // midnight rewrites the same mock records instead of shifting them.
      final dayIndex = DateTime.utc(date.year, date.month, date.day).difference(DateTime.utc(2000)).inDays;
      // Patterns spread across 30 days for higher confidence
      final isPizzaDay = dayIndex % 4 == 0; // Bloating every 4 days
      final isEnergyDay = dayIndex % 3 == 0; // High Energy every 3 days
      final isHeadacheDay = dayIndex % 5 == 0; // Headache every 5 days
      final isDigestionDay = dayIndex % 7 == 0; // Digestion every 7 days
      final isFullnessDay = dayIndex % 2 == 0; // Fullness every 2 days
      final isSleepDay = dayIndex % 3 == 0; // Poor sleep linked to late eating
      final isDairyDay = dayIndex % 6 == 0; // Skin Flare-up linked to Dairy

      // --- LOG MEALS ---
      // Breakfast
      await _logMockMeal(
        MealLog(
          items: isFullnessDay ? const ['Steel Cut Oats', 'Walnuts', 'Blueberries'] : const ['White Toast', 'Jam'],
          foodTags: isFullnessDay ? const ['whole_grains', 'high_fiber'] : const ['high_sugar'],
          mealType: 'breakfast',
          photoUrl: isFullnessDay ? oatsPhoto : null,
          createdAt: DateTime(date.year, date.month, date.day, 8, 0),
          source: 'debug',
        ),
      );

      // Mid-Morning (Pattern triggers)
      if (isEnergyDay) {
        final time = DateTime(date.year, date.month, date.day, 10, 30);
        await _logMockMeal(MealLog(items: const ['Whey Protein Shake', 'Banana'], foodTags: const ['dairy'], mealType: 'snack', photoUrl: shakePhoto, createdAt: time, source: 'debug'));
      }
      if (isHeadacheDay) {
        final time = DateTime(date.year, date.month, date.day, 9, 0);
        await _logMockMeal(MealLog(items: const ['Double Espresso', 'Sugar Packet'], foodTags: const ['caffeine'], mealType: 'snack', photoUrl: espressoPhoto, createdAt: time, source: 'debug'));
      }

      // Lunch
      await _logMockMeal(
        MealLog(
          items: isDigestionDay ? const ['Spicy Street Tacos', 'Jalapeños', 'Corn Tortilla'] : const ['Grilled Chicken Salad', 'Vinaigrette', 'Avocado'],
          foodTags: isDigestionDay ? const ['spicy'] : const ['high_fiber'],
          mealType: 'lunch',
          photoUrl: saladPhoto,
          createdAt: DateTime(date.year, date.month, date.day, 13, 0),
          source: 'debug',
        ),
      );

      // Dinner
      if (isPizzaDay) {
        final time = DateTime(date.year, date.month, date.day, 19, 0);
        await _logMockMeal(MealLog(items: const ['Pepperoni Pizza', 'Garlic Bread', 'Soda'], foodTags: const ['dairy', 'processed_meat'], mealType: 'dinner', photoUrl: pizzaPhoto, createdAt: time, source: 'debug'));
      } else if (isDairyDay) {
        await _logMockMeal(MealLog(items: const ['Creamy Pasta Carbonara', 'Parmesan Cheese'], foodTags: const ['dairy'], mealType: 'dinner', createdAt: DateTime(date.year, date.month, date.day, 19, 30), source: 'debug'));
      } else {
        await _logMockMeal(
          MealLog(items: const ['Steamed Salmon', 'Broccoli', 'Brown Rice'], foodTags: const ['whole_grains'], mealType: 'dinner', photoUrl: salmonPhoto, createdAt: DateTime(date.year, date.month, date.day, 19, 0), source: 'debug'),
        );
      }

      // Late Night
      if (isSleepDay) {
        await _logMockMeal(MealLog(items: const ['Red Wine', 'Dark Chocolate'], foodTags: const ['alcohol'], mealType: 'snack', createdAt: DateTime(date.year, date.month, date.day, 22, 0), source: 'debug'));
      }

      // --- LOG SYMPTOMS (REACTIONS) ---

      // Morning Fullness Check
      if (isFullnessDay) {
        await _logMockSymptom(
          SymptomLog(
            symptom: 'Sustained Fullness',
            severity: 1,
            mood: 'Content',
            foodName: 'Steel Cut Oats',
            notes: 'Feeling satisfied long after breakfast.',
            createdAt: DateTime(date.year, date.month, date.day, 10, 30),
            source: 'debug',
          ),
        );
      }

      // Energy Spike
      if (isEnergyDay) {
        await _logMockSymptom(
          SymptomLog(
            symptom: 'High Energy',
            severity: 2,
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
        await _logMockSymptom(
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
        await _logMockSymptom(
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
        await _logMockSymptom(
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
      if (isDairyDay && !isPizzaDay) {
        await _logMockSymptom(
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
        final nextDay = DateTime(date.year, date.month, date.day + 1);
        await _logMockSymptom(
          SymptomLog(
            symptom: 'Restless Sleep',
            severity: 4,
            sleep: 'Poor',
            notes: 'Woke up multiple times.',
            createdAt: DateTime(nextDay.year, nextDay.month, nextDay.day, 7, 0),
            occurredAt: DateTime(date.year, date.month, date.day, 23, 0),
            source: 'debug',
          ),
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
      final scanDayOffset = scanProducts.length == 1 ? 0 : (i * 29 ~/ (scanProducts.length - 1));
      await _saveMockScan(
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
          createdAt: now.subtract(Duration(days: scanDayOffset)),
          source: p['cat'] == 'food' ? 'barcode' : p['cat'] as String,
          consumed: p['cat'] == 'food',
          isSaved: i < 5,
        ),
        scanId: 'debug_mock_product_$i',
      );
    }

    // --- SHOWCASE SCANS: fully-detailed bad + good products for the Scan Results UI ---
    await _seedShowcaseScans(now);

    // --- SEED ACTIVE GUT EXPERIMENT DATA ---
    final expStart = now.subtract(const Duration(days: 3));
    final mockExperiment = GutExperiment(
      id: 'exp_mock_thirty_days',
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

    // --- CHAT HISTORY SEEDING ---
    await _seedMockChatHistory(now);

    // Run the same deterministic pipeline used by the Insights screen after all
    // mock source records have been written.
    await _generateInsightUseCase.execute(force: true);

    AppLogger.mock('Complete 30-day mock history and rule-generated Insights refreshed.');
  }
}
