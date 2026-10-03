import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/ai/protocol/ai_analysis_result.dart';
import 'package:gutgood/core/ai/protocol/ai_constants.dart';
import 'package:gutgood/core/models/chat/chat_message.dart';
import 'package:gutgood/core/models/insights/ai_insight.dart';
import 'package:gutgood/core/models/insights/body_pattern.dart';
import 'package:gutgood/core/models/journal/meal_log.dart';
import 'package:gutgood/core/models/journal/symptom_log.dart';
import 'package:gutgood/core/models/scans/scan_result.dart';

void main() {
  group('schema version stamps (§17)', () {
    test('every stamped model writes v=1 into toMap', () {
      final now = DateTime.now();

      expect(ScanResult(productName: 'p', brand: 'b', score: 1, impactType: ImpactType.neutral, impact: 'i', createdAt: now).toMap()['v'], AiVersions.schemaVersion);
      expect(AIInsight(gutScore: 1, updatedAt: now).toMap()['v'], AiVersions.schemaVersion);
      expect(
        BodyPattern(type: 'correlation', trigger: 't', reaction: 'r', frequency: 3, confidence: 'High', description: 'd', updatedAt: now.toIso8601String()).toMap()['v'],
        AiVersions.schemaVersion,
      );
      expect(MealLog(items: const ['x'], createdAt: now).toMap()['v'], AiVersions.schemaVersion);
      expect(SymptomLog(symptom: 'x', createdAt: now).toMap()['v'], AiVersions.schemaVersion);
    });

    test('legacy docs without v read as version 1 (current)', () {
      final now = DateTime.now();

      expect(ScanResult.fromMap({'productName': 'p', 'brand': 'b', 'score': 1, 'impactType': 'neutral', 'impact': 'i', 'createdAt': now.toIso8601String()}).schemaVersion, 1);
      expect(AIInsight.fromMap({'gutScore': 1, 'updatedAt': now.toIso8601String()}).schemaVersion, 1);
      expect(
        BodyPattern.fromMap({'type': 'correlation', 'trigger': 't', 'reaction': 'r', 'frequency': 3, 'confidence': 'High', 'description': 'd', 'updatedAt': now.toIso8601String()}).schemaVersion,
        1,
      );
      expect(
        MealLog.fromMap(const {
          'items': ['x'],
        }).schemaVersion,
        1,
      );
      expect(SymptomLog.fromMap(const {'symptom': 'x'}).schemaVersion, 1);
    });

    test('explicit v and verdict on AI turns parse and round-trip', () {
      final result = AiAnalysisResult.fromMap(const {
        'v': 1,
        'metadata': {'confidence': 0.9},
        'verdict': 'food',
      });

      expect(result.schemaVersion, 1);
      expect(result.verdict, 'food');
      expect(result.confidence, 0.9);
      expect(result.toMap()['v'], 1);
      expect(result.toMap()['verdict'], 'food');
    });

    test('J-4 prompt/model stamps round-trip; legacy docs read null', () {
      final now = DateTime.now();

      final scan = ScanResult(productName: 'p', brand: 'b', score: 1, impactType: ImpactType.neutral, impact: 'i', createdAt: now, promptVersion: AiVersions.chatPromptVersion, model: 'gpt-test');
      final scanRt = ScanResult.fromMap(scan.toMap());
      expect(scanRt.promptVersion, AiVersions.chatPromptVersion);
      expect(scanRt.model, 'gpt-test');

      final meal = MealLog(items: const ['x'], createdAt: now, promptVersion: AiVersions.chatPromptVersion, model: 'gpt-test');
      expect(MealLog.fromMap(meal.toMap()).promptVersion, AiVersions.chatPromptVersion);
      expect(MealLog.fromMap(meal.toMap()).model, 'gpt-test');

      final symptom = SymptomLog(symptom: 'x', createdAt: now, promptVersion: AiVersions.chatPromptVersion, model: 'gpt-test');
      expect(SymptomLog.fromMap(symptom.toMap()).promptVersion, AiVersions.chatPromptVersion);
      expect(SymptomLog.fromMap(symptom.toMap()).model, 'gpt-test');

      final msg = ChatMessage(localId: 'l1', role: 'ai', text: 'hi', createdAt: now, promptVersion: AiVersions.chatPromptVersion, model: 'gpt-test');
      expect(ChatMessage.fromMap(msg.toMap()).promptVersion, AiVersions.chatPromptVersion);
      expect(ChatMessage.fromMap(msg.toMap()).model, 'gpt-test');

      // Legacy docs predate stamping: nulls, never fabricated versions.
      expect(ScanResult.fromMap({'productName': 'p', 'createdAt': now.toIso8601String()}).promptVersion, isNull);
      expect(
        MealLog.fromMap(const {
          'items': ['x'],
        }).model,
        isNull,
      );
      expect(SymptomLog.fromMap(const {'symptom': 'x'}).promptVersion, isNull);
      expect(ChatMessage.fromMap(const {'text': 'hi'}).promptVersion, isNull);
    });
  });
}
