import 'package:gutgood/core/models/ai_analysis_result.dart';
import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/symptom_log.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/firestore/history_firestore_service.dart';
import 'package:gutgood/core/services/streak_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/features/logs/domain/repositories/log_repository.dart';

class PersistAiResponseUseCase {
  PersistAiResponseUseCase({
    required HistoryFirestoreService firestoreService,
    required LogRepository logRepository,
    required AppStateService appStateService,
    required StreakService streakService,
  }) : _firestoreService = firestoreService,
       _logRepository = logRepository,
       _appStateService = appStateService,
       _streakService = streakService;

  final HistoryFirestoreService _firestoreService;
  final LogRepository _logRepository;
  final AppStateService _appStateService;
  final StreakService _streakService;

  Future<void> call(
    AiAnalysisResult result, {
    String? chatMessageId,
    String? imageUrl,
    String? source,
    required Set<String> persistedTagBlocks,
  }) async {
    var hasPersistedAnything = false;

    // 1. Persist Scan Result
    if (result.scan != null) {
      final scan = result.scan!;
      final persistenceKey = 'SCAN_${scan.productName}_${scan.score}';
      
      if (!persistedTagBlocks.contains(persistenceKey)) {
        if (scan.isLoggableProduct) {
          AppLogger.ai('PersistAiResponse: Saving Scan Result - ${scan.productName}');
          final stableScanId = chatMessageId != null ? '${chatMessageId}_scan' : null;
          
          await _firestoreService.saveToScanHistory(
            scan.copyWith(scanId: stableScanId, chatMessageId: chatMessageId),
            userImageUrl: imageUrl,
            scanId: stableScanId,
          );
          hasPersistedAnything = true;
          
          // Auto-log meal if it's a food image
          final isFoodImage = source == 'food' || source == 'meal' || source == 'gallery' || imageUrl != null;
          if (isFoodImage && !persistedTagBlocks.contains('__MEAL_LOGGED_IN_TURN__')) {
             final mealLog = MealLog(
              items: [scan.productName],
              photoUrl: imageUrl ?? scan.imageUrl,
              time: scan.time ?? DateTime.now(),
              source: source ?? 'chat',
              chatMessageId: chatMessageId,
            );
            await _logRepository.logMeal(mealLog);
            persistedTagBlocks.add('__MEAL_LOGGED_IN_TURN__');
            hasPersistedAnything = true;
          }
        }
        persistedTagBlocks.add(persistenceKey);
      }
    }

    // 2. Persist Meal Log
    if (result.meal != null && !persistedTagBlocks.contains('__MEAL_LOGGED_IN_TURN__')) {
      final meal = result.meal!;
      // Use items and time as a unique key for the turn
      final persistenceKey = 'MEAL_${meal.items.join('_')}_${meal.time.millisecondsSinceEpoch}';

      if (!persistedTagBlocks.contains(persistenceKey)) {
        AppLogger.ai('PersistAiResponse: Saving Meal Log');
        await _logRepository.logMeal(meal.copyWith(chatMessageId: chatMessageId));
        persistedTagBlocks.add(persistenceKey);
        persistedTagBlocks.add('__MEAL_LOGGED_IN_TURN__');
        hasPersistedAnything = true;
      }
    }

    // 3. Persist Symptoms
    for (final symptom in result.symptoms) {
      final persistenceKey = 'SYMPTOM_${symptom.symptom}_${symptom.time.millisecondsSinceEpoch}';
      if (!persistedTagBlocks.contains(persistenceKey)) {
        AppLogger.ai('PersistAiResponse: Saving Symptom - ${symptom.symptom}');
        await _logRepository.logSymptom(symptom.copyWith(chatMessageId: chatMessageId));
        persistedTagBlocks.add(persistenceKey);
        hasPersistedAnything = true;
      }
    }

    if (hasPersistedAnything) {
      await _streakService.markActivityToday();
      _appStateService.notifyChatUpdated();
    }
  }
}
