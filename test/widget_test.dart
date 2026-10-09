// GutGood unit tests (model + contract level).
//
// Integration coverage (auth, Firestore, Cloud Functions, chat E2E) requires a
// Firebase project / emulator suite and is exercised via the audit checklist in
// AUDIT_REPORT.md. These tests verify the pure-Dart invariants that guard the
// ChatGPT-style chat interaction model.

import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/ai/protocol/ai_analysis_result.dart';
import 'package:gutgood/core/models/chat/chat_message.dart';
import 'package:gutgood/core/models/scans/scan_result.dart';

void main() {
  group('ChatMessage slim persistence', () {
    test('toMap() stores a scan preview without duplicating the full analysis payload', () {
      final rawData = {'intent': 'MEAL_RECOGNITION', 'scan': 'duplicated-nested-blob'};
      final scan = ScanResult(productName: 'Salad', brand: 'GutGood', score: 80, impactType: ImpactType.positive, impact: 'Good', category: 'food', createdAt: DateTime(2026), rawData: rawData);
      final msg = ChatMessage(
        localId: 'x',
        role: 'ai',
        text: 'Analysis',
        scanData: scan,
        analysisResult: AiAnalysisResult(text: 'Analysis', scan: scan),
        createdAt: DateTime(2026),
      );

      final map = msg.toMap();
      expect(map.containsKey('analysisResult'), isFalse);
      expect(map.containsKey('mealLogs'), isFalse);
      expect(map['scanPreview'], isA<Map<String, dynamic>>());
      expect((map['scanPreview'] as Map<String, dynamic>)['intent'], 'MEAL_RECOGNITION');
      expect(msg.analysisResult!.scan!.rawData, rawData);
    });
  });

  group('ChatMessage image handling (multi-image turns)', () {
    test('imageUrl mirrors the first entry of imageUrls', () {
      final msg = ChatMessage(localId: 'a', role: 'user', text: '', imageUrls: const ['u1', 'u2'], createdAt: DateTime(2026));
      expect(msg.imageUrls, ['u1', 'u2']);
      expect(msg.imageUrl, 'u1');
    });

    test('legacy single imageUrl maps into imageUrls on fromMap', () {
      final msg = ChatMessage.fromMap(const {'role': 'user', 'text': 'hi', 'imageUrl': 'legacy-url', 'time': '2026-07-31T10:00:00.000'});
      expect(msg.imageUrls, ['legacy-url']);
      expect(msg.imageUrl, 'legacy-url');
    });

    test('imageUrls round-trips through toMap/fromMap', () {
      final original = ChatMessage(localId: 'x', role: 'user', text: 'what is this?', imageUrls: const ['a', 'b', 'c'], createdAt: DateTime(2026, 7, 31));
      final restored = ChatMessage.fromMap(original.toMap());
      expect(restored.imageUrls, ['a', 'b', 'c']);
      expect(restored.text, 'what is this?');
    });

    test('clearLocalImages frees bytes after upload', () {
      final msg = ChatMessage(localId: 'y', role: 'user', text: '', localImages: const [], createdAt: DateTime(2026));
      final cleared = msg.copyWith(imageUrls: const ['u'], clearLocalImages: true);
      expect(cleared.localImages, isNull);
      expect(cleared.imageUrls, ['u']);
    });
  });

  group('ChatErrorKind', () {
    test('error kinds are distinct (quota vs connection drives different UI)', () {
      expect(ChatErrorKind.quota == ChatErrorKind.connection, isFalse);
      expect(ChatErrorKind.none.index, 0);
    });
  });
}
