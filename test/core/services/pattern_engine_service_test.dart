import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/constants/ai_constants.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/services/firestore/history_firestore_service.dart';
import 'package:gutgood/core/services/firestore/insight_firestore_service.dart';
import 'package:gutgood/core/services/pattern_engine_service.dart';
import 'package:mocktail/mocktail.dart';

class MockHistoryFirestoreService extends Mock implements HistoryFirestoreService {}

class MockInsightFirestoreService extends Mock implements InsightFirestoreService {}

MealLog _meal(List<String> items, DateTime at) => MealLog(items: items, createdAt: at);

SymptomLog _symptom(String name, DateTime at, {int? energy, String? sleep, String? provenance}) => SymptomLog(symptom: name, createdAt: at, energyLevel: energy, sleep: sleep, provenance: provenance);

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
      ),
    ).thenAnswer((_) async => []);
    when(
      () => history.getRecentScans(
        limit: any(named: 'limit'),
        since: any(named: 'since'),
      ),
    ).thenAnswer((_) async => []);
    when(
      () => history.getRecentSymptomLogs(
        limit: any(named: 'limit'),
        since: any(named: 'since'),
      ),
    ).thenAnswer((_) async => []);
    when(() => insights.savePatternData(any())).thenAnswer((_) async {});
  });

  Future<List<BodyPattern>> runWith({required List<MealLog> meals, required List<SymptomLog> symptoms, List<ScanResult> scans = const []}) async {
    when(
      () => history.getRecentMealLogs(
        limit: any(named: 'limit'),
        since: any(named: 'since'),
      ),
    ).thenAnswer((_) async => meals);
    when(
      () => history.getRecentScans(
        limit: any(named: 'limit'),
        since: any(named: 'since'),
      ),
    ).thenAnswer((_) async => scans);
    when(
      () => history.getRecentSymptomLogs(
        limit: any(named: 'limit'),
        since: any(named: 'since'),
      ),
    ).thenAnswer((_) async => symptoms);
    return engine.runAnalysis();
  }

  group('PatternEngineService (P1-7)', () {
    test('scanning a product twice does not establish consumption or a pattern', () async {
      final now = DateTime.now().subtract(const Duration(days: 1));
      final patterns = await runWith(
        meals: [],
        symptoms: [_symptom('Bloating', now.add(const Duration(hours: 1))), _symptom('Bloating', now.add(const Duration(days: 1, hours: 1)))],
        scans: [
          for (var day = 0; day < 2; day++)
            ScanResult(
              productName: 'Pizza',
              brand: '',
              score: 20,
              impactType: ImpactType.negative,
              impact: '',
              createdAt: now.add(Duration(days: day)),
            ),
        ],
      );
      expect(patterns, isEmpty);
    });

    test('higher energy associations retain a positive direction', () async {
      final meals = List.generate(2, (i) => _meal(['Rice'], DateTime.now().subtract(Duration(days: i + 1))));
      final patterns = await runWith(meals: meals, symptoms: meals.map((m) => _symptom('Energetic', m.eventTime.add(const Duration(hours: 1)), energy: 8)).toList());
      expect(patterns.single.impactDirection, 'positive');
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
        ),
      ).captured;
      expect(captured[0], 150);
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
      expect(three.first.evidenceRatio, 1.0);
      expect(three.first.confidence, BodyPattern.confidenceMedium);

      final m5 = meals(5);
      final five = await runWith(meals: m5, symptoms: bloatAfter(m5));
      expect(five.first.frequency, 5);
      expect(five.first.confidence, BodyPattern.confidenceMedium, reason: '5-of-5 has no observed negative: coincidence undistinguishable from trigger.');
    });

    test('High requires freq ≥ 5, ratio ≥ 0.66, and ≥ 1 observed negative', () async {
      final now = DateTime.now();
      final meals = List.generate(5, (i) => _meal(['Pizza'], now.subtract(Duration(days: 5 - i))));
      final symptoms = meals.map((m) => _symptom('Bloating', m.createdAt.add(const Duration(hours: 2)))).toList();
      meals.add(_meal(['Pizza'], now.subtract(const Duration(days: 10)))); // asymptomatic contrast

      final patterns = await runWith(meals: meals, symptoms: symptoms);

      expect(patterns, hasLength(1));
      expect(patterns.first.frequency, 5);
      expect(patterns.first.evidenceRatio, closeTo(5 / 6, 0.001));
      expect(patterns.first.negativeCount, 1);
      expect(patterns.first.confidence, BodyPattern.confidenceHigh);
    });

    test('confidence follows the evidence ratio: 3-of-10 reads Low', () async {
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
      expect(patterns.first.evidenceRatio, closeTo(0.3, 0.001));
      expect(patterns.first.confidence, BodyPattern.confidenceLow);
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

    test('energy uses the NEAREST reading after the meal regardless of list order', () async {
      final now = DateTime.now();
      final meals = List.generate(3, (i) => _meal(['Oats'], now.subtract(Duration(days: 3 - i))));
      // Firestore newest-first order: the +3h reading sorts before the +2h one.
      final symptoms = <SymptomLog>[];
      for (final m in meals) {
        symptoms
          ..add(_symptom('Energy check', m.createdAt.add(const Duration(hours: 3)), energy: 9))
          ..add(_symptom('Energy check', m.createdAt.add(const Duration(hours: 2)), energy: 2));
      }

      final patterns = await runWith(meals: meals, symptoms: symptoms);

      expect(patterns, hasLength(1));
      expect(patterns.first.reaction, 'Energy Drop');
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

    test('co-occurring items join the trigger in involvedFoods', () async {
      final now = DateTime.now();
      final meals = List.generate(3, (i) => _meal(['Pizza', 'Garlic bread'], now.subtract(Duration(days: 3 - i))));
      final symptoms = meals.map((m) => _symptom('Bloating', m.createdAt.add(const Duration(hours: 2)))).toList();

      final patterns = await runWith(meals: meals, symptoms: symptoms);

      // One pattern per trigger food; the pizza one carries garlic bread too.
      final pizza = patterns.firstWhere((p) => p.trigger == 'Pizza');
      expect(pizza.involvedFoods, ['pizza', 'garlic bread']);
    });

    test('timeframeDays reports the honest span (no 7-day floor)', () async {
      final now = DateTime.now();
      final meals = [
        _meal(['Pizza'], now.subtract(const Duration(days: 2, hours: 3))),
        _meal(['Pizza'], now.subtract(const Duration(days: 2, hours: 2))),
        _meal(['Pizza'], now.subtract(const Duration(days: 2, hours: 1))),
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

    test('patterns sort High-first, then by frequency', () async {
      final now = DateTime.now();
      // 5-of-6 high-energy oat meals (one contrast case → High)...
      final meals = List.generate(5, (i) => _meal(['Oats'], now.subtract(Duration(days: 10 - i))))..add(_meal(['Oats'], now.subtract(const Duration(days: 11)))); // asymptomatic contrast
      final symptoms = meals.take(5).map((m) => _symptom('Energy check', m.createdAt.add(const Duration(hours: 2)), energy: 9)).toList();
      // ...plus 3-of-10 pizza bloat (ratio 0.3 → Low).
      for (var i = 0; i < 3; i++) {
        final m = _meal(['Pizza'], now.subtract(Duration(days: 3 - i)));
        meals.add(m);
        symptoms.add(_symptom('Bloating', m.createdAt.add(const Duration(hours: 2))));
      }
      for (var d = 20; d < 27; d++) {
        meals.add(_meal(['Pizza'], now.subtract(Duration(days: d))));
      }

      final patterns = await runWith(meals: meals, symptoms: symptoms);

      expect(patterns.map((p) => p.confidence), [BodyPattern.confidenceHigh, BodyPattern.confidenceLow]);
    });
  });
}
