import 'dart:math';

import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/ai_insight_details.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/symptom_log.dart';
import 'package:gutgood/core/services/firestore/chat_firestore_service.dart';
import 'package:gutgood/core/services/firestore/history_firestore_service.dart';
import 'package:gutgood/core/services/firestore/insight_firestore_service.dart';
import 'package:gutgood/core/services/pattern_engine_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/core/utils/mock_data_seeder.dart';

class DebugMockDataService {
  DebugMockDataService({
    required HistoryFirestoreService historyFirestoreService,
    required InsightFirestoreService insightFirestoreService,
    required ChatFirestoreService chatFirestoreService,
    required PatternEngineService patternEngineService,
  }) : _historyFirestoreService = historyFirestoreService,
       _insightFirestoreService = insightFirestoreService,
       _chatFirestoreService = chatFirestoreService,
       _patternEngineService = patternEngineService;

  final HistoryFirestoreService _historyFirestoreService;
  final InsightFirestoreService _insightFirestoreService;
  final ChatFirestoreService _chatFirestoreService;
  final PatternEngineService _patternEngineService;

  /// Generates 45 days of raw historical data designed to naturally trigger
  /// all 6 insight patterns (Bloating, Energy, Headache, Digestion, Fullness, Sleep).
  ///
  /// IMPORTANT: This DOES NOT create Insight or Pattern records directly.
  /// It only populates the underlying meal and symptom logs.
  Future<void> generatePatternTriggeringData(String uid) async {
    AppLogger.info('MockData: Generating pattern-triggering data for $uid...');
    await MockDataSeeder.seedHistoricalData(historyService: _historyFirestoreService, chatService: _chatFirestoreService, uid: uid);
  }

  /// Manually triggers the Pattern Engine to analyze existing logs and
  /// generate patterns immediately, bypassing the usual 24h background cycle.
  Future<void> triggerPatternAnalysis() async {
    AppLogger.info('MockData: Manually triggering pattern engine analysis...');
    await _patternEngineService.runAnalysis();
  }
}
