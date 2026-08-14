import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/symptom_log.dart';
import 'package:gutgood/core/utils/logger_service.dart';

abstract class HistoryFirestoreService {
  Future<void> saveToScanHistory(ScanResult scanData, {String? userImageUrl});
  Future<List<ScanResult>> getScanHistory({int limit = 50});
  Future<List<ScanResult>> getRecentScans({int limit = 20});
  Future<List<ScanResult>> getSavedFoods();
  Future<void> toggleSaveFood(ScanResult scanData);
  Future<bool> isFoodSaved(String? productName, {String? barcode});

  Future<String?> logMeal(MealLog log);
  Future<List<MealLog>> getRecentMealLogs({int limit = 30});

  Future<String?> logSymptom(SymptomLog log);
  Future<List<SymptomLog>> getRecentSymptomLogs({int limit = 30});
  Future<List<SymptomLog>> getSymptomLogs();

  Future<int> getScansCountSince(DateTime since);
  Future<int> getMealLogsCountSince(DateTime since);
  Future<int> getSymptomsCountSince(DateTime since);
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
  Future<void> saveToScanHistory(ScanResult scanData, {String? userImageUrl}) async {
    try {
      final doc = _userDoc;
      if (doc == null) return;

      var bestImageUrl = userImageUrl;
      if (bestImageUrl == null || bestImageUrl.isEmpty) {
        bestImageUrl = scanData.userImageUrl;
      }
      if (bestImageUrl != null && bestImageUrl.isEmpty) bestImageUrl = null;

      // 🟢 Check if this product is already saved in history to persist the 'isSaved' state
      final isSaved = await isFoodSaved(scanData.productName, barcode: scanData.barcode);

      await doc.collection('scan_history').add({
        ...scanData.toMap(),
        'userImageUrl': bestImageUrl,
        'isSaved': isSaved,
        'timestamp': FieldValue.serverTimestamp(),
        'time': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      AppLogger.error('HistoryFirestoreService: Error saving to scan history', error: e);
    }
  }

  @override
  Future<List<ScanResult>> getScanHistory({int limit = 50}) async {
    try {
      final doc = _userDoc;
      if (doc == null) return [];
      final snapshot = await doc.collection('scan_history').orderBy('time', descending: true).limit(limit).get();
      final results = snapshot.docs.map((doc) => ScanResult.fromMap({...doc.data(), 'id': doc.id})).toList();
      return results;
    } catch (e) {
      AppLogger.error('HistoryFirestoreService: Error getting scan history', error: e);
      return [];
    }
  }

  @override
  Future<List<ScanResult>> getRecentScans({int limit = 20}) async => getScanHistory(limit: limit);

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

      AppLogger.info('HistoryFirestoreService: Toggled isSaved to $newState for ${scanData.productName}');
    } catch (e) {
      AppLogger.error('HistoryFirestoreService: Error toggling saved food', error: e);
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

      // 🟢 Get all saved items from history, ordered by time
      final snapshot = await doc.collection('scan_history').where('isSaved', isEqualTo: true).orderBy('time', descending: true).get();

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
      AppLogger.error('HistoryFirestoreService: Error getting saved foods', error: e);
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
      AppLogger.error('HistoryFirestoreService: Error logging meal', error: e);
      return null;
    }
  }

  @override
  Future<List<MealLog>> getRecentMealLogs({int limit = 30}) async {
    try {
      final doc = _userDoc;
      if (doc == null) return [];
      final snapshot = await doc.collection('meal_logs').orderBy('time', descending: true).limit(limit).get();
      final results = snapshot.docs.map((doc) => MealLog.fromMap(doc.data())).toList();
      // AppLogger.data('MEAL_LOGS', results.map((r) => r.toMap()).toList());
      return results;
    } catch (e) {
      AppLogger.error('HistoryFirestoreService: Error getting recent meal logs', error: e);
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
      AppLogger.error('HistoryFirestoreService: Error logging symptom', error: e);
      return null;
    }
  }

  @override
  Future<List<SymptomLog>> getRecentSymptomLogs({int limit = 30}) async {
    try {
      final doc = _userDoc;
      if (doc == null) return [];
      final snapshot = await doc.collection('symptom_logs').orderBy('time', descending: true).limit(limit).get();
      final results = snapshot.docs.map((doc) => SymptomLog.fromMap({...doc.data(), 'id': doc.id})).toList();
      // AppLogger.data('SYMPTOM_LOGS', results.map((r) => r.toMap()).toList());
      return results;
    } catch (e) {
      AppLogger.error('HistoryFirestoreService: Error getting recent symptom logs', error: e);
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
      AppLogger.error('HistoryFirestoreService: Error getting symptom logs', error: e);
      return [];
    }
  }

  @override
  Future<int> getScansCountSince(DateTime since) async {
    final doc = _userDoc;
    if (doc == null) return 0;
    final snapshot = await doc.collection('scan_history').where('time', isGreaterThanOrEqualTo: since.toIso8601String()).get();
    return snapshot.size;
  }

  @override
  Future<int> getMealLogsCountSince(DateTime since) async {
    final doc = _userDoc;
    if (doc == null) return 0;
    final snapshot = await doc.collection('meal_logs').where('time', isGreaterThanOrEqualTo: since.toIso8601String()).get();
    return snapshot.size;
  }

  @override
  Future<int> getSymptomsCountSince(DateTime since) async {
    final doc = _userDoc;
    if (doc == null) return 0;
    final snapshot = await doc.collection('symptom_logs').where('time', isGreaterThanOrEqualTo: since.toIso8601String()).get();
    return snapshot.size;
  }
}
