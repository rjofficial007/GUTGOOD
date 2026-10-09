import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gutgood/core/models/insights/ai_insight.dart';
import 'package:gutgood/core/models/insights/body_pattern.dart';
import 'package:gutgood/core/models/insights/gut_experiment.dart';
import 'package:gutgood/core/models/insights/insight_ai_interpretation.dart';
import 'package:gutgood/core/models/user/health_alert.dart';
import 'package:gutgood/core/utils/date_time_utils.dart';
import 'package:gutgood/core/utils/logger_service.dart';

abstract class InsightFirestoreService {
  Future<String?> saveInsights(AIInsight insight, {bool useServerTimestamp = true});
  Future<bool> saveAiInterpretation({required String uid, required String insightId, required DateTime expectedPeriodTo, required InsightAiInterpretation interpretation});
  Stream<AIInsight?> getLatestInsightsStream();
  Future<List<AIInsight>> getInsightsHistory();
  Future<void> savePatternData(List<BodyPattern> patterns);
  Future<List<BodyPattern>> getLatestPatterns();
  Stream<List<BodyPattern>> getPatternDataStream();
  Future<void> saveHealthAlert(HealthAlert alert);
  Future<void> markAlertsAsRead(List<String> alertIds);
  Stream<List<HealthAlert>> getHealthAlertsStream({int limit = 20});
  Future<void> saveActiveExperiment(GutExperiment experiment);
  Future<GutExperiment?> getActiveExperiment();
  Stream<GutExperiment?> getActiveExperimentStream();
  Future<void> updateExperimentCheckIn(String experimentId, String dateKey, bool adhered, bool hadSymptoms);
  Future<void> completeExperiment(String experimentId, String outcomeSummary);
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
      if (doc == null || (insight.uid != null && insight.uid != _uid)) return null;
      final collection = doc.collection('insights');
      final requestedId = insight.firestoreId?.trim();
      final docRef = requestedId != null && requestedId.isNotEmpty ? collection.doc(requestedId) : collection.doc();
      final data = {...insight.toMap(), 'firestoreId': docRef.id, 'updatedAt': useServerTimestamp ? FieldValue.serverTimestamp() : Timestamp.fromDate(insight.updatedAt)};
      if (insight.origin == AIInsight.originRuleBased) {
        final batch = _db.batch()
          ..set(docRef, data)
          ..set(doc.collection('pattern_data').doc('latest'), {
            'patterns': insight.detectedPatterns.map((pattern) => pattern.toMap()).toList(),
            'periodTo': data['period'] is Map ? (data['period'] as Map)['to'] : null,
            'updatedAt': data['updatedAt'],
          });
        await batch.commit();
      } else {
        await docRef.set(data);
      }
      return docRef.id;
    } catch (e) {
      AppLogger.firestore('Error saving insights', error: e);
      return null;
    }
  }

  @override
  Future<bool> saveAiInterpretation({required String uid, required String insightId, required DateTime expectedPeriodTo, required InsightAiInterpretation interpretation}) async {
    final userDoc = _userDoc;
    if (userDoc == null || _uid != uid || insightId != 'rule_based_latest') return false;

    final insightDoc = userDoc.collection('insights').doc(insightId);
    try {
      return await _db.runTransaction<bool>((transaction) async {
        final snapshot = await transaction.get(insightDoc);
        if (!snapshot.exists) return false;

        final data = snapshot.data();
        if (data == null || data['origin'] != AIInsight.originRuleBased) return false;
        final rawPeriod = data['period'];
        final savedPeriodTo = rawPeriod is Map<String, dynamic> ? DateTimeUtils.tryParse(rawPeriod['to']) : null;
        if (savedPeriodTo == null || !savedPeriodTo.isAtSameMomentAs(expectedPeriodTo)) return false;

        // Merge only the optional AI prose: the deterministic snapshot and its
        // updatedAt ordering remain untouched.
        transaction.set(insightDoc, {'aiInterpretation': interpretation.toMap()}, SetOptions(merge: true));
        return true;
      });
    } catch (e) {
      AppLogger.firestore('Error saving AI Insight interpretation', error: e);
      return false;
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
      rethrow;
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
      await doc.collection('health_alerts').add(alert.toMap());
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

  @override
  Future<void> saveActiveExperiment(GutExperiment experiment) async {
    try {
      final doc = _userDoc;
      if (doc == null) return;
      await doc.collection('experiments').doc(experiment.id).set({...experiment.toMap(), 'updatedAt': FieldValue.serverTimestamp()});
      // Also update latest pointer
      await doc.collection('experiments').doc('active_latest').set({'experimentId': experiment.id, ...experiment.toMap(), 'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      AppLogger.firestore('Error saving active experiment', error: e);
    }
  }

  @override
  Future<GutExperiment?> getActiveExperiment() async {
    try {
      final doc = _userDoc;
      if (doc == null) return null;
      final snapshot = await doc.collection('experiments').doc('active_latest').get();
      if (!snapshot.exists) return null;
      final data = snapshot.data();
      if (data == null) return null;
      return GutExperiment.fromMap(data);
    } catch (e) {
      AppLogger.firestore('Error getting active experiment', error: e);
      return null;
    }
  }

  @override
  Stream<GutExperiment?> getActiveExperimentStream() {
    final doc = _userDoc;
    if (doc == null) return Stream.value(null);
    return doc
        .collection('experiments')
        .doc('active_latest')
        .snapshots()
        .handleError((e) {
          if (e.toString().contains('permission-denied')) {
            AppLogger.firestore('Experiment stream closed (permission-denied)');
          } else {
            throw e;
          }
        })
        .map((doc) {
          if (!doc.exists) return null;
          final data = doc.data();
          if (data == null) return null;
          return GutExperiment.fromMap(data);
        });
  }

  @override
  Future<void> updateExperimentCheckIn(String experimentId, String dateKey, bool adhered, bool hadSymptoms) async {
    try {
      final doc = _userDoc;
      if (doc == null) return;
      final checkInMap = {'date': dateKey, 'adhered': adhered, 'hadSymptoms': hadSymptoms};
      await doc.collection('experiments').doc(experimentId).set({'checkIns.$dateKey': checkInMap, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      await doc.collection('experiments').doc('active_latest').set({'checkIns.$dateKey': checkInMap, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    } catch (e) {
      AppLogger.firestore('Error updating experiment check-in', error: e);
    }
  }

  @override
  Future<void> completeExperiment(String experimentId, String outcomeSummary) async {
    try {
      final doc = _userDoc;
      if (doc == null) return;
      final updates = {'status': 'completed', 'completedOutcome': outcomeSummary, 'updatedAt': FieldValue.serverTimestamp()};
      await doc.collection('experiments').doc(experimentId).update(updates);
      await doc.collection('experiments').doc('active_latest').update(updates);
    } catch (e) {
      AppLogger.firestore('Error completing experiment', error: e);
    }
  }
}
