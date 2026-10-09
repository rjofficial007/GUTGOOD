import 'dart:ui' show PlatformDispatcher;

import 'package:dio/dio.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/data/additive_concern_db.dart';
import 'package:gutgood/core/models/scans/off_product.dart';
import 'package:gutgood/core/models/scans/scan_result_details.dart';
import 'package:gutgood/core/utils/barcode_validator.dart';
import 'package:gutgood/core/utils/gut_score_utils.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/yuka_score.dart';
import 'package:openfoodfacts/openfoodfacts.dart' as off;

abstract class OffService {
  Future<OffProduct?> getProduct(String barcode);
  Future<List<OffProduct>> getBetterAlternatives(String? category, String? currentGrade);
}

/// Single-barcode product fetch, mapped to the app's [OffProduct].
///
/// Constructor-injectable seam: production uses [_fetchWithPackage] (the
/// official `openfoodfacts` SDK); tests swap in a fake so the session-memo
/// cache can be verified without HTTP.
typedef OffProductFetcher = Future<OffProduct?> Function(String barcode);

/// Raw name/value query parameter on the SDK's [off.Parameter] interface.
///
/// Needed for OFF facet filters the typed SDK parameters can't express, e.g.
/// the comma-OR grades filter `nutrition_grades_tags=a,b` (a [off.TagFilter]
/// would AND multiple entries instead of OR-ing them).
class _QueryParameter implements off.Parameter {
  const _QueryParameter(this._name, this._value);
  final String _name;
  final String _value;

  @override
  String getName() => _name;

  @override
  String getValue() => _value;
}

class OffServiceImpl implements OffService {
  OffServiceImpl({required Dio dio, OffProductFetcher? productFetcher}) : _dio = dio {
    // Assigned in the constructor body (not the initializer list): the default
    // is a tear-off of an instance method, which `this` can't reference yet.
    _productFetcher = productFetcher ?? _fetchWithPackage;
    _configurePackage();
  }

  /// Kept for the Search-a-licious endpoint in [getBetterAlternatives], which
  /// the SDK does not cover; product fetches themselves go through the SDK.
  final Dio _dio;
  late final OffProductFetcher _productFetcher;

  static var _packageConfigured = false;

  /// Per-request locale, smooth-app style (`ProductQuery.getLanguage() /
  /// getCountry()`): queries carry `language:` + `country:` per call rather
  /// than relying on globals, and `globalCountry` stays null so the world
  /// database answers every query (the country only steers localized fields).
  static off.OpenFoodFactsLanguage _language = off.OpenFoodFactsLanguage.ENGLISH;
  static off.OpenFoodFactsCountry _country = off.OpenFoodFactsCountry.FRANCE;

  /// Override the device-derived locale (e.g. once user settings expose
  /// app-language/country). Mirrors smooth-app's `ProductQuery.setLanguage /
  /// setCountry`; call before the first fetch (e.g. from app bootstrap).
  static void configureLocale({String? languageCode, String? countryIsoCode}) {
    if (languageCode != null) {
      final language = off.LanguageHelper.fromJson(languageCode);
      if (language != off.OpenFoodFactsLanguage.UNDEFINED) _language = language;
    }
    final country = off.OpenFoodFactsCountry.fromOffTag(countryIsoCode?.toLowerCase());
    if (country != null) _country = country;
    off.OpenFoodAPIConfiguration.globalLanguages = [_language];
  }

  /// One-time, idempotent SDK configuration.
  ///
  /// The package THROWS on every request when no User-Agent is set. OFF
  /// requires an identifiable agent and rate-limits per caller (product GET
  /// ~100/min, search ~10/min) — anonymous callers get blocked as scrapers.
  static void _configurePackage() {
    if (_packageConfigured) return;
    // Not a const constructor: UserAgent validates its name in the body.
    off.OpenFoodAPIConfiguration.userAgent = off.UserAgent(name: 'GutGood', version: '1.0', url: 'https://gutgood.app');
    // Default locale comes from the device (smooth-app: `ProductQuery.setLanguage`
    // falls back to the platform locale when no app-language pref exists).
    final locale = PlatformDispatcher.instance.locale;
    configureLocale(languageCode: locale.languageCode, countryIsoCode: locale.countryCode);
    _packageConfigured = true;
  }

