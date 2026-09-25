import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/constants/ai_constants.dart';
import 'package:gutgood/core/models/chat/chat_message.dart';
import 'package:gutgood/core/models/insights/ai_insight.dart';
import 'package:gutgood/core/models/insights/ai_insight_details.dart';
import 'package:gutgood/core/models/insights/body_pattern.dart';
import 'package:gutgood/core/models/insights/food_swap.dart';
import 'package:gutgood/core/models/insights/insight_action.dart';
import 'package:gutgood/core/models/insights/insight_empty_state.dart';
import 'package:gutgood/core/models/insights/insight_evidence.dart';
import 'package:gutgood/core/models/insights/recent_insight_item.dart';
import 'package:gutgood/core/utils/insight_presentation.dart';
import 'package:gutgood/features/insights/domain/usecases/generate_insight_usecase.dart';

BodyPattern _pattern({int timeframeDays = 30, int frequency = 5, double ratio = 0.8}) => BodyPattern(
  type: BodyPattern.typeBloating,
  trigger: 'Pizza',
  reaction: 'Bloating',
  frequency: frequency,
  confidence: BodyPattern.confidenceHigh,
  description: 'Pizza bloat',
  involvedFoods: const ['pizza'],
  updatedAt: DateTime.now().toIso8601String(),
  totalSimilarMeals: 6,
  timeframeDays: timeframeDays,
  evidenceRatio: ratio,
  positiveCount: frequency,
  negativeCount: 1,
);

AIInsight _insight({InsightSummary? top}) => AIInsight(gutScore: 72, topInsight: top, detectedPatterns: [_pattern()], updatedAt: DateTime.now());

