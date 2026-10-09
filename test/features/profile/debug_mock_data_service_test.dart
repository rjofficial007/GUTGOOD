import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/ai/protocol/ai_constants.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/features/insights/application/usecases/generate_insight_usecase.dart';
import 'package:gutgood/features/insights/data/services/pattern_engine_service.dart';
import 'package:gutgood/features/profile/data/services/debug_mock_data_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/chat_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/history_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/insight_firestore_service.dart';
import 'package:mocktail/mocktail.dart';

class _History extends Mock implements HistoryFirestoreService {}

class _Insights extends Mock implements InsightFirestoreService {}

class _Chat extends Mock implements ChatFirestoreService {}

class _GenerateInsights extends Mock implements GenerateInsightUseCase {}

class _MealLog extends Fake implements MealLog {}

class _SymptomLog extends Fake implements SymptomLog {}

class _ScanResult extends Fake implements ScanResult {}

class _ChatMessage extends Fake implements ChatMessage {}

class _GutExperiment extends Fake implements GutExperiment {}

void main() {
  setUpAll(() {
    registerFallbackValue(_MealLog());
    registerFallbackValue(_SymptomLog());
    registerFallbackValue(_ScanResult());
    registerFallbackValue(_ChatMessage());
    registerFallbackValue(_GutExperiment());
  });

  test('30-day fixture writes confirmed event times and refreshes real insights', () async {
    final history = _History();
    final insights = _Insights();
    final chat = _Chat();
    final generateInsights = _GenerateInsights();
    final scans = <ScanResult>[];

    when(() => history.logMeal(any(), docId: any(named: 'docId'))).thenAnswer((_) async => 'meal');
    when(() => history.logSymptom(any(), docId: any(named: 'docId'))).thenAnswer((_) async => 'symptom');
    when(() => history.trySaveToScanHistory(any(), scanId: any(named: 'scanId'))).thenAnswer((invocation) async {
      scans.add((invocation.positionalArguments.first as ScanResult).copyWith(scanId: invocation.namedArguments[#scanId] as String));
      return true;
    });
    when(() => insights.saveActiveExperiment(any())).thenAnswer((_) async {});
    when(() => chat.saveMessage(any())).thenAnswer((_) async => 'message');
    when(() => generateInsights.execute(force: true)).thenAnswer((_) async {});

    final service = DebugMockDataService(
      historyFirestoreService: history,
      insightFirestoreService: insights,
      chatFirestoreService: chat,
      generateInsightUseCase: generateInsights,
    );

    await service.generateThirtyDaysData();

    final meals = verify(() => history.logMeal(captureAny(), docId: any(named: 'docId'))).captured.cast<MealLog>();
    final symptoms = verify(() => history.logSymptom(captureAny(), docId: any(named: 'docId'))).captured.cast<SymptomLog>();
    expect(meals, isNotEmpty);
    expect(symptoms, isNotEmpty);
    expect(meals.every((meal) => meal.occurredAt == meal.createdAt && meal.occurredAtProvenance == OccurrenceProvenance.user), isTrue);
    expect(symptoms.every((symptom) => symptom.occurredAt != null && symptom.occurredAtProvenance == OccurrenceProvenance.user && symptom.provenance == RecordProvenance.user), isTrue);
    final generatedAt = DateTime.now();
    expect(meals.every((meal) => !meal.createdAt.isAfter(generatedAt) && !meal.eventTime.isAfter(generatedAt)), isTrue);
    expect(symptoms.every((symptom) => !symptom.createdAt.isAfter(generatedAt) && !symptom.eventTime.isAfter(generatedAt)), isTrue);
    for (final symptom in symptoms.where((symptom) => symptom.foodName != null)) {
      expect(meals.any((meal) {
        final gap = symptom.eventTime.difference(meal.eventTime);
        return meal.items.contains(symptom.foodName) && !gap.isNegative && gap < const Duration(days: 1);
      }), isTrue, reason: '${symptom.foodName} must have been logged before its mock reaction.');
    }
    verify(() => generateInsights.execute(force: true)).called(1);

    final consumedProducts = scans.where((scan) => scan.scanId?.startsWith('debug_mock_product_') == true && scan.category == 'food').toList();
    expect(consumedProducts, isNotEmpty);
    expect(consumedProducts.every((scan) => scan.consumed == true), isTrue);
    expect(scans.where((scan) => scan.category == 'label' || scan.category == 'menu').every((scan) => scan.consumed != true), isTrue);
    final scanDates = scans.map((scan) => scan.createdAt).toList();
    final oldestScan = scanDates.reduce((a, b) => a.isBefore(b) ? a : b);
    final newestScan = scanDates.reduce((a, b) => a.isAfter(b) ? a : b);
    expect(newestScan.difference(oldestScan), greaterThanOrEqualTo(const Duration(days: 25)));

    final patterns = await PatternEngineServiceImpl(
      historyFirestoreService: history,
      insightFirestoreService: insights,
    ).runAnalysis(mealData: meals, symptomData: symptoms, scanData: scans, persistResults: false);
    expect(patterns, isNotEmpty);
    expect(patterns.any((pattern) => pattern.type == BodyPattern.typeBloating && pattern.frequency >= 2), isTrue);
    expect(patterns.any((pattern) => pattern.commonFactors.any((factor) => factor.label == 'Dairy')), isTrue);
  });
}
