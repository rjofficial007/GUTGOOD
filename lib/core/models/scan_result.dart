import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:gutgood/core/data/additive_concern_db.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/utils/date_time_utils.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/model_utils.dart';

/// Categorizes the directional impact of a product on gut health.
enum ImpactType { positive, neutral, negative }

/// Represents the exhaustive result of an AI product analysis.
///
/// This model encapsulates all the data points required to render
/// the [ScanResultScreen], including nutrient levels, ingredient breakdown,
/// and hormonal cycle insights.
class ScanResult extends Equatable {
  const ScanResult({
    required this.productName,
    required this.brand,
    this.category,
    this.imageUrl,
    required this.score,
    required this.impactType,
    required this.impact,
    this.badge,
    this.nutriscore,
    this.novaGroup,
    this.allergens,
    this.additives,
    this.additiveItems = const [],
    this.ingredients = const [],
    this.nutrients,
    this.nutrientLevels,
    this.impacts = const [],
    this.swaps = const [],
    this.cycleInsight,
    this.barcode,
    this.source,
    this.userImageUrl,
    this.flaggedIngredients = const [],
    this.isSaved = false,
    this.scanId,
    this.chatMessageId,
    this.servingSize,
    required this.createdAt,
    this.rawData,
    this.nutritionEstimated = false,
  });

