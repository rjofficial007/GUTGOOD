import 'package:dio/dio.dart';
import 'package:gutgood/core/constants/api_constants.dart';
import 'package:gutgood/core/constants/app_strings.dart';
import 'package:gutgood/core/models/off_product.dart';
import 'package:gutgood/core/models/scan_result_details.dart';
import 'package:gutgood/core/utils/gut_score_utils.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/model_utils.dart';

abstract class OffService {
  Future<OffProduct?> getProduct(String barcode);
  Future<List<OffProduct>> getBetterAlternatives(String? category, String? currentGrade);
}

class OffServiceImpl implements OffService {
  final Dio _dio;

  OffServiceImpl({required Dio dio}) : _dio = dio;

  @override
  Future<OffProduct?> getProduct(String barcode) async {
    try {
      final response = await _dio.get('${ApiConstants.offBaseUrl}${ApiConstants.productEndpoint}/$barcode.json');
      if (response.data != null && response.data['status'] == 1) {
        return _mapProductData(response.data['product']);
      }
    } catch (e) {
      Log.e('OffService: Error fetching product: $e');
    }
    return null;
  }

  OffProduct _mapProductData(dynamic product) {
    final name = product['product_name'] ?? product['product_name_en'];
    final brand = product['brands'];
    final imageUrl = product['image_url'] ?? product['image_front_url'];

    // Nutri-Score & NOVA
    final nutriscore = (product['nutriscore_grade'] as String?)?.toLowerCase();
    final novaGroup = product['nova_group'] is int ? product['nova_group'] as int : null;
    final ecoscore = (product['ecoscore_grade'] as String?)?.toLowerCase();

    // Ingredients & Additives
    final ingredientsText = product['ingredients_text'] ?? product['ingredients_text_en'];
    final ingredientsList = ModelUtils.parseList<dynamic>(product['ingredients']).map((i) => i['text']?.toString() ?? '').toList();

    final additivesCount = product['additives_n'] is int ? product['additives_n'] as int : null;
    final additivesTags = ModelUtils.parseList<dynamic>(product['additives_tags']).map((a) => a.toString().replaceAll('en:', '').toUpperCase()).toList();

    // Allergens
    final allergensTags = ModelUtils.parseList<dynamic>(product['allergens_tags']).map((a) => a.toString().replaceAll('en:', '').replaceAll('fr:', '')).toList();
    final allergensText = product['allergens'];

    // Labels & Categories
    final labels = ModelUtils.parseList<dynamic>(product['labels_tags']).map((l) => l.toString().replaceAll('en:', '')).toList();
    final category = product['categories_en'] ?? product['categories'];
    final categoriesTags = ModelUtils.parseList<dynamic>(product['categories_tags']);
    final categoryTag = categoriesTags.isNotEmpty ? categoriesTags.last.toString() : null;

    // Nutrition
    final nutrientsRaw = product['nutriments'] ?? {};
    final nutrientLevelsRaw = product['nutrient_levels'] ?? {};

    final nutrients = NutrientData(
      calories: nutrientsRaw['energy-kcal_100g'],
      fat: nutrientsRaw['fat_100g'],
      saturatedFat: nutrientsRaw['saturated-fat_100g'],
      carbs: nutrientsRaw['carbohydrates_100g'],
      sugars: nutrientsRaw['sugars_100g'],
      fiber: nutrientsRaw['fiber_100g'],
      proteins: nutrientsRaw['proteins_100g'],
      salt: nutrientsRaw['salt_100g'],
    );

    final nutrientLevels = NutrientLevels(
      sugars: nutrientLevelsRaw['sugars']?.toString() ?? 'unknown',
      salt: nutrientLevelsRaw['salt']?.toString() ?? 'unknown',
      fat: nutrientLevelsRaw['fat']?.toString() ?? 'unknown',
      saturatedFat: nutrientLevelsRaw['saturated-fat']?.toString() ?? 'unknown',
    );

    // Calculate Score (0-100) using the unified GutScoreUtils
    int? score;
    if (nutriscore != null || novaGroup != null) {
      score = GutScoreUtils.calculateGutScore(nutriscore, novaGroup);
    }

    return OffProduct(
      productName: name ?? 'Unknown Product',
      brand: brand,
      imageUrl: imageUrl,
      barcode: product['code'],
      score: score,
      status: score != null ? GutScoreUtils.getStatus(score) : null,
      statusColor: score != null ? GutScoreUtils.getStatusColor(score) : null,
      nutriscore: nutriscore,
      novaGroup: novaGroup,
      ecoscore: ecoscore,
      ingredientsText: ingredientsText,
      ingredients: ingredientsList,
      additivesCount: additivesCount,
      additives: additivesTags,
      allergens: allergensTags,
      allergensText: allergensText,
      labels: labels,
      category: category,
      categoryTag: categoryTag,
      nutrientLevels: nutrientLevels,
      nutrients: nutrients,
      impacts: _generateImpacts(nutriscore, novaGroup, ingredientsText ?? ''),
    );
  }

