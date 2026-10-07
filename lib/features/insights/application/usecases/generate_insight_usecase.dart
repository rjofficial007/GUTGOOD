import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/services/gut_score_calculator_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/features/insights/data/services/pattern_engine_service.dart';
import 'package:gutgood/features/insights/domain/repositories/insight_repository.dart';
import 'package:gutgood/features/insights/domain/services/rule_based_insight_builder.dart';
import 'package:gutgood/infrastructure/firebase/firestore/auth_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/gut_score_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Refreshes Insights on the device using Firestore journal data and rules.
/// This path intentionally makes no AI/API calls and requires no Cloud Function.
class GenerateInsightUseCase {
  GenerateInsightUseCase({
    required InsightRepository insightRepository,
    required AuthFirestoreService authFirestoreService,
    required SharedPreferences prefs,
    required NotificationService notificationService,
    required PatternEngineService patternEngineService,
    GutScoreCalculatorService gutScoreCalculatorService = const GutScoreCalculatorService(),
    RuleBasedInsightBuilder insightBuilder = const RuleBasedInsightBuilder(),
    GutScoreFirestoreService? gutScoreFirestoreService,
  }) : _insightRepository = insightRepository,
       _authFirestoreService = authFirestoreService,
       _prefs = prefs,
       _notificationService = notificationService,
       _patternEngineService = patternEngineService,
       _gutScoreCalculatorService = gutScoreCalculatorService,
       _insightBuilder = insightBuilder,
       _gutScoreFirestoreService = gutScoreFirestoreService;

  final InsightRepository _insightRepository;
  final AuthFirestoreService _authFirestoreService;
  final SharedPreferences _prefs;
  final NotificationService _notificationService;
  final PatternEngineService _patternEngineService;
  final GutScoreCalculatorService _gutScoreCalculatorService;
  final RuleBasedInsightBuilder _insightBuilder;
  final GutScoreFirestoreService? _gutScoreFirestoreService;