void main() {
  group('P2-10 presentation mapping (Dart-side)', () {
    test('emojiForFood resolves keywords case-insensitively with a default', () {
      expect(InsightPresentation.emojiForFood('Pepperoni Pizza'), '🍕');
      expect(InsightPresentation.emojiForFood('Overnight OATS'), '🥣');
      expect(InsightPresentation.emojiForFood('Masala Chai'), '🍵');
      expect(InsightPresentation.emojiForFood('Quinoa Bowl Surprise'), InsightPresentation.defaultFoodEmoji);
    });

    test('food emoji defaults derive from the name; stored emoji is kept', () {
      expect(HealingFood.fromMap(const {'name': 'Pizza', 'effect': 'x'}).emoji, '🍕');
      expect(TriggerFood.fromMap(const {'name': 'Oats', 'effect': 'x'}).emoji, '🥣');
      expect(TopHighlight.fromMap(const {'food': 'Salad', 'effects': 'x', 'timeframe': 'w', 'frequency': '1x'}).emoji, '🥗');
      expect(FoodImpact.fromMap(const {'food': 'Coffee', 'impactType': 'positive'}).emoji, '☕');

      // Stored values (legacy docs) win; empty strings count as missing.
      expect(HealingFood.fromMap(const {'name': 'Pizza', 'effect': 'x', 'emoji': '🌮'}).emoji, '🌮');
      expect(HealingFood.fromMap(const {'name': 'Pizza', 'effect': 'x', 'emoji': ''}).emoji, '🍕');
    });
  });

  group('P2-10 evidence models', () {
    test('PatternRef.fromBodyPattern carries the citable fields', () {
      final ref = PatternRef.fromBodyPattern(_pattern());

      expect(ref.trigger, 'Pizza');
      expect(ref.frequency, 5);
      expect(ref.evidenceRatio, 0.8);
      expect(ref.positiveCount, 5);
      expect(ref.negativeCount, 1);
      expect(ref.involvedFoods, ['pizza']);
    });

    test('InsightEvidence round-trips and rebuilds from patterns', () {
      const evidence = InsightEvidence(patternRefs: [], sampleSizes: SampleSizes(meals: 20, symptoms: 8, scans: 3), spanDays: 30);
      final roundTripped = InsightEvidence.fromMap(evidence.toMap());
      expect(roundTripped, evidence);

      final rebuilt = InsightEvidence.fromPatterns([_pattern(timeframeDays: 12)]);
      expect(rebuilt.spanDays, 12);
      expect(rebuilt.patternRefs, hasLength(1));
      expect(InsightEvidence.fromPatterns(const []).spanDays, 0);
    });
  });

  group('P2-10 insight v2 envelope', () {
    test('envelope fields round-trip through toMap/fromMap', () {
      final stamped = _insight().copyWith(
        periodFrom: DateTime.utc(2026, 8, 1),
        periodTo: DateTime.utc(2026, 8, 31),
        evidence: InsightEvidence.fromPatterns([_pattern()], sampleSizes: const SampleSizes(meals: 20, symptoms: 8, scans: 3)),
        actions: const ['Eat dinner earlier'],
        model: 'gpt-test',
        promptVersion: AiVersions.insightPromptVersion,
        status: AIInsight.statusReady,
        expiresAt: DateTime.utc(2026, 9, 2),
        origin: AIInsight.originClient,
      );

      final roundTripped = AIInsight.fromMap(stamped.toMap());

      expect(roundTripped.periodFrom, DateTime.utc(2026, 8, 1));
      expect(roundTripped.periodTo, DateTime.utc(2026, 8, 31));
      expect(roundTripped.evidence?.patternRefs, hasLength(1));
      expect(roundTripped.evidence?.sampleSizes.meals, 20);
      expect(roundTripped.evidence?.spanDays, 30);
      expect(roundTripped.actions, ['Eat dinner earlier']);
      expect(roundTripped.model, 'gpt-test');
      expect(roundTripped.promptVersion, AiVersions.insightPromptVersion);
      expect(roundTripped.status, AIInsight.statusReady);
      expect(roundTripped.expiresAt, DateTime.utc(2026, 9, 2));
      expect(roundTripped.origin, AIInsight.originClient);
    });

    test('legacy docs default the envelope', () {
      final legacy = AIInsight.fromMap({
        'gutScore': 70,
        'updatedAt': DateTime.now().toIso8601String(),
        'detectedPatterns': const [
          {'type': 'bloating', 'trigger': 'Pizza', 'reaction': 'Bloating', 'frequency': 3, 'confidence': 'Medium', 'description': 'x', 'timeframeDays': 9},
        ],
      });

      expect(legacy.status, AIInsight.statusReady);
      expect(legacy.evidence, isNull);
      expect(legacy.actions, isEmpty);
      expect(legacy.model, isNull);
      expect(legacy.promptVersion, isNull);
      expect(legacy.origin, isNull);
      expect(legacy.periodFrom, isNull);
      expect(legacy.expiresAt, isNull);
    });
  });

  group('stampInsightEnvelope', () {
    AIInsight base() => _insight(
      top: const InsightSummary(title: 't', description: 'd', type: 'Pattern', nextSteps: ['Step one']),
    );

    test('ready when candidates exist with ≥ 7d span; actions come from nextSteps', () {
      final stamped = stampInsightEnvelope(
        base(),
        candidates: [_pattern(timeframeDays: 12)],
        periodFrom: DateTime.utc(2026, 8, 1),
        periodTo: DateTime.utc(2026, 8, 31),
        sampleSizes: const SampleSizes(meals: 20, symptoms: 8, scans: 3),
        model: 'gpt-test',
        promptVersion: AiVersions.insightPromptVersion,
        expiresAt: DateTime.utc(2026, 9, 2),
      );

      expect(stamped.status, AIInsight.statusReady);
      expect(stamped.actions, ['Step one']);
      expect(stamped.evidence?.spanDays, 12);
      expect(stamped.evidence?.sampleSizes.scans, 3);
      expect(stamped.promptVersion, AiVersions.insightPromptVersion);
      expect(stamped.origin, AIInsight.originClient);
    });

    test('takeRecentChat keeps the head of a newest-first list', () {
      final chat = List.generate(15, (i) => ChatMessage(localId: 'm$i', role: 'user', text: 'msg $i', createdAt: DateTime.now()));

      final recent = takeRecentChat(chat);

      expect(recent, hasLength(10));
      expect(recent.first.localId, 'm0');
      expect(takeRecentChat(chat.take(5).toList()), hasLength(5));
    });

    test('eligibility depends on logs rather than pattern span', () {
      final noCandidates = stampInsightEnvelope(
        base(),
        candidates: [],
        periodFrom: DateTime.utc(2026, 8, 1),
        periodTo: DateTime.utc(2026, 8, 31),
        sampleSizes: const SampleSizes(meals: 2, symptoms: 1, scans: 0),
        model: 'gpt-test',
        promptVersion: AiVersions.insightPromptVersion,
        expiresAt: DateTime.utc(2026, 9, 2),
      );
      expect(noCandidates.status, AIInsight.statusInsufficientData);

      final thinSpan = stampInsightEnvelope(
        base(),
        candidates: [_pattern(timeframeDays: 3)],
        periodFrom: DateTime.utc(2026, 8, 28),
        periodTo: DateTime.utc(2026, 8, 31),
        sampleSizes: const SampleSizes(meals: 9, symptoms: 4, scans: 1),
        model: 'gpt-test',
        promptVersion: AiVersions.insightPromptVersion,
        expiresAt: DateTime.utc(2026, 9, 2),
      );
      expect(thinSpan.status, AIInsight.statusReady);
    });
  });

  group('v2 Spec Models Round-Trip', () {
    test('InsightAction round-trips through toMap/fromMap', () {
      const action = InsightAction(
        id: 'act_001',
        title: 'Increase prebiotic vegetables',
        description: 'Add more fiber-rich foods like leafy greens.',
        category: 'nutrition',
        impactLevel: 'high',
        difficulty: 'easy',
        status: 'not_started',
        whenToDo: 'Daily with meals',
        expectedBenefit: 'Higher fiber intake and less bloating',
        relatedPatternIds: ['pat_synergy_01'],
        relatedFoodIds: ['food_leafy_greens'],
        progress: ActionProgress(target: 7, completed: 2, unit: 'days'),
      );

      final roundTripped = InsightAction.fromMap(action.toMap());
      expect(roundTripped, action);
    });

    test('FoodSwap round-trips through toMap/fromMap', () {
      const swap = FoodSwap(
        id: 'swap_001',
        source: SwapSource(foodId: 'food_onion_rings', name: 'Onion Rings'),
        alternatives: [SwapAlternative(foodId: 'food_roasted_veg', name: 'Roasted Vegetables', reason: 'Lower in added frying fat.', impactLevel: 'high')],
        relatedPatternId: 'pat_digest_01',
      );

      final roundTripped = FoodSwap.fromMap(swap.toMap());
      expect(roundTripped, swap);
    });

    test('RecentInsightItem round-trips through toMap/fromMap', () {
      const item = RecentInsightItem(
        id: 'recent_001',
        kind: 'product_scan',
        date: '2024-09-14T08:00:00.000Z',
        dateLabel: 'Sep 14, 2024',
        title: 'Organic Greek Yogurt',
        description: 'Probiotic source',
        score: 92,
        destination: InsightDestination(screen: 'food_detail', id: 'food_greek_yogurt'),
      );

      final roundTripped = RecentInsightItem.fromMap(item.toMap());
      expect(roundTripped, item);
    });

    test('InsightEmptyState round-trips through toMap/fromMap', () {
      const emptyState = InsightEmptyState(
        reason: 'insufficient_data',
        title: "We're still learning about your gut",
        description: 'Log a few more meals and symptoms.',
        requirements: [EmptyStateRequirement(key: 'meals', label: 'Meals logged', current: 4, recommended: 10)],
        primaryAction: EmptyStateAction(label: 'Log a meal', route: 'meal_log'),
      );

      final roundTripped = InsightEmptyState.fromMap(emptyState.toMap());
      expect(roundTripped, emptyState);
    });

    test('AIInsight.fromMap parses gutScore whether Map or num', () {
      final mapScore = AIInsight.fromMap(const {
        'gutScore': {'score': 78, 'scoreDiff': 4},
      });
      expect(mapScore.gutScore, 78);

      final numScore = AIInsight.fromMap(const {'gutScore': 78});
      expect(numScore.gutScore, 78);
    });
  });
}
