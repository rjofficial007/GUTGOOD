import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:gutgood/core/ai/protocol/ai_constants.dart';
import 'package:gutgood/core/data/additive_concern_db.dart';
import 'package:gutgood/core/models/insights/food_swap.dart';
import 'package:gutgood/core/models/scans/scan_result_details.dart';
import 'package:gutgood/core/utils/date_time_utils.dart';
import 'package:gutgood/core/utils/gut_score_utils.dart';
import 'package:gutgood/core/utils/insight_values.dart';
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
    this.summary,
    this.badge,
    this.nutriscore,
    this.novaGroup,
    this.nutriscoreScore,
    this.isOrganic,
    this.allergens,
    this.additives,
    this.additiveItems = const [],
    this.foodTags = const [],
    this.ingredients = const [],
    this.nutrients,
    this.nutrientLevels,
    this.impacts = const [],
    this.swaps = const [],
    this.foodSwap,
    this.cycleInsight,
    this.barcode,
    this.source,
    this.userImageUrl,
    this.flaggedIngredients = const [],
    this.isSaved = false,
    this.scanId,
    this.scanConfidence,
    this.scanVerdict,
    this.consumed,
    this.chatMessageId,
    this.servingSize,
    this.nutritionBasis,
    required this.createdAt,
    this.rawData,
    this.nutritionEstimated = false,
    this.schemaVersion = AiVersions.schemaVersion,
    this.promptVersion,
    this.model,
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
    if (score == 0 && InsightValues.number(map['score']) == null && (category == 'meal' || category == 'food' || category == 'menu')) {
      final mealBlock = map['meal'] is Map
          ? Map<String, dynamic>.from(map['meal'] as Map)
          : ((map['rawData'] as Map?)?['meal'] is Map ? Map<String, dynamic>.from((map['rawData'] as Map)['meal'] as Map) : null);

      score = ModelUtils.computeMealScore(
        novaGroup: novaInt,
        balance: mealBlock?['balance'] is Map ? Map<String, dynamic>.from(mealBlock!['balance'] as Map) : null,
        nutrientLevels: map['nutrientLevels'] is Map ? Map<String, dynamic>.from(map['nutrientLevels'] as Map) : null,
        impactType: it,
        isOrganic: map['isOrganic'] != null ? ModelUtils.parseBool(map['isOrganic']) : null,
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

    final rawSwaps = map['swaps'] is List && (map['swaps'] as List).isNotEmpty ? map['swaps'] as List : (resolvedRaw['swaps'] is List ? resolvedRaw['swaps'] as List : null);
    final legacySwaps = ModelUtils.parseModelList<ProductSwap>(rawSwaps, ProductSwap.fromMap);
    final storedFoodSwap = ModelUtils.parseNestedModel<FoodSwap>(map['foodSwap'] ?? resolvedRaw['foodSwap'], FoodSwap.fromMap);
    final foodSwap =
        (storedFoodSwap?.alternatives.isNotEmpty == true ? storedFoodSwap : null) ??
        _foodSwapFromProductSwaps(
          legacySwaps,
          id: (map['scanId'] ?? map['barcode'] ?? map['productName'] ?? map['name'] ?? '').toString(),
          sourceId: (map['barcode'] ?? map['scanId'] ?? map['productName'] ?? map['name'] ?? '').toString(),
          sourceName: _extractProductName(map),
          sourceImageUrl: map['imageUrl']?.toString(),
        );
    final scanSwaps = foodSwap?.alternatives.map((alternative) => ProductSwap.fromMap(alternative.toMap())).toList() ?? legacySwaps;
    final mealTags = map['meal'] is Map ? (map['meal'] as Map)['foodTags'] : (resolvedRaw['meal'] as Map?)?['foodTags'];

    return ScanResult(
      productName: _extractProductName(map),
      brand: map['brand']?.toString() ?? map['restaurantName']?.toString() ?? 'GutGood',
      category: category,
      imageUrl: map['imageUrl']?.toString(),
      score: score,
      impactType: type,
      impact: map['impact']?.toString() ?? (map['meal'] as Map?)?['summary']?.toString() ?? (resolvedRaw['meal'] as Map?)?['summary']?.toString() ?? '',
      summary: (map['meal'] as Map?)?['summary']?.toString() ?? (resolvedRaw['meal'] as Map?)?['summary']?.toString(),
      badge: map['badge']?.toString(),
      nutriscore: normalizedNutriscore,
      novaGroup: normalizedNova,
      nutriscoreScore: (map['nutriscoreScore'] as num?)?.toInt(),
      // Null-preserving: unknown organic status must survive the round-trip
      isOrganic: map['isOrganic'] != null ? ModelUtils.parseBool(map['isOrganic']) : null,
      allergens: ModelUtils.parseString(map['allergens']),
      additives: ModelUtils.parseString(map['additives']),
      additiveItems: _additiveItemsFrom(map),
      foodTags: ModelUtils.parseList<String>(map['foodTags']).isNotEmpty ? ModelUtils.parseList<String>(map['foodTags']) : ModelUtils.parseList<String>(mealTags),
      ingredients: ModelUtils.parseModelList<Ingredient>(map['ingredients'] as List?, Ingredient.fromMap),
      nutrients: ModelUtils.parseNestedModel<NutrientData>(map['nutrients'] as Map?, NutrientData.fromMap),
      nutrientLevels: ModelUtils.parseNestedModel<NutrientLevels>(map['nutrientLevels'] as Map?, NutrientLevels.fromMap),
      impacts: ModelUtils.parseModelList<ImpactDetail>(map['impacts'], ImpactDetail.fromMap),
      // 🚀 Robust Recovery: Check primary field and rawData block for swaps.
      // We check for null or empty list to ensure old data with empty swaps is fixed.
      swaps: scanSwaps,
      foodSwap: foodSwap,
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
      scanConfidence: _parseScanConfidence(map['scanConfidence']),
      scanVerdict: map['scanVerdict']?.toString(),
      consumed: map['consumed'] is bool ? map['consumed'] as bool : null,
      chatMessageId: map['chatMessageId']?.toString(),
      servingSize: map['servingSize']?.toString(),
      nutritionBasis: _parseNutritionBasis(map['nutritionBasis']),
      // `time` in the AI scan payload is model supplied; it must not replace
      // the actual scan/save timestamp when hydrating a scan record.
      createdAt: DateTimeUtils.parse(map['createdAt'] ?? map['timestamp']),
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
      schemaVersion: (map['v'] as num?)?.toInt() ?? AiVersions.schemaVersion,
      promptVersion: (map['promptVersion'] as num?)?.toInt(),
      model: map['model'] as String?,
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

  /// Concise identity summary (e.g. "Refreshing mango chia pudding").
  final String? summary;

  /// Optional highlight badge text (e.g., "CLEAN CHOICE").
  final String? badge;

  /// Nutri-Score grade (A-E).
  final String? nutriscore;

  /// NOVA processing group (1-4).
  final String? novaGroup;

  /// Original-algorithm Nutri-Score FSA points (OFF `nutriscore_data.score`).
  /// Persisted so barcode-cache hits re-run the engine on identical inputs.
  final int? nutriscoreScore;

  /// Whether the product carries an organic label (OFF `labels_tags`).
  /// Persisted for the same cache-rescore reason as [nutriscoreScore].
  final bool? isOrganic;

  /// Summary of detected allergens based on user profile.
  final String? allergens;

  /// Summary of detected additives or ultra-processed components.
  final String? additives;

  /// Per-additive items (E-codes / names, e.g. ['E621', 'E631', 'Palm Oil']).
  /// Parsed from the legacy [additives] summary when absent, so old scans
  /// still get per-additive detail views and concern-based scoring.
  final List<String> additiveItems;

  /// Meal tags retained from the scan's extracted meal candidate until the
  /// user confirms it was eaten.
  final List<String> foodTags;

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

  /// Legacy card list retained for existing scan and chat widgets.
  final List<ProductSwap> swaps;

  /// Canonical shared swap bundle used by scans and personalized insights.
  /// Older records with a flat `swaps` list are normalized into this shape.
  final FoodSwap? foodSwap;

  /// Shared-model view of swaps, including legacy scan results built with
  /// the former flat card list.
  FoodSwap? get effectiveFoodSwap =>
      foodSwap ?? _foodSwapFromProductSwaps(swaps, id: scanId ?? barcode ?? productName, sourceId: barcode ?? scanId ?? productName, sourceName: productName, sourceImageUrl: imageUrl ?? userImageUrl);

  /// Contextual advice based on the user's current hormonal phase.
  final CycleInsight? cycleInsight;

  /// Product EAN/UPC barcode string.
  final String? barcode;

  /// Analytics source identifier (e.g., 'barcode', 'label').
  final String? source;

  /// Public URL to the actual photo taken by the user.
  final String? userImageUrl;

  /// Barcode scans use the product catalog image when available.
  bool get isBarcodeScan => barcode?.trim().isNotEmpty == true || (source?.toUpperCase().contains('BARCODE') ?? false);

  /// Barcode scans prefer the catalog image; photo scans prefer the uploaded
  /// photo. Returns null when neither has a usable URL.
  String? get displayImageUrl {
    final productImage = imageUrl?.trim();
    if (isBarcodeScan) return productImage?.isNotEmpty == true ? productImage : null;
    final userImage = userImageUrl?.trim();
    return userImage?.isNotEmpty == true ? userImage : (productImage?.isNotEmpty == true ? productImage : null);
  }

  /// List of names for ingredients flagged as risky during analysis.
  final List<String> flaggedIngredients;

  /// Whether this product is saved as a favorite. Legacy on scan_history docs
  /// (P2-6 moved saved state to the `saved_foods` collection; the flag is
  /// only still read by the lazy migration, never by the UI).
  final bool isSaved;

  /// Unique identifier for this specific scan event.
  final String? scanId;

  /// AI confidence attached to this scan, when reported by the structured
  /// response. Kept on the scan as well as its meal projection.
  final double? scanConfidence;

  /// AI verdict attached to this scan, when reported by the structured
  /// response. Kept on the scan as well as its meal projection.
  final String? scanVerdict;

  /// Whether the user confirmed they ate this scanned food. Null means the
  /// scan is awaiting an answer; false means informational scan only.
  final bool? consumed;

  /// The localId of the ChatMessage that triggered this log.
  final String? chatMessageId;

  /// Serving size information (e.g., "100g", "1 pack").
  final String? servingSize;

  /// Basis used for the nutrient values, preserved from the scan source.
  /// Known values: per_serving, per_100g, per_100ml, pictured_portion.
  final String? nutritionBasis;

  String get nutritionBasisLabel => switch (nutritionBasis) {
    'per_serving' => 'Per ${servingSize ?? 'serving'}',
    'per_100g' => 'Per 100 g',
    'per_100ml' => 'Per 100 ml',
    'pictured_portion' => 'Estimated for pictured portion',
    _ => nutritionEstimated ? 'Estimated for analyzed portion' : 'Nutrition basis not recorded',
  };

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

  /// Durable-doc schema version (§17), stamped as `v`.
  final int schemaVersion;

  /// J-4 §17: prompt version that produced this scan (chat vs one-shot
  /// builders disambiguated by [source]). Null on legacy docs.
  final int? promptVersion;

  /// J-4 §17: serving model id echoed by the proxy for this scan.
  final String? model;

  /// Returns the theme-appropriate color for the scan's score impact.
  Color get impactColor => GutScoreUtils.getScoreColor(score);

  static double? _parseScanConfidence(Object? raw) {
    final parsed = raw is num ? raw.toDouble() : double.tryParse(raw?.toString() ?? '');
    if (parsed == null || parsed.isNaN || parsed < 0 || parsed > 1) return null;
    return parsed;
  }

  static String _extractProductName(Map<String, dynamic> map) {
    final direct = map['productName']?.toString() ?? map['name']?.toString() ?? map['title']?.toString();
    if (direct != null && direct.trim().isNotEmpty) {
      final lower = direct.trim().toLowerCase();
      if (lower != 'unknown' && lower != 'food' && lower != 'meal' && lower != 'product' && lower != 'item' && lower != 'food item') {
        return direct.trim();
      }
    }

    final mealBlock = map['meal'] is Map
        ? Map<String, dynamic>.from(map['meal'] as Map)
        : ((map['rawData'] as Map?)?['meal'] is Map ? Map<String, dynamic>.from((map['rawData'] as Map)['meal'] as Map) : null);
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

    final restName = map['restaurantName']?.toString() ?? (map['menu'] as Map?)?['restaurantName']?.toString() ?? map['location']?.toString() ?? map['detectedText']?.toString();
    if (restName != null && restName.trim().isNotEmpty) {
      return restName.trim();
    }

    if (direct != null && direct.trim().isNotEmpty) {
      return direct.trim();
    }

    return 'Meal Scan';
  }

  /// Returns true if this result is product-shaped for product-scan views and
  /// score aggregates. It is not a persistence gate: completed scans remain
  /// in `scan_history`, while a separate confirmation gates meal projection.
  ///
  /// Generic utility scans such as restaurant menus or ingredient labels can
  /// still be separated into their dedicated history views.
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

    // 4. Content check: has ingredients, nutrients, or meal items. The rawData
    // meal check only fires for legacy docs — new docs strip the blob at
    // persistence (see toPersistenceMap), so only pre-strip scans qualify here.
    if (ingredients.isNotEmpty || nutrients != null || (rawData as Map?)?['meal'] != null) return true;

    // 5. Fallback Heuristics for older scans or missing category
    return !_isGenericName(productName);
  }

  /// Food photos and barcode product scans need an explicit eaten/not-eaten
  /// answer before they can affect personal food insights.
  bool get needsConsumptionConfirmation {
    final normalizedSource = (source ?? '').toUpperCase();
    final normalizedCategory = (category ?? '').toUpperCase();
    if (normalizedSource.contains('LABEL') ||
        normalizedSource.contains('MENU') ||
        normalizedCategory.contains('LABEL') ||
        normalizedCategory.contains('MENU')) {
      return false;
    }
    return (barcode?.isNotEmpty ?? false) ||
        normalizedSource.contains('BARCODE') ||
        normalizedSource == 'FOOD' ||
        normalizedSource == 'MEAL' ||
        {'FOOD', 'MEAL', 'PRODUCT', 'PACKAGING'}.contains(normalizedCategory);
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
    String? summary,
    String? badge,
    String? nutriscore,
    String? novaGroup,
    int? nutriscoreScore,
    bool? isOrganic,
    String? allergens,
    String? additives,
    List<String>? additiveItems,
    List<String>? foodTags,
    List<Ingredient>? ingredients,
    NutrientData? nutrients,
    NutrientLevels? nutrientLevels,
    List<ImpactDetail>? impacts,
    List<ProductSwap>? swaps,
    FoodSwap? foodSwap,
    CycleInsight? cycleInsight,
    String? barcode,
    String? source,
    String? userImageUrl,
    List<String>? flaggedIngredients,
    bool? isSaved,
    String? scanId,
    double? scanConfidence,
    String? scanVerdict,
    bool? consumed,
    bool clearConsumed = false,
    String? chatMessageId,
    String? servingSize,
    String? nutritionBasis,
    DateTime? createdAt,
    Map<String, dynamic>? rawData,
    bool? nutritionEstimated,
    int? schemaVersion,
    int? promptVersion,
    String? model,
  }) => ScanResult(
    productName: productName ?? this.productName,
    brand: brand ?? this.brand,
    category: category ?? this.category,
    imageUrl: imageUrl ?? this.imageUrl,
    score: score != null ? score.clamp(0, 100) : this.score,
    impactType: impactType ?? this.impactType,
    impact: impact ?? this.impact,
    summary: summary ?? this.summary,
    badge: badge ?? this.badge,
    nutriscore: nutriscore ?? this.nutriscore,
    novaGroup: novaGroup ?? this.novaGroup,
    nutriscoreScore: nutriscoreScore ?? this.nutriscoreScore,
    isOrganic: isOrganic ?? this.isOrganic,
    allergens: allergens ?? this.allergens,
    additives: additives ?? this.additives,
    additiveItems: additiveItems ?? this.additiveItems,
    foodTags: foodTags ?? this.foodTags,
    ingredients: ingredients ?? this.ingredients,
    nutrients: nutrients ?? this.nutrients,
    nutrientLevels: nutrientLevels ?? this.nutrientLevels,
    impacts: impacts ?? this.impacts,
    swaps: swaps ?? (foodSwap != null ? foodSwap.alternatives.map((alternative) => ProductSwap.fromMap(alternative.toMap())).toList() : this.swaps),
    foodSwap:
        foodSwap ??
        (swaps != null
            ? _foodSwapFromProductSwaps(
                swaps,
                id: scanId ?? this.scanId ?? barcode ?? this.barcode ?? productName ?? this.productName,
                sourceId: barcode ?? this.barcode ?? scanId ?? this.scanId ?? productName ?? this.productName,
                sourceName: productName ?? this.productName,
                sourceImageUrl: imageUrl ?? this.imageUrl,
              )
            : this.foodSwap),
    cycleInsight: cycleInsight ?? this.cycleInsight,
    barcode: barcode ?? this.barcode,
    source: source ?? this.source,
    userImageUrl: userImageUrl ?? this.userImageUrl,
    flaggedIngredients: flaggedIngredients ?? this.flaggedIngredients,
    isSaved: isSaved ?? this.isSaved,
    scanId: scanId ?? this.scanId,
    scanConfidence: scanConfidence ?? this.scanConfidence,
    scanVerdict: scanVerdict ?? this.scanVerdict,
    consumed: clearConsumed ? null : (consumed ?? this.consumed),
    chatMessageId: chatMessageId ?? this.chatMessageId,
    servingSize: servingSize ?? this.servingSize,
    nutritionBasis: nutritionBasis ?? this.nutritionBasis,
    createdAt: createdAt ?? this.createdAt,
    rawData: rawData ?? this.rawData,
    nutritionEstimated: nutritionEstimated ?? this.nutritionEstimated,
    schemaVersion: schemaVersion ?? this.schemaVersion,
    promptVersion: promptVersion ?? this.promptVersion,
    model: model ?? this.model,
  );

  Map<String, dynamic> toMap() => {
    'v': schemaVersion,
    'promptVersion': promptVersion,
    'model': model,
    'productName': productName,
    'brand': brand,
    'category': category,
    'imageUrl': imageUrl,
    'score': score,
    'impactType': impactType.name,
    'impact': impact,
    'summary': summary,
    'badge': badge,
    'nutriscore': nutriscore,
    'novaGroup': novaGroup,
    'nutriscoreScore': nutriscoreScore,
    'isOrganic': isOrganic,
    'allergens': allergens,
    'additives': additives,
    'additiveItems': additiveItems,
    'foodTags': foodTags,
    'ingredients': ingredients.map((e) => e.toMap()).toList(),
    'nutrients': nutrients?.toMap(),
    'nutrientLevels': nutrientLevels?.toMap(),
    'impacts': impacts.map((e) => e.toMap()).toList(),
    if (effectiveFoodSwap != null) 'foodSwap': effectiveFoodSwap!.toMap(),
    'cycleInsight': cycleInsight?.toMap(),
    'barcode': barcode,
    'source': source,
    'userImageUrl': userImageUrl,
    'flaggedIngredients': flaggedIngredients,
    'isSaved': isSaved,
    'scanId': scanId,
    if (scanConfidence != null) 'scanConfidence': scanConfidence,
    if (scanVerdict != null) 'scanVerdict': scanVerdict,
    if (consumed != null) 'consumed': consumed,
    'chatMessageId': chatMessageId,
    'servingSize': servingSize,
    'nutritionBasis': nutritionBasis,
    'createdAt': DateTimeUtils.toTimestamp(createdAt),
    'rawData': rawData,
    'nutritionEstimated': nutritionEstimated,
  };

  /// Stable fingerprint of the decoded AI payload, kept so identical analyses
  /// stay recognizable after the blob itself is stripped at persistence.
  /// Null when there is no raw payload (or it can't be encoded).
  String? get rawDataHash {
    final raw = rawData;
    if (raw == null || raw.isEmpty) return null;
    try {
      return sha256.convert(utf8.encode(jsonEncode(raw))).toString();
    } catch (_) {
      return null;
    }
  }

  /// Firestore-bound map. Identical to [toMap] except the `rawData` blob —
  /// the entire decoded `[GUTGOOD_DATA]` block the scan was already parsed
  /// from — is replaced by its [rawDataHash]. Persisting the blob meant every
  /// scan doc carried the full AI payload toward the 1 MB cap and taxed every
  /// history/insight read; the durable facts all live in top-level fields.
  /// In-memory `rawData` (used during the live turn) is untouched.
  Map<String, dynamic> toPersistenceMap() => toMap()
    ..remove('rawData')
    ..['rawDataHash'] = rawDataHash;

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
    if (foodTags.isNotEmpty) 'foodTags': foodTags,
    if (consumed != null) 'consumed': consumed,
  };

  @override
  List<Object?> get props => [
    productName,
    brand,
    category,
    swaps,
    foodSwap,
    score,
    impactType,
    impact,
    summary,
    barcode,
    userImageUrl,
    flaggedIngredients,
    isSaved,
    scanId,
    scanConfidence,
    scanVerdict,
    consumed,
    foodTags,
    chatMessageId,
    servingSize,
    nutritionBasis,
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

  static String? _parseNutritionBasis(dynamic value) {
    final basis = value?.toString().toLowerCase();
    return const {'per_serving', 'per_100g', 'per_100ml', 'pictured_portion'}.contains(basis) ? basis : null;
  }

  static FoodSwap? _foodSwapFromProductSwaps(List<ProductSwap> swaps, {required String id, required String sourceId, required String sourceName, String? sourceImageUrl}) {
    if (swaps.isEmpty) return null;
    return FoodSwap(
      id: id,
      source: SwapSource(foodId: sourceId, name: sourceName, imageUrl: sourceImageUrl),
      alternatives: swaps.map((swap) => swap.toAlternative()).toList(),
    );
  }
}
