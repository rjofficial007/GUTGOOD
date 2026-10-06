import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/insights/body_pattern.dart';
import 'package:gutgood/features/insights/data/repositories/insight_repository_impl.dart';
import 'package:gutgood/features/insights/domain/services/insight_response_validator.dart';

void main() {
  Map<String, dynamic> baseline() => {
    'status': 'ready',
    'topInsight': {
      'title': 'Your first food and symptom snapshot',
      'description':
          'You logged oats and rice and reported mild bloating. A repeated association is not established.',
      'nextSteps': ['Record when bloating starts after your logged meals.'],
    },
    'weeklyRecap': {'foodsLogged': 3},
    'detectedPatterns': [],
  };

  test(
    'accepts a personalized baseline without previous scores or patterns',
    () {
      expect(isUsableInsightResponse(baseline()), isTrue);
    },
  );

  test('rejects insufficient and empty responses for eligible users', () {
    expect(
      isUsableInsightResponse({...baseline(), 'status': 'insufficient_data'}),
      isFalse,
    );
    expect(
      isUsableInsightResponse({
        ...baseline(),
        'weeklyRecap': {'foodsLogged': 0},
      }),
      isFalse,
    );
    expect(isUsableInsightResponse({}), isFalse);
  });

  test('accepts a valid insight when application-owned status is omitted', () {
    final response = baseline()..remove('status');

    expect(isUsableInsightResponse(response), isTrue);
  });

  test('rejects copied placeholder instructions even when marked ready', () {
    final data = baseline();
    (data['topInsight'] as Map)['description'] =
        "Synthesize a personalized summary of the user's logged meals and reported symptoms.";
    expect(isUsableInsightResponse(data), isFalse);
  });

  test('removes derived food claims when there are no qualified candidates', () {
    final response = {
      ...baseline(),
      'topInsight': {
        ...baseline()['topInsight'] as Map,
        'kind': 'progress',
        'confidence': 0.5,
        'frequency': 4,
        'description': 'Bloating happened after fried chicken burgers on multiple occasions.',
        'observation': 'Bloating followed the burger repeatedly.',
      },
      'healing': {
        'goal': 'Increase energy levels',
        'trend': 'Improving energy after meals',
        'topFoodId': 'roasted_chicken_dinner',
        'foods': [
          {
            'foodId': 'roasted_chicken_dinner',
            'name': 'Roasted Chicken Dinner',
            'impactLevel': 'high',
            'frequencyCount': 1,
            'confidence': 'medium',
            'whyItWorks': [
              {'title': 'Lean Protein', 'description': 'Helps sustain energy levels.'},
            ],
          },
        ],
      },
      'detectedPatterns': [
        {'trigger': 'Roasted Chicken Dinner', 'frequency': 1},
      ],
      'foodImpactBalance': {'positivePercent': 100, 'neutralPercent': 0, 'negativePercent': 0},
      'foodImpacts': [
        {'food': 'Roasted Chicken Dinner', 'impactDirection': 'positive'},
      ],
      'smartSwap': {'after': 'Oatmeal', 'benefit': 'Reduces bloating'},
      'topHealing': {'food': 'Roasted Chicken Dinner', 'effects': 'More energy'},
    };

    final normalized = InsightResponseValidator.normalize(response, patternCandidates: const []).data;
    final healing = normalized['healing'] as Map;
    final top = normalized['topInsight'] as Map;

    expect(healing['foods'] as List, isEmpty);
    expect(normalized['detectedPatterns'], isEmpty);
    expect(normalized['foodImpacts'], isEmpty);
    expect((normalized['foodImpactBalance'] as Map)['positivePercent'], 0);
    expect(normalized.containsKey('smartSwap'), isFalse);
    expect(normalized.containsKey('topHealing'), isFalse);
    expect(top['type'], 'progress');
    expect(top['confidence'], 'low');
    expect(top['confidenceScore'], 0.5);
    expect(top['frequency'], 1);
    expect(top['description'], contains('early observation'));
    expect(top['description'], isNot(contains('multiple occasions')));
    expect(top['observation'], top['description']);
  });

  test('grounds top insight frequency and narrative in its matching pattern candidate', () {
    const candidate = BodyPattern(
      type: BodyPattern.typeBloating,
      trigger: 'Fried Chicken Burger',
      reaction: 'Bloating',
      frequency: 2,
      confidence: BodyPattern.confidenceMedium,
      confidenceScore: 0.65,
      description: 'You reported bloating after 2 recent meals containing fried chicken burger.',
      involvedFoods: ['fried chicken burger'],
      positiveCount: 2,
      negativeCount: 1,
      evidenceRatio: 2 / 3,
      updatedAt: '2026-10-07T00:00:00.000Z',
    );
    final response = {
      ...baseline(),
      'topInsight': {
        'title': 'Bloating After Fried Foods',
        'domain': 'bloating',
        'involvedFoods': ['Fried Chicken Burger'],
        'frequency': 4,
        'confidence': 'high',
        'confidenceScore': 0.9,
        'description': 'Bloating followed this food on four occasions.',
      },
    };

    final top = InsightResponseValidator.normalize(response, patternCandidates: [candidate]).data['topInsight'] as Map;

    expect(top['frequency'], 2);
    expect(top['positiveCount'], 2);
    expect(top['negativeCount'], 1);
    expect(top['confidence'], 'medium');
    expect(top['description'], candidate.description);
  });

  test(
    'keeps legacy trigger fields aligned with validated nested trigger evidence',
    () {
      const candidate = BodyPattern(
        type: BodyPattern.typeBloating,
        trigger: 'Fried Chicken Burger',
        reaction: 'Bloating',
        frequency: 2,
        confidence: BodyPattern.confidenceMedium,
        description: 'Bloating followed two recent fried chicken burger meals.',
        involvedFoods: ['fried chicken burger'],
        updatedAt: '2026-10-08T00:00:00.000Z',
      );
      final response = {
        ...baseline(),
        'triggerSymptom': '',
        'triggerTrend': '',
        'triggerFoods': <dynamic>[],
        'triggers': {
          'primarySymptom': 'bloating',
          'trend': 'Increasing',
          'foods': [
            {'foodId': 'fried_chicken_burger', 'name': 'Fried Chicken Burger'},
          ],
        },
      };

      final normalized = InsightResponseValidator.normalize(
        response,
        patternCandidates: [candidate],
      ).data;
      final nested = (normalized['triggers'] as Map)['foods'] as List;
      final legacy = normalized['triggerFoods'] as List;

      expect(normalized['triggerSymptom'], 'bloating');
      expect(normalized['triggerTrend'], 'Repeated association');
      expect(legacy, nested);
      expect((legacy.single as Map)['name'], 'Fried Chicken Burger');
    },
  );

  test('caps one-occurrence food evidence at low confidence', () {
    const candidate = BodyPattern(
      type: BodyPattern.typeEnergy,
      trigger: 'Roasted Chicken Dinner',
      reaction: 'High Energy',
      frequency: 2,
      confidence: BodyPattern.confidenceMedium,
      description: 'Repeated energy observation',
      updatedAt: '2026-10-03T00:00:00.000Z',
    );
    final response = {
      ...baseline(),
      'healing': {
        'goal': 'Increase energy levels',
        'foods': [
          {
            'foodId': 'roasted_chicken_dinner',
            'name': 'Roasted Chicken Dinner',
            'impactLevel': 'high',
            'frequencyCount': 1,
            'confidence': 'medium',
            'confidenceScore': 0.7,
            'whyItWorks': [
              {'title': 'Lean Protein'},
            ],
          },
        ],
      },
      'foodImpacts': [
        {'food': 'Roasted Chicken Dinner', 'impactDirection': 'positive', 'frequencyCount': 1, 'impactLevel': 'high'},
      ],
    };

    final normalized = InsightResponseValidator.normalize(response, patternCandidates: [candidate]).data;
    final food = ((normalized['healing'] as Map)['foods'] as List).single as Map;
    final impact = (normalized['foodImpacts'] as List).single as Map;

    expect(food['impactLevel'], 'low');
    expect(food['confidence'], 'low');
    expect(food['confidenceScore'], 0.5);
    expect(food['whyItWorks'], isEmpty);
    expect(impact['impactLevel'], 'low');
    expect(impact['confidence'], 'low');
    expect(impact['impactDirection'], 'neutral');
    expect((normalized['foodImpactBalance'] as Map)['positivePercent'], 0);
    expect((normalized['foodImpactBalance'] as Map)['neutralPercent'], 100);
  });

  test('removes unsupported mechanisms and derives balance from retained impacts', () {
    const candidate = BodyPattern(
      type: BodyPattern.typeEnergy,
      trigger: 'Oats',
      reaction: 'High Energy',
      frequency: 3,
      confidence: BodyPattern.confidenceMedium,
      description: 'Repeated energy observation',
      updatedAt: '2026-10-03T00:00:00.000Z',
    );
    final response = {
      ...baseline(),
      'healing': {
        'foods': [
          {
            'foodId': 'oats',
            'name': 'Oats',
            'whyItWorks': [
              {'title': 'Soluble Fiber', 'description': 'Repairs the gut lining.'},
            ],
          },
        ],
      },
      'foodImpacts': [
        {'food': 'Oats', 'impactDirection': 'positive', 'impactLevel': 'high'},
        {'food': 'Unsupported Food', 'impactDirection': 'negative'},
      ],
      'foodImpactBalance': {'positivePercent': 100, 'neutralPercent': 0, 'negativePercent': 0},
    };

    final normalized = InsightResponseValidator.normalize(response, patternCandidates: [candidate]).data;
    final food = ((normalized['healing'] as Map)['foods'] as List).single as Map;
    final impacts = normalized['foodImpacts'] as List;
    final balance = normalized['foodImpactBalance'] as Map;

    expect(food.containsKey('whyItWorks'), isFalse);
    expect(impacts, hasLength(1));
    expect((impacts.single as Map)['impactDirection'], 'positive');
    expect((impacts.single as Map)['impactLevel'], 'moderate');
    expect(balance['positivePercent'], 100);
    expect(balance['negativePercent'], 0);
  });

  test('does not match one food to a multi-food candidate', () {
    const candidate = BodyPattern(
      type: BodyPattern.typeBloating,
      trigger: 'Pizza + Garlic bread',
      reaction: 'Bloating',
      frequency: 3,
      confidence: BodyPattern.confidenceMedium,
      description: 'The meal combination was followed by bloating.',
      involvedFoods: ['pizza', 'garlic bread'],
      updatedAt: '2026-10-03T00:00:00.000Z',
    );
    final response = {
      ...baseline(),
      'triggers': {
        'foods': [
          {'foodId': 'pizza', 'name': 'Pizza', 'impactLevel': 'high'},
          {'foodId': 'pizza_garlic_bread', 'name': 'Pizza + Garlic bread', 'impactLevel': 'high'},
        ],
      },
    };

    final normalized = InsightResponseValidator.normalize(response, patternCandidates: [candidate]).data;
    final foods = (normalized['triggers'] as Map)['foods'] as List;

    expect(foods, hasLength(1));
    expect((foods.single as Map)['name'], 'Pizza + Garlic bread');
  });

  test('requires four complete distinct swap alternatives for a repeated negative food pattern', () {
    const candidate = BodyPattern(
      type: BodyPattern.typeBloating,
      trigger: 'Fried Chicken Burger',
      reaction: 'Bloating',
      frequency: 5,
      confidence: BodyPattern.confidenceMedium,
      description: 'Bloating was reported after five burger meals.',
      involvedFoods: ['fried chicken burger'],
      updatedAt: '2026-10-11T00:00:00Z',
    );
    final alternatives = ['Grilled Chicken Burger', 'Baked Chicken Burger', 'Grilled Fish Sandwich', 'Roasted Vegetable Sandwich']
        .map(
          (name) => {
            'foodId': name.toLowerCase().replaceAll(' ', '_'),
            'name': name,
            'reason': 'Try a different preparation.',
            'category': 'Meals & Bowls',
            'benefitTags': ['Different preparation'],
            'structuredBenefits': [
              {'title': 'Preparation', 'description': 'A different preparation to compare in your logs.', 'icon': 'leaf'},
            ],
            'whyBetterOption': 'Compare this preparation with your usual burger.',
            'imageUrl': null,
            'nutrition': null,
          },
        )
        .toList();
    Map<String, dynamic> normalize(List<dynamic> swaps) => InsightResponseValidator.normalize({...baseline(), 'foodSwaps': swaps}, patternCandidates: [candidate]).data;
    Map<String, dynamic> swap(List<dynamic> items, {String source = 'Fried Chicken Burger'}) => {
      'source': {'foodId': source.toLowerCase().replaceAll(' ', '_'), 'name': source},
      'alternatives': items,
    };

    for (final swaps in [
      <dynamic>[],
      [swap([])],
      [swap(alternatives.take(3).toList())],
      [
        swap([alternatives[0], alternatives[0], alternatives[1], alternatives[2]]),
      ],
      [
        swap([
          ...alternatives.take(3),
          {...alternatives.last, 'reason': ''},
        ]),
      ],
      [swap(alternatives, source: 'Unrelated soup')],
    ]) {
      final data = normalize(swaps);
      expect(data['foodSwaps'], isEmpty);
      expect(isUsableInsightResponse(data), isFalse);
    }

    final complete = normalize([swap(alternatives, source: 'FRIED CHICKEN BURGER')]);
    expect(isUsableInsightResponse(complete), isTrue);
    final savedSwap = (complete['foodSwaps'] as List).single as Map;
    expect(savedSwap['id'], 'swap_fried_chicken_burger');
    expect((savedSwap['source'] as Map)['name'], candidate.trigger);
    expect(savedSwap['alternatives'], hasLength(4));
  });

  test('positive-only and sleep-timing patterns do not require food replacement', () {
    for (final candidate in [
      const BodyPattern(
        type: BodyPattern.typeEnergy,
        trigger: 'Oats',
        reaction: 'High Energy',
        frequency: 3,
        confidence: 'Medium',
        description: 'Higher energy reported.',
        updatedAt: '',
      ),
      const BodyPattern(
        type: BodyPattern.typeSleep,
        trigger: 'Late night eating',
        reaction: 'Interrupted Sleep',
        frequency: 3,
        confidence: 'Medium',
        description: 'Poor sleep reported.',
        updatedAt: '',
      ),
    ]) {
      final data = InsightResponseValidator.normalize(baseline(), patternCandidates: [candidate]).data;
      expect(data['foodSwaps'], isEmpty);
      expect(isUsableInsightResponse(data), isTrue);
    }
  });
}
