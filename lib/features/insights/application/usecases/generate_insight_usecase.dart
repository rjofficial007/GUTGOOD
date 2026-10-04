import 'dart:async';

import 'package:gutgood/core/ai/protocol/ai_constants.dart';
import 'package:gutgood/core/constants/storage_keys.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/services/gut_score_calculator_service.dart';
import 'package:gutgood/core/utils/date_time_utils.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/features/insights/application/usecases/summarize_journal_usecase.dart';
import 'package:gutgood/features/insights/data/services/pattern_engine_service.dart';
import 'package:gutgood/features/insights/domain/repositories/insight_repository.dart';
import 'package:gutgood/features/insights/domain/services/insight_generation_policy.dart';
import 'package:gutgood/features/insights/domain/usecases/build_unified_journal_usecase.dart';
import 'package:gutgood/features/insights/domain/usecases/check_insight_threshold_usecase.dart';
import 'package:gutgood/infrastructure/firebase/firestore/auth_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/gut_score_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/notification_service.dart';
import 'package:gutgood/infrastructure/firebase/remote_config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// UseCase to coordinate the generation of gut health insights.
class GenerateInsightUseCase {
  GenerateInsightUseCase({
    required InsightRepository insightRepository,
    required AuthFirestoreService authFirestoreService,
    required CheckInsightThresholdUseCase checkThreshold,
    required BuildUnifiedJournalUseCase buildJournal,
    required SummarizeJournalUseCase summarizeJournal,
    required SharedPreferences prefs,
    required NotificationService notificationService,
    required PatternEngineService patternEngineService,
    GutScoreCalculatorService gutScoreCalculatorService = const GutScoreCalculatorService(),
    GutScoreFirestoreService? gutScoreFirestoreService,
  }) : _insightRepository = insightRepository,
       _authFirestoreService = authFirestoreService,
       _checkThreshold = checkThreshold,
       _buildJournal = buildJournal,
       _summarizeJournal = summarizeJournal,
       _prefs = prefs,
       _notificationService = notificationService,
       _patternEngineService = patternEngineService,
       _gutScoreCalculatorService = gutScoreCalculatorService,
       _gutScoreFirestoreService = gutScoreFirestoreService;

  final InsightRepository _insightRepository;
  final AuthFirestoreService _authFirestoreService;
  final CheckInsightThresholdUseCase _checkThreshold;
  final BuildUnifiedJournalUseCase _buildJournal;
  final SummarizeJournalUseCase _summarizeJournal;
  final SharedPreferences _prefs;
  final NotificationService _notificationService;
  final PatternEngineService _patternEngineService;
  final GutScoreCalculatorService _gutScoreCalculatorService;
  final GutScoreFirestoreService? _gutScoreFirestoreService;

