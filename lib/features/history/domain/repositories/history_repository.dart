import 'package:gutgood/core/models/chat_message.dart';
import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/symptom_log.dart';

abstract class HistoryRepository {
  Future<List<ChatMessage>> getMessages({
    int? limit,
    int? offset,
    DateTime? beforeTime,
  });
  Future<List<ScanResult>> getScanHistory({int limit = 50});
  Future<List<ScanResult>> getSavedFoods();
  Future<void> toggleSaveFood(ScanResult scanData);
  Future<bool> isFoodSaved(String? productName, {String? barcode});
  
  Future<List<MealLog>> getRecentMealLogs({int limit = 30});
  Future<List<SymptomLog>> getRecentSymptomLogs({int limit = 30});
}