  /// Fields requested on a barcode lookup — the SDK-typed equivalent of the
  /// old raw `fields` list (≈90% payload saving vs [off.ProductField.ALL]).
  ///
  /// Dropped vs the raw-JSON era (verified unreachable through the SDK's
  /// [off.Product] model, 3.30.2):
  ///  - `nutriscore_score` / `nutriscore_data` (exact FSA points): the engine
  ///    falls back to grade-representative points; see [_mapPackageProduct].
  ///  - `product_name_en`, `ingredients_text_en`, `categories_en`: the
  ///    `*_IN_LANGUAGES` request fields emit these keys, but the model only
  ///    parses the `*_in_languages` pseudo-field, which the OFF server returns
  ///    as `{}`. The unprefixed primary keys carry the payload instead.
  ///  - `additives_n`: the count is derived locally (SDK tags ∪ text parse).
  ///  - `image_url` / standalone `allergens` string: superseded by
  ///    `image_front_url` and structured `allergens_tags` resp.
  static const _productFields = <off.ProductField>[
    off.ProductField.BARCODE,
    off.ProductField.NAME,
    off.ProductField.BRANDS,
    off.ProductField.QUANTITY,
    off.ProductField.IMAGE_FRONT_URL,
    off.ProductField.IMAGE_INGREDIENTS_URL,
    off.ProductField.IMAGE_NUTRITION_URL,
    off.ProductField.NUTRISCORE, // legacy `nutrition_grade_fr` — still served (grade)
    off.ProductField.NOVA_GROUP,
    off.ProductField.ECOSCORE_GRADE, // SDK field maps environmental_score_grade on API v3.1+
    off.ProductField.ECOSCORE_SCORE,
    off.ProductField.INGREDIENTS_TEXT,
    off.ProductField.INGREDIENTS,
    off.ProductField.INGREDIENTS_ANALYSIS_TAGS,
    off.ProductField.ADDITIVES,
    off.ProductField.ALLERGENS,
    off.ProductField.TRACES_TAGS,
    off.ProductField.LABELS_TAGS,
    off.ProductField.CATEGORIES,
    off.ProductField.CATEGORIES_TAGS,
    off.ProductField.COMPARED_TO_CATEGORY,
    off.ProductField.NUTRITION,
    off.ProductField.NO_NUTRITION_DATA,
    off.ProductField.NUTRIENT_LEVELS,
    off.ProductField.SERVING_SIZE,
    off.ProductField.COUNTRIES,
    off.ProductField.ATTRIBUTE_GROUPS,
    off.ProductField.KNOWLEDGE_PANELS, // Nutri-Score components table (details page)
    off.ProductField.MISC_TAGS,
  ];

  /// Session memo for OFF lookups (P0-3): label facts don't change mid-session,
  /// so repeat fetches of the same barcode (preview → analyze, batch mode,
  /// retries) skip the network. scan_history is the durable cross-session
  /// cache for analyzed products; this only dedupes raw OFF fetches.
  static const _productTtl = Duration(minutes: 30);
  static const _productCacheCap = 200;
  final _productCache = <String, _CachedProduct>{};

  @override
  Future<OffProduct?> getProduct(String rawBarcode) async {
    // smooth-app normalization (BarcodeValidator): UPC-A → EAN-13, strip
    // formatting; invalid codes are ignored (null ⇒ "not found" upstream).
    final barcode = BarcodeValidator.normalizeForScan(rawBarcode);
    if (barcode == null) return null;
    final hit = _productCache[barcode];
    if (hit != null) {
      if (DateTime.now().difference(hit.fetchedAt) < _productTtl) return hit.product;
      _productCache.remove(barcode);
    }
    try {
      final mappedProduct = await _productFetcher(barcode);
      if (mappedProduct != null) {
        AppLogger.data('OFF_MAPPED_PRODUCT', mappedProduct.toMap());
        _rememberProduct(barcode, mappedProduct);
        return mappedProduct;
      }
    } catch (e) {
      AppLogger.error('OffService: Error fetching product: $e');
    }
    return null;
  }

