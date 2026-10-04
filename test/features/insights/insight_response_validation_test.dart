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
        'frequency': 1,
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
    expect(top['description'], contains('early observation'));
  });

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
}
