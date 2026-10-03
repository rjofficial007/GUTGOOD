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

    test('classifyTextIntent parses the JSON object the prompt asks for', () async {
      // The intent prompt requests {"intent": "CATEGORY_NAME"} and the request
      // runs in JSON mode, so this is the real production shape. Returning the
      // raw JSON string silently broke the server-side per-intent max_tokens
      // budget (resolveMaxTokens does an exact-match lookup).
      when(
        () => mockAiService.generateContent(
          systemInstruction: any(named: 'systemInstruction'),
          prompt: any(named: 'prompt'),
          usageType: 'system',
        ),
      ).thenAnswer((_) async => '{"intent": "MEAL_RATING"}');

      // Deliberately does not match any fast-path keyword, so the JSON branch runs.
      final result = await classifierService.classifyTextIntent(userText: 'So, thoughts on that lunch?');

      expect(result, 'MEAL_RATING');
    });

    test('classifyTextIntent normalises a canonical token from prose', () async {
      when(
        () => mockAiService.generateContent(
          systemInstruction: any(named: 'systemInstruction'),
          prompt: any(named: 'prompt'),
          usageType: 'system',
        ),
      ).thenAnswer((_) async => 'The best match is SWAP_REQUEST here.');

      final result = await classifierService.classifyTextIntent(userText: 'Make it healthier');

      expect(result, 'SWAP_REQUEST');
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

    test('classifyTextIntent falls back to COMPLETE_ANALYSIS for an unknown intent', () async {
      when(
        () => mockAiService.generateContent(
          systemInstruction: any(named: 'systemInstruction'),
          prompt: any(named: 'prompt'),
          usageType: 'system',
        ),
      ).thenAnswer((_) async => '{"intent": "FLY_TO_THE_MOON"}');

      final result = await classifierService.classifyTextIntent(userText: 'Hello');

      expect(result, 'COMPLETE_ANALYSIS');
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
