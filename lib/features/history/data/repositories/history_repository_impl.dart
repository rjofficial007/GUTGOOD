import 'package:gutgood/core/models/chat_message.dart';
import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/symptom_log.dart';
import 'package:gutgood/core/services/firestore/history_firestore_service.dart';
import 'package:gutgood/features/history/domain/repositories/history_repository.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  HistoryRepositoryImpl({required HistoryFirestoreService firestoreService})
    : _firestoreService = firestoreService;
  final HistoryFirestoreService _firestoreService;

  @override
  Future<List<ChatMessage>> getMessages({
    int? limit,
    int? offset,
    DateTime? beforeTime,
  }) async => []; // Re-routing history logic to use the getScanHistory instead of scanning all chat messages

  @override
  Future<List<ScanResult>> getScanHistory({int? limit, DateTime? since, DateTime? before}) async =>
      _firestoreService.getScanHistory(limit: limit, since: since, before: before);

  @override
  Future<List<ScanResult>> getSavedFoods() async =>
      _firestoreService.getSavedFoods();

  @override
  Future<void> toggleSaveFood(ScanResult scanData) async =>
      _firestoreService.toggleSaveFood(scanData);

  @override
  Future<bool> isFoodSaved(String? productName, {String? barcode}) async =>
      _firestoreService.isFoodSaved(productName, barcode: barcode);

  @override
  Future<List<MealLog>> getRecentMealLogs({int? limit, DateTime? since, DateTime? before}) async =>
      _firestoreService.getRecentMealLogs(limit: limit, since: since, before: before);

  @override
  Future<List<SymptomLog>> getRecentSymptomLogs({int? limit, DateTime? since, DateTime? before}) async =>
      _firestoreService.getRecentSymptomLogs(limit: limit, since: since, before: before);
}
