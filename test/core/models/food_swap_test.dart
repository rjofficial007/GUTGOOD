import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/insights/food_swap.dart';
import 'package:gutgood/core/models/scans/scan_result_details.dart';

void main() {
  test(
    'swap product details and complete macros survive parsing and navigation conversion',
    () {
      final response = <String, dynamic>{
        'name': 'Quinoa',
        'replaces': 'steel cut oats',
        'reason': 'A whole-grain alternative with a similar texture.',
        'category': 'Grain',
        'tag': 'Whole Grain',
        'imageKeyword': 'quinoa',
        'imageUrl': 'https://images.example/quinoa.jpg',
        'barcode': '1234567890123',
        'nutriscore': 'b',
        'impactLevel': 'positive',
        'benefitTags': ['Whole grain'],
        'structuredBenefits': [
          {
            'title': 'Whole grain',
            'description': 'Contains fiber.',
            'icon': 'leaf',
          },
        ],
        'whyBetterOption':
            'It provides a source-specific comparison and tradeoff.',
        'nutrition': {
          'calories': 120,
          'protein': '4 g',
          'totalFat': '2 g',
          'carbohydrates': '21 g',
          'fiber': '3 g',
          'sugars': '1 g',
          'saturatedFat': '0.3 g',
          'sodium': '7 mg',
          'servingSize': '45 g dry',
          'basis': 'per serving',
        },
      };

      final productSwap = ProductSwap.fromMap(response);
      final alternative = productSwap.toAlternative();
      final restored = SwapAlternative.fromMap(alternative.toMap());

      expect(restored.name, 'Quinoa');
      expect(restored.replaces, 'steel cut oats');
      expect(restored.reason, contains('whole-grain'));
      expect(restored.whyBetterOption, contains('tradeoff'));
      expect(restored.category, 'Grain');
      expect(restored.tag, 'Whole Grain');
      expect(restored.imageUrl, response['imageUrl']);
      expect(restored.barcode, response['barcode']);
      expect(restored.nutriscore, 'b');
      expect(restored.impactLevel, 'positive');
      expect(restored.benefits.single.title, 'Whole grain');
      expect(restored.nutrition.toMap(), response['nutrition']);
    },
  );
}
