import 'dart:async';

import 'package:gutgood/core/constants/ai_constants.dart';
import 'package:gutgood/core/constants/storage_keys.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/services/firestore/auth_firestore_service.dart';
import 'package:gutgood/core/services/firestore/history_firestore_service.dart';
import 'package:gutgood/core/services/notification_service.dart';
import 'package:gutgood/core/services/pattern_engine_service.dart';
import 'package:gutgood/core/services/remote_config_service.dart';
import 'package:gutgood/core/utils/date_time_utils.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/features/insights/domain/repositories/insight_repository.dart';
import 'package:gutgood/features/insights/domain/usecases/build_unified_journal_usecase.dart';
import 'package:gutgood/features/insights/domain/usecases/check_insight_threshold_usecase.dart';
import 'package:gutgood/features/insights/domain/usecases/summarize_journal_usecase.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// UseCase to coordinate the generation of gut health insights.
class GenerateInsightUseCase {
  GenerateInsightUseCase({
    required InsightRepository insightRepository,
    required AuthFirestoreService authFirestoreService,
    required HistoryFirestoreService historyFirestoreService,
    required CheckInsightThresholdUseCase checkThreshold,
    required BuildUnifiedJournalUseCase buildJournal,
    required SummarizeJournalUseCase summarizeJournal,
    required SharedPreferences prefs,
    required NotificationService notificationService,
    required PatternEngineService patternEngineService,
  }) : _insightRepository = insightRepository,
       _authFirestoreService = authFirestoreService,
       _historyFirestoreService = historyFirestoreService,
       _checkThreshold = checkThreshold,
       _buildJournal = buildJournal,
       _summarizeJournal = summarizeJournal,
       _prefs = prefs,
       _notificationService = notificationService,
       _patternEngineService = patternEngineService;

  final InsightRepository _insightRepository;
  final AuthFirestoreService _authFirestoreService;
  // ignore: unused_field
  final HistoryFirestoreService _historyFirestoreService;
  final CheckInsightThresholdUseCase _checkThreshold;
  final BuildUnifiedJournalUseCase _buildJournal;
  final SummarizeJournalUseCase _summarizeJournal;
  final SharedPreferences _prefs;
  final NotificationService _notificationService;
  final PatternEngineService _patternEngineService;

  Future<void> execute() async {
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
    final hoursSinceLastRun = nowUtc.difference(lastRun).inHours;

    if (hoursSinceLastRun < 24) {
      AppLogger.debug('GenerateInsightUseCase: Last insight was generated $hoursSinceLastRun hours ago. Skipping.');
      return;
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

    // Check if TODAY's new logs (since lastRun) meet the exact daily threshold:
    // Exactly: 3 New Scans Today OR (3 New Meals Today AND 1 New Symptom Today)
    final newMeals = allMeals.where((m) => m.eventTime.isAfter(lastRun)).toList();
    final newSymptoms = allSymptoms.where((s) => s.eventTime.isAfter(lastRun)).toList();
    final newScans = allScans.where((s) => s.createdAt.isAfter(lastRun)).toList();

    if (!_checkThreshold.execute(scanCount: newScans.length, mealCount: newMeals.length, symptomCount: newSymptoms.length)) {
      AppLogger.debug('GenerateInsightUseCase: Daily log threshold (3 new scans OR 3 new meals + 1 symptom today) not reached since last run ($lastRun). Skipping insight generation.');
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

    // P2-10 v2 envelope (period/evidence/provenance/status) at the write edge.
    final stamped = stampInsightEnvelope(
      insight,
      candidates: freshPatterns,
      periodFrom: thirtyDaysAgo,
      periodTo: nowUtc,
      sampleSizes: SampleSizes(meals: allMeals.length, symptoms: allSymptoms.length, scans: allScans.length),
      model: RemoteConfigService.instance.openAIModel,
      promptVersion: AiVersions.insightPromptVersion,
      expiresAt: DateTime.now().add(const Duration(hours: 48)),
    );

    // Side Effects
    await _prefs.setString(StorageKeys.lastInsightRun, DateTime.now().toUtc().toIso8601String());
    await _insightRepository.saveInsight(stamped);

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
  }
}

/// P2-10: pure v2-envelope stamp. Status honors the minimum-evidence doctrine
/// (§H): no candidates, or a data span under 7 days, yields
/// [AIInsight.statusInsufficientData] — a score-trend digest with zero pattern
/// claims and an explicit "not enough data yet" state downstream.
AIInsight stampInsightEnvelope(
  AIInsight insight, {
  required List<BodyPattern> candidates,
  required DateTime periodFrom,
  required DateTime periodTo,
  required SampleSizes sampleSizes,
  required String model,
  required int promptVersion,
  required DateTime expiresAt,
}) {
  final spanDays = candidates.isEmpty ? 0 : candidates.first.timeframeDays;
  return insight.copyWith(
    periodFrom: periodFrom,
    periodTo: periodTo,
    evidence: InsightEvidence.fromPatterns(candidates, sampleSizes: sampleSizes),
    status: (candidates.isEmpty || spanDays < 7) ? AIInsight.statusInsufficientData : AIInsight.statusReady,
    actions: insight.topInsight?.nextSteps ?? const [],
    model: model,
    promptVersion: promptVersion,
    expiresAt: expiresAt,
    origin: AIInsight.originClient,
  );
}

/// C-4: takes the [limit] most recent messages from a newest-first list.
List<ChatMessage> takeRecentChat(List<ChatMessage> newestFirst, [int limit = 10]) => newestFirst.length > limit ? newestFirst.sublist(0, limit) : newestFirst;