  factory ScanResult.fromMap(Map<String, dynamic> map) {
    var type = ImpactType.neutral;
    final it = map['impactType']?.toString().toLowerCase();
    if (it == 'positive' || it == 'healing') type = ImpactType.positive;
    if (it == 'negative' || it == 'trigger') type = ImpactType.negative;

    // 🟢 FIXED: category is normalized to lowercase
    final category = map['category']?.toString().toLowerCase();

    // 🟢 FIXED: novaGroup is normalized to a plain "1".."4" string
    String? normalizedNova;
    final rawNova = map['novaGroup'];
    final novaInt = rawNova is num ? rawNova.toInt() : int.tryParse(rawNova?.toString() ?? '');
    if (novaInt != null && novaInt >= 1 && novaInt <= 4) {
      normalizedNova = novaInt.toString();
    }

    // 🟢 FIXED: score is now clamped 0-100 via ModelUtils.parseScore instead
    // of trusting the AI's raw integer verbatim.
    var score = ModelUtils.parseScore(map['score']);

    // 🚀 Professional Fallback: If AI returns 0 for a meal/food/menu scan, calculate a heuristic score
    // based on NOVA group, nutrient levels, and meal balance.
    if (score == 0 && (category == 'meal' || category == 'food' || category == 'menu')) {
      final mealBlock = map['meal'] is Map ? Map<String, dynamic>.from(map['meal'] as Map) : (map['rawData']?['meal'] is Map ? Map<String, dynamic>.from(map['rawData']['meal'] as Map) : null);

      score = ModelUtils.computeMealScore(
        novaGroup: novaInt,
        balance: mealBlock?['balance'] is Map ? Map<String, dynamic>.from(mealBlock!['balance'] as Map) : null,
        nutrientLevels: map['nutrientLevels'] is Map ? Map<String, dynamic>.from(map['nutrientLevels'] as Map) : null,
        impactType: it,
      );
    }

    if (map['impactType'] == null) {
      if (score > 70) {
        type = ImpactType.positive;
      } else if (score < 40) {
        type = ImpactType.negative;
      }
    }

    // 🟢 FIXED: nutriscore is normalized to uppercase A-E
    String? normalizedNutriscore;
    final rawNutriscore = map['nutriscore']?.toString().trim().toUpperCase();
    if (rawNutriscore != null && {'A', 'B', 'C', 'D', 'E'}.contains(rawNutriscore)) {
      normalizedNutriscore = rawNutriscore;
    }

    // 🚀 Robust Data Extraction: Unpack rawData if it was stored as a field in Firestore.
    // This handles both direct AI results and hydrated records from History.
    Map<String, dynamic> resolvedRaw;
    if (map['rawData'] is Map) {
      resolvedRaw = Map<String, dynamic>.from(map['rawData'] as Map);
    } else {
      // 🟢 Fix: Never store Firestore Timestamps in rawData to prevent jsonEncode crashes.
      resolvedRaw = Map<String, dynamic>.from(map);
      resolvedRaw.forEach((key, value) {
        if (value is Timestamp) {
          resolvedRaw[key] = value.toDate().toIso8601String();
        }
      });
    }

    return ScanResult(
      productName: _extractProductName(map),
      brand: map['brand']?.toString() ?? map['restaurantName']?.toString() ?? 'GutGood',
      category: category,
      imageUrl: map['imageUrl']?.toString(),
      score: score,
      impactType: type,
      impact: map['impact']?.toString() ?? map['meal']?['summary']?.toString() ?? map['rawData']?['meal']?['summary']?.toString() ?? '',
      badge: map['badge']?.toString(),
      nutriscore: normalizedNutriscore,
      novaGroup: normalizedNova,
      allergens: ModelUtils.parseString(map['allergens']),
      additives: ModelUtils.parseString(map['additives']),
      additiveItems: _additiveItemsFrom(map),
      ingredients: ModelUtils.parseModelList<Ingredient>(map['ingredients'], Ingredient.fromMap),
      nutrients: ModelUtils.parseNestedModel<NutrientData>(map['nutrients'], NutrientData.fromMap),
      nutrientLevels: ModelUtils.parseNestedModel<NutrientLevels>(map['nutrientLevels'], NutrientLevels.fromMap),
      impacts: ModelUtils.parseModelList<ImpactDetail>(map['impacts'], ImpactDetail.fromMap),
      // 🚀 Robust Recovery: Check primary field and rawData block for swaps.
      // We check for null or empty list to ensure old data with empty swaps is fixed.
      swaps: ModelUtils.parseModelList<ProductSwap>((map['swaps'] is List && (map['swaps'] as List).isNotEmpty) ? map['swaps'] : (resolvedRaw['swaps'] ?? map['swaps']), ProductSwap.fromMap),
      cycleInsight: ModelUtils.parseNestedModel<CycleInsight>(map['cycleInsight'], CycleInsight.fromMap),
      barcode: map['barcode']?.toString(),
      source: map['source']?.toString(),
      // 🚀 Professional Image Fallback: Handles multiple common field names from AI and Firestore
      userImageUrl:
          ModelUtils.parseString(map['userImageUrl']) ?? ModelUtils.parseString(map['scanImage']) ?? ModelUtils.parseString(map['menuImage']) ?? ModelUtils.parseString(map['user_image_url']),
      flaggedIngredients: ModelUtils.parseList<String>(map['flaggedIngredients']),
      isSaved: ModelUtils.parseBool(map['isSaved']),
      // 🚀 Robust ID Parsing: Supports both 'scanId' and legacy 'id' keys
      scanId: (map['scanId'] ?? map['id'])?.toString(),
      chatMessageId: map['chatMessageId']?.toString(),
      servingSize: map['servingSize']?.toString(),
      createdAt: DateTimeUtils.parse(map['createdAt'] ?? map['timestamp'] ?? map['time']),
      rawData: resolvedRaw,
      // 🚀 audit §F.2/§O item 6: the AI is explicitly instructed to
      // APPROXIMATE nutrition fields for home-cooked/unpackaged meals
      // (VisionSafetyPrompt's estimation exception) rather than leave them
      // null. `nutritionEstimated` lets the UI honestly label those
      // approximated macros instead of presenting them with the same visual
      // authority as a barcode-scanned fact. Default to `true` for
      // meal/food/menu categories even if the model omits the flag, since
      // those categories are estimated by prompt design; packaged/labeled
      // products default to `false` (label-sourced facts).
      nutritionEstimated: map['nutritionEstimated'] != null ? ModelUtils.parseBool(map['nutritionEstimated']) : (category == 'meal' || category == 'food' || category == 'menu'),
    );
  }

  /// The official name of the product.
  final String productName;

  /// The manufacturing brand.
  final String brand;

  /// The category of the scan (e.g., 'food', 'menu', 'label').
  final String? category;

  /// URL to the product's image (usually front-facing).
  final String? imageUrl;

  /// Calculated gut health score (0-100).
  final int score;

  /// The general impact category (e.g., healing vs trigger).
  final ImpactType impactType;

  /// Narrative summary of the product's effect on gut health.
  final String impact;

  /// Optional highlight badge text (e.g., "CLEAN CHOICE").
  final String? badge;

  /// Nutri-Score grade (A-E).
  final String? nutriscore;

  /// NOVA processing group (1-4).
  final String? novaGroup;

  /// Summary of detected allergens based on user profile.
  final String? allergens;