  void _rememberProduct(String barcode, OffProduct product) {
    // Null results are NOT cached: "not found" may flip to found (fresh OFF
    // entry) and must never poison the session.
    if (_productCache.length >= _productCacheCap) {
      _productCache.remove(_productCache.keys.first);
    }
    _productCache[barcode] = _CachedProduct(product, DateTime.now());
  }

  /// Production fetch path: official `openfoodfacts` SDK (`getProductV3`),
  /// configured the smooth-app way: per-query `language` + `country` (their
  /// `ProductRefresher.silentFetchAndRefresh`), v3, and a `scan` User-Agent
  /// comment for the duration of the call (their `BarcodeProductQuery` marks
  /// scan traffic the same way).
  ///
  /// Errors (network, 429 `TooManyRequestsException`, malformed payloads) map
  /// to null — same contract as the old raw-dio path, so callers need no
  /// special handling for SDK exceptions. "Not found" vs "network failure" is
  /// distinguished one level up: not-found trips `resultProductNotFound`,
  /// everything else throws → callers read `lastErrorWasOffline`.
  Future<OffProduct?> _fetchWithPackage(String barcode) async {
    _setUserAgentComment('scan');
    try {
      final result = await off.OpenFoodAPIClient.getProductV3(
        off.ProductQueryConfiguration(barcode, version: off.ProductQueryVersion.latestVersion, language: _language, country: _country, fields: _productFields),
      );
      if (result.result?.id == off.ProductResultV3.resultProductNotFound) return null;
      final product = result.product;
      if (product == null) return null;
      return _mapPackageProduct(product);
    } finally {
      _setUserAgentComment(null);
    }
  }

  /// smooth-app's `ProductQuery.setUserAgentComment`: rewrite the configured
  /// User-Agent with a traffic marker around a call.
  static void _setUserAgentComment(String? comment) {
    final previous = off.OpenFoodAPIConfiguration.userAgent;
    if (previous == null) return;
    off.OpenFoodAPIConfiguration.userAgent = off.UserAgent(name: previous.name, version: previous.version, system: previous.system, url: previous.url, comment: comment);
  }

  static String _stripLangPrefix(String tag) {
    // OFF tags look like 'en:e150d' / 'fr:gluten'; keep what follows the
    // leading language prefix.
    final i = tag.indexOf(':');
    return (i > 0 && i <= 3) ? tag.substring(i + 1) : tag;
  }

