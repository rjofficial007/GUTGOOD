part of 'debug_mock_data_service.dart';

/// Debug showcase-scan fixture generation.

extension DebugMockShowcaseScans on DebugMockDataService {
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

    // --- SHOWCASE 3: photo scan; the uploaded photo is the display image ---
    const photoMealUrl = 'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=800&q=80';
    await _historyFirestoreService.saveToScanHistory(
      ScanResult(
        productName: 'Chicken & Grain Bowl',
        brand: 'GutGood',
        score: 81,
        impactType: ImpactType.positive,
        impact: 'A balanced meal with protein, whole grains, and vegetables.',
        category: 'food',
        source: 'photo',
        userImageUrl: photoMealUrl,
        nutrients: const NutrientData(calories: 520, fat: 18, saturatedFat: 4, carbs: 58, sugars: 7, fiber: 9, proteins: 32, salt: 0.8),
        createdAt: now.subtract(const Duration(hours: 2)),
        isSaved: true,
        nutritionEstimated: true,
      ),
    );

    AppLogger.mock('Showcase scans seeded (barcode products, photo meal + menu).');

    // --- SEED MENU SCAN SHOWCASE ---
    await _historyFirestoreService.saveToScanHistory(
      ScanResult(
        productName: 'Avocado Toast & Poached Egg',
        brand: 'The Breakfast Club',
        score: 78,
        impactType: ImpactType.positive,
        impact: 'A nutrient-dense menu pick. High in healthy fats and quality protein, with a solid fiber base from sourdough.',
        category: 'menu',
        source: 'menu',
        imageUrl: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?auto=format&fit=crop&w=500&q=80',
        userImageUrl: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?auto=format&fit=crop&w=500&q=80',
        createdAt: now.subtract(const Duration(days: 2)),
        isSaved: true,
      ),
    );

    // --- SEED SAVED FOODS ---
    final savedItems = await _historyFirestoreService.getScanHistory(limit: 3);
    for (final item in savedItems) {
      await _historyFirestoreService.toggleSaveFood(item);
    }
    AppLogger.mock('Seeded ${savedItems.length} saved foods.');
  }
}