  /// Summary of detected additives or ultra-processed components.
  final String? additives;

  /// Per-additive items (E-codes / names, e.g. ['E621', 'E631', 'Palm Oil']).
  /// Parsed from the legacy [additives] summary when absent, so old scans
  /// still get per-additive detail views and concern-based scoring.
  final List<String> additiveItems;

  /// Resolved concern profiles for [additiveItems], de-duplicated.
  List<AdditiveConcern> get additiveConcerns => AdditiveConcernDb.resolveAll(additiveItems);

  /// List of identified ingredients with their individual risk levels.
  final List<Ingredient> ingredients;

  /// Breakdown of caloric and macronutrient values per 100g.
  final NutrientData? nutrients;

  /// Standardized nutrient levels (low/moderate/high) for salt, sugar, fat.
  final NutrientLevels? nutrientLevels;

  /// Mapping of specific body impacts (e.g., inflammation, satiety).
  final List<ImpactDetail> impacts;

  /// Healthier alternatives for this specific product.
  final List<ProductSwap> swaps;

  /// Contextual advice based on the user's current hormonal phase.
  final CycleInsight? cycleInsight;

  /// Product EAN/UPC barcode string.
  final String? barcode;

  /// Analytics source identifier (e.g., 'barcode', 'label').
  final String? source;

  /// Public URL to the actual photo taken by the user.
  final String? userImageUrl;

  /// List of names for ingredients flagged as risky during analysis.
  final List<String> flaggedIngredients;

  /// Whether this product is saved as a favorite.
  final bool isSaved;

  /// Unique identifier for this specific scan event.
  final String? scanId;

  /// The localId of the ChatMessage that triggered this log.
  final String? chatMessageId;

  /// Serving size information (e.g., "100g", "1 pack").
  final String? servingSize;

  /// Record creation timestamp.
  final DateTime createdAt;

  /// Holds the raw JSON data from the AI for routing and specialized storage.
  final Map<String, dynamic>? rawData;

  /// Whether [nutrients]/[nutrientLevels]/[novaGroup] are a visually-grounded
  /// AI APPROXIMATION (typical for home-cooked/unpackaged meals) rather than
  /// a label-sourced or barcode-sourced fact. The UI must label estimated
  /// macros as "Estimated" instead of presenting them with the same visual
  /// authority as scanned data (audit §F.2 / §O item 6).
  final bool nutritionEstimated;

  static String _extractProductName(Map<String, dynamic> map) {
    final direct = map['productName']?.toString() ?? map['name']?.toString() ?? map['title']?.toString();
    if (direct != null && direct.trim().isNotEmpty) {
      final lower = direct.trim().toLowerCase();
      if (lower != 'unknown' && lower != 'food' && lower != 'meal' && lower != 'product' && lower != 'item' && lower != 'food item') {
        return direct.trim();
      }
    }

    final mealBlock = map['meal'] is Map ? map['meal'] as Map : (map['rawData']?['meal'] is Map ? map['rawData']['meal'] as Map : null);
    if (mealBlock != null) {
      final items = mealBlock['items'];
      if (items is List && items.isNotEmpty) {
        final names = <String>[];
        for (final item in items) {
          if (item is Map && item['name'] != null && item['name'].toString().trim().isNotEmpty) {
            names.add(item['name'].toString().trim());
          } else if (item is String && item.trim().isNotEmpty) {
            names.add(item.trim());
          }
        }
        if (names.isNotEmpty) {
          return names.join(' + ');
        }
      }
      final summary = mealBlock['summary']?.toString();
      if (summary != null && summary.trim().isNotEmpty) {
        final s = summary.trim();
        return s.length > 40 ? '${s.substring(0, 40)}...' : s;
      }
      final mealType = mealBlock['mealType']?.toString();
      if (mealType != null && mealType.trim().isNotEmpty) {
        return mealType.trim();
      }
    }

    final restName = map['restaurantName']?.toString() ?? map['menu']?['restaurantName']?.toString() ?? map['location']?.toString() ?? map['detectedText']?.toString();
    if (restName != null && restName.trim().isNotEmpty) {
      return restName.trim();
    }

    if (direct != null && direct.trim().isNotEmpty) {
      return direct.trim();
    }

    return 'Meal Scan';
  }

