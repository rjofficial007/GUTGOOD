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
  HistoryFirestoreServiceImpl({
    required FirebaseAuth auth,
    required FirebaseFirestore db,
  })  : _auth = auth,
        _db = db;

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
      final barcode = scanData.barcode;

      var bestImageUrl = userImageUrl;
      if (bestImageUrl == null || bestImageUrl.isEmpty) {
        bestImageUrl = scanData.userImageUrl;
      }
      if (bestImageUrl != null && bestImageUrl.isEmpty) bestImageUrl = null;

      if (barcode != null && barcode.isNotEmpty) {
        final existing = await doc.collection('scan_history').where('barcode', isEqualTo: barcode).limit(1).get();
        if (existing.docs.isNotEmpty) {
          final existingData = existing.docs.first.data();
          final dbImageUrl = existingData['userImageUrl'] as String?;

          if (bestImageUrl == null || bestImageUrl.isEmpty) {
            bestImageUrl = dbImageUrl;
          }

          await existing.docs.first.reference.update({
            'timestamp': FieldValue.serverTimestamp(),
            'time': DateTime.now().toIso8601String(),
            'userImageUrl': bestImageUrl
          });
          return;
        }
      }

      await doc.collection('scan_history').add({
        ...scanData.toMap(),
        'userImageUrl': bestImageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'time': DateTime.now().toIso8601String()
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
      return snapshot.docs.map((doc) => ScanResult.fromMap(doc.data())).toList();
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

      final docId = _getFoodDocId(scanData.productName, barcode: scanData.barcode);
      final ref = doc.collection('saved_foods').doc(docId);
      final snap = await ref.get();

      if (snap.exists) {
        await ref.delete();
      } else {
        await ref.set({...scanData.toMap(), 'savedAt': FieldValue.serverTimestamp()});
      }
    } catch (e) {
      AppLogger.error('HistoryFirestoreService: Error toggling saved food', error: e);
    }
  }

  @override
  Future<bool> isFoodSaved(String? productName, {String? barcode}) async {
    try {
      final doc = _userDoc;
      if (doc == null) return false;

      final docId = _getFoodDocId(productName, barcode: barcode);
      final snap = await doc.collection('saved_foods').doc(docId).get();
      return snap.exists;
    } catch (e) {
      return false;
    }
  }

  String _getFoodDocId(String? productName, {String? barcode}) {
    if (barcode != null && barcode.isNotEmpty) return 'bc_$barcode';
    final safeName = (productName ?? 'unknown').replaceAll(RegExp('[^a-zA-Z0-9]'), '_').toLowerCase();
    return 'name_$safeName';
  }

  @override
  Future<List<ScanResult>> getSavedFoods() async {
    try {
      final doc = _userDoc;
      if (doc == null) return [];
      final snapshot = await doc.collection('saved_foods').get();
      return snapshot.docs.map((doc) => ScanResult.fromMap(doc.data())).toList();
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
      final data = {
        ...log.toMap(),
        'firestoreId': docRef.id,
        'source': log.source ?? 'chat',
        'createdAt': FieldValue.serverTimestamp()
      };
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
      return snapshot.docs.map((doc) => MealLog.fromMap(doc.data())).toList();
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
      final data = {
        ...log.toMap(),
        'firestoreId': docRef.id,
        'source': log.source ?? 'manual',
        'createdAt': FieldValue.serverTimestamp()
      };
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
      return snapshot.docs.map((doc) => SymptomLog.fromMap({...doc.data(), 'id': doc.id})).toList();
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
