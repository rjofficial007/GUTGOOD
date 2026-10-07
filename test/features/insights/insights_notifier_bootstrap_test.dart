import 'package:flutter_test/flutter_test.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/features/auth/domain/repositories/auth_repository.dart';
import 'package:gutgood/features/insights/application/usecases/generate_insight_ai_interpretation_usecase.dart';
import 'package:gutgood/features/insights/application/usecases/generate_insight_usecase.dart';
import 'package:gutgood/features/insights/domain/repositories/insight_repository.dart';
import 'package:gutgood/features/insights/presentation/providers/insights_notifier.dart';
import 'package:gutgood/infrastructure/firebase/analytics_service.dart';
import 'package:mocktail/mocktail.dart';

class MockInsightRepository extends Mock implements InsightRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockAnalyticsService extends Mock implements AnalyticsService {}

class MockGenerateInsightUseCase extends Mock implements GenerateInsightUseCase {}

class MockGenerateInsightAiInterpretationUseCase extends Mock implements GenerateInsightAiInterpretationUseCase {}

void main() {
  test('bootstraps deterministic insights when no insight exists, below today threshold', () async {
    final repository = MockInsightRepository();
    final authRepository = MockAuthRepository();
    final analytics = MockAnalyticsService();
    final generateInsight = MockGenerateInsightUseCase();

    when(repository.getDashboardStateStream).thenAnswer((_) => Stream.value(const InsightsDashboardState(totalMeals: 12, totalSymptoms: 4)));
    when(repository.getInsightHistory).thenAnswer((_) async => const []);
    when(repository.getActiveExperiment).thenAnswer((_) async => null);
    when(repository.getActiveExperimentStream).thenAnswer((_) => Stream.value(null));
    when(() => repository.getRecentMeals(any())).thenAnswer((_) async => const []);
    when(() => repository.getRecentSymptoms(any())).thenAnswer((_) async => const []);
    when(() => repository.getRecentScans(any())).thenAnswer((_) async => const []);
    when(() => authRepository.authStateChanges).thenAnswer((_) => const Stream.empty());
    when(() => analytics.logEvent(name: any(named: 'name'), parameters: any(named: 'parameters'))).thenAnswer((_) async {});
    when(() => generateInsight.execute(force: any(named: 'force'))).thenAnswer((_) async {});

    final notifier = InsightsNotifier(
      repository,
      AppStateServiceImpl(),
      authRepository,
      analytics,
      generateInsight,
      MockGenerateInsightAiInterpretationUseCase(),
    );

    await Future<void>.delayed(const Duration(milliseconds: 650));

    expect(notifier.isSufficient, isFalse);
    verify(() => generateInsight.execute(force: false)).called(1);
    notifier.dispose();
  });
}
