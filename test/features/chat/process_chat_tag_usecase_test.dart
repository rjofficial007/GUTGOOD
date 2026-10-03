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

    test('should fallback extract symptoms from userText for core categories', () {
      final energetic = useCase.call('AI Response', userText: 'I feel energetic after eating this', isFinal: true);
      expect(energetic.symptoms.first.symptom, 'Energetic');
      // P2-4: no invented numbers; tagged for corroboration exclusion.
      expect(energetic.symptoms.first.energyLevel, isNull);
      expect(energetic.symptoms.first.severity, isNull);
      expect(energetic.symptoms.first.provenance, RecordProvenance.keywordFallback);

      final bloating = useCase.call('AI Response', userText: 'I am feeling bloated', isFinal: true);
      expect(bloating.symptoms.first.symptom, 'Bloating');
      expect(bloating.symptoms.first.severity, isNull);
      expect(bloating.symptoms.first.provenance, RecordProvenance.keywordFallback);

      final headache = useCase.call('AI Response', userText: 'I have a bad headache', isFinal: true);
      expect(headache.symptoms.first.symptom, 'Headache');
      expect(headache.symptoms.first.severity, isNull);
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

    test('J-4 does not stamp keyword-fallback symptoms (not prompt-extracted)', () {
      final result = useCase.call('AI Response', userText: 'I am feeling bloated', isFinal: true, promptVersion: AiVersions.chatPromptVersion, servedModel: 'gpt-test');

      expect(result.symptoms.single.symptom, 'Bloating');
      expect(result.symptoms.single.promptVersion, isNull);
      expect(result.symptoms.single.model, isNull);
    });

    test('swaps are trimmed to exactly 3 cards', () {
      const text =
          'Here you go [GUTGOOD_DATA]{"swaps": [{"title": "A", "subtitle": "s", "imageKeyword": "a", "tag": "T"}, {"title": "B", "subtitle": "s", "imageKeyword": "b", "tag": "T"}, {"title": "C", "subtitle": "s", "imageKeyword": "c", "tag": "T"}, {"title": "D", "subtitle": "s", "imageKeyword": "d", "tag": "T"}]}[/GUTGOOD_DATA]';

      final result = useCase.call(text, isFinal: true);

      expect(result.swaps.map((s) => s.title).toList(), ['A', 'B', 'C']);
    });

    test('short swap lists backfill from grounded fallback to exactly 3', () {
      const text = 'Here you go [GUTGOOD_DATA]{"swaps": [{"title": "A", "subtitle": "s", "imageKeyword": "a", "tag": "T", "barcode": "111"}]}[/GUTGOOD_DATA]';
      const fallback = [
        ProductSwap(title: 'A-grounded', subtitle: 's', imageKeyword: 'a', tag: 'T', barcode: '111'),
        ProductSwap(title: 'B-grounded', subtitle: 's', imageKeyword: 'b', tag: 'T', barcode: '222'),
        ProductSwap(title: 'C-grounded', subtitle: 's', imageKeyword: 'c', tag: 'T', barcode: '333'),
      ];

      final result = useCase.call(text, isFinal: true, fallbackSwaps: fallback);

      // LLM card kept first; barcode dupe skipped; filled to exactly 3.
      expect(result.swaps.map((s) => s.title).toList(), ['A', 'B-grounded', 'C-grounded']);
    });

    test('no swaps emitted stays empty without fallback (never manufactured)', () {
      final result = useCase.call('Solid meal, no changes needed', isFinal: true);

      expect(result.swaps, isEmpty);
    });
  });
}
