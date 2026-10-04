import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/ai/protocol/ai_constants.dart';
import 'package:gutgood/core/models/journal/food_event_linking.dart';
import 'package:gutgood/core/models/journal/meal_log.dart';
import 'package:gutgood/core/models/journal/symptom_log.dart';
import 'package:gutgood/core/models/scans/scan_result.dart';
import 'package:gutgood/core/utils/date_time_utils.dart';

void main() {
  group('occurredAt routing (P1-2)', () {
    test('AI time becomes a tagged occurrence; createdAt stays log time', () {
      final mealTime = DateTime.now().subtract(const Duration(hours: 2));
      final meal = MealLog.fromMap({
        'items': const ['Dal'],
        'time': mealTime.toIso8601String(),
      });

      expect(meal.occurredAt, mealTime);
      expect(meal.occurredAtProvenance, OccurrenceProvenance.aiEstimated);
      expect(meal.createdAt.isAfter(mealTime), isTrue, reason: 'createdAt is log time (≈ now), never the estimate.');
      expect(meal.eventTime, mealTime);
    });

    test('stored occurredAt passes through verbatim (no clamp on vetted values)', () {
      final old = DateTime.now().subtract(const Duration(days: 60));
      final meal = MealLog.fromMap({
        'items': const ['Dal'],
        'createdAt': old.toIso8601String(),
        'occurredAt': old.toIso8601String(),
        'occurredAtProvenance': 'user',
      });

      expect(meal.occurredAt, old);
      expect(meal.occurredAtProvenance, 'user');
    });

    test('insane AI estimates (far future / ancient) resolve to unknown', () {
      final future = MealLog.fromMap({
        'items': const ['x'],
        'time': DateTime.now().add(const Duration(days: 2)).toIso8601String(),
      });
      expect(future.occurredAt, isNull);
      expect(future.occurredAtProvenance, isNull);

      final ancient = MealLog.fromMap({
        'items': const ['x'],
        'time': DateTime.now().subtract(const Duration(days: 60)).toIso8601String(),
      });
      expect(ancient.occurredAt, isNull);
    });

    test('garbage AI time ("last night") resolves to unknown, not now()', () {
      final meal = MealLog.fromMap(const {
        'items': ['x'],
        'time': 'last night',
      });

      expect(meal.occurredAt, isNull);
      expect(meal.eventTime, meal.createdAt);
    });

    test('no time anywhere leaves occurredAt null with createdAt fallback', () {
      final symptom = SymptomLog.fromMap(const {'symptom': 'Bloating'});

      expect(symptom.occurredAt, isNull);
      expect(symptom.eventTime, symptom.createdAt);
    });

    test('toMap round-trips occurredAt + provenance', () {
      final at = DateTime.now().subtract(const Duration(hours: 5));
      final meal = MealLog(items: const ['x'], createdAt: DateTime.now(), occurredAt: at, occurredAtProvenance: OccurrenceProvenance.user);

      final hydrated = MealLog.fromMap(meal.toMap());

      expect(hydrated.occurredAt, at);
      expect(hydrated.occurredAtProvenance, OccurrenceProvenance.user);
    });
  });

  group('journal event linking', () {
    test('meal and symptom preserve the shared journalEntryId and scanId', () {
      final now = DateTime.now();
      final meal = MealLog(
        items: const ['Yogurt'],
        createdAt: now,
        firestoreId: 'scan-1_meal',
        journalEntryId: 'scan-1_meal',
        scanId: 'scan-1',
        scanCategory: 'label',
        scanConfidence: 0.42,
        scanVerdict: 'uncertain',
      );
      final symptom = SymptomLog(symptom: 'Bloating', createdAt: now.add(const Duration(hours: 1)), journalEntryId: 'scan-1_meal', lastMealFirestoreId: 'scan-1_meal');

      final mealRoundTrip = MealLog.fromMap(meal.toMap());
      final symptomRoundTrip = SymptomLog.fromMap(symptom.toMap());

      expect(mealRoundTrip.journalEntryId, 'scan-1_meal');
      expect(mealRoundTrip.scanId, 'scan-1');
      expect(mealRoundTrip.scanCategory, 'label');
      expect(mealRoundTrip.scanConfidence, 0.42);
      expect(mealRoundTrip.scanVerdict, 'uncertain');
      expect(symptomRoundTrip.journalEntryId, 'scan-1_meal');
      expect(symptomRoundTrip.lastMealFirestoreId, 'scan-1_meal');
    });

    test('legacy lastMealFirestoreId remains a usable journal link', () {
      final symptom = SymptomLog.fromMap(const {'symptom': 'Gas', 'lastMealFirestoreId': 'legacy-meal'});

      expect(symptom.journalEntryId, isNull);
      expect(symptom.lastMealFirestoreId, 'legacy-meal');
    });

    test('meal recognizes all stable scan projection identifiers', () {
      final meal = MealLog(
        items: const ['Yogurt'],
        createdAt: DateTime.now(),
        scanId: 'scan-1',
        firestoreId: 'scan-1_meal',
        journalEntryId: 'scan-1_meal',
      );

      expect(meal.representsScanId('scan-1'), isTrue);
      expect(meal.representsScanId(''), isFalse);
      expect(meal.representsScanId(null), isFalse);
      expect(MealLog(items: const ['x'], createdAt: DateTime.now(), chatMessageId: 'scan-2').representsScanId('scan-2'), isTrue);
    });

    test('unique food event helpers count scan projections once', () {
      final now = DateTime.now();
      final projectedScan = ScanResult(
        productName: 'Oats',
        brand: 'Brand',
        scanId: 'scan-1',
        score: 80,
        impactType: ImpactType.positive,
        impact: 'Good',
        createdAt: now,
      );
      final legacyScan = projectedScan.copyWith(scanId: 'scan-2', productName: 'Rice');
      final projectedMeal = MealLog(items: const ['Oats'], scanId: 'scan-1', journalEntryId: 'scan-1_meal', createdAt: now);
      final manualMeal = MealLog(items: const ['Dal'], createdAt: now);

      expect(standaloneScanRecords(meals: [projectedMeal, manualMeal], scans: [projectedScan, legacyScan]), [legacyScan]);
      expect(standaloneMealRecords(meals: [projectedMeal, manualMeal], scans: [projectedScan, legacyScan]), [manualMeal]);
      expect(uniqueFoodEventCount(meals: [projectedMeal, manualMeal], scans: [projectedScan, legacyScan]), 3);
    });

    test('nearest meal linking honors the earlier-four-hour window', () {
      final symptomTime = DateTime(2026, 1, 2, 12);
      final nearest = MealLog(
        items: const ['Oats'],
        createdAt: symptomTime.subtract(const Duration(hours: 1)),
        firestoreId: 'nearest-meal',
      );
      final farther = MealLog(
        items: const ['Rice'],
        createdAt: symptomTime.subtract(const Duration(hours: 3)),
        firestoreId: 'farther-meal',
      );
      final boundary = MealLog(
        items: const ['Soup'],
        createdAt: symptomTime.subtract(const Duration(hours: 4)),
        firestoreId: 'boundary-meal',
      );
      final tooOld = MealLog(
        items: const ['Dal'],
        createdAt: symptomTime.subtract(const Duration(hours: 4, seconds: 1)),
        firestoreId: 'old-meal',
      );
      final future = MealLog(
        items: const ['Fruit'],
        createdAt: symptomTime.add(const Duration(minutes: 1)),
        firestoreId: 'future-meal',
      );

      expect(nearestMealJournalEntryId(symptomTime: symptomTime, meals: [farther, future, tooOld, boundary, nearest]), 'nearest-meal');
      expect(nearestMealJournalEntryId(symptomTime: symptomTime, meals: [future, tooOld, boundary]), 'boundary-meal');
    });
  });

  group('symptom provenance + honest numbers (P2-4)', () {
    test('provenance round-trips through toMap/fromMap', () {
      final log = SymptomLog(symptom: 'Bloating', createdAt: DateTime.now(), provenance: RecordProvenance.keywordFallback);

      expect(SymptomLog.fromMap(log.toMap()).provenance, RecordProvenance.keywordFallback);
    });

    test('explicit symptom provenance round-trips', () {
      final symptom = SymptomLog.fromMap(const {'symptom': 'Bloating'});
      expect(symptom.provenance, isNull);

      final confirmed = symptom.copyWith(provenance: RecordProvenance.user);
      expect(SymptomLog.fromMap(confirmed.toMap()).provenance, RecordProvenance.user);
    });

    test('legacy docs without provenance read as null (treated as confirmed)', () {
      final log = SymptomLog.fromMap(const {'symptom': 'Bloating', 'severity': 4});

      expect(log.provenance, isNull);
      expect(log.severity, 4, reason: 'Explicitly provided numbers are preserved.');
    });

    test('energy is no longer inferred from the symptom name', () {
      final fatigue = SymptomLog.fromMap(const {'symptom': 'Fatigue'});
      final energetic = SymptomLog.fromMap(const {'symptom': 'Energetic'});

      expect(fatigue.energyLevel, isNull);
      expect(energetic.energyLevel, isNull);
    });

    test('validator clear flags void numbers via copyWith', () {
      final log = SymptomLog(symptom: 'x', severity: 99, energyLevel: 0, createdAt: DateTime.now());

      final cleared = log.copyWith(clearSeverity: true, clearEnergyLevel: true);

      expect(cleared.severity, isNull);
      expect(cleared.energyLevel, isNull);
    });
  });

  group('DateTimeUtils.tryParse', () {
    test('parses valid ISO, nulls everything else', () {
      final at = DateTime(2026, 1, 2, 3, 4, 5);
      expect(DateTimeUtils.tryParse(at.toIso8601String()), at);
      expect(DateTimeUtils.tryParse(at), at);
      expect(DateTimeUtils.tryParse(null), isNull);
      expect(DateTimeUtils.tryParse(''), isNull);
      expect(DateTimeUtils.tryParse('last night'), isNull);
      expect(DateTimeUtils.tryParse(0), DateTime.fromMillisecondsSinceEpoch(0));
    });
  });
}
