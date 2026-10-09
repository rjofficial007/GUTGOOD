import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/ai/protocol/ai_constants.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/features/insights/data/services/pattern_engine_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/history_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/insight_firestore_service.dart';
import 'package:mocktail/mocktail.dart';

class MockHistoryFirestoreService extends Mock implements HistoryFirestoreService {}

class MockInsightFirestoreService extends Mock implements InsightFirestoreService {}

MealLog _meal(List<String> items, DateTime at) => MealLog(items: items, createdAt: at, occurredAt: at, occurredAtProvenance: OccurrenceProvenance.user);

SymptomLog _symptom(String name, DateTime at, {String? sleep, String? provenance}) =>
    SymptomLog(symptom: name, createdAt: at, occurredAt: at, occurredAtProvenance: OccurrenceProvenance.user, sleep: sleep, provenance: provenance);

void main() {
  late MockHistoryFirestoreService history;
  late MockInsightFirestoreService insights;
  late PatternEngineServiceImpl engine;

  setUpAll(() {
    registerFallbackValue(DateTime.now());
    registerFallbackValue(<BodyPattern>[]);
  });

  setUp(() {
    history = MockHistoryFirestoreService();
    insights = MockInsightFirestoreService();
    engine = PatternEngineServiceImpl(historyFirestoreService: history, insightFirestoreService: insights);

    when(
      () => history.getRecentMealLogs(
        limit: any(named: 'limit'),
        since: any(named: 'since'),
        throwOnError: any(named: 'throwOnError'),
      ),
    ).thenAnswer((_) async => []);
    when(
      () => history.getRecentScans(
        limit: any(named: 'limit'),
        since: any(named: 'since'),
        throwOnError: any(named: 'throwOnError'),
      ),
    ).thenAnswer((_) async => []);
    when(
      () => history.getRecentSymptomLogs(
        limit: any(named: 'limit'),
        since: any(named: 'since'),
        throwOnError: any(named: 'throwOnError'),
      ),
    ).thenAnswer((_) async => []);
    when(() => insights.savePatternData(any())).thenAnswer((_) async {});
  });

  Future<List<BodyPattern>> runWith({required List<MealLog> meals, required List<SymptomLog> symptoms, List<ScanResult> scans = const []}) async {
    when(
      () => history.getRecentMealLogs(
        limit: any(named: 'limit'),
        since: any(named: 'since'),
        throwOnError: any(named: 'throwOnError'),
      ),
    ).thenAnswer((_) async => meals);
    when(
      () => history.getRecentScans(
        limit: any(named: 'limit'),
        since: any(named: 'since'),
        throwOnError: any(named: 'throwOnError'),
      ),
    ).thenAnswer((_) async => scans);
    when(
      () => history.getRecentSymptomLogs(
        limit: any(named: 'limit'),
        since: any(named: 'since'),
        throwOnError: any(named: 'throwOnError'),
      ),
    ).thenAnswer((_) async => symptoms);
    return engine.runAnalysis();
  }

  group('PatternEngineService (P1-7)', () {
    test('does not correlate records whose event times are outside the 30-day window', () async {
      final now = DateTime.now();
      final oldEventTime = now.subtract(const Duration(days: 31));
      final oldMeal = MealLog(
        firestoreId: 'old-meal',
        journalEntryId: 'old-meal',
        items: const ['Oats'],
        createdAt: now,
        occurredAt: oldEventTime,
        occurredAtProvenance: OccurrenceProvenance.user,
      );
      final oldSymptom = SymptomLog(
        firestoreId: 'old-symptom',
        journalEntryId: 'old-meal',
        lastMealFirestoreId: 'old-meal',
        symptom: 'bloated',
        createdAt: now,
        occurredAt: oldEventTime,
        occurredAtProvenance: OccurrenceProvenance.user,
      );

      final patterns = await runWith(meals: [oldMeal], symptoms: [oldSymptom]);

      expect(patterns, isEmpty);
      verify(() => insights.savePatternData(const <BodyPattern>[])).called(1);
    });

    test('repeated burgers and explicit energetic reports survive incomplete scan detail', () async {
      final now = DateTime.now();
      final meals = <MealLog>[];
      final symptoms = <SymptomLog>[];
      for (var day = 1; day <= 6; day++) {
        final at = now.subtract(Duration(days: day));
        final burgerId = 'burger-$day';
        final burger = MealLog(
          firestoreId: burgerId,
          journalEntryId: burgerId,
          items: day == 6
              ? ['Chicken Burger', 'Chicken Patty', 'Lettuce', 'Pickles', 'Sauce']
              : day == 2
              ? ['Fried Chicken Burger']
              : ['Fried Chicken Burger', if (day == 1) 'Fried Chicken Patty' else 'Fried Chicken', 'Lettuce', 'Pickles', 'Sauce', if (day == 1) 'Bun' else 'Burger Bun'],
          createdAt: at,
        );
        meals.add(burger);
        symptoms.add(
          SymptomLog(
            firestoreId: 'bloat-$day',
            journalEntryId: burgerId,
            lastMealFirestoreId: burgerId,
            symptom: 'bloated',
            severity: 2,
            createdAt: at.add(const Duration(seconds: 29)),
          ),
        );
        if (day.isEven) {
          final pancakeId = 'pancake-$day';
          meals.add(
            MealLog(
              firestoreId: pancakeId,
              items: ['Pancakes with Blueberries', 'Blueberries', 'Maple Syrup', if (day == 6) 'flour' else 'Pancake Mix'],
              createdAt: at.subtract(const Duration(minutes: 2)),
            ),
          );
          symptoms.add(
            SymptomLog(firestoreId: 'energy-$day', lastMealFirestoreId: pancakeId, symptom: 'energetic', createdAt: at.subtract(const Duration(minutes: 1))),
          );
        }
      }
      final patterns = await runWith(meals: meals, symptoms: symptoms);
      final bloating = patterns.where((p) => p.type == BodyPattern.typeBloating).single;
      expect(bloating.trigger, 'Fried chicken burger');
      expect(bloating.frequency, 5);
      expect(bloating.impactDirection, 'negative');
      expect(bloating.id, isNotEmpty);
      expect(bloating.confidenceScore, 0);
      expect(bloating.negativeCount, 0, reason: 'No symptom log is not an explicit symptom-free check-in.');
      expect(bloating.occurrences.map((o) => o.mealId), contains('burger-2'));
      expect(bloating.occurrences.first.symptomId, 'bloat-1');
      expect(bloating.occurrences.first.symptomSeverity, '2');
      expect(bloating.occurrences.first.timeAfter, 'Timing not confirmed');
      expect(bloating.occurrences.first.timeAfterMinutes, isNull);
      expect(bloating.commonFactors, isEmpty, reason: 'No food tags were supplied.');
      final energy = patterns.where((p) => p.reaction == 'High Energy').single;
      expect(energy.frequency, 3);
      expect(energy.impactDirection, 'positive');
    });

    test('user-provided occurrence times preserve actual symptom delay', () async {
      final now = DateTime.now();
      final meals = List.generate(3, (i) => MealLog(
        items: const ['Oats'],
        createdAt: now.subtract(Duration(days: i + 1)),
        occurredAt: now.subtract(Duration(days: i + 1, hours: 3)),
        occurredAtProvenance: OccurrenceProvenance.user,
      ));
      final symptoms = meals.map((m) => SymptomLog(
        symptom: 'bloated',
        createdAt: m.createdAt.add(const Duration(seconds: 30)),
        occurredAt: m.occurredAt!.add(const Duration(hours: 2)),
        occurredAtProvenance: OccurrenceProvenance.user,
      )).toList();
      final patterns = await runWith(meals: meals, symptoms: symptoms);
      expect(patterns.single.occurrences.first.timeAfterMinutes, 120);
      expect(patterns.single.occurrences.first.timeAfter, 'About 2 hours later');
    });

    test('explicit energetic reports generate a qualitative high-energy pattern', () async {
      final meals = List.generate(3, (i) => _meal(['Oats'], DateTime.now().subtract(Duration(days: i + 1))));
      final patterns = await runWith(meals: meals, symptoms: meals.map((m) => _symptom('energetic', m.createdAt.add(const Duration(minutes: 30)))).toList());
      expect(patterns.single.reaction, 'High Energy');
      expect(patterns.single.frequency, 3);
    });

    test('two repeated observations on separate days surface as low confidence', () async {
      final now = DateTime.now();
      final meals = List.generate(2, (i) {
        final id = 'pancakes-$i';
        return MealLog(firestoreId: id, journalEntryId: id, items: const ['Pancakes with Blueberries'], createdAt: now.subtract(Duration(days: i + 1)));
      });
      final symptoms = meals.map((meal) {
        final id = meal.journalEntryId!;
        return SymptomLog(
          firestoreId: 'energy-$id',
          journalEntryId: id,
          lastMealFirestoreId: id,
          symptom: 'energetic',
          createdAt: meal.createdAt.add(const Duration(minutes: 1)),
          occurredAt: meal.createdAt.add(const Duration(minutes: 1)),
          occurredAtProvenance: OccurrenceProvenance.aiEstimated,
        );
      }).toList();

      final patterns = await runWith(meals: meals, symptoms: symptoms);

      expect(patterns, hasLength(1));
      expect(patterns.single.trigger, 'Pancakes with blueberries');
      expect(patterns.single.frequency, 2);
      expect(patterns.single.confidence, BodyPattern.confidenceLow);
      expect(patterns.single.description, contains('observed association, not proof of cause'));
    });

    test('unconfirmed timestamps do not create timing correlations', () async {
      final now = DateTime.now();
      final meals = List.generate(3, (i) => MealLog(items: const ['Oats'], createdAt: now.subtract(Duration(days: i + 1))));
      final symptoms = meals.map((meal) => SymptomLog(symptom: 'Bloating', createdAt: meal.createdAt.add(const Duration(hours: 1)))).toList();

      expect(await runWith(meals: meals, symptoms: symptoms), isEmpty);
    });

    test('three observations from one day do not meet the evidence threshold', () async {
      final now = DateTime.now();
      final meals = List.generate(3, (i) => _meal(['Oats'], now.subtract(Duration(minutes: i * 45))));
      final symptoms = meals.map((meal) => _symptom('Bloating', meal.createdAt.add(const Duration(minutes: 15)))).toList();

      expect(await runWith(meals: meals, symptoms: symptoms), isEmpty);
    });

    test('returns [] and clears stale patterns when data is insufficient', () async {
      final noMeals = await runWith(meals: [], symptoms: [_symptom('Bloating', DateTime.now())]);
      final noSymptoms = await runWith(
        meals: [
          _meal(['Pizza'], DateTime.now()),
        ],
        symptoms: [],
      );

      expect(noMeals, isEmpty);
      expect(noSymptoms, isEmpty);
      verify(() => insights.savePatternData([])).called(2);
    });

    test('analysis is time-bounded to the 30-day window', () async {
      await runWith(meals: [], symptoms: []);

      final captured = verify(
        () => history.getRecentMealLogs(
          limit: captureAny(named: 'limit'),
          since: captureAny(named: 'since'),
          throwOnError: true,
        ),
      ).captured;
      expect(captured[0], isNull);
      final since = captured[1] as DateTime;
      expect(DateTime.now().difference(since).inDays, 30);
    });

    test('bloating: 3-of-3 reads Medium; 5-of-5 caps at Medium without a contrast case', () async {
      List<MealLog> meals(int n) => List.generate(n, (i) => _meal(['Pizza'], DateTime.now().subtract(Duration(days: n - i))));
      List<SymptomLog> bloatAfter(List<MealLog> ms) => ms.map((m) => _symptom('Bloating', m.createdAt.add(const Duration(hours: 2)))).toList();

      final m3 = meals(3);
      final three = await runWith(meals: m3, symptoms: bloatAfter(m3));
      expect(three, hasLength(1));
      expect(three.first.type, BodyPattern.typeBloating);
      expect(three.first.trigger, 'Pizza');
      expect(three.first.frequency, 3);
      expect(three.first.evidenceRatio, 0);
      expect(three.first.negativeCount, 0);
      expect(three.first.confidence, BodyPattern.confidenceMedium);

      final m5 = meals(5);
      final five = await runWith(meals: m5, symptoms: bloatAfter(m5));
      expect(five.first.frequency, 5);
      expect(five.first.confidence, BodyPattern.confidenceMedium, reason: 'Passive logs lack explicit symptom-free comparisons, so this engine never labels an association High.');
    });

    test('meals without symptom entries never become negative comparison cases', () async {
      final now = DateTime.now();
      final meals = List.generate(5, (i) => _meal(['Pizza'], now.subtract(Duration(days: 5 - i))));
      final symptoms = meals.map((m) => _symptom('Bloating', m.createdAt.add(const Duration(hours: 2)))).toList();
      meals.add(_meal(['Pizza'], now.subtract(const Duration(days: 10)))); // no symptom entry: unknown outcome

      final patterns = await runWith(meals: meals, symptoms: symptoms);

      expect(patterns, hasLength(1));
      expect(patterns.first.frequency, 5);
      expect(patterns.first.evidenceRatio, 0);
      expect(patterns.first.negativeCount, 0);
      expect(patterns.first.confidence, BodyPattern.confidenceMedium);
    });

    test('unreported meals do not reduce the observed-pattern tier or count as negatives', () async {
      final now = DateTime.now();
      // 3 symptomatic pizza meals on days 1-3...
      final meals = List.generate(3, (i) => _meal(['Pizza'], now.subtract(Duration(days: 3 - i))));
      final symptoms = meals.map((m) => _symptom('Bloating', m.createdAt.add(const Duration(hours: 2)))).toList();
      // ...plus 7 asymptomatic pizza meals far from any symptom.
      for (var d = 10; d < 17; d++) {
        meals.add(_meal(['Pizza'], now.subtract(Duration(days: d))));
      }

      final patterns = await runWith(meals: meals, symptoms: symptoms);

      expect(patterns, hasLength(1));
      expect(patterns.first.frequency, 3);
      expect(patterns.first.evidenceRatio, 0);
      expect(patterns.first.negativeCount, 0, reason: 'Seven meals without a symptom entry are unknown, not confirmed symptom-free.');
      expect(patterns.first.confidence, BodyPattern.confidenceMedium);
    });

    test('food keys normalize: "Pizza", "pizza " and "2x Pizza" group together', () async {
      final now = DateTime.now();
      final meals = [
        _meal(['Pizza'], now.subtract(const Duration(days: 3))),
        _meal(['pizza '], now.subtract(const Duration(days: 2))),
        _meal(['2x Pizza'], now.subtract(const Duration(days: 1))),
      ];
      final symptoms = meals.map((m) => _symptom('Bloating', m.createdAt.add(const Duration(hours: 2)))).toList();

      final patterns = await runWith(meals: meals, symptoms: symptoms);

      expect(patterns, hasLength(1));
      expect(patterns.first.frequency, 3);
      expect(patterns.first.trigger, 'Pizza');
    });

    test('windows are exact: a symptom 4h30m after the meal does not count for the 4h window', () async {
      final now = DateTime.now();
      final meals = List.generate(3, (i) => _meal(['Pizza'], now.subtract(Duration(days: 3 - i))));
      final symptoms = meals.map((m) => _symptom('Bloating', m.createdAt.add(const Duration(hours: 4, minutes: 30)))).toList();

      expect(await runWith(meals: meals, symptoms: symptoms), isEmpty);
    });

    test('energy uses the NEAREST qualitative report after the meal', () async {
      final now = DateTime.now();
      final meals = List.generate(3, (i) => _meal(['Oats'], now.subtract(Duration(days: 3 - i))));
      // Firestore newest-first order: the later low-energy report comes first,
      // but the closer high-energy report should determine the association.
      final symptoms = <SymptomLog>[];
      for (final m in meals) {
        symptoms
          ..add(_symptom('Tired', m.createdAt.add(const Duration(hours: 3))))
          ..add(_symptom('Energetic', m.createdAt.add(const Duration(hours: 2))));
      }

      final patterns = await runWith(meals: meals, symptoms: symptoms);

      expect(patterns, hasLength(1));
      expect(patterns.first.reaction, 'High Energy');
      expect(patterns.first.frequency, 3);
    });

    test('sleep picks the latest evening meal by event time, not list order', () async {
      final now = DateTime.now();
      // Pass meals newest-first (Firestore order): the 21:30 meal sorts first.
      final meals = <MealLog>[];
      final symptoms = <SymptomLog>[];
      for (var d = 3; d >= 1; d--) {
        final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: d));
        meals
          ..add(_meal(['Late snack'], day.add(const Duration(hours: 21, minutes: 30))))
          ..add(_meal(['Early dinner'], day.add(const Duration(hours: 18, minutes: 30))));
        symptoms.add(_symptom('Morning check', day.add(const Duration(days: 1, hours: 7)), sleep: 'Poor, interrupted'));
      }

      final patterns = await runWith(meals: meals, symptoms: symptoms);
      final late = patterns.where((p) => p.trigger == 'Late night eating').toList();

      expect(late, hasLength(1));
      expect(late.first.frequency, 3);
      expect(late.first.occurrences.map((o) => o.mealName), everyElement('Late snack'));
    });

    test('sleep has no dead zone: 20:30 dinners count as late', () async {
      final now = DateTime.now();
      final meals = <MealLog>[];
      final symptoms = <SymptomLog>[];
      for (var d = 3; d >= 1; d--) {
        final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: d));
        meals.add(_meal(['Dinner'], day.add(const Duration(hours: 20, minutes: 30))));
        symptoms.add(_symptom('Morning check', day.add(const Duration(days: 1, hours: 7)), sleep: 'Poor, interrupted'));
      }

      final patterns = await runWith(meals: meals, symptoms: symptoms);

      expect(patterns.where((p) => p.trigger == 'Late night eating'), hasLength(1));
    });

    test('migraines are detected with migraine labeling', () async {
      final now = DateTime.now();
      final meals = List.generate(3, (i) => _meal(['Red wine'], now.subtract(Duration(days: 3 - i))));
      final symptoms = meals.map((m) => _symptom('Migraine', m.createdAt.add(const Duration(hours: 3)))).toList();

      final patterns = await runWith(meals: meals, symptoms: symptoms);

      expect(patterns, hasLength(1));
      expect(patterns.first.reaction, 'Migraine');
      expect(patterns.first.description, contains('migraines'));
    });

    test('co-occurring items remain one combination exposure', () async {
      final now = DateTime.now();
      final meals = List.generate(3, (i) => _meal(['Pizza', 'Garlic bread'], now.subtract(Duration(days: 3 - i))));
      final symptoms = meals.map((m) => _symptom('Bloating', m.createdAt.add(const Duration(hours: 2)))).toList();

      final patterns = await runWith(meals: meals, symptoms: symptoms);

      // The exact combination is one exposure; neither food is published as
      // an independently causal trigger.
      expect(patterns, hasLength(1));
      expect(patterns.first.trigger, 'Pizza + Garlic bread');
      expect(patterns.first.involvedFoods, ['pizza', 'garlic bread']);
      expect(patterns.first.frequency, 3);
    });

    test('ingredient detail on only one repeated meal does not suppress the shared food pattern', () async {
      final now = DateTime.now();
      final meals = [
        _meal(['Fried Chicken Burger'], now.subtract(const Duration(days: 2))),
        _meal(['Fried Chicken Burger'], now.subtract(const Duration(days: 1))),
        _meal(['Fried Chicken Burger', 'Fried Chicken Patty', 'Lettuce', 'Pickles', 'Sauce', 'Bun'], now.subtract(const Duration(hours: 1))),
      ];
      final symptoms = meals.map((meal) => _symptom('Bloating', meal.createdAt.add(const Duration(minutes: 30)))).toList();

      final patterns = await runWith(meals: meals, symptoms: symptoms);

      expect(patterns, hasLength(1));
      expect(patterns.single.trigger, 'Fried chicken burger');
      expect(patterns.single.frequency, 3);
      expect(patterns.single.involvedFoods, ['fried chicken burger']);
    });

    test('future-dated meal and symptom events do not create a pattern', () async {
      final now = DateTime.now();
      final meals = [
        _meal(['Burger'], now.subtract(const Duration(hours: 2))),
        _meal(['Burger'], now.add(const Duration(hours: 2))),
      ];
      final symptoms = [_symptom('Bloating', meals[0].createdAt.add(const Duration(minutes: 30))), _symptom('Bloating', meals[1].createdAt.add(const Duration(minutes: 30)))];

      expect(await runWith(meals: meals, symptoms: symptoms), isEmpty);
    });

    test('timeframeDays reports the honest span (no 7-day floor)', () async {
      final now = DateTime.now();
      final meals = [
        _meal(['Pizza'], now.subtract(const Duration(days: 2, hours: 3))),
        _meal(['Pizza'], now.subtract(const Duration(days: 1, hours: 2))),
        _meal(['Pizza'], now.subtract(const Duration(hours: 3))),
      ];
      final symptoms = meals.map((m) => _symptom('Bloating', m.createdAt.add(const Duration(hours: 2)))).toList();

      final patterns = await runWith(meals: meals, symptoms: symptoms);

      expect(patterns.first.timeframeDays, 2);
    });

    test('keyword-guessed symptoms are excluded from corroboration', () async {
      final now = DateTime.now();
      final meals = List.generate(3, (i) => _meal(['Pizza'], now.subtract(Duration(days: 3 - i))));
      final symptoms = meals.map((m) => _symptom('Bloating', m.createdAt.add(const Duration(hours: 2)), provenance: RecordProvenance.keywordFallback)).toList();

      expect(await runWith(meals: meals, symptoms: symptoms), isEmpty);
    });

    test('scan journal projection is not counted again from scan_history', () async {
      final now = DateTime.now();
      final scans = List.generate(
        3,
        (i) => ScanResult(
          productName: 'Scan Oats',
          brand: 'Brand',
          category: 'food',
          scanId: 'scan-$i',
          score: 80,
          impactType: ImpactType.positive,
          impact: 'Good',
          createdAt: now.subtract(Duration(days: 3 - i)),
        ),
      );
      final meals = scans
          .map(
            (scan) =>
                MealLog(firestoreId: '${scan.scanId}_meal', journalEntryId: '${scan.scanId}_meal', scanId: scan.scanId, consumptionConfirmed: true, items: const ['Scan Oats'], createdAt: scan.createdAt, occurredAt: scan.createdAt, occurredAtProvenance: OccurrenceProvenance.user),
          )
          .toList();
      final symptoms = meals.map((meal) => _symptom('Bloating', meal.createdAt.add(const Duration(hours: 2)))).toList();

      final patterns = await runWith(meals: meals, symptoms: symptoms, scans: scans);

      expect(patterns, hasLength(1));
      expect(patterns.first.frequency, 3);
      expect(patterns.first.totalSimilarMeals, 3);
    });

    test('patterns sort repeated observations by frequency without a High confidence tier', () async {
      final now = DateTime.now();
      // Five high-energy oat observations across five days...
      final meals = List.generate(5, (i) => _meal(['Oats'], now.subtract(Duration(days: 10 - i))))..add(_meal(['Oats'], now.subtract(const Duration(days: 11)))); // no symptom entry: unknown outcome
      final symptoms = meals.take(5).map((m) => _symptom('Energetic', m.createdAt.add(const Duration(hours: 2)))).toList();
      // ...plus three pizza-associated bloat reports across three days.
      for (var i = 0; i < 3; i++) {
        final m = _meal(['Pizza'], now.subtract(Duration(days: 3 - i)));
        meals.add(m);
        symptoms.add(_symptom('Bloating', m.createdAt.add(const Duration(hours: 2))));
      }
      for (var d = 20; d < 27; d++) {
        meals.add(_meal(['Pizza'], now.subtract(Duration(days: d))));
      }

      final patterns = await runWith(meals: meals, symptoms: symptoms);

      expect(patterns.map((p) => p.frequency), [5, 3]);
      expect(patterns.map((p) => p.confidence), [BodyPattern.confidenceMedium, BodyPattern.confidenceMedium]);
    });
  });
}
