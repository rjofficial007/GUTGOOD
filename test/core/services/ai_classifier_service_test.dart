import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/ai/classification/ai_classifier_service.dart';
import 'package:gutgood/core/ai/client/ai_client.dart';
import 'package:mocktail/mocktail.dart';

class MockAiService extends Mock implements AiClient {}

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

    test('meal rating phrasing keeps its specialized route without a classifier call', () async {
      for (final phrase in ['So, thoughts on that lunch?', 'How is my lunch?']) {
        expect(await classifierService.classifyTextIntent(userText: phrase), 'MEAL_RATING');
      }
      verifyZeroInteractions(mockAiService);
    });

    test('classifyTextIntent resolves common phrasings on-device without a model call', () async {
      // Otherwise every text turn pays a round trip before the reply can stream.
      final result = await classifierService.classifyTextIntent(userText: 'How many calories are in this?');

      expect(result, 'NUTRITION_ANALYSIS');
      verifyNever(
        () => mockAiService.generateContent(
          systemInstruction: any(named: 'systemInstruction'),
          prompt: any(named: 'prompt'),
          usageType: any(named: 'usageType'),
        ),
      );
    });

    test('classifyTextIntent fast-path is case and whitespace tolerant', () async {
      final result = await classifierService.classifyTextIntent(userText: '  Is This Healthy?  ');

      expect(result, 'HEALTH_ASSESSMENT');
    });

    test('greetings use the general route without a classifier model call', () async {
      final result = await classifierService.classifyTextIntent(userText: 'Hello');

      expect(result, 'COMPLETE_ANALYSIS');
      verifyZeroInteractions(mockAiService);
    });
  });

  group('classifyImage UI-hint fast path (K-3)', () {
    test('known hints resolve the mode with zero model calls', () async {
      const hints = {'food': 'FOOD', 'menu': 'RESTAURANT_MENU', 'label': 'INGREDIENTS_LABEL', 'barcode': 'PRODUCT_BARCODE'};
      for (final entry in hints.entries) {
        final result = await classifierService.classifyImage(imageBytes: Uint8List(0), modeHint: entry.key);

        expect(result.imageMode, entry.value);
        expect(result.intent, 'COMPLETE_ANALYSIS');
        expect(result.confidence, 1.0);
        expect(result.reason, 'ui-hint');
      }
      verifyZeroInteractions(mockAiService);
    });

    test('hinted intent resolves from text without vision bytes', () async {
      final result = await classifierService.classifyImage(imageBytes: Uint8List(0), userText: 'How many calories?', modeHint: 'food');

      expect(result.imageMode, 'FOOD');
      expect(result.intent, 'NUTRITION_ANALYSIS');
      verifyZeroInteractions(mockAiService);
    });

    test('hints are case and whitespace tolerant', () async {
      final result = await classifierService.classifyImage(imageBytes: Uint8List(0), modeHint: '  Menu ');

      expect(result.imageMode, 'RESTAURANT_MENU');
      verifyZeroInteractions(mockAiService);
    });

    test('gallery and unknown hints fall through to vision classification', () async {
      const jsonResponse = '{"image_mode": "PACKAGED_PRODUCT", "intent": "COMPLETE_ANALYSIS", "confidence": 0.8}';
      when(
        () => mockAiService.generateContent(
          imageBytes: any(named: 'imageBytes'),
          systemInstruction: any(named: 'systemInstruction'),
          prompt: any(named: 'prompt'),
          usageType: 'system',
        ),
      ).thenAnswer((_) async => jsonResponse);

      for (final hint in ['gallery', 'unknown', null]) {
        final result = await classifierService.classifyImage(imageBytes: Uint8List(0), modeHint: hint);

        expect(result.imageMode, 'PACKAGED_PRODUCT');
        expect(result.reason, isNull);
      }
      verify(
        () => mockAiService.generateContent(
          imageBytes: any(named: 'imageBytes'),
          systemInstruction: any(named: 'systemInstruction'),
          prompt: any(named: 'prompt'),
          usageType: 'system',
        ),
      ).called(3);
    });
  });
}