  OffProduct _mapPackageProduct(off.Product product) {
    final name = product.productName;
    final brand = product.brands;
    final imageUrl = product.imageFrontUrl;

    final nutriscore = product.nutriscore?.toLowerCase();
    // NOTE (SDK migration): the SDK model has no field for the exact FSA
    // points (`nutriscore_data.score`), so `nutriscoreScore` is now always
    // null from OFF. YukaScore falls back to grade-representative points, and
    // when no grade exists it still computes FSA points from the nutrient
    // table — that path is unchanged. Grade (the user-visible signal) is
    // bit-identical to before.
    final novaGroup = product.novaGroup;
    final ecoscore = product.environmentalScoreGrade?.toLowerCase();

    // Ingredients & Additives
    // (main-language text — same primary key the raw client preferred; the
    // `ingredients_text_en` fallback is unreachable via the SDK model).
    final ingredientsText = product.ingredientsText;
    final ingredientsList = (product.ingredients ?? const <off.Ingredient>[]).map((i) => i.text ?? '').toList();

    final additivesTags = (product.additives?.ids ?? const <String>[]).map((a) => _stripLangPrefix(a).toUpperCase()).toList();

    // 🚀 Robust Additive Detection: If OFF tags are empty/incomplete, parse from text.
    final additivesFromText = AdditiveConcernDb.parseItems(ingredientsText);
    final combinedAdditives = {...additivesTags, ...additivesFromText}.toList();

    // Allergens
    final allergensTags = (product.allergens?.ids ?? const <String>[]).map(_stripLangPrefix).toList();

    // Labels & Categories
    final labels = (product.labelsTags ?? const <String>[]).map(_stripLangPrefix).toList();
    // Human-readable categories (server-localized via lc=en). Note: nothing
    // downstream consumes this string — swaps use the canonical [categoryTag].
    final category = product.categories;
    final categoriesTags = product.categoriesTags ?? const <String>[];
    final categoryTag = categoriesTags.isNotEmpty ? categoriesTags.last : null;

    // API v3.5 nutrition is represented as input sets; prefer as-sold packaging
    // facts, then other as-sold facts, and only then the first available set.
    final inputSets = off.NutritionHelper().getInputSets(product) ?? const <off.NutritionSet>[];
    int nutritionSetPriority(off.NutritionSet set) =>
        (set.key.preparation == off.NutritionSetKey.preparationAsSold ? 2 : 0) +
        (set.key.source == off.NutritionSetKey.sourcePackaging ? 1 : 0);
    off.NutritionSet? setFor(off.PerSize perSize) {
      final candidates = inputSets.where((set) => set.key.perSize == perSize).toList()
        ..sort((a, b) => nutritionSetPriority(b).compareTo(nutritionSetPriority(a)));
      return candidates.isEmpty ? null : candidates.first;
    }
    final primaryNutritionSet = setFor(off.PerSize.oneHundredGrams) ?? setFor(off.PerSize.oneHundredMilliliters);
    double? nutrient(off.Nutrient n) {
      final value = primaryNutritionSet?.nutritionValues?[n];
      return (value?.valueComputed ?? value?.value)?.toDouble();
    }
    final nutrients = NutrientData(
      calories: nutrient(off.Nutrient.energyKCal),
      fat: nutrient(off.Nutrient.fat),
      saturatedFat: nutrient(off.Nutrient.saturatedFat),
      carbs: nutrient(off.Nutrient.carbohydrates),
      sugars: nutrient(off.Nutrient.sugars),
      fiber: nutrient(off.Nutrient.fiber),
      proteins: nutrient(off.Nutrient.proteins),
      salt: nutrient(off.Nutrient.salt),
    );

    final levels = product.nutrientLevels?.levels ?? const <String, off.NutrientLevel>{};
    String levelOf(String key) {
      final level = levels[key];
      return (level == null || level == off.NutrientLevel.UNDEFINED) ? 'unknown' : level.offTag;
    }

    final nutrientLevels = NutrientLevels(
      sugars: levelOf(off.NutrientLevels.NUTRIENT_SUGARS),
      salt: levelOf(off.NutrientLevels.NUTRIENT_SALT),
      fat: levelOf(off.NutrientLevels.NUTRIENT_FAT),
      saturatedFat: levelOf(off.NutrientLevels.NUTRIENT_SATURATED_FAT),
    );

    // Score (0-100) from the one scoring engine (`yuka_score.dart`), so a
    // product shows the same number everywhere: search results, alternatives
    // and the scan result screen.
    final breakdown = YukaScore.evaluate(
      nutriscore: nutriscore,
      energyKcal: nutrients.calories,
      fiberG: nutrients.fiber,
      proteinG: nutrients.proteins,
      sugarG: nutrients.sugars,
      saltG: nutrients.salt,
      saturatedFatG: nutrients.saturatedFat,
      additiveConcerns: AdditiveConcernDb.resolveAll(combinedAdditives),
      isOrganic: YukaScore.detectOrganic(labels),
    );
    final score = breakdown.hasData ? breakdown.score : null;

    // Structured ingredients (rank + percent + sub-ingredients) for the
    // smooth-app-style details page.
    final ingredientsDetail = (product.ingredients ?? const <off.Ingredient>[])
        .where((i) => (i.text ?? '').trim().isNotEmpty)
        .map(
          (i) => IngredientDetail(
            text: i.text!,
            percent: i.percent ?? i.percentEstimate,
            percentIsEstimate: i.percent == null && i.percentEstimate != null,
            subIngredients: (i.ingredients ?? const <off.Ingredient>[]).map((s) => s.text ?? '').where((s) => s.isNotEmpty).toList(),
          ),
        )
        .toList();

    // Ingredient analysis chips (vegan / vegetarian / palm-oil-free).
    final analysis = product.ingredientsAnalysisTags;
    final analysisVegan = switch (analysis?.veganStatus) {
      off.VeganStatus.VEGAN => 'yes',
      off.VeganStatus.NON_VEGAN => 'no',
      off.VeganStatus.MAYBE_VEGAN => 'maybe',
      _ => null, // unknown / absent
    };
    final analysisVegetarian = switch (analysis?.vegetarianStatus) {
      off.VegetarianStatus.VEGETARIAN => 'yes',
      off.VegetarianStatus.NON_VEGETARIAN => 'no',
      off.VegetarianStatus.MAYBE_VEGETARIAN => 'maybe',
      _ => null,
    };
    final analysisPalmOilFree = switch (analysis?.palmOilFreeStatus) {
      off.PalmOilFreeStatus.PALM_OIL_FREE => 'yes',
      off.PalmOilFreeStatus.PALM_OIL => 'no',
      off.PalmOilFreeStatus.MAY_CONTAIN_PALM_OIL => 'maybe',
      _ => null,
    };

    // Per-serving nutrients (for the 100g ↔ serving toggle on the details page).
    double? servingValue(off.Nutrient n) {
      final value = setFor(off.PerSize.serving)?.nutritionValues?[n];
      return (value?.valueComputed ?? value?.value)?.toDouble();
    }
    final servingNutrients = NutrientData(
      calories: servingValue(off.Nutrient.energyKCal),
      fat: servingValue(off.Nutrient.fat),
      saturatedFat: servingValue(off.Nutrient.saturatedFat),
      carbs: servingValue(off.Nutrient.carbohydrates),
      sugars: servingValue(off.Nutrient.sugars),
      fiber: servingValue(off.Nutrient.fiber),
      proteins: servingValue(off.Nutrient.proteins),
      salt: servingValue(off.Nutrient.salt),
    );

    // Nutri-Score breakdown (smooth-app detail table) from the knowledge panel.
    final (nutriscoreComponents, nutriscoreExplanation) = _extractNutriscoreDetails(product);

    return OffProduct(
      productName: name ?? 'Unknown Product',
      brand: brand,
      imageUrl: imageUrl,
      imageIngredientsUrl: product.imageIngredientsUrl,
      imageNutritionUrl: product.imageNutritionUrl,
      barcode: product.barcode,
      quantity: product.quantity,
      score: score,
      status: score != null ? GutScoreUtils.getStatus(score) : null,
      statusColor: score != null ? GutScoreUtils.getStatusColor(score) : null,
      nutriscore: nutriscore,
      nutriscoreScore: null, // not modeled by the SDK — see note above
      isOrganic: YukaScore.detectOrganic(labels),
      novaGroup: novaGroup,
      ecoscore: ecoscore,
      ecoscoreScore: product.environmentalScoreScore?.round(),
      ingredientsText: ingredientsText,
      ingredients: ingredientsList,
      ingredientsDetail: ingredientsDetail.isEmpty ? null : ingredientsDetail,
      ingredientAnalysisVegan: analysisVegan,
      ingredientAnalysisVegetarian: analysisVegetarian,
      ingredientAnalysisPalmOilFree: analysisPalmOilFree,
      additivesCount: combinedAdditives.length,
      additives: combinedAdditives,
      allergens: allergensTags,
      allergensText: null,
      tracesTags: (product.tracesTags ?? const <String>[]).map(_stripLangPrefix).where((t) => t.isNotEmpty).toList(),
      labels: labels,
      category: category,
      categoryTag: categoryTag,
      countries: product.countries,
      comparedToCategory: product.comparedToCategory,
      servingSize: product.servingSize,
      nutrientDataPer: primaryNutritionSet?.key.perSize.offTag,
      nutrientLevels: nutrientLevels,
      nutrients: nutrients,
      servingNutrients: (servingNutrients.calories != null || servingNutrients.proteins != null) ? servingNutrients : null,
      nutriscoreComponents: nutriscoreComponents,
      nutriscoreExplanation: nutriscoreExplanation,
      impacts: _generateImpacts(nutriscore, novaGroup, ingredientsText ?? ''),
      miscTags: product.miscTags,
    );
  }

