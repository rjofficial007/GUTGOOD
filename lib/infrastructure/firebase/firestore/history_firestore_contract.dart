part of 'history_firestore_service.dart';

/// Application-facing history persistence contract.

abstract class HistoryFirestoreService {
  /// Recalculate the current calendar-week score from persisted journal data.
  /// A refresh failure keeps the previous score and never undoes a saved log.
  Future<void> refreshGutScore();

  Future<void> saveToScanHistory(ScanResult scanData, {String? userImageUrl, String? scanId});

  /// Same write as [saveToScanHistory], but reports whether the scan document
  /// write completed. The void method remains for existing callers that keep
  /// the historical best-effort contract.
  Future<bool> trySaveToScanHistory(ScanResult scanData, {String? userImageUrl, String? scanId});

  Future<ScanResult?> getScanById(String scanId, {bool throwOnError = false});

  /// Appends distinct alternatives to an existing scan without creating a new record.
  Future<bool> appendScanSwaps({required String scanId, required List<ProductSwap> swaps});

  /// Updates an existing scan with its uploaded user photo without creating a partial scan record.
  Future<bool> patchScanUserImageUrl({required String scanId, required String imageUrl});

  /// Newest scan for [barcode], or null when never scanned. Backs the personal
  /// barcode cache (P0-3). Requires the (barcode, createdAt) composite index.
  Future<ScanResult?> getLatestScanByBarcode(String barcode);
  Future<List<ScanResult>> getScanHistory({int? limit, DateTime? since, DateTime? before, bool throwOnError = false});
  Future<List<ScanResult>> getLabelScans({int? limit, DateTime? since, DateTime? before});
  Future<List<ScanResult>> getMenuScans({int? limit, DateTime? since, DateTime? before});

  Future<List<ScanResult>> getRecentScans({int? limit, DateTime? since, DateTime? before, bool throwOnError = false});

  /// Saved-foods list (P2-6: single `saved_foods` collection read + lazy
  /// migration of pre-P2-6 flags). Returns full scans, newest first.
  Future<List<ScanResult>> getSavedFoods();

  /// Single-doc set/delete in `saved_foods` (no more history-wide batch).
  Future<void> toggleSaveFood(ScanResult scanData);

  /// Single doc get, with a legacy-flag fallback for unmigrated users.
  Future<bool> isFoodSaved(String? productName, {String? barcode});

  Future<String?> logMeal(MealLog log, {String? docId});
  Future<void> deleteScanMealProjections({required String chatMessageId, required String scanId, String? keepMealId});
  Future<List<MealLog>> getRecentMealLogs({int? limit, DateTime? since, DateTime? before, bool throwOnError = false});

  Future<String?> logSymptom(SymptomLog log, {String? docId});
  Future<List<SymptomLog>> getRecentSymptomLogs({int? limit, DateTime? since, DateTime? before, bool throwOnError = false});

  /// Count of meal logs with `createdAt >= [since]`.
  /// Returns -1 when the query itself failed (offline, permission, index) so
  /// callers can distinguish "no meals" from "unknown".
  Future<int> getMealLogsCountSince(DateTime since);

  /// Count of symptom logs with `createdAt >= [since]`.
  Future<int> getSymptomLogsCountSince(DateTime since);

  /// Count of scan history records with `createdAt >= [since]`.
  Future<int> getScansCountSince(DateTime since);

  /// Reactive history totals, read from the server-maintained
  /// `counters/totals` document (single-doc read). Falls back to cheap
  /// `count()` aggregations while the counters doc does not exist yet.
  Stream<HistoryCounts> watchHistoryCounts();

  /// Returns a stream of the average food score, updating in real-time.
  Stream<int> getAverageFoodScoreStream();

  /// Deletes all meal and symptom logs associated with a specific chat message.
  Future<void> deleteLogsForMessage(String chatMessageId);
}
