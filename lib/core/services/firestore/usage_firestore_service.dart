import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gutgood/core/models/daily_usage.dart';
import 'package:gutgood/core/utils/logger_service.dart';

abstract class UsageFirestoreService {
  Future<DailyUsage?> getUsageToday();
  Stream<DailyUsage?> getUsageTodayStream();
}

class UsageFirestoreServiceImpl implements UsageFirestoreService {
  UsageFirestoreServiceImpl({
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
  Future<DailyUsage?> getUsageToday() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    try {
      final doc = _userDoc;
      if (doc == null) return null;
      final snap = await doc.collection('daily_usage').doc(today).get();
      if (!snap.exists) return null;
      return DailyUsage.fromMap({
        ...snap.data() as Map<String, dynamic>,
        'uid': _uid,
        'date': today
      });
    } catch (e) {
      AppLogger.error('UsageFirestoreService: Error getting daily usage', error: e);
      return null;
    }
  }

  @override
  Stream<DailyUsage?> getUsageTodayStream() {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final doc = _userDoc;
    if (doc == null) return Stream.value(null);
    return doc
        .collection('daily_usage')
        .doc(today)
        .snapshots()
        .handleError((e) {
      if (e.toString().contains('permission-denied')) {
        AppLogger.debug('UsageFirestoreService: Usage stream closed (permission-denied)');
      } else {
        throw e;
      }
    }).map((doc) {
      if (!doc.exists) return null;
      return DailyUsage.fromMap({
        ...doc.data() as Map<String, dynamic>,
        'uid': _uid,
        'date': today
      });
    });
  }
}