  /// Returns true if this result represents a specific food product suitable for history.
  ///
  /// Filters out generic utility scans like "Restaurant Menus" or "Ingredient Labels"
  /// which are analyzed for immediate feedback but shouldn't clutter the Pattern Engine.
  bool get isLoggableProduct {
    // 1. Barcode scans are always legitimate products from the database.
    if (barcode != null && barcode!.isNotEmpty) return true;

    // 2. Explicit AI Category Check
    if (category != null) {
      final cat = category!.toLowerCase();
      // 'food', 'meal', 'product', 'packaging' are always loggable.
      if (cat == 'food' || cat == 'meal' || cat == 'product' || cat == 'packaging') return true;

      // Explicitly non-loggable categories.
      if (cat == 'menu' || cat == 'non-food') return false;
    }

    // 3. Source-based check: photo/vision scans are often products
    if (source == 'food' || source == 'meal' || source == 'vision' || source == 'chat') return true;

    // 4. Content check: has ingredients, nutrients, or meal items
    if (ingredients.isNotEmpty || nutrients != null || rawData?['meal'] != null) return true;

    // 5. Fallback Heuristics for older scans or missing category
    return !_isGenericName(productName);
  }

  bool _isGenericName(String name) {
    final n = name.toLowerCase().trim();
    if (n.isEmpty || n == 'unknown' || n == 'food' || n == 'product' || n == 'item' || n == 'meal') return true;

    final isMenu = n.contains('menu') && !n.contains('meal') && !n.contains('combo');
    final isLabelOnly = n.contains('ingredients list') || n.contains('nutrition label') || n.contains('ingredients only');
    final isGeneric = const {'menu', 'ingredients', 'label', 'nutrition', 'facts'}.contains(n);

    return isMenu || isLabelOnly || isGeneric;
  }

  ScanResult copyWith({
    String? productName,
    String? brand,
    String? category,
    String? imageUrl,
    int? score,
    ImpactType? impactType,
    String? impact,
    String? badge,
    String? nutriscore,
    String? novaGroup,
    String? allergens,
    String? additives,
    List<String>? additiveItems,
    List<Ingredient>? ingredients,
    NutrientData? nutrients,
    NutrientLevels? nutrientLevels,
    List<ImpactDetail>? impacts,
    List<ProductSwap>? swaps,
    CycleInsight? cycleInsight,
    String? barcode,
    String? source,
    String? userImageUrl,
    List<String>? flaggedIngredients,
    bool? isSaved,
    String? scanId,
    String? chatMessageId,
    String? servingSize,
    DateTime? createdAt,
    Map<String, dynamic>? rawData,
    bool? nutritionEstimated,
  }) => ScanResult(
    productName: productName ?? this.productName,
    brand: brand ?? this.brand,
    category: category ?? this.category,
    imageUrl: imageUrl ?? this.imageUrl,
    score: score != null ? score.clamp(0, 100) : this.score,
    impactType: impactType ?? this.impactType,
    impact: impact ?? this.impact,
    badge: badge ?? this.badge,
    nutriscore: nutriscore ?? this.nutriscore,
    novaGroup: novaGroup ?? this.novaGroup,
    allergens: allergens ?? this.allergens,
    additives: additives ?? this.additives,
    additiveItems: additiveItems ?? this.additiveItems,
    ingredients: ingredients ?? this.ingredients,
    nutrients: nutrients ?? this.nutrients,
    nutrientLevels: nutrientLevels ?? this.nutrientLevels,
    impacts: impacts ?? this.impacts,
    swaps: swaps ?? this.swaps,
    cycleInsight: cycleInsight ?? this.cycleInsight,
    barcode: barcode ?? this.barcode,
    source: source ?? this.source,
    userImageUrl: userImageUrl ?? this.userImageUrl,
    flaggedIngredients: flaggedIngredients ?? this.flaggedIngredients,
    isSaved: isSaved ?? this.isSaved,
    scanId: scanId ?? this.scanId,
    chatMessageId: chatMessageId ?? this.chatMessageId,
    servingSize: servingSize ?? this.servingSize,
    createdAt: createdAt ?? this.createdAt,
    rawData: rawData ?? this.rawData,
    nutritionEstimated: nutritionEstimated ?? this.nutritionEstimated,
  );