  Future<void> execute({bool force = false}) async {
    final lastRunStr = _prefs.getString(StorageKeys.lastInsightRun);
    DateTime lastRun;

    if (lastRunStr != null) {
      lastRun = DateTimeUtils.parseToUtc(lastRunStr);
    } else {
      final latestCloud = await _insightRepository.getLatestInsight();
      lastRun = latestCloud?.updatedAt.toUtc() ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      AppLogger.insights('No local lastRun found. Fallback to Firestore: $lastRun');
    }

    final nowUtc = DateTime.now().toUtc();
    final isSameDay = lastRun.year == nowUtc.year && lastRun.month == nowUtc.month && lastRun.day == nowUtc.day;

    if (isSameDay && !force) {
      AppLogger.debug('GenerateInsightUseCase: Insight was already generated today ($lastRun). Skipping.');
      return;
    }
    if (force && isSameDay) {
      AppLogger.insights('GenerateInsightUseCase: manual refresh bypassed the daily generation guard');
    }

    final profile = await _authFirestoreService.getUserMetadata();
    // Client-owned cadence: honor the per-user disable toggle here (the
    // retired server pipeline used to enforce it).
    if (profile?.insightsDisabled ?? false) {
      AppLogger.debug('GenerateInsightUseCase: insights disabled in profile. Skipping.');
      return;
    }
    final userGoals = profile?.goals ?? _prefs.getStringList(StorageKeys.userGoals) ?? [];
    final userSensitivities = profile?.sensitivities ?? _prefs.getStringList('user_sensitivities') ?? [];
    final userLifestyle = profile?.lifestyle ?? _prefs.getStringList('user_lifestyle') ?? [];

    final cycleSyncEnabled = profile?.cycleSyncEnabled ?? _prefs.getBool('cycle_sync_enabled') ?? false;
    final cyclePhase = cycleSyncEnabled ? (profile?.cyclePhase ?? _prefs.getString('cycle_phase') ?? 'Luteal Phase') : 'Not specified';

    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    final dataStreams = await Future.wait([
      _insightRepository.getRecentMeals(thirtyDaysAgo),
      _insightRepository.getRecentSymptoms(thirtyDaysAgo),
      _insightRepository.getRecentScans(thirtyDaysAgo),
      _insightRepository.getInsightHistory(),
      _insightRepository.getLatestPatterns(),
      _insightRepository.getRecentChat(thirtyDaysAgo),
    ]);

    final allMeals = dataStreams[0] as List<MealLog>;
    final allSymptoms = dataStreams[1] as List<SymptomLog>;
    final allScans = dataStreams[2] as List<ScanResult>;
    final history = dataStreams[3] as List<AIInsight>;
    final allChat = dataStreams[5] as List<ChatMessage>;

    // Check if today's logs meet the exact daily threshold matching InsightBentoLearning:
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    final todayMealLogs = allMeals.where((m) => m.createdAt.isAfter(startOfToday) || m.eventTime.isAfter(startOfToday)).toList();
    final todayMeals = todayMealLogs.length;
    final todaySymptoms = allSymptoms.where((s) => s.createdAt.isAfter(startOfToday) || s.eventTime.isAfter(startOfToday)).length;
    final todayScanLogs = allScans.where((s) => s.createdAt.isAfter(startOfToday)).toList();
    // New scans have a meal projection. Count only legacy scan-only records in
    // the scan leg so the daily threshold does not count one scan twice.
    final todayStandaloneScans = standaloneScanRecords(meals: todayMealLogs, scans: todayScanLogs);
    final todayFood = uniqueFoodEventCount(meals: todayMealLogs, scans: todayScanLogs);

    // Baseline daily logging threshold: 3 Food Scans/Meals AND 1 Symptom Log TODAY
    final hasBaselineLogs = _checkThreshold.execute(scanCount: todayStandaloneScans.length, mealCount: todayMeals, symptomCount: todaySymptoms);

    if (!hasBaselineLogs) {
      AppLogger.debug('GenerateInsightUseCase: Insufficient daily logs today (food: $todayFood/3, symptoms: $todaySymptoms/1). Skipping AI generation until threshold is reached.');
      return;
    }

    // 🟢 EVIDENCE-FIRST: Run deterministic pattern engine BEFORE AI interpretation
    final freshPatterns = await _patternEngineService.runAnalysis();

    // 🟢 TIERED JOURNALING: Split into High-Fidelity (7d) and Historical (8-30d)
    final recentMeals = allMeals.where((m) => m.eventTime.isAfter(sevenDaysAgo)).toList();
    final recentSymptoms = allSymptoms.where((s) => s.eventTime.isAfter(sevenDaysAgo)).toList();
    final recentScans = allScans.where((s) => s.createdAt.isAfter(sevenDaysAgo)).toList();

    final historicalMeals = allMeals.where((m) => m.eventTime.isBefore(sevenDaysAgo)).toList();
    final historicalSymptoms = allSymptoms.where((s) => s.eventTime.isBefore(sevenDaysAgo)).toList();
    final historicalScans = allScans.where((s) => s.createdAt.isBefore(sevenDaysAgo)).toList();

    final recentJournalText = _buildJournal.execute(meals: recentMeals, symptoms: recentSymptoms, scans: recentScans);

    String? historicalJournalSummary;
    if (historicalMeals.isNotEmpty || historicalScans.isNotEmpty) {
      final historicalJournalText = _buildJournal.execute(meals: historicalMeals, symptoms: historicalSymptoms, scans: historicalScans);
      historicalJournalSummary = await _summarizeJournal.execute(historicalJournalText);
    }

    // 🟢 CHAT HYGIENE: Limit raw recent chat to last 10 messages (C-4: the
    // list arrives newest-first, so the head — not the tail — is "recent").
    final recentChat = takeRecentChat(allChat);

    final scoreList = history.take(6).toList().reversed.toList();
    final scoreHistoryString = scoreList.map((i) => i.gutScore).join(', ');
    final lastScore = scoreList.isNotEmpty ? scoreList.last.gutScore : null;

    final insight = await _insightRepository.analyzeGutHealth(
      goals: userGoals,
      sensitivities: userSensitivities,
      lifestyle: userLifestyle,
      cyclePhase: cyclePhase,
      chatSummary: profile?.chatSummary,
      chatHistory: recentChat,
      recentJournalText: recentJournalText,
      historicalJournalSummary: historicalJournalSummary,
      scoreHistory: scoreHistoryString.isEmpty ? null : 'Score history (oldest to newest): $scoreHistoryString. Most recent score is $lastScore.',
      patternCandidates: freshPatterns,
      lastScore: lastScore,
    );

    // Deterministic gut score from the last 7 local days only.
    // Do NOT fall back to 30-day scans — that inflated gutScore / avgScanScore
    // and made dailyScores look "full" while mealsCount stayed at the 7-day window.
    final endLocal = DateTime.now();
    final weekScans = recentScans;
    final weekSymptoms = recentSymptoms;
    final weekMeals = recentMeals;
    final hasWeekScore = _gutScoreCalculatorService.hasScoreData(weekScans);

    final avgScanScore = _gutScoreCalculatorService.calculateAvgScanScore(weekScans);
    // Trend uses all loaded logs but buckets only the last 7 local days.
    final weeklyTrend = List<int>.from(_gutScoreCalculatorService.calculateWeeklyTrend(scans: allScans, symptoms: allSymptoms, meals: allMeals, endDate: endLocal));
    final displayScore = hasWeekScore ? avgScanScore : 0;

    // Ensure today's slot in dailyScores matches the profile score (displayScore)
    final todayIndex = endLocal.weekday % 7;
    if (todayIndex >= 0 && todayIndex < weeklyTrend.length) {
      weeklyTrend[todayIndex] = displayScore;
    }

    final weeklyRecap = _gutScoreCalculatorService.calculateWeeklyRecap(
      recentScans: weekScans,
      recentSymptoms: weekSymptoms,
      recentMeals: weekMeals,
      weeklyTrend: weeklyTrend,
      exactScore: displayScore,
      endDate: endLocal,
    );

    if (_gutScoreFirestoreService != null) {
      final startLocalDay = GutScoreCalculatorService.startOfLocalDay(endLocal);
      final sunday = startLocalDay.subtract(Duration(days: startLocalDay.weekday % 7));
      final saturday = sunday.add(const Duration(days: 6));

      final scoreRecord = GutScoreRecord(
        id: 'weekly_${endLocal.year}_W${_isoWeekOf(endLocal)}',
        uid: profile?.uid ?? '',
        type: 'weekly',
        scansCount: weekScans.length,
        mealsCount: weekMeals.length,
        symptomsCount: weekSymptoms.length,
        dailyScores: weeklyTrend,
        // Period starts from Sunday and ends on Saturday of the current week.
        periodFrom: sunday.toUtc(),
        periodTo: saturday.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1)).toUtc(),
        createdAt: endLocal.toUtc(),
      );
      await _gutScoreFirestoreService.saveGutScore(scoreRecord);
    }

    // P2-10 theme envelope (period/evidence/provenance/status) at the write edge.
    final standaloneScans = standaloneScanRecords(meals: allMeals, scans: allScans);
    final stamped = stampInsightEnvelope(
      insight,
      candidates: freshPatterns,
      periodFrom: thirtyDaysAgo,
      periodTo: nowUtc,
      sampleSizes: SampleSizes(meals: allMeals.length, symptoms: allSymptoms.length, scans: standaloneScans.length),
      model: insight.model ?? RemoteConfigService.instance.openAIModel,
      promptVersion: insight.promptVersion ?? AiVersions.insightPromptVersion,
      expiresAt: DateTime.now().add(const Duration(hours: 48)),
      exactGutScore: displayScore,
      hasGutScore: hasWeekScore,
      avgScanScore: avgScanScore,
      weeklyTrend: weeklyTrend,
      weeklyRecap: weeklyRecap,
    );
    // The score is calculated locally after the AI response. Use that same
    // score for the displayed delta instead of a model/missing-score value.
    final finalizedInsight = lastScore != null && hasWeekScore
        ? stamped.copyWith(scoreDiff: _formatScoreDiff(displayScore - lastScore))
        : stamped;

    // Save insight and notify user upon successful generation
    await _insightRepository.saveInsight(finalizedInsight);
    await _prefs.setString(StorageKeys.lastInsightRun, DateTime.now().toUtc().toIso8601String());

    unawaited(
      _insightRepository.saveHealthAlert(
        HealthAlert(
          id: '',
          title: 'Gut Insight Ready',
          message: 'Your latest personalized gut health analysis is ready. Open to see your new score!',
          type: 'insight_ready',
          createdAt: DateTime.now(),
          isRead: false,
        ),
      ),
    );

    unawaited(_notificationService.showInsightGeneratedNotification());
    AppLogger.insights('GenerateInsightUseCase: Insight generated and user notified successfully.');
  }
}

/// ISO-like week-of-year helper for stable weekly gut_scores doc ids.
int _isoWeekOf(DateTime date) {
  final local = date.toLocal();
  final dayOfYear = DateTime(local.year, local.month, local.day).difference(DateTime(local.year)).inDays + 1;
  return ((dayOfYear - local.weekday + 10) / 7).floor().clamp(1, 53);
}

String _formatScoreDiff(int diff) => diff >= 0 ? '+$diff' : '$diff';
