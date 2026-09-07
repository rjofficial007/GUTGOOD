import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/models/health_alert.dart';
import 'package:gutgood/core/utils/logger_service.dart';

abstract class InsightFirestoreService {
  Future<String?> saveInsights(AIInsight insight, {bool useServerTimestamp = true});
  Future<AIInsight?> getLatestInsights();
  Stream<AIInsight?> getLatestInsightsStream();
  Future<List<AIInsight>> getInsightsHistory();
  Future<void> savePatternData(List<BodyPattern> patterns);
  Future<List<BodyPattern>> getLatestPatterns();
  Stream<List<BodyPattern>> getPatternDataStream();
  Future<void> saveHealthAlert(HealthAlert alert);
  Future<void> markAlertsAsRead(List<String> alertIds);
  Stream<List<HealthAlert>> getHealthAlertsStream({int limit = 20});
}

class InsightFirestoreServiceImpl implements InsightFirestoreService {
  InsightFirestoreServiceImpl({required FirebaseAuth auth, required FirebaseFirestore db}) : _auth = auth, _db = db;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  String? get _uid => _auth.currentUser?.uid;
  DocumentReference? get _userDoc {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('user_profiles').doc(uid);
  }

  @override
  Future<String?> saveInsights(AIInsight insight, {bool useServerTimestamp = true}) async {
    try {
      final doc = _userDoc;
      if (doc == null) return null;
      final docRef = doc.collection('insights').doc();
      final data = {...insight.toMap(), 'firestoreId': docRef.id, 'updatedAt': useServerTimestamp ? FieldValue.serverTimestamp() : Timestamp.fromDate(insight.updatedAt)};
      await docRef.set(data);
      return docRef.id;
    } catch (e) {
      AppLogger.firestore('Error saving insights', error: e);
      return null;
    }
  }

  @override
  Future<AIInsight?> getLatestInsights() async {
    try {
      final doc = _userDoc;
      if (doc == null) return null;
      final snapshot = await doc.collection('insights').orderBy('updatedAt', descending: true).limit(1).get();
      if (snapshot.docs.isEmpty) return null;
      return AIInsight.fromMap({...snapshot.docs.first.data(), 'id': snapshot.docs.first.id});
    } catch (e) {
      AppLogger.firestore('Error getting latest insights', error: e);
      return null;
    }
  }

  @override
  Stream<AIInsight?> getLatestInsightsStream() {
    final doc = _userDoc;
    if (doc == null) return Stream.value(null);
    return doc
        .collection('insights')
        .orderBy('updatedAt', descending: true)
        .limit(1)
        .snapshots()
        .handleError((e) {
          if (e.toString().contains('permission-denied')) {
            AppLogger.firestore('Insights stream closed (permission-denied)');
          } else {
            throw e;
          }
        })
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return AIInsight.fromMap({...snapshot.docs.first.data(), 'id': snapshot.docs.first.id});
        });
  }

  @override
  Future<List<AIInsight>> getInsightsHistory() async {
    try {
      final doc = _userDoc;
      if (doc == null) return [];
      final snapshot = await doc.collection('insights').orderBy('updatedAt', descending: true).get();
      final results = snapshot.docs.map((doc) => AIInsight.fromMap({...doc.data(), 'id': doc.id})).toList();
      // AppLogger.data('INSIGHTS_HISTORY_RAW', results.map((r) => r.toMap()).toList());
      return results;
    } catch (e) {
      AppLogger.firestore('Error getting insights history', error: e);
      return [];
    }
  }

  @override
  Future<void> savePatternData(List<BodyPattern> patterns) async {
    try {
      final doc = _userDoc;
      if (doc == null) return;
      await doc.collection('pattern_data').doc('latest').set({'patterns': patterns.map((p) => p.toMap()).toList(), 'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      AppLogger.firestore('Error saving pattern data', error: e);
    }
  }

  @override
  Future<List<BodyPattern>> getLatestPatterns() async {
    try {
      final doc = _userDoc;
      if (doc == null) return [];
      final snapshot = await doc.collection('pattern_data').doc('latest').get();
      if (!snapshot.exists) return [];
      final data = snapshot.data();
      if (data == null || data['patterns'] == null) return [];
      return (data['patterns'] as List).map((p) => BodyPattern.fromMap(p as Map<String, dynamic>)).toList();
    } catch (e) {
      AppLogger.firestore('Error getting latest patterns', error: e);
      return [];
    }
  }

  @override
  Stream<List<BodyPattern>> getPatternDataStream() {
    final doc = _userDoc;
    if (doc == null) return Stream.value([]);
    return doc
        .collection('pattern_data')
        .doc('latest')
        .snapshots()
        .handleError((e) {
          if (e.toString().contains('permission-denied')) {
            AppLogger.firestore('Patterns stream closed (permission-denied)');
          } else {
            throw e;
          }
        })
        .map((doc) {
          if (!doc.exists) return [];
          final data = doc.data();
          if (data == null || data['patterns'] == null) return [];
          final patterns = (data['patterns'] as List).map((p) => BodyPattern.fromMap(p as Map<String, dynamic>)).toList();
          return patterns;
        });
  }

  @override
  Future<void> saveHealthAlert(HealthAlert alert) async {
    try {
      final doc = _userDoc;
      if (doc == null) return;
      await doc.collection('health_alerts').add({...alert.toMap(), 'createdAt': FieldValue.serverTimestamp()});
    } catch (e) {
      AppLogger.firestore('Error saving health alert', error: e);
    }
  }

  @override
  Future<void> markAlertsAsRead(List<String> alertIds) async {
    try {
      final doc = _userDoc;
      if (doc == null || alertIds.isEmpty) return;

      final batch = _db.batch();
      final collection = doc.collection('health_alerts');

      for (final id in alertIds) {
        batch.update(collection.doc(id), {'isRead': true});
      }

      await batch.commit();
    } catch (e) {
      AppLogger.firestore('Error marking alerts as read', error: e);
    }
  }

  @override
  Stream<List<HealthAlert>> getHealthAlertsStream({int limit = 20}) {
    final doc = _userDoc;
    if (doc == null) return Stream.value([]);
    return doc
        .collection('health_alerts')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .handleError((e) {
          if (e.toString().contains('permission-denied')) {
            AppLogger.firestore('Alerts stream closed (permission-denied)');
          } else {
            throw e;
          }
        })
        .map((snapshot) => snapshot.docs.map((doc) => HealthAlert.fromMap(doc.data(), id: doc.id)).toList());
  }
}