  /// Extracts the Nutri-Score component rows + plain-language explanation from
  /// the OFF `nutriscore` knowledge panel — the same data smooth-app renders
  /// as its "Nutri-Score details" table. Returns `(null, null)` when the panel
  /// or table is absent (product without a computed score).
  (List<NutriScoreComponent>?, String?) _extractNutriscoreDetails(off.Product product) {
    final panels = product.knowledgePanels?.panelIdToPanelMap;
    if (panels == null) return (null, null);

    // The components table lives under the 'nutriscore' panel (v2 taxonomy);
    // fall back to any panel whose id starts with 'nutriscore'.
    var panel = panels['nutriscore'];
    if (panel == null) {
      for (final entry in panels.entries) {
        if (entry.key.startsWith('nutriscore')) {
          panel = entry.value;
          break;
        }
      }
    }
    if (panel == null) return (null, null);

    List<NutriScoreComponent>? components;
    String? explanation;
    for (final element in panel.elements ?? const <off.KnowledgePanelElement>[]) {
      final table = element.tableElement;
      if (table != null && components == null) {
        components = [
          for (final row in table.rows)
            if (row.values.length >= 2)
              NutriScoreComponent(
                label: row.values.first.text,
                value: row.values.last.text,
                evaluation: row.values.last.evaluation == off.Evaluation.UNKNOWN ? null : row.values.last.evaluation?.name.toLowerCase(),
              ),
        ];
      }
      final text = element.textElement;
      if (text != null && explanation == null) {
        explanation = _stripHtml(text.sourceText ?? text.html);
      }
    }
    return (components == null || components.isEmpty ? null : components, explanation);
  }

