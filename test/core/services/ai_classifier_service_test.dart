import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/services/ai_classifier_service.dart';
import 'package:gutgood/core/services/ai_service.dart';
import 'package:mocktail/mocktail.dart';

class MockAiService extends Mock implements AiService {}

void main() {
  late MockAiService mockAiService;
  late AiClassifierService classifierService;

  setUp(() {
    mockAiService = MockAiService();
    classifierService = AiClassifierServiceImpl(aiService: mockAiService);
  });

  group('AiClassifierService', () {
    test('classifyImage returns correct result on success', () async {
      const jsonResponse = '{"image_mode": "FOOD", "intent": "MEAL_RATING", "confidence": 0.9, "reason": "Looks like a salad"}';

      when(
        () => mockAiService.generateContent(
          imageBytes: any(named: 'imageBytes'),
          systemInstruction: any(named: 'systemInstruction'),
          prompt: any(named: 'prompt'),
          usageType: 'system',
        ),
      ).thenAnswer((_) async => jsonResponse);

      final result = await classifierService.classifyImage(imageBytes: Uint8List(0));

      expect(result.imageMode, 'FOOD');
      expect(result.intent, 'MEAL_RATING');
      expect(result.confidence, 0.9);
    });

    test('classifyTextIntent returns correct intent on success', () async {
      const intentResponse = 'MEAL_RATING';

      when(
        () => mockAiService.generateContent(
          systemInstruction: any(named: 'systemInstruction'),
          prompt: any(named: 'prompt'),
          usageType: 'system',
        ),
      ).thenAnswer((_) async => intentResponse);

      final result = await classifierService.classifyTextIntent(userText: 'How is my lunch?');

      expect(result, 'MEAL_RATING');
    });

    test('classifyTextIntent falls back to COMPLETE_ANALYSIS on error', () async {
      when(
        () => mockAiService.generateContent(
          systemInstruction: any(named: 'systemInstruction'),
          prompt: any(named: 'prompt'),
          usageType: 'system',
        ),
      ).thenThrow(Exception('AI Error'));

      final result = await classifierService.classifyTextIntent(userText: 'Hello');

      expect(result, 'COMPLETE_ANALYSIS');
    });
  });
}
