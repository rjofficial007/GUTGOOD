import 'package:flutter_test/flutter_test.dart';
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
      expect(energetic.symptoms.first.energyLevel, 8);

      final bloating = useCase.call('AI Response', userText: 'I am feeling bloated', isFinal: true);
      expect(bloating.symptoms.first.symptom, 'Bloating');

      final headache = useCase.call('AI Response', userText: 'I have a bad headache', isFinal: true);
      expect(headache.symptoms.first.symptom, 'Headache');
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
  });
}
