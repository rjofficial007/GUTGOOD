import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/symptom_log.dart';
import 'package:gutgood/core/utils/date_time_utils.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:uuid/uuid.dart';

abstract class HistoryFirestoreService {
  Future<void> saveToScanHistory(ScanResult scanData, {String? userImageUrl, String? scanId});
  Future<List<ScanResult>> getScanHistory({int? limit, DateTime? since, DateTime? before});
  Future<List<ScanResult>> getRecentScans({int? limit, DateTime? since, DateTime? before});
  Future<List<ScanResult>> getSavedFoods();
  Future<void> toggleSaveFood(ScanResult scanData);
  Future<bool> isFoodSaved(String? productName, {String? barcode});

  Future<String?> logMeal(MealLog log);
  Future<List<MealLog>> getRecentMealLogs({int? limit, DateTime? since, DateTime? before});

  Future<String?> logSymptom(SymptomLog log);
  Future<List<SymptomLog>> getRecentSymptomLogs({int? limit, DateTime? since, DateTime? before});
  Future<List<SymptomLog>> getSymptomLogs();

  Future<int> getScansCountSince(DateTime since);
  Future<int> getMealLogsCountSince(DateTime since);
  Future<int> getSymptomsCountSince(DateTime since);

  Future<int> getTotalScansCount();
  Future<int> getTotalMealLogsCount();
  Future<int> getTotalSymptomsCount();

  Stream<int> getTotalScansCountStream();
  Stream<int> getTotalMealLogsCountStream();
  Stream<int> getTotalSymptomsCountStream();

  /// Calculates the average score of all food product scans in history.
  /// Ignores generic utility scans (menus, labels) via [ScanResult.isLoggableProduct].
  Future<int> getAverageFoodScore();

  /// Returns a stream of the average food score, updating in real-time.
  Stream<int> getAverageFoodScoreStream();

  /// Deletes all meal and symptom logs associated with a specific chat message.
  Future<void> deleteLogsForMessage(String chatMessageId);
}

class HistoryFirestoreServiceImpl implements HistoryFirestoreService {
  HistoryFirestoreServiceImpl({required FirebaseAuth auth, required FirebaseFirestore db}) : _auth = auth, _db = db;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  String? get _uid => _auth.currentUser?.uid;
  DocumentReference? get _userDoc {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('user_profiles').doc(uid);
  }

  @override
  Future<void> saveToScanHistory(ScanResult scanData, {String? userImageUrl, String? scanId}) async {
    try {
      final doc = _userDoc;
      final uid = _uid;
      if (doc == null || uid == null) return;

      final finalScanId = scanId ?? scanData.scanId ?? const Uuid().v4();

      // 🟢 Optimization: Start the isSaved check and the write together, or
      // handle isSaved defensively.
      var isSaved = scanData.isSaved;
      try {
        isSaved = await isFoodSaved(scanData.productName, barcode: scanData.barcode);
      } catch (e) {
        AppLogger.firestore('isFoodSaved check failed during scan save (likely missing index)');
      }

      var bestImageUrl = userImageUrl;
      if (bestImageUrl == null || bestImageUrl.isEmpty) {
        bestImageUrl = scanData.userImageUrl;
      }
      if (bestImageUrl != null && bestImageUrl.isEmpty) bestImageUrl = null;

      final data = {...scanData.toMap(), 'scanId': finalScanId, 'userId': uid, 'userImageUrl': bestImageUrl, 'isSaved': isSaved, 'createdAt': FieldValue.serverTimestamp()};

      await doc.collection('scan_history').doc(finalScanId).set(data, SetOptions(merge: true));
      AppLogger.firestore('Saved scan history doc: $finalScanId');
    } catch (e) {
      AppLogger.firestore('Critical error saving to scan history', error: e);
    }
  }

  @override
  Future<List<ScanResult>> getScanHistory({int? limit, DateTime? since, DateTime? before}) async {
    try {
      final doc = _userDoc;
      if (doc == null) return [];

      var query = doc.collection('scan_history').orderBy('createdAt', descending: true);

      if (since != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: DateTimeUtils.toTimestamp(since));
      }

      if (before != null) {
        query = query.where('createdAt', isLessThan: DateTimeUtils.toTimestamp(before));
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();

      // 🟢 DEFENSIVE: Map one by one and catch individual parsing errors
      // so one corrupt document doesn't hide the entire history.
      final results = <ScanResult>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          results.add(ScanResult.fromMap({...data, 'id': doc.id}));
        } catch (e) {
          AppLogger.error('Failed to parse scan history document ${doc.id}', error: e);
        }
      }