  Map<String, dynamic> toMap() => {
    'productName': productName,
    'brand': brand,
    'category': category,
    'imageUrl': imageUrl,
    'score': score,
    'impactType': impactType.name,
    'impact': impact,
    'badge': badge,
    'nutriscore': nutriscore,
    'novaGroup': novaGroup,
    'allergens': allergens,
    'additives': additives,
    'additiveItems': additiveItems,
    'ingredients': ingredients.map((e) => e.toMap()).toList(),
    'nutrients': nutrients?.toMap(),
    'nutrientLevels': nutrientLevels?.toMap(),
    'impacts': impacts.map((e) => e.toMap()).toList(),
    'swaps': swaps.map((e) => e.toMap()).toList(),
    'cycleInsight': cycleInsight?.toMap(),
    'barcode': barcode,
    'source': source,
    'userImageUrl': userImageUrl,
    'flaggedIngredients': flaggedIngredients,
    'isSaved': isSaved,
    'scanId': scanId,
    'chatMessageId': chatMessageId,
    'servingSize': servingSize,
    'createdAt': DateTimeUtils.toTimestamp(createdAt),
    'rawData': rawData,
    'nutritionEstimated': nutritionEstimated,
  };

  /// Optimized Map for AI context to prevent 502/payload-too-large errors.
  /// Excludes large fields like full ingredients, nutrients, and swaps.
  Map<String, dynamic> toAiMap() => {
    'productName': productName,
    'brand': brand,
    'score': score,
    'impact': impact,
    'nutriscore': nutriscore,
    'novaGroup': novaGroup,
    'flaggedIngredients': flaggedIngredients,
  };

  @override
  List<Object?> get props => [
    productName,
    brand,
    category,
    score,
    impactType,
    impact,
    barcode,
    userImageUrl,
    flaggedIngredients,
    isSaved,
    scanId,
    chatMessageId,
    servingSize,
    createdAt,
    rawData,
    nutritionEstimated,
    additiveItems,
  ];

  /// Stored per-additive list, or parsed from the legacy summary string.
  static List<String> _additiveItemsFrom(Map<String, dynamic> map) {
    final stored = ModelUtils.parseList<String>(map['additiveItems']);
    if (stored.isNotEmpty) return stored;
    return AdditiveConcernDb.parseItems(ModelUtils.parseString(map['additives']));
  }

  /// 🚀 Professional Routing: Determines which screen should be used to display
  /// the full details of this specific scan.
  String get detailRoute {
    final s = source?.toLowerCase() ?? '';
    final c = category?.toLowerCase() ?? '';
    final n = productName.toLowerCase();

    // Unpack intent from rawData if available
    final intent = (rawData?['intent'] ?? '').toString().toLowerCase();

    AppLogger.info('ScanResult: Calculating detailRoute. ProductName: $productName, Intent: $intent, Category: $c, Source: $s');

    // 🚀 Priority 1: Explicit Intent
    // If the AI says it's a meal analysis, we use the Scan Result screen (with score/swaps).
    if (intent == 'meal_analysis' || intent == 'meal_rating' || intent == 'food_analysis') {
      return '/scan-result';
    }
    if (intent == 'menu_analysis' || intent == 'menu') {
      return '/menu-result';
    }
    if (intent == 'label_analysis' || intent == 'label') {
      return '/label-result';
    }

    // 🍴 Priority 2: Explicit Source/Category
    if (s == 'menu' || c == 'menu') return '/menu-result';
    if (s == 'label' || c == 'label') return '/label-result';

    // 🔍 Priority 3: Name-based Heuristics (Venue vs Product)
    // We check for venue-suggesting words.
    final isVenue = n.contains('cafe') || n.contains('restaurant') || n.contains('kitchen') || n.contains('dining') || n.contains('bakery') || n.contains('bistro');
    final hasMenuWord = n.contains('menu');
    final hasItemsWord = n.contains('items') || n.contains('selection') || n.contains('dishes');

    if (isVenue || hasMenuWord) {
      // If it's a venue name, it's likely a menu unless it explicitly looks like a meal log
      if (!hasItemsWord || intent == 'menu_analysis') {
        return '/menu-result';
      }

      // Fallback: If it has "Menu" and "Items", it might be a venue analysis that identified dishes
      if (hasMenuWord && isVenue) return '/menu-result';
    }

    if (n.contains('label') || n.contains('ingredients') || n.contains('nutrition facts') || n == 'ingredients list' || n == 'nutrition') {
      return '/label-result';
    }

    // 🍎 Default: Standard Product/Meal Scan
    return '/scan-result';
  }
}
