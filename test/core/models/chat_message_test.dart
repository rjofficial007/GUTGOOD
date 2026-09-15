import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/chat/chat_message.dart';
import 'package:gutgood/core/models/journal/meal_log.dart';
import 'package:gutgood/core/models/journal/symptom_log.dart';
import 'package:gutgood/core/models/scans/ai_analysis_result.dart';
import 'package:gutgood/core/models/scans/scan_result.dart';
import 'package:gutgood/core/models/scans/scan_result_details.dart';

void main() {
  ScanResult scan() => ScanResult(productName: 'Test Cola', brand: 'Test', score: 42, impactType: ImpactType.neutral, impact: 'okay', createdAt: DateTime.now(), scanId: 's1');

  ChatMessage fatMessage() => ChatMessage(
    localId: 'm1',
    role: 'ai',
    text: 'analysis here',
    imageUrls: const ['https://x/food_images/abcdef0123456789.jpg'],
    imageHashes: const ['abcdef0123456789'],
    scanData: scan(),
    mealLogs: [
      MealLog(items: const ['Pizza'], firestoreId: 'j1', createdAt: DateTime.now()),
    ],
    symptomLogs: [SymptomLog(symptom: 'Bloating', firestoreId: 'j2', createdAt: DateTime.now())],
    swapData: const [ProductSwap(title: 'Oat milk', subtitle: 'swap', imageKeyword: 'oat milk', tag: 'BETTER')],
    analysisResult: AiAnalysisResult(text: 'analysis here', scan: scan()),
    foodMentions: const ['Pizza'],
    symptomMentions: const ['Bloating'],
    createdAt: DateTime.now(),
  );

  group('ChatMessage slim docs (P2-1)', () {
    test('toMap drops mealLogs and analysisResult, keeps the slim set', () {
      final map = fatMessage().toMap();

      expect(map.containsKey('mealLogs'), isFalse);
      expect(map.containsKey('analysisResult'), isFalse);

      // References + render/context fields survive.
      expect(map['journalEntryIds'], ['j1', 'j2']);
      expect(map['scanId'], 's1');
      expect((map['scanPreview'] as Map)['productName'], 'Test Cola');
      expect(map['symptomLogs'] as List, hasLength(1));
      expect(map['swapData'] as List, hasLength(1));
      expect(map['imageHashes'], ['abcdef0123456789']);
      expect(map['foodMentions'], ['Pizza']);
    });

    test('fromMap still hydrates legacy fat docs', () {
      final legacy = {
        'localId': 'm1',
        'role': 'ai',
        'text': 'analysis here',
        'mealLogs': [
          {
            'items': ['Pizza'],
            'createdAt': '2026-01-01T00:00:00.000',
          },
        ],
        'analysisResult': {
          'text': 'analysis here',
          'scan': {'productName': 'Legacy Cola', 'brand': 'L', 'score': 30, 'impact': 'meh', 'createdAt': '2026-01-01T00:00:00.000'},
        },
        'createdAt': '2026-01-01T00:00:00.000',
      };

      final msg = ChatMessage.fromMap(legacy);

      expect(msg.analysisResult, isNotNull);
      expect(msg.scanData?.productName, 'Legacy Cola');
      expect(msg.mealLogs.map((m) => m.items), [
        ['Pizza'],
      ]);
    });

    test('fromMap builds the inline card from scanPreview when no analysis is stored', () {
      final slim = fatMessage().toMap();

      final msg = ChatMessage.fromMap(slim);

      expect(msg.analysisResult, isNull);
      expect(msg.mealLogs, isEmpty);
      // Card fields resolve from the preview (detail re-hydrates by scanId).
      expect(msg.scanData?.productName, 'Test Cola');
      expect(msg.scanData?.brand, 'Test');
      expect(msg.scanData?.score, 42);
      expect(msg.scanData?.impact, 'okay');
      expect(msg.scanData?.scanId, 's1');
      // Rendered + context fields round-trip.
      expect(msg.symptomLogs.map((s) => s.symptom), ['Bloating']);
      expect(msg.swapData?.map((s) => s.title), ['Oat milk']);
      expect(msg.imageHashes, ['abcdef0123456789']);
    });
  });
}
