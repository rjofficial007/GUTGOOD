import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gutgood/core/models/daily_usage.dart';
import 'package:gutgood/core/utils/logger_service.dart';

abstract class UsageFirestoreService {
  Future<DailyUsage?> getUsageToday();
  Future<DailyUsage> getLifetimeUsage();
  Stream<DailyUsage?> getUsageTodayStream();
  Stream<DailyUsage> getLifetimeUsageStream();
}

class UsageFirestoreServiceImpl implements UsageFirestoreService {
  UsageFirestoreServiceImpl({required FirebaseAuth auth, required FirebaseFirestore db}) : _auth = auth, _db = db;

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
      return DailyUsage.fromMap({...snap.data() as Map<String, dynamic>, 'uid': _uid, 'date': today});
    } catch (e) {
      AppLogger.error('UsageFirestoreService: Error getting daily usage', error: e);
      return null;
    }
  }

  @override
  Future<DailyUsage> getLifetimeUsage() async {
    final uid = _uid;
    if (uid == null) return DailyUsage(uid: '', date: 'lifetime');
    try {
      final doc = _userDoc;
      if (doc == null) return DailyUsage(uid: uid, date: 'lifetime');

      final snap = await doc.get();
      if (!snap.exists) return DailyUsage(uid: uid, date: 'lifetime');

      final data = snap.data() as Map<String, dynamic>;
      final chats = (data['chat_count_lifetime'] as num?)?.toInt() ?? 0;
      final scans = (data['scan_count_lifetime'] as num?)?.toInt() ?? 0;

      return DailyUsage(uid: uid, date: 'lifetime', chatCount: chats, scanCount: scans);
    } catch (e) {
      AppLogger.error('UsageFirestoreService: Error getting lifetime usage from profile', error: e);
      return DailyUsage(uid: uid, date: 'lifetime');
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
        })
        .map((doc) {
          if (!doc.exists) return null;
          return DailyUsage.fromMap({...doc.data() as Map<String, dynamic>, 'uid': _uid, 'date': today});
        });
  }

  @override
  Stream<DailyUsage> getLifetimeUsageStream() {
    final doc = _userDoc;
    if (doc == null) return Stream.value(DailyUsage(uid: '', date: 'lifetime'));
    return doc.snapshots().map((snap) {
      if (!snap.exists) return DailyUsage(uid: _uid ?? '', date: 'lifetime');
      final data = snap.data() as Map<String, dynamic>;
      final chats = (data['chat_count_lifetime'] as num?)?.toInt() ?? 0;
      final scans = (data['scan_count_lifetime'] as num?)?.toInt() ?? 0;
      return DailyUsage(uid: _uid ?? '', date: 'lifetime', chatCount: chats, scanCount: scans);
    });
  }
}
