import 'package:gutgood/core/models/ai_analysis_result.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/symptom_log.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/firestore/history_firestore_service.dart';
import 'package:gutgood/core/services/streak_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/features/logs/domain/repositories/log_repository.dart';

class PersistAiResponseUseCase {
  PersistAiResponseUseCase({required HistoryFirestoreService firestoreService, required LogRepository logRepository, required AppStateService appStateService, required StreakService streakService})
    : _firestoreService = firestoreService,
      _appStateService = appStateService,
      _streakService = streakService;

  final HistoryFirestoreService _firestoreService;
  final AppStateService _appStateService;
  final StreakService _streakService;

  Future<AiAnalysisResult> call(AiAnalysisResult result, {String? chatMessageId, String? imageUrl, String? source, required Set<String> persistedTagBlocks}) async {
    var hasPersistedAnything = false;
    var updatedResult = result;

    // 🚀 Intent-Based Persistence Router
    final resolvedSource = (source ?? updatedResult.scan?.source ?? '').toUpperCase();
    final resolvedCategory = (updatedResult.scan?.category ?? '').toUpperCase();
    final intent = (updatedResult.intent ?? '').toUpperCase();

    // 1. Label Analysis
    if (resolvedSource.contains('LABEL') || resolvedCategory.contains('LABEL') || intent.contains('LABEL') || intent.contains('INGREDIENT')) {
      if (updatedResult.scan != null) {
        final persistenceKey = 'LABEL_${updatedResult.scan!.productName}_$chatMessageId';
        if (!persistedTagBlocks.contains(persistenceKey)) {
          AppLogger.ai('PersistAiResponse: Routing label to scan_history');

          final stableScanId = chatMessageId != null ? '${chatMessageId}_scan' : null;
          await _firestoreService.saveLabelScan(updatedResult.scan!, userImageUrl: imageUrl, scanId: stableScanId);

          updatedResult = updatedResult.copyWith(
            scan: updatedResult.scan!.copyWith(scanId: stableScanId, userImageUrl: imageUrl),
          );

          persistedTagBlocks.add(persistenceKey);
          hasPersistedAnything = true;
        }
      }
      _notifyAndMark(hasPersistedAnything);
      return updatedResult;
    }

    // 2. Restaurant Menu Analysis
    if (resolvedSource.contains('MENU') || resolvedCategory.contains('MENU') || intent.contains('MENU')) {
      if (updatedResult.scan != null || updatedResult.menu != null) {
        final persistenceKey = 'MENU_${updatedResult.scan?.productName ?? updatedResult.menu?['restaurantName']}_$chatMessageId';
        if (!persistedTagBlocks.contains(persistenceKey)) {
          AppLogger.ai('PersistAiResponse: Routing menu to scan_history');

          final stableScanId = chatMessageId != null ? '${chatMessageId}_scan' : null;
          await _firestoreService.saveMenuScan(
            updatedResult.scan ?? ScanResult(productName: 'Unknown', brand: 'Unknown', score: 0, impactType: ImpactType.neutral, impact: '', createdAt: DateTime.now()),
            menuData: updatedResult.menu,
            userImageUrl: imageUrl,
            scanId: stableScanId,
          );

          if (updatedResult.scan != null) {
            updatedResult = updatedResult.copyWith(
              scan: updatedResult.scan!.copyWith(scanId: stableScanId, userImageUrl: imageUrl),
            );
          }

          persistedTagBlocks.add(persistenceKey);
          hasPersistedAnything = true;
        }
      }
      _notifyAndMark(hasPersistedAnything);
      return updatedResult;
    }

    // 3. Normal Meal/Food/Product Scan
    // Persist Scan Result (Analysis)
    if (updatedResult.scan != null) {
      final scan = updatedResult.scan!;
      final persistenceKey = 'SCAN_${scan.productName}_${scan.score}';

      if (!persistedTagBlocks.contains(persistenceKey)) {
        if (scan.isLoggableProduct) {
          AppLogger.ai('PersistAiResponse: Saving Scan Result to scan_history - ${scan.productName}');
          final stableScanId = chatMessageId != null ? '${chatMessageId}_scan' : null;

          await _firestoreService.saveToScanHistory(
            scan.copyWith(scanId: stableScanId, chatMessageId: chatMessageId),
            userImageUrl: imageUrl,
            scanId: stableScanId,
          );

          // 🚀 Professional Data Linkage: Ensure the userImageUrl and scanId are returned
          // to the caller so they can be persisted in the Chat History document.
          updatedResult = updatedResult.copyWith(
            scan: scan.copyWith(scanId: stableScanId, chatMessageId: chatMessageId, userImageUrl: imageUrl),
          );

          hasPersistedAnything = true;
        }
        persistedTagBlocks.add(persistenceKey);
      }
    }

    // Persist Meal Log (Consumption)
    final isConsumptionIntent =
        intent == 'LOG_MEAL' ||
        intent == 'MEAL_RATING' ||
        intent == 'MEAL_PHOTO' ||
        intent == 'MEAL_RECOGNITION' ||
        intent == 'FOOD_RECOMMENDATION' ||
        (resolvedSource.contains('FOOD') && intent.contains('ANALYSIS'));

    if (updatedResult.meal != null && isConsumptionIntent) {
      final meal = updatedResult.meal!;
      final persistenceKey = 'MEAL_${meal.items.join('_')}_${meal.createdAt.millisecondsSinceEpoch}';

      if (!persistedTagBlocks.contains(persistenceKey)) {
        AppLogger.ai('PersistAiResponse: Saving Meal Log to journal_logs');

        // 🚀 PRD §13 & §14: Use chatMessageId to ensure idempotency.
        final stableMealId = chatMessageId != null ? '${chatMessageId}_meal' : null;

        final id = await _firestoreService.logMeal(
          meal.copyWith(chatMessageId: chatMessageId, source: source),
          docId: stableMealId,
        );
        if (id != null) {
          updatedResult = updatedResult.copyWith(meal: updatedResult.meal!.copyWith(firestoreId: id));
        }
        persistedTagBlocks.add(persistenceKey);
        hasPersistedAnything = true;
      }
    }

    // Persist Symptoms
    if (updatedResult.symptoms.isNotEmpty) {
      final updatedSymptoms = <SymptomLog>[];
      for (var i = 0; i < updatedResult.symptoms.length; i++) {
        var symptom = updatedResult.symptoms[i];
        final persistenceKey = 'SYMPTOM_${symptom.symptom}_${symptom.createdAt.millisecondsSinceEpoch}';
        if (!persistedTagBlocks.contains(persistenceKey)) {
          AppLogger.ai('PersistAiResponse: Saving Symptom - ${symptom.symptom}');

          // 🚀 PRD §13 & §14: Use indexed chatMessageId for multiple symptoms in one turn.
          final stableSymptomId = chatMessageId != null ? '${chatMessageId}_symptom_$i' : null;

          final id = await _firestoreService.logSymptom(symptom.copyWith(chatMessageId: chatMessageId), docId: stableSymptomId);
          if (id != null) {
            symptom = symptom.copyWith(firestoreId: id);
          }
          persistedTagBlocks.add(persistenceKey);
          hasPersistedAnything = true;
        }
        updatedSymptoms.add(symptom);
      }
      updatedResult = updatedResult.copyWith(symptoms: updatedSymptoms);
    }

    _notifyAndMark(hasPersistedAnything);
    return updatedResult;
  }

  void _notifyAndMark(bool hasPersistedAnything) {
    if (hasPersistedAnything) {
      _streakService.markActivityToday();
      _appStateService.notifyChatUpdated();
    }
  }
}
