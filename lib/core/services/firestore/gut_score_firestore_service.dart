import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gutgood/core/models/insights/gut_score_record.dart';
import 'package:gutgood/core/utils/logger_service.dart';

abstract class GutScoreFirestoreService {
  Future<void> saveGutScore(GutScoreRecord record);
  Future<GutScoreRecord?> getLatestGutScore();
  Stream<GutScoreRecord?> watchLatestGutScore();
  Future<List<GutScoreRecord>> getWeeklyScores({int limit = 12});
}

class GutScoreFirestoreServiceImpl implements GutScoreFirestoreService {
  GutScoreFirestoreServiceImpl({
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
  Future<void> saveGutScore(GutScoreRecord record) async {
    try {
      final userDoc = _userDoc;
      if (userDoc == null) return;

      final docId = record.id.isNotEmpty ? record.id : 'score_${record.createdAt.millisecondsSinceEpoch}';
      final scoreRef = userDoc.collection('gut_scores').doc(docId);

      await scoreRef.set(record.toMap(), SetOptions(merge: true));

      // Mirror aggregate gutScore onto user_profiles/{uid} document
      await userDoc.set({
        'gutScore': record.gutScore,
        'lastScoreUpdate': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      AppLogger.firestore('Saved gut score ${record.gutScore} to gut_scores/$docId');
    } catch (e) {
      AppLogger.firestore('Error saving gut score record', error: e);
    }
  }

  @override
  Future<GutScoreRecord?> getLatestGutScore() async {
    try {
      final userDoc = _userDoc;
      if (userDoc == null) return null;

      final snap = await userDoc
          .collection('gut_scores')
          .orderBy('createdAt', descending: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      return GutScoreRecord.fromMap(doc.data(), docId: doc.id);
    } catch (e) {
      AppLogger.firestore('Error getting latest gut score', error: e);
      return null;
    }
  }

  @override
  Stream<GutScoreRecord?> watchLatestGutScore() {
    final userDoc = _userDoc;
    if (userDoc == null) return Stream.value(null);

    return userDoc
        .collection('gut_scores')
        .orderBy('createdAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      final doc = snap.docs.first;
      return GutScoreRecord.fromMap(doc.data(), docId: doc.id);
    });
  }

  @override
  Future<List<GutScoreRecord>> getWeeklyScores({int limit = 12}) async {
    try {
      final userDoc = _userDoc;
      if (userDoc == null) return [];

      final snap = await userDoc
          .collection('gut_scores')
          .where('type', isEqualTo: 'weekly')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();

      return snap.docs
          .map((doc) => GutScoreRecord.fromMap(doc.data(), docId: doc.id))
          .toList();
    } catch (e) {
      AppLogger.firestore('Error getting weekly scores', error: e);
      return [];
    }
  }
}
