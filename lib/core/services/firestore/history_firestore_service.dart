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
  Future<void> saveLabelScan(ScanResult scanData, {String? userImageUrl, String? scanId});
  Future<void> saveMenuScan(ScanResult scanData, {Map<String, dynamic>? menuData, String? userImageUrl, String? scanId});
  Future<ScanResult?> getScanById(String scanId);
  Future<List<ScanResult>> getScanHistory({int? limit, DateTime? since, DateTime? before});
  Future<List<ScanResult>> getLabelScans({int? limit, DateTime? since, DateTime? before});
  Future<List<ScanResult>> getMenuScans({int? limit, DateTime? since, DateTime? before});

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

      AppLogger.firestore('Saving scan history for ${scanData.productName}. Image URL present: ${bestImageUrl != null}');

      final data = {...scanData.toMap(), 'scanId': finalScanId, 'userId': uid, 'userImageUrl': bestImageUrl, 'isSaved': isSaved, 'createdAt': FieldValue.serverTimestamp()};

      await doc.collection('scan_history').doc(finalScanId).set(data, SetOptions(merge: true));
      AppLogger.firestore('Saved scan history doc: $finalScanId');
    } catch (e) {
      AppLogger.firestore('Critical error saving to scan history', error: e);
    }
  }

  @override
  Future<void> saveLabelScan(ScanResult scanData, {String? userImageUrl, String? scanId}) async {
    try {
      final doc = _userDoc;
      final uid = _uid;
      if (doc == null || uid == null) return;

      final finalScanId = scanId ?? scanData.scanId ?? const Uuid().v4();

      var bestImageUrl = userImageUrl ?? scanData.userImageUrl;
      if (bestImageUrl != null && bestImageUrl.isEmpty) bestImageUrl = null;

      // 🚀 Consolidated: Save to scan_history with source='label'
      final labelData = {...scanData.toMap(), 'scanId': finalScanId, 'userId': uid, 'source': 'label', 'category': 'label', 'userImageUrl': bestImageUrl, 'createdAt': FieldValue.serverTimestamp()};

      await doc.collection('scan_history').doc(finalScanId).set(labelData, SetOptions(merge: true));
      AppLogger.firestore('Label scan saved to scan_history: $finalScanId');
    } catch (e) {
      AppLogger.firestore('Error saving label scan to scan_history', error: e);
    }
  }

  @override
  Future<void> saveMenuScan(ScanResult scanData, {Map<String, dynamic>? menuData, String? userImageUrl, String? scanId}) async {
    try {
      final doc = _userDoc;
      final uid = _uid;
      if (doc == null || uid == null) return;

      final finalScanId = scanId ?? scanData.scanId ?? const Uuid().v4();

      var bestImageUrl = userImageUrl ?? scanData.userImageUrl;
      if (bestImageUrl != null && bestImageUrl.isEmpty) bestImageUrl = null;

      // Use provided menuData or fallback to scanData.rawData
      final raw = menuData ?? scanData.rawData ?? {};

      // 🚀 Consolidated: Save to scan_history with source='menu'
      final Map<String, dynamic> dataToSave = {
        ...scanData.toMap(),
        'scanId': finalScanId,
        'userId': uid,
        'source': 'menu',
        'category': 'menu',
        'restaurantName': raw['restaurantName'] ?? scanData.productName,
        'userImageUrl': bestImageUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await doc.collection('scan_history').doc(finalScanId).set(dataToSave, SetOptions(merge: true));
      AppLogger.firestore('Menu scan saved to scan_history: $finalScanId');
    } catch (e) {
      AppLogger.firestore('Error saving menu scan to scan_history', error: e);
    }
  }

  @override
  Future<ScanResult?> getScanById(String scanId) async {
    try {
      final doc = _userDoc;
      if (doc == null) return null;

      final snap = await doc.collection('scan_history').doc(scanId).get();
      if (!snap.exists) return null;

      return ScanResult.fromMap({...snap.data()!, 'id': snap.id});
    } catch (e) {
      AppLogger.firestore('Error getting scan by ID: $scanId', error: e);
      return null;
    }
  }

  @override
  Future<List<ScanResult>> getScanHistory({int? limit, DateTime? since, DateTime? before}) async {
    try {
      final doc = _userDoc;
      if (doc == null) return [];

      // 🚀 Robust Query: Fetch all scans and filter in-memory to support legacy data (where 'source' might be missing)
      // and ensure consistent behavior with ScanResult.isLoggableProduct.
      var query = doc.collection('scan_history').orderBy('createdAt', descending: true);

      if (since != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: DateTimeUtils.toTimestamp(since));
      }

      if (before != null) {
        query = query.where('createdAt', isLessThan: DateTimeUtils.toTimestamp(before));
      }

      // If we have a limit, we fetch a bit more to account for filtered items,
      // though for most users the filter won't remove many items.
      if (limit != null) {
        query = query.limit(limit * 2);
      }

      final snapshot = await query.get();

      final results = <ScanResult>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          final scan = ScanResult.fromMap({...data, 'id': doc.id});

          // Only show legitimate products in the main Scan History (filters out menus/labels)
          if (scan.isLoggableProduct) {
            results.add(scan);
          }

          if (limit != null && results.length >= limit) break;
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
  Future<List<ScanResult>> getLabelScans({int? limit, DateTime? since, DateTime? before}) async {
    try {
      final doc = _userDoc;
      if (doc == null) return [];

      // 🚀 Consolidated: Query scan_history with source='label'
      var query = doc.collection('scan_history').where('source', isEqualTo: 'label').orderBy('createdAt', descending: true);

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

      final results = <ScanResult>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          results.add(
            ScanResult.fromMap({
              ...data,
              'id': doc.id,
              'brand': data['brandName'] ?? data['brand'] ?? 'Unknown',
              'userImageUrl': data['userImageUrl'] ?? data['scanImage'],
              'category': 'label',
              'source': 'label',
            }),
          );
        } catch (e) {
          AppLogger.error('Failed to parse label scan document ${doc.id}', error: e);
        }
      }

      return results;
    } catch (e) {
      AppLogger.firestore('Error getting label scans', error: e);
      return [];
    }
  }

  @override
  Future<List<ScanResult>> getMenuScans({int? limit, DateTime? since, DateTime? before}) async {
    try {
      final doc = _userDoc;
      if (doc == null) return [];

      // 🚀 Consolidated: Query scan_history with source='menu'
      var query = doc.collection('scan_history').where('source', isEqualTo: 'menu').orderBy('createdAt', descending: true);

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

      final results = <ScanResult>[];
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          // For menus, productName is restaurantName
          final restaurantName = data['restaurantName'] ?? 'Unknown Restaurant';
          results.add(ScanResult.fromMap({...data, 'id': doc.id, 'productName': restaurantName, 'userImageUrl': data['userImageUrl'] ?? data['menuImage'], 'category': 'menu', 'source': 'menu'}));
        } catch (e) {
          AppLogger.error('Failed to parse menu scan document ${doc.id}', error: e);
        }
      }

      return results;
    } catch (e) {
      AppLogger.firestore('Error getting menu scans', error: e);
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
      // 🚀 Consolidated: Save to journal_logs
      final docRef = doc.collection('journal_logs').doc();
      final data = {...log.toMap(), 'firestoreId': docRef.id, 'type': 'meal', 'source': log.source ?? 'chat', 'createdAt': FieldValue.serverTimestamp()};
      await docRef.set(data);
      return docRef.id;
    } catch (e) {
      AppLogger.firestore('Error logging meal to journal_logs', error: e);
      return null;
    }
  }

  @override
  Future<List<MealLog>> getRecentMealLogs({int? limit, DateTime? since, DateTime? before}) async {
    try {
      final doc = _userDoc;
      if (doc == null) return [];

      // 🚀 Consolidated: Query journal_logs with type='meal'
      var query = doc.collection('journal_logs').where('type', isEqualTo: 'meal').orderBy('createdAt', descending: true);

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
      // 🚀 Consolidated: Save to journal_logs
      final docRef = doc.collection('journal_logs').doc();
      final data = {...log.toMap(), 'firestoreId': docRef.id, 'type': 'symptom', 'source': log.source ?? 'manual', 'createdAt': FieldValue.serverTimestamp()};
      await docRef.set(data);
      return docRef.id;
    } catch (e) {
      AppLogger.firestore('Error logging symptom to journal_logs', error: e);
      return null;
    }
  }

  @override
  Future<List<SymptomLog>> getRecentSymptomLogs({int? limit, DateTime? since, DateTime? before}) async {
    try {
      final doc = _userDoc;
      if (doc == null) return [];

      // 🚀 Consolidated: Query journal_logs with type='symptom'
      var query = doc.collection('journal_logs').where('type', isEqualTo: 'symptom').orderBy('createdAt', descending: true);

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
      final snapshot = await doc.collection('journal_logs').where('type', isEqualTo: 'symptom').get();
      return snapshot.docs.map((doc) => SymptomLog.fromMap({...doc.data(), 'id': doc.id})).toList();
    } catch (e) {
      AppLogger.firestore('Error getting symptom logs from journal_logs', error: e);
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
    final snapshot = await doc.collection('journal_logs').where('type', isEqualTo: 'meal').where('createdAt', isGreaterThanOrEqualTo: DateTimeUtils.toTimestamp(since)).get();
    return snapshot.size;
  }

  @override
  Future<int> getSymptomsCountSince(DateTime since) async {
    final doc = _userDoc;
    if (doc == null) return 0;
    final snapshot = await doc.collection('journal_logs').where('type', isEqualTo: 'symptom').where('createdAt', isGreaterThanOrEqualTo: DateTimeUtils.toTimestamp(since)).get();
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
    final snapshot = await doc.collection('journal_logs').where('type', isEqualTo: 'meal').get();
    return snapshot.size;
  }

  @override
  Future<int> getTotalSymptomsCount() async {
    final doc = _userDoc;
    if (doc == null) return 0;
    final snapshot = await doc.collection('journal_logs').where('type', isEqualTo: 'symptom').get();
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
    return doc.collection('journal_logs').where('type', isEqualTo: 'meal').snapshots().map((s) => s.size);
  }

  @override
  Stream<int> getTotalSymptomsCountStream() {
    final doc = _userDoc;
    if (doc == null) return Stream.value(0);
    return doc.collection('journal_logs').where('type', isEqualTo: 'symptom').snapshots().map((s) => s.size);
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

      // Find and delete associated logs from journal_logs
      final journalSnaps = await doc.collection('journal_logs').where('chatMessageId', isEqualTo: chatMessageId).get();
      for (final d in journalSnaps.docs) {
        batch.delete(d.reference);
      }

      // 🚀 Also delete the associated scan analysis if it was linked to this message
      batch
        ..delete(doc.collection('scan_history').doc(chatMessageId))
        ..delete(doc.collection('scan_history').doc('${chatMessageId}_scan'));

      await batch.commit();
      AppLogger.firestore('Deleted journal logs associated with chatMessageId: $chatMessageId');
    } catch (e) {
      AppLogger.firestore('Error deleting journal logs for message', error: e);
    }
  }
}