      return results;
    } catch (e) {
      AppLogger.firestore('Error getting scan history', error: e);
      return [];
    }
  }

  @override
  Future<List<ScanResult>> getRecentScans({int? limit, DateTime? since, DateTime? before}) async => getScanHistory(limit: limit, since: since, before: before);

  @override
  Future<void> toggleSaveFood(ScanResult scanData) async {
    try {
      final doc = _userDoc;
      if (doc == null) return;

      final isCurrentlySaved = await isFoodSaved(scanData.productName, barcode: scanData.barcode);
      final newState = !isCurrentlySaved;

      // 🟢 Update ALL instances of this product in scan_history
      final collection = doc.collection('scan_history');
      Query query;
      if (scanData.barcode != null && scanData.barcode!.isNotEmpty) {
        query = collection.where('barcode', isEqualTo: scanData.barcode);
      } else {
        query = collection.where('productName', isEqualTo: scanData.productName);
      }

      final snapshot = await query.get();
      final batch = _db.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'isSaved': newState});
      }
      await batch.commit();

      AppLogger.firestore('Toggled isSaved to $newState for ${scanData.productName}');
    } catch (e) {
      AppLogger.firestore('Error toggling saved food', error: e);
    }
  }

  @override
  Future<bool> isFoodSaved(String? productName, {String? barcode}) async {
    try {
      final doc = _userDoc;
      if (doc == null) return false;

      final collection = doc.collection('scan_history');
      Query query;
      if (barcode != null && barcode.isNotEmpty) {
        query = collection.where('barcode', isEqualTo: barcode);
      } else {
        query = collection.where('productName', isEqualTo: productName);
      }

      final snapshot = await query.where('isSaved', isEqualTo: true).limit(1).get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<List<ScanResult>> getSavedFoods() async {
    try {
      final doc = _userDoc;
      if (doc == null) return [];

      // 🟢 Get all saved items from history, ordered by creation time
      final snapshot = await doc.collection('scan_history').where('isSaved', isEqualTo: true).orderBy('createdAt', descending: true).get();

      final allSaved = snapshot.docs.map((doc) => ScanResult.fromMap({...doc.data(), 'id': doc.id})).toList();

      // 🟢 Deduplicate by barcode or name to show unique products only
      final uniqueProducts = <String, ScanResult>{};
      for (final scan in allSaved) {
        final key = scan.barcode ?? scan.productName;
        if (!uniqueProducts.containsKey(key)) {
          uniqueProducts[key] = scan;
        }
      }

      return uniqueProducts.values.toList();
    } catch (e) {
      AppLogger.firestore('Error getting saved foods', error: e);
      return [];
    }
  }

  @override
  Future<String?> logMeal(MealLog log) async {
    try {
      final doc = _userDoc;
      if (doc == null) return null;
      final docRef = doc.collection('meal_logs').doc();
      final data = {...log.toMap(), 'firestoreId': docRef.id, 'source': log.source ?? 'chat', 'createdAt': FieldValue.serverTimestamp()};
      await docRef.set(data);
      return docRef.id;
    } catch (e) {
      AppLogger.firestore('Error logging meal', error: e);
      return null;
    }
  }

  @override
  Future<List<MealLog>> getRecentMealLogs({int? limit, DateTime? since, DateTime? before}) async {
    try {
      final doc = _userDoc;
      if (doc == null) return [];

      var query = doc.collection('meal_logs').orderBy('createdAt', descending: true);

      if (since != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: DateTimeUtils.toTimestamp(since));
      }

      if (before != null) {
        query = query.where('createdAt', isLessThan: DateTimeUtils.toTimestamp(before));
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      final results = snapshot.docs.map((doc) => MealLog.fromMap(doc.data())).toList();
      return results;
    } catch (e) {
      AppLogger.firestore('Error getting recent meal logs', error: e);
      return [];
    }
  }

  @override
  Future<String?> logSymptom(SymptomLog log) async {
    try {
      final doc = _userDoc;
      if (doc == null) return null;
      final docRef = doc.collection('symptom_logs').doc();
      final data = {...log.toMap(), 'firestoreId': docRef.id, 'source': log.source ?? 'manual', 'createdAt': FieldValue.serverTimestamp()};
      await docRef.set(data);
      return docRef.id;
    } catch (e) {
      AppLogger.firestore('Error logging symptom', error: e);
      return null;
    }
  }

  @override
  Future<List<SymptomLog>> getRecentSymptomLogs({int? limit, DateTime? since, DateTime? before}) async {
    try {
      final doc = _userDoc;
      if (doc == null) return [];

      var query = doc.collection('symptom_logs').orderBy('createdAt', descending: true);

      if (since != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: DateTimeUtils.toTimestamp(since));
      }

      if (before != null) {
        query = query.where('createdAt', isLessThan: DateTimeUtils.toTimestamp(before));
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      final results = snapshot.docs.map((doc) => SymptomLog.fromMap({...doc.data(), 'id': doc.id})).toList();
      return results;
    } catch (e) {
      AppLogger.firestore('Error getting recent symptom logs', error: e);
      return [];
    }
  }

  @override
  Future<List<SymptomLog>> getSymptomLogs() async {
    try {
      final doc = _userDoc;
      if (doc == null) return [];
      final snapshot = await doc.collection('symptom_logs').get();
      return snapshot.docs.map((doc) => SymptomLog.fromMap({...doc.data(), 'id': doc.id})).toList();
    } catch (e) {
      AppLogger.firestore('Error getting symptom logs', error: e);
      return [];
    }
  }

  @override
  Future<int> getScansCountSince(DateTime since) async {
    final doc = _userDoc;
    if (doc == null) return 0;
    final snapshot = await doc.collection('scan_history').where('createdAt', isGreaterThanOrEqualTo: DateTimeUtils.toTimestamp(since)).get();
    return snapshot.size;
  }

  @override
  Future<int> getMealLogsCountSince(DateTime since) async {
    final doc = _userDoc;
    if (doc == null) return 0;
    final snapshot = await doc.collection('meal_logs').where('createdAt', isGreaterThanOrEqualTo: DateTimeUtils.toTimestamp(since)).get();
    return snapshot.size;
  }

  @override
  Future<int> getSymptomsCountSince(DateTime since) async {
    final doc = _userDoc;
    if (doc == null) return 0;
    final snapshot = await doc.collection('symptom_logs').where('createdAt', isGreaterThanOrEqualTo: DateTimeUtils.toTimestamp(since)).get();
    return snapshot.size;
  }

  @override
  Future<int> getTotalScansCount() async {
    final doc = _userDoc;
    if (doc == null) return 0;
    final snapshot = await doc.collection('scan_history').get();
    return snapshot.size;
  }

  @override
  Future<int> getTotalMealLogsCount() async {
    final doc = _userDoc;
    if (doc == null) return 0;
    final snapshot = await doc.collection('meal_logs').get();
    return snapshot.size;
  }

  @override
  Future<int> getTotalSymptomsCount() async {
    final doc = _userDoc;
    if (doc == null) return 0;
    final snapshot = await doc.collection('symptom_logs').get();
    return snapshot.size;
  }

  @override
  Stream<int> getTotalScansCountStream() {
    final doc = _userDoc;
    if (doc == null) return Stream.value(0);
    return doc.collection('scan_history').snapshots().map((s) => s.size);
  }

  @override
  Stream<int> getTotalMealLogsCountStream() {
    final doc = _userDoc;
    if (doc == null) return Stream.value(0);
    return doc.collection('meal_logs').snapshots().map((s) => s.size);
  }

  @override
  Stream<int> getTotalSymptomsCountStream() {
    final doc = _userDoc;
    if (doc == null) return Stream.value(0);
    return doc.collection('symptom_logs').snapshots().map((s) => s.size);
  }

  @override
  Future<int> getAverageFoodScore() async {
    try {
      final doc = _userDoc;
      if (doc == null) return 0;

      // Note: In production, this should ideally be an aggregated counter updated via triggers.
      // For now, we fetch all scans to calculate a true average.
      final snapshot = await doc.collection('scan_history').get();
      return _calculateAverage(snapshot.docs);
    } catch (e) {
      AppLogger.firestore('Error calculating average food score', error: e);
      return 0;
    }
  }

  @override
  Stream<int> getAverageFoodScoreStream() {
    final doc = _userDoc;
    if (doc == null) return Stream.value(0);

    return doc.collection('scan_history').snapshots().map((snapshot) => _calculateAverage(snapshot.docs));
  }

  int _calculateAverage(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    if (docs.isEmpty) return 0;

    final scores = docs.map((doc) => ScanResult.fromMap(doc.data())).where((s) => s.isLoggableProduct).map((s) => s.score).toList();

    if (scores.isEmpty) return 0;

    final sum = scores.reduce((a, b) => a + b);
    return (sum / scores.length).round();
  }

  @override
  Future<void> deleteLogsForMessage(String chatMessageId) async {
    try {
      final doc = _userDoc;
      if (doc == null) return;

      final batch = _db.batch();

      // Find and delete associated meal logs
      final mealSnaps = await doc.collection('meal_logs').where('chatMessageId', isEqualTo: chatMessageId).get();
      for (final d in mealSnaps.docs) {
        batch.delete(d.reference);
      }

      // Find and delete associated symptom logs
      final symptomSnaps = await doc.collection('symptom_logs').where('chatMessageId', isEqualTo: chatMessageId).get();
      for (final d in symptomSnaps.docs) {
        batch.delete(d.reference);
      }

      await batch.commit();
      AppLogger.firestore('Deleted logs associated with chatMessageId: $chatMessageId');
    } catch (e) {
      AppLogger.firestore('Error deleting logs for message', error: e);
    }
  }
}
