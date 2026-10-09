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

    test('food photo strips unsupported label and packaging claims before persistence', () {
      final result = useCase.call(
        '[GUTGOOD_DATA]${jsonEncode({
          'image_mode': 'FOOD',
          'scan': {
            'productName': 'Dessert Platter',
            'category': 'meal',
            'allergens': 'Contains gluten, dairy, and nuts.',
            'additives': 'None',
            'additiveItems': ['E621'],
            'servingSize': '1 platter',
            'servingsPerPack': 4,
            'portionEaten': '1 serving',
            'nutriscore': 'B',
            'novaGroup': 2,
            'nutritionBasis': 'per_serving',
            'cycleInsight': {'phase': 'string', 'description': 'string', 'tags': []},
          },
        })}[/GUTGOOD_DATA]',
        isFinal: true,
      );

      final scan = result.scan!;
      expect(scan.allergens, isNull);
      expect(scan.additives, isNull);
      expect(scan.additiveItems, isEmpty);
      expect(scan.servingSize, isNull);
      expect(scan.nutriscore, isNull);
      expect(scan.novaGroup, isNull);
      expect(scan.nutritionEstimated, isTrue);
      expect(scan.cycleInsight, isNull);
      final storedScan = scan.rawData!['scan'] as Map<String, dynamic>;
      expect(storedScan['allergens'], isNull);
      expect(storedScan['additives'], isNull);
      expect(storedScan['cycleInsight'], isNull);
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
            'replaces': 'Original yogurt',
            'reason': 'An option without added sugar',
            'tag': 'NO ADDED SUGAR',
            'benefitTags': ['No added sugar'],
            'structuredBenefits': [
              {'title': 'No added sugar', 'description': 'The supplied label lists no added sugar.', 'icon': 'leaf'},
            ],
            'whyBetterOption': 'The supplied labels show less added sugar per 100 g.',
            'nutrition': {'calories': 65, 'protein': '4 g', 'basis': 'per 100 g'},
          },
          {'name': 'Kefir', 'replaces': 'Original yogurt', 'reason': 'Another supported option', 'tag': 'T'},
          {'name': 'Soy yogurt', 'replaces': 'Original yogurt', 'reason': 'Another supported option', 'tag': 'T'},
          {'name': 'Cottage cheese', 'replaces': 'Original yogurt', 'reason': 'Another supported option', 'tag': 'T'},
        ],
      };
      final result = useCase.call(
        '[GUTGOOD_DATA]${jsonEncode(payload)}[/GUTGOOD_DATA]',
        isFinal: true,
        fallbackSwaps: const [
          ProductSwap(
            title: 'Plain yogurt',
            subtitle: 'Catalog alternative',
            imageKeyword: 'plain yogurt',
            tag: 'NO ADDED SUGAR',
            alternative: SwapAlternative(
              foodId: 'plain-yogurt-123',
              name: 'Plain yogurt',
              nutrition: SwapNutrition(calories: 65, protein: '4 g', basis: 'per 100 g'),
            ),
          ),
        ],
      );
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

    test('shows up to four distinct usable swaps without hiding partial results', () {
      const a = ProductSwap(title: 'A', subtitle: 'Supported reason', imageKeyword: 'a', tag: 'T');
      const duplicate = ProductSwap(title: ' a ', subtitle: 'Same food', imageKeyword: 'a', tag: 'T');
      const b = ProductSwap(title: 'B', subtitle: 'Another reason', imageKeyword: 'b', tag: 'T');
      const c = ProductSwap(title: 'C', subtitle: 'Third reason', imageKeyword: 'c', tag: 'T');
      const d = ProductSwap(title: 'D', subtitle: 'Fourth reason', imageKeyword: 'd', tag: 'T');
      const invalid = ProductSwap(title: '', subtitle: '', imageKeyword: '', tag: 'T');
      expect(normalizeSwapCards([a, b, c, d], []), [a, b, c, d]);
      expect(normalizeSwapCards([a, duplicate, invalid, b, c, d], []), [a, b, c, d]);
      expect(normalizeSwapCards([a, b, c], []), [a, b, c]);
      expect(normalizeSwapCards([], [a, b]), isEmpty);
    });

    test('ice cream photo keeps swaps and labels supplied nutrition as an estimate', () {
      final swaps = ['Coconut milk ice cream', 'Soy frozen yogurt bowl', 'Oat milk ice cream', 'Banana nice cream'].map((name) => {
        'name': name,
        'replaces': 'vanilla ice cream',
        'reason': 'A different frozen dessert base; check its label.',
        'nutrition': {'calories': 150, 'protein': 2, 'basis': 'per serving'},
      }).toList();
      AiAnalysisResult parse(List<Map<String, Object>> alternatives) => useCase.call(
        '**Would I swap anything?**\nTry a different frozen dessert.\n**The GutGood take:**\nEnjoy your dessert.\n'
        '[GUTGOOD_DATA]${jsonEncode({
          'scan': {'productName': 'Vanilla Ice Cream', 'category': 'meal', 'swaps': swaps},
          'swaps': alternatives,
        })}[/GUTGOOD_DATA]',
        isFinal: true,
      );

      final complete = parse(swaps);
      expect(complete.swaps, hasLength(4));
      expect(complete.scan!.swaps, hasLength(4));
      expect(complete.swaps.every((swap) => swap.toAlternative().nutrition.hasData), isTrue);
      expect(complete.swaps.first.toAlternative().nutrition.basis, contains('not verified'));
      expect(complete.text, contains('Would I swap anything?'));

      final partial = parse(swaps.take(1).toList());
      expect(partial.swaps, hasLength(1));
      expect(partial.scan!.swaps, hasLength(1));
      expect(partial.text, contains('Would I swap anything?'));

    });

    test('dessert spread keeps component swaps in chat and scan persistence', () {
      final result = useCase.call('[GUTGOOD_DATA]${jsonEncode({
        'scan': {'productName': 'Dessert Spread', 'category': 'meal'},
        'swaps': [
          for (final name in ['Fruit Parfait', 'Yogurt with Berries', 'Chia Seed Pudding', 'Dark Chocolate Bark with Nuts'])
            {'name': name, 'replaces': 'Chocolate Cake', 'reason': 'A different dessert option.', 'nutrition': {'calories': 150}},
        ],
      })}[/GUTGOOD_DATA]', isFinal: true);
      expect(result.swaps, hasLength(4));
      expect(result.scan!.swaps, hasLength(4));
      expect(result.swaps.first.toAlternative().replaces, 'Chocolate Cake');
      expect(result.swaps.every((swap) => swap.toAlternative().nutrition.hasData), isTrue);
      expect(result.swaps.first.toAlternative().nutrition.basis, contains('not verified'));
      final restored = AiAnalysisResult.fromMap(result.toMap());
      expect(restored.swaps.map((swap) => swap.title), result.swaps.map((swap) => swap.title));
    });

    test('keeps swap details and marks unsupported nutrition as an estimate', () {
      const a = ProductSwap(
        title: 'Chickpeas',
        subtitle: 'Adds a plant-based option.',
        imageKeyword: 'chickpeas',
        tag: 'ALTERNATIVE',
        alternative: SwapAlternative(
          foodId: 'Chickpeas',
          name: 'Chickpeas',
          whyBetterOption: 'Replace the rice with chickpeas for a different texture.',
          benefits: [SwapBenefit(title: 'Plant-based', description: 'A legume option.', icon: 'leaf')],
          nutrition: SwapNutrition(calories: 164, fiber: '7.6 g', basis: 'per 100 g'),
        ),
      );
      const b = ProductSwap(title: 'B', subtitle: 'Reason B', imageKeyword: 'b', tag: 'T');
      const c = ProductSwap(title: 'C', subtitle: 'Reason C', imageKeyword: 'c', tag: 'T');
      const d = ProductSwap(title: 'D', subtitle: 'Reason D', imageKeyword: 'd', tag: 'T');

      final normalized = normalizeSwapCards([a, b, c, d], []);

      expect(normalized, hasLength(4));
      expect(normalized.first.toAlternative().whyBetterOption, contains('Replace the rice'));
      expect(normalized.first.toAlternative().benefits.single.title, 'Plant-based');
      expect(normalized.first.toAlternative().nutrition.hasData, isTrue);
      expect(normalized.first.toAlternative().nutrition.basis, contains('not verified'));
      expect(normalized.first.barcode, isNull);
      expect(normalized.first.nutriscore, isNull);
    });

    test('no swaps emitted stays empty without fallback (never manufactured)', () {
      final result = useCase.call('Solid meal, no changes needed', isFinal: true);

      expect(result.swaps, isEmpty);
    });
  });
}