  static String _stripHtml(String html) => html.replaceAll(RegExp('<[^>]+>'), '').replaceAll('&amp;', '&').replaceAll('&quot;', '"').trim();

  /// Light-weight mapping for search results (alternatives), identical in
  /// shape to the old raw-mapping for the v2 fallback.
  OffProduct _mapAlternativeProduct(off.Product product) {
    final nutriscore = product.nutriscore?.toLowerCase();
    return OffProduct(
      productName: product.productName ?? 'Unknown Product',
      brand: product.brands ?? 'Unknown Brand',
      imageUrl: product.imageFrontUrl,
      nutriscore: nutriscore,
      score: YukaScore.evaluate(nutriscore: nutriscore).score,
      barcode: product.barcode,
    );
  }

  List<ImpactDetail> _generateImpacts(String? nutriscore, dynamic nova, String ingredients) {
    final impacts = <ImpactDetail>[];

    if (nova == 1) {
      impacts.add(const ImpactDetail(title: AppStrings.minimallyProcessed, level: 'Positive', color: 'green'));
    } else if (nova == 4) {
      impacts.add(const ImpactDetail(title: AppStrings.ultraProcessed, level: 'Negative', color: 'red'));
    }

    final lowerIng = ingredients.toLowerCase();
    if (lowerIng.contains('sugar') || lowerIng.contains('syrup')) {
      impacts.add(const ImpactDetail(title: AppStrings.addedSugars, level: 'Negative', color: 'orange'));
    }

    if (nutriscore == 'a' || nutriscore == 'b') {
      impacts.add(const ImpactDetail(title: AppStrings.nutrientDense, level: 'Positive', color: 'green'));
    }

    return impacts;
  }

