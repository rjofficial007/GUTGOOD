import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/ai/protocol/ai_constants.dart';
import 'package:gutgood/core/ai/validation/ai_response_validator.dart';
import 'package:gutgood/core/models/models.dart';

AiAnalysisResult _result({
  double? confidence,
  int? schemaVersion,
  String? verdict,
  String? intent,
  ScanResult? scan,
  MealLog? meal,
  List<SymptomLog> symptoms = const [],
  Map<String, dynamic> metadata = const {},
}) => AiAnalysisResult(text: 'hi', confidence: confidence, schemaVersion: schemaVersion, verdict: verdict, intent: intent, scan: scan, meal: meal, symptoms: symptoms, metadata: metadata);

ScanResult _scan({String? userImageUrl}) =>
    ScanResult(productName: 'Test Cola', brand: 'Test', score: 50, impactType: ImpactType.neutral, impact: 'meh', createdAt: DateTime.now(), userImageUrl: userImageUrl);

MealLog _meal() => MealLog(items: const ['Pizza'], createdAt: DateTime.now());

SymptomLog _symptom({int? severity}) => SymptomLog(symptom: 'Bloating', severity: severity, createdAt: DateTime.now());

void main() {
  group('AiResponseValidator', () {
    test('clean legacy result (no envelope fields) passes untouched', () {
      final input = _result();
      final out = AiResponseValidator.validate(input);

      expect(out.persistRecords, isTrue);
      expect(out.reasons, isEmpty);
      expect(identical(out.result, input), isTrue, reason: 'Nothing to sanitize — same instance back.');
    });

    test('low confidence blocks persistence with a reason', () {
      final out = AiResponseValidator.validate(_result(confidence: 0.3));

      expect(out.persistRecords, isFalse);
      expect(out.reasons.join(' '), contains('confidence'));
    });

    test('out-of-range confidence is treated as unreported (passes, noted)', () {
      final out = AiResponseValidator.validate(_result(confidence: 5.0));

      expect(out.persistRecords, isTrue);
      expect(out.reasons.join(' '), contains('confidence'));
    });

    test('non_food verdict blocks records', () {
      final out = AiResponseValidator.validate(_result(verdict: Verdict.nonFood));

      expect(out.persistRecords, isFalse);
      expect(out.reasons.join(' '), contains('non_food'));
    });

    test('uncertain verdict blocks records', () {
      final out = AiResponseValidator.validate(_result(verdict: Verdict.uncertain));

      expect(out.persistRecords, isFalse);
    });

    test('food verdict passes', () {
      final out = AiResponseValidator.validate(_result(verdict: Verdict.food));

      expect(out.persistRecords, isTrue);
      expect(out.reasons, isEmpty);
    });

    test('unknown verdict value blocks records', () {
      final out = AiResponseValidator.validate(_result(verdict: 'maybe'));

      expect(out.persistRecords, isFalse);
    });

    test('unsupported envelope version blocks records', () {
      final out = AiResponseValidator.validate(_result(schemaVersion: AiVersions.schemaVersion + 1));

      expect(out.persistRecords, isFalse);
      expect(out.reasons.join(' '), contains('unsupported envelope'));
    });

    test('unknown intent is advisory, never blocking', () {
      final out = AiResponseValidator.validate(_result(intent: 'MEAL_OVERVIEW'));

      expect(out.persistRecords, isTrue);
      expect(out.reasons.join(' '), contains('unknown intent'));
    });

    test('model declining persistence blocks records', () {
      final out = AiResponseValidator.validate(_result(metadata: const {'requiresPersistence': false}));

      expect(out.persistRecords, isFalse);
    });

    test('out-of-range severity is voided but the symptom persists', () {
      final out = AiResponseValidator.validate(_result(symptoms: [_symptom(severity: 99)]));

      expect(out.persistRecords, isTrue, reason: 'Bad numbers sanitize; they do not block the record.');
      expect(out.result.symptoms, hasLength(1));
      expect(out.result.symptoms.first.severity, isNull);
      expect(out.reasons, isNotEmpty);
    });

    test('in-range severity passes through untouched', () {
      final out = AiResponseValidator.validate(_result(symptoms: [_symptom(severity: 1), _symptom(severity: 7)]));

      expect(out.persistRecords, isTrue);
      expect(out.reasons, isEmpty);
      expect(out.result.symptoms[0].severity, 1);
      expect(out.result.symptoms[1].severity, 7);
    });
  });

  group('AiResponseValidator per-intent contracts (J-2)', () {
    test('zero-data intents block on any scan block (render preserved)', () {
      for (final intent in [UserIntent.generalChat, UserIntent.generalWellness, UserIntent.ingredientAnalysis, UserIntent.menuRecommendation]) {
        final out = AiResponseValidator.validate(_result(intent: intent, scan: _scan()));

        expect(out.persistRecords, isFalse, reason: intent);
        expect(out.result.scan, isNotNull, reason: '$intent keeps the chat card');
        expect(out.reasons.join(' '), contains('zero-data'));
      }
    });

    test('zero-data intents strip meal blocks but keep user symptoms', () {
      final out = AiResponseValidator.validate(_result(intent: UserIntent.generalFoodQuestion, meal: _meal(), symptoms: [_symptom()]));

      expect(out.persistRecords, isTrue);
      expect(out.result.meal, isNull);
      expect(out.result.symptoms, hasLength(1));
    });

    test('label/menu intents embargo symptoms (persister parity)', () {
      final out = AiResponseValidator.validate(_result(intent: UserIntent.ingredientAnalysis, symptoms: [_symptom()]));

      expect(out.persistRecords, isTrue);
      expect(out.result.symptoms, isEmpty);
    });

    test('symptom/swap intents block invented scans but pass photo-derived ones', () {
      for (final intent in [UserIntent.symptomAnalysis, UserIntent.swapRequest]) {
        final invented = AiResponseValidator.validate(_result(intent: intent, scan: _scan()));
        expect(invented.persistRecords, isFalse, reason: '$intent invented scan');

        final photo = AiResponseValidator.validate(
          _result(
            intent: intent,
            scan: _scan(userImageUrl: 'https://x/p.jpg'),
          ),
        );
        expect(photo.persistRecords, isTrue, reason: '$intent photo scan');
      }
    });

    test('full-data and unknown intents get no contract opinion', () {
      for (final intent in [UserIntent.mealRating, UserIntent.completeAnalysis, UserIntent.nutritionComparison, 'MEAL_OVERVIEW', null]) {
        final out = AiResponseValidator.validate(_result(intent: intent, scan: _scan(), meal: _meal()));

        expect(out.persistRecords, isTrue, reason: '$intent');
      }
    });

    test('scan persistence override keeps concrete scan records through old gates', () {
      final out = AiResponseValidator.validate(
        _result(
          confidence: 0.2,
          verdict: Verdict.nonFood,
          intent: UserIntent.ingredientAnalysis,
          scan: _scan(),
          meal: _meal(),
          symptoms: [_symptom()],
        ),
        preserveScanRecords: true,
      );

      expect(out.persistRecords, isTrue);
      expect(out.result.scan, isNotNull);
      expect(out.result.meal, isNotNull);
      expect(out.result.symptoms, hasLength(1));
      expect(out.reasons.join(' '), contains('scan persistence override'));
    });
  });
}
