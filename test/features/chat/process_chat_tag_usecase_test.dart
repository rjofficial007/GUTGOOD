import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/ai/protocol/ai_constants.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/features/chat/domain/usecases/process_chat_tag_usecase.dart';

void main() {
  late ProcessChatTagUseCase useCase;

  setUp(() {
    useCase = ProcessChatTagUseCase();
  });

  group('ProcessChatTagUseCase', () {
    test('should extract symptom when [SYMPTOM] tag is present', () {
      const text = 'I feel bad [SYMPTOM]{"symptom": "Bloating", "severity": 3, "time": "2023-01-01T12:00:00Z"}[/SYMPTOM]';

      final result = useCase.call(text, isFinal: true);

      expect(result.text, 'I feel bad');
      expect(result.symptoms.first.symptom, 'Bloating');
    });

    test('should extract meal when [MEAL] tag is present', () {
      const text = 'Had lunch [MEAL]{"items": [{"name": "Apple", "confidence": 0.9}, {"name": "Banana", "confidence": 0.9}], "time": "2023-01-01T12:00:00Z"}[/MEAL]';

      final result = useCase.call(text, isFinal: true);

      expect(result.text, 'Had lunch');
      expect(result.meal?.items.length, 2);
    });

    test('preserves structured food tags and omits unknown occurrence metadata', () {
      const text = 'Saved [GUTGOOD_DATA]{"meal":{"items":["Lentils","Brown rice"],"foodTags":["Legumes","whole grains","unknown"]}}[/GUTGOOD_DATA]';

      final result = useCase.call(text, isFinal: true);

      expect(result.meal!.foodTags, ['legumes', 'whole_grains']);
      expect(result.meal!.toMap(), contains('foodTags'));
      expect(result.meal!.toMap(), isNot(contains('occurredAtProvenance')));
      expect(result.meal!.toMap(), isNot(contains('occurredAt')));
    });

    test('should extract scan when [SCAN] tag is present', () {
      const text = 'Check this [SCAN]{"productName": "Oats", "brand": "Quaker", "category": "food", "score": 90, "impact": "Great"}[/SCAN]';

      final result = useCase.call(text, isFinal: true);

      expect(result.text, 'Check this');
      expect(result.scan?.productName, 'Oats');
    });

    test('should extract intent when [INTENT] tag is present', () {
      const text = 'Help me [INTENT]{"category": "meal_analysis", "confidence": 0.9}[/INTENT]';

      final result = useCase.call(text, isFinal: true);

      expect(result.text, 'Help me');
      expect(result.intent, 'meal_analysis');
      expect(result.metadata['intentConfidence'], 0.9);
    });

    test('extracts direct user-reported symptoms without fallback provenance or invented values', () {
      final energetic = useCase.call('AI Response', userText: 'I feel energetic after eating this', isFinal: true);
      expect(energetic.symptoms.first.symptom, 'Energetic');
      expect(energetic.symptoms.first.severity, isNull);
      expect(energetic.symptoms.first.provenance, RecordProvenance.user);
      expect(energetic.symptoms.first.occurredAt, isNull);
      expect(energetic.symptoms.first.notes, isNull);
      expect(energetic.symptoms.first.toMap(), isNot(contains('severity')));
      expect(energetic.symptoms.first.toMap(), isNot(contains('mood')));
      expect(energetic.symptoms.first.toMap(), isNot(contains('sleep')));

      final bloating = useCase.call('AI Response', userText: 'I am feeling bloated', isFinal: true);
      expect(bloating.symptoms.first.symptom, 'Bloating');
      expect(bloating.symptoms.first.severity, isNull);
      expect(bloating.symptoms.first.provenance, RecordProvenance.user);

      final headache = useCase.call('AI Response', userText: 'I have a bad headache', isFinal: true);
      expect(headache.symptoms.first.symptom, 'Headache');
      expect(headache.symptoms.first.severity, isNull);

      final negated = useCase.call('AI Response', userText: "I don't feel energetic after eating this", isFinal: true);
      expect(negated.symptoms, isEmpty);
    });

    test('should parse envelope v and verdict from the unified block', () {
      const text = 'Done [GUTGOOD_DATA]{"v": 1, "verdict": "food", "intent": "COMPLETE_ANALYSIS"}[/GUTGOOD_DATA]';
      final result = useCase.call(text, isFinal: true);
      expect(result.schemaVersion, 1);
      expect(result.verdict, 'food');
      expect(result.intent, 'COMPLETE_ANALYSIS');
    });

    test('should route AI meal time to occurredAt, not the ordering clock', () {
      final mealTime = DateTime.now().subtract(const Duration(hours: 3));
      final text = 'Logged [GUTGOOD_DATA]{"meal": {"items": ["Dal"], "time": "${mealTime.toIso8601String()}"}}[/GUTGOOD_DATA]';
      final before = DateTime.now();
      final result = useCase.call(text, isFinal: true);
      expect(result.meal, isNotNull);
      expect(result.meal!.occurredAt, mealTime);
      expect(result.meal!.occurredAtProvenance, OccurrenceProvenance.aiEstimated);
      // createdAt is log time (≈ now), never the AI estimate.
      expect(result.meal!.createdAt.isAfter(before.subtract(const Duration(seconds: 5))), isTrue);
      expect(result.meal!.eventTime, mealTime);
    });

    test('should NOT extract symptoms from AI text to prevent hallucinations', () {
      final result = useCase.call('This meal will make you feel energetic!', isFinal: true);
      expect(result.symptoms, isEmpty);
    });

    test('should still extract symptoms from structured [SYMPTOM] tag in AI text even if userText is null', () {
      const text = 'Logged. [SYMPTOM]{"symptom": "Bloating", "severity": 3}[/SYMPTOM]';
      final result = useCase.call(text, userText: null, isFinal: true);
      expect(result.symptoms.first.symptom, 'Bloating');
    });

    test('should return original text if no tags are present', () {
      const text = 'Hello world';
      final result = useCase.call(text, isFinal: true);
      expect(result.text, 'Hello world');
      expect(result.scan, isNull);
      expect(result.meal, isNull);
      expect(result.symptoms, isEmpty);
    });

    test('J-4 stamps promptVersion/servedModel onto every extracted record', () {
      const text =
          'Done [SCAN]{"productName": "Oats", "brand": "Quaker", "category": "food", "score": 90, "impact": "Great"}[/SCAN] '
          '[MEAL]{"items": [{"name": "Apple", "confidence": 0.9}]}[/MEAL] '
          '[SYMPTOM]{"symptom": "Bloating", "severity": 3}[/SYMPTOM]';
      final result = useCase.call(text, isFinal: true, promptVersion: AiVersions.chatPromptVersion, servedModel: 'gpt-test');

      expect(result.scan?.promptVersion, AiVersions.chatPromptVersion);
      expect(result.scan?.model, 'gpt-test');
      expect(result.meal?.promptVersion, AiVersions.chatPromptVersion);
      expect(result.meal?.model, 'gpt-test');
      expect(result.symptoms.single.promptVersion, AiVersions.chatPromptVersion);
      expect(result.symptoms.single.model, 'gpt-test');
    });

    test('J-4 leaves records unversioned when no versions are passed', () {
      const text = 'Done [SCAN]{"productName": "Oats", "brand": "Quaker", "category": "food", "score": 90, "impact": "Great"}[/SCAN]';
      final result = useCase.call(text, isFinal: true);

      expect(result.scan?.promptVersion, isNull);
      expect(result.scan?.model, isNull);
    });

    test('J-4 stamps explicit user-text symptom records', () {
      final result = useCase.call('AI Response', userText: 'I am feeling bloated', isFinal: true, promptVersion: AiVersions.chatPromptVersion, servedModel: 'gpt-test');

      expect(result.symptoms.single.symptom, 'Bloating');
      expect(result.symptoms.single.provenance, RecordProvenance.user);
      expect(result.symptoms.single.promptVersion, AiVersions.chatPromptVersion);
      expect(result.symptoms.single.model, 'gpt-test');
    });

    test('swaps are trimmed to exactly 4 cards', () {
      const text =
          'Here you go [GUTGOOD_DATA]{"swaps": [{"title": "A", "subtitle": "s", "imageKeyword": "a", "tag": "T"}, {"title": "B", "subtitle": "s", "imageKeyword": "b", "tag": "T"}, {"title": "C", "subtitle": "s", "imageKeyword": "c", "tag": "T"}, {"title": "D", "subtitle": "s", "imageKeyword": "d", "tag": "T"}]}[/GUTGOOD_DATA]';

      final result = useCase.call(text, isFinal: true);

      expect(result.swaps.map((s) => s.title).toList(), ['A', 'B', 'C', 'D']);
    });

    test('catalog data enriches selected swaps without adding unselected products', () {
      const text =
          'Here you go [GUTGOOD_DATA]{"swaps": [{"title": "A", "subtitle": "s", "imageKeyword": "a", "tag": "T", "barcode": "111"}, {"title": "B", "subtitle": "s", "imageKeyword": "b", "tag": "T"}, {"title": "C", "subtitle": "s", "imageKeyword": "c", "tag": "T"}, {"title": "D", "subtitle": "s", "imageKeyword": "d", "tag": "T"}]}[/GUTGOOD_DATA]';
      const fallback = [
        ProductSwap(title: 'A-grounded', subtitle: 's', imageKeyword: 'a', tag: 'T', barcode: '111'),
        ProductSwap(title: 'B-grounded', subtitle: 's', imageKeyword: 'b', tag: 'T', barcode: '222'),
        ProductSwap(title: 'C-grounded', subtitle: 's', imageKeyword: 'c', tag: 'T', barcode: '333'),
        ProductSwap(title: 'D-grounded', subtitle: 's', imageKeyword: 'd', tag: 'T', barcode: '444'),
      ];

      final result = useCase.call(text, isFinal: true, fallbackSwaps: fallback);

      // The catalog enriches selected choices without replacing them with unselected candidates.
      expect(result.swaps.map((s) => s.title).toList(), ['A-grounded', 'B', 'C', 'D']);
    });

    test('shared swap details survive AI, chat and scan persistence', () {
      final payload = {
        'scan': {'productName': 'Original yogurt', 'score': 50},
        'swaps': [
          {
            'name': 'Plain yogurt',
            'reason': 'An option without added sugar',
            'tag': 'NO ADDED SUGAR',
            'benefitTags': ['No added sugar'],
            'structuredBenefits': [
              {'title': 'No added sugar', 'description': 'The supplied label lists no added sugar.', 'icon': 'leaf'},
            ],
            'whyBetterOption': 'The supplied labels show less added sugar per 100 g.',
            'nutrition': {'calories': 65, 'protein': '4 g', 'basis': 'per 100 g'},
          },
          {'name': 'Kefir', 'reason': 'Another supported option', 'tag': 'T'},
          {'name': 'Soy yogurt', 'reason': 'Another supported option', 'tag': 'T'},
          {'name': 'Cottage cheese', 'reason': 'Another supported option', 'tag': 'T'},
        ],
      };
      final result = useCase.call('[GUTGOOD_DATA]${jsonEncode(payload)}[/GUTGOOD_DATA]', isFinal: true);
      expect(result.swaps, hasLength(4));
      final restored = AiAnalysisResult.fromMap(result.toMap());
      final card = ProductSwap.fromMap(restored.swaps.first.toMap()).toAlternative();
      final persisted = ScanResult.fromMap(restored.scan!.toPersistenceMap()).foodSwap!.alternatives.first;
      for (final alternative in [card, persisted]) {
        expect(alternative.benefits.single.description, 'The supplied label lists no added sugar.');
        expect(alternative.whyBetterOption, 'The supplied labels show less added sugar per 100 g.');
        expect(alternative.nutrition.calories, 65);
        expect(alternative.nutrition.basis, 'per 100 g');
      }
    });

    test('shows exactly four distinct valid swaps and does not manufacture a quota', () {
      const a = ProductSwap(title: 'A', subtitle: 'Supported reason', imageKeyword: 'a', tag: 'T');
      const duplicate = ProductSwap(title: ' a ', subtitle: 'Same food', imageKeyword: 'a', tag: 'T');
      const b = ProductSwap(title: 'B', subtitle: 'Another reason', imageKeyword: 'b', tag: 'T');
      const c = ProductSwap(title: 'C', subtitle: 'Third reason', imageKeyword: 'c', tag: 'T');
      const d = ProductSwap(title: 'D', subtitle: 'Fourth reason', imageKeyword: 'd', tag: 'T');
      const invalid = ProductSwap(title: '', subtitle: '', imageKeyword: '', tag: 'T');
      expect(normalizeSwapCards([a, b, c, d], []), [a, b, c, d]);
      expect(normalizeSwapCards([a, duplicate, invalid, b, c, d], []), [a, b, c, d]);
      expect(normalizeSwapCards([a, b, c], []), isEmpty);
      expect(normalizeSwapCards([], [a, b]), isEmpty);
    });

    test('no swaps emitted stays empty without fallback (never manufactured)', () {
      final result = useCase.call('Solid meal, no changes needed', isFinal: true);

      expect(result.swaps, isEmpty);
    });
  });
}