  Future<void> execute({bool force = false}) async {
    final stopwatch = Stopwatch()..start();
    final nowLocal = DateTime.now();
    final profile = await _authFirestoreService.getUserMetadata();
    if (profile?.insightsDisabled ?? false) {
      AppLogger.insights('Rule-based insight refresh skipped: Insights are disabled.');
      return;
    }

    const window = Duration(days: 30);
    final periodFrom = nowLocal.subtract(window);

    // Only fetch data needed for deterministic analytics. Chat history and AI
    // journal summaries are deliberately excluded from this pipeline.
    final streams = await Future.wait([
      _insightRepository.getRecentMeals(periodFrom),
      _insightRepository.getRecentSymptoms(periodFrom),
      _insightRepository.getRecentScans(periodFrom),
      _insightRepository.getLatestPatterns(),
    ]);

    final fetchedMeals = streams[0] as List<MealLog>;
    final fetchedSymptoms = streams[1] as List<SymptomLog>;
    final fetchedScans = streams[2] as List<ScanResult>;
    final previousPatterns = streams[3] as List<BodyPattern>;
    final candidateMeals = fetchedMeals.where((meal) => !meal.createdAt.isAfter(nowLocal) && !meal.eventTime.isAfter(nowLocal)).toList();
    final symptoms = fetchedSymptoms.where((symptom) => !symptom.createdAt.isAfter(nowLocal) && !symptom.eventTime.isAfter(nowLocal)).toList();
    final scans = fetchedScans.where((scan) => !scan.createdAt.isAfter(nowLocal)).toList();
    final meals = confirmedFoodMeals(meals: candidateMeals, scans: scans);

    // PatternEngineService is deterministic and runs independently of the old
    // daily AI threshold. Reuse the fetched journal snapshot to avoid repeating
    // three Firestore history reads; the engine still refreshes pattern_data/latest.
    final patterns = await _patternEngineService.runAnalysis(mealData: meals, symptomData: symptoms, scanData: scans);

    final isSaturday = nowLocal.weekday == DateTime.saturday;
    final currentWeekStart = GutScoreCalculatorService.startOfLocalWeek(nowLocal);
    final recapWeekStart = isSaturday
        ? currentWeekStart
        : DateTime(currentWeekStart.year, currentWeekStart.month, currentWeekStart.day - 7);
    final recapWeekEndExclusive = isSaturday ? nowLocal.add(const Duration(microseconds: 1)) : currentWeekStart;
    final recapWeekEnd = recapWeekEndExclusive.subtract(const Duration(microseconds: 1));

    final weekMeals = meals.where((meal) {
      final eventTime = meal.eventTime.toLocal();
      return !eventTime.isBefore(recapWeekStart) && eventTime.isBefore(recapWeekEndExclusive);
    }).toList();
    final weekSymptoms = symptoms.where((symptom) {
      final eventTime = symptom.eventTime.toLocal();
      return !eventTime.isBefore(recapWeekStart) && eventTime.isBefore(recapWeekEndExclusive);
    }).toList();
    final weekScans = scans.where((scan) {
      final createdAt = scan.createdAt.toLocal();
      return !createdAt.isBefore(recapWeekStart) && createdAt.isBefore(recapWeekEndExclusive);
    }).toList();

    final completedWeekRecord = _gutScoreCalculatorService.calculateWeeklyRecord(
      uid: profile?.uid ?? '',
      scans: scans,
      symptoms: symptoms,
      meals: meals,
      asOf: recapWeekEnd,
      recordedThrough: nowLocal,
    );
    final weeklyRecap = _gutScoreCalculatorService.calculateWeeklyRecap(
      recentScans: weekScans,
      recentSymptoms: weekSymptoms,
      recentMeals: weekMeals,
      weeklyTrend: completedWeekRecord.dailyScores,
      scoredDayIndices: completedWeekRecord.scoredDayIndices,
      periodFrom: recapWeekStart,
      periodTo: DateTime(recapWeekStart.year, recapWeekStart.month, recapWeekStart.day + 7).subtract(const Duration(microseconds: 1)),
    );

    // Keep the current score separate from the completed-week recap. A
    // deterministic journal refresh remains the score source of truth.
    final currentRecord = _gutScoreCalculatorService.calculateWeeklyRecord(
      uid: profile?.uid ?? '',
      scans: scans,
      symptoms: symptoms,
      meals: meals,
      asOf: nowLocal,
    );
    final latestRecord = await _gutScoreFirestoreService?.getLatestGutScore();
    final scoreRecord = latestRecord != null &&
            latestRecord.uid == currentRecord.uid &&
            latestRecord.periodFrom.isAtSameMomentAs(currentRecord.periodFrom)
        ? latestRecord
        : currentRecord;

    final standaloneScans = standaloneScanRecords(meals: meals, scans: scans);
    final insight = _insightBuilder.build(
      uid: profile?.uid,
      patterns: patterns,
      sampleSizes: SampleSizes(meals: meals.length, symptoms: symptoms.length, scans: standaloneScans.length),
      weeklyRecap: weeklyRecap,
      gutScore: scoreRecord.gutScore,
      hasGutScore: scoreRecord.hasScore,
      periodFrom: periodFrom.toUtc(),
      periodTo: nowLocal.toUtc(),
      updatedAt: nowLocal,
    );

    if ((await _authFirestoreService.getUserMetadata())?.uid != profile?.uid) {
      AppLogger.insights('Cancelled rule-based insight save because the active user changed during generation.');
      return;
    }

    // The repository uses the stable `rule_based_latest` document ID, so
    // refreshes update one current snapshot instead of growing AI history.
    await _insightRepository.saveInsight(insight);
    await _notifyForNewPatterns(profile, previousPatterns, patterns, nowLocal);

    final scoreText = scoreRecord.hasScore ? scoreRecord.gutScore.toString() : 'n/a';
    AppLogger.insights(
      'Rule-based Insights refreshed: meals=${meals.length}, symptoms=${symptoms.length}, patterns=${patterns.length}, score=$scoreText, forced=$force, elapsed=${stopwatch.elapsedMilliseconds}ms.',
    );
  }

  Future<void> _notifyForNewPatterns(
    UserProfile? profile,
    List<BodyPattern> previousPatterns,
    List<BodyPattern> currentPatterns,
    DateTime now,
  ) async {
    if (profile == null || !profile.notifPrefs.enableAll || !profile.notifPrefs.insightUpdates) return;

    String key(BodyPattern pattern) => pattern.id ?? '${pattern.type}|${pattern.trigger}|${pattern.reaction}';
    final known = previousPatterns.map(key).toSet();
    final hasNewPattern = currentPatterns.any((pattern) => !known.contains(key(pattern)));
    if (!hasNewPattern) return;

    final dayKey = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final notificationKey = 'last_rule_based_insight_notification_${profile.uid}';
    if (_prefs.getString(notificationKey) == dayKey) return;

    try {
      await _insightRepository.saveHealthAlert(
        HealthAlert(
          id: '',
          title: 'New pattern observation',
          message: 'Your recent logs show a repeated timing association. Review the observations and evidence in Insights.',
          type: 'insight_ready',
          createdAt: now,
          isRead: false,
        ),
      );
      await _notificationService.showInsightGeneratedNotification();
      await _prefs.setString(notificationKey, dayKey);
    } catch (error) {
      AppLogger.warning('Could not notify user about a new rule-based pattern: $error');
    }
  }
}