  @override
  Future<List<OffProduct>> getBetterAlternatives(String? category, String? currentGrade) async {
    if (category == null || category.isEmpty) return [];

    // Determine target grades
    var targetGrades = <String>[];
    final current = (currentGrade ?? 'c').toLowerCase();
    if (current == 'a') return []; // Already top tier

    if (current == 'b') {
      targetGrades = ['a'];
    } else if (current == 'c') {
      targetGrades = ['a', 'b'];
    } else if (current == 'd') {
      targetGrades = ['a', 'b', 'c'];
    } else if (current == 'e') {
      targetGrades = ['a', 'b', 'c', 'd'];
    } else {
      targetGrades = ['a', 'b']; // Default if grade is unknown
    }

    // Try Search-a-licious (Modern, more stable for search) — the SDK has no
    // client for this endpoint, so it stays on the injected Dio.
    try {
      final gradesFilter = targetGrades.map((g) => 'nutrition_grades:$g').join(' OR ');
      final categoryFilter = category.contains(':') ? category : 'en:$category';

      // Search-a-licious URL
      const url = 'https://search.openfoodfacts.org/search';
      final params = {'q': 'categories_tags:$categoryFilter AND ($gradesFilter)', 'sort_by': 'nutriscore_score', 'fields': 'product_name,brands,image_front_url,nutrition_grades,code', 'size': 5};

      final response = await _dio.get(url, queryParameters: params);

      final data = response.data as Map<String, dynamic>;
      if (data.isNotEmpty && data['products'] != null) {
        final products = data['products'] as List;
        return products.map((p) {
          final product = p as Map<String, dynamic>;
          return OffProduct(
            productName: product['product_name'] ?? 'Unknown Product',
            brand: product['brands'] ?? 'Unknown Brand',
            imageUrl: product['image_front_url'],
            nutriscore: (product['nutrition_grades'] as String?)?.toLowerCase(),
            score: YukaScore.evaluate(nutriscore: (product['nutrition_grades'] as String?)?.toLowerCase()).score,
            barcode: product['code'],
          );
        }).toList();
      }
    } catch (e) {
      AppLogger.error('OffService: Search-a-licious failed, falling back to SDK search: $e');

      // Fallback via the official SDK on /cgi/search.pl. The facet params
      // (`categories_tags_en`, comma-OR `nutrition_grades_tags`) are passed
      // raw through [_QueryParameter] and keep the exact semantics of the old
      // hand-rolled /api/v2 fallback.
      try {
        final result = await off.OpenFoodAPIClient.searchProducts(
          null,
          off.ProductSearchQueryConfiguration(
            version: off.ProductQueryVersion.latestVersion,
            language: _language,
            country: _country,
            fields: const [off.ProductField.BARCODE, off.ProductField.NAME, off.ProductField.BRANDS, off.ProductField.IMAGE_FRONT_URL, off.ProductField.NUTRISCORE],
            parametersList: [
              _QueryParameter('categories_tags_en', category),
              _QueryParameter('nutrition_grades_tags', targetGrades.join(',')),
              const off.SortBy(option: off.SortOption.NUTRISCORE),
              const off.PageSize(size: 5),
            ],
          ),
        );
        final products = result.products ?? const <off.Product>[];
        return products.take(5).map(_mapAlternativeProduct).toList();
      } catch (e2) {
        AppLogger.scanner('SDK fallback also failed: $e2');
      }
    }
    return [];
  }
}

class _CachedProduct {
  const _CachedProduct(this.product, this.fetchedAt);
  final OffProduct product;
  final DateTime fetchedAt;
}