  List<ImpactDetail> _generateImpacts(String? nutriscore, dynamic nova, String ingredients) {
    List<ImpactDetail> impacts = [];

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
    List<String> targetGrades = [];
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

    // Try Search-a-licious (Modern, more stable for search)
    try {
      final gradesFilter = targetGrades.map((g) => 'nutrition_grades:$g').join(' OR ');
      final categoryFilter = category.contains(':') ? category : 'en:$category';

      // Search-a-licious URL
      final url = 'https://search.openfoodfacts.org/search';
      final params = {
        'q': 'categories_tags:$categoryFilter AND ($gradesFilter)',
        'sort_by': 'nutriscore_score',
        'fields': 'product_name,brands,image_front_url,nutrition_grades,code',
        'size': 5,
      };

      final response = await _dio.get(url, queryParameters: params);

      if (response.data != null && response.data['products'] != null) {
        final List products = response.data['products'];
        return products
            .map(
              (p) => OffProduct(
                productName: p['product_name'] ?? 'Unknown Product',
                brand: p['brands'] ?? 'Unknown Brand',
                imageUrl: p['image_front_url'],
                nutriscore: (p['nutrition_grades'] as String?)?.toLowerCase(),
                score: GutScoreUtils.calculateGutScore((p['nutrition_grades'] as String?)?.toLowerCase(), null),
                barcode: p['code'],
              ),
            )
            .toList();
      }
    } catch (e) {
      Log.e('OffService: Search-a-licious failed, falling back to v2: $e');

      // Fallback to v2 API (Legacy, might be 503 but better than nothing)
      try {
        final String encodedCat = Uri.encodeComponent(category);
        final String grades = targetGrades.join(',');
        final v2Url =
            'https://world.openfoodfacts.org/api/v2/search?categories_tags_en=$encodedCat&nutrition_grades_tags=$grades&sort_by=nutriscore_score&fields=product_name,brands,image_front_url,nutrition_grades,code&page_size=5';

        final response = await _dio.get(v2Url);
        if (response.data != null && response.data['products'] != null) {
          final List products = response.data['products'];
          return products
              .map(
                (p) => OffProduct(
                  productName: p['product_name'] ?? 'Unknown Product',
                  brand: p['brands'] ?? 'Unknown Brand',
                  imageUrl: p['image_front_url'],
                  nutriscore: (p['nutrition_grades'] as String?)?.toLowerCase(),
                  score: GutScoreUtils.calculateGutScore((p['nutrition_grades'] as String?)?.toLowerCase(), null),
                  barcode: p['code'],
                ),
              )
              .toList();
        }
      } catch (e2) {
        Log.e('OffService: V2 Fallback also failed: $e2');
      }
    }
    return [];
  }
}
