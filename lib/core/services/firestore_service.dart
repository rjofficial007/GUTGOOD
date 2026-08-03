import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gutgood/core/models/ai_insight.dart';
import 'package:gutgood/core/models/body_pattern.dart';
import 'package:gutgood/core/models/chat_message.dart';
import 'package:gutgood/core/models/daily_usage.dart';
import 'package:gutgood/core/models/meal_log.dart';
import 'package:gutgood/core/models/notification_preferences.dart';
import 'package:gutgood/core/models/scan_result.dart';
import 'package:gutgood/core/models/symptom_log.dart';
import 'package:gutgood/core/models/user_profile.dart';
import 'package:gutgood/core/services/storage_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';

abstract class FirestoreService {
  Future<void> saveUserProfile(UserProfile profile);
  Future<void> updateUserProfile(UserProfile profile);
  Future<void> saveNotificationPreferences(NotificationPreferences prefs);
  Future<String?> saveMessage(ChatMessage message);
  Stream<List<ChatMessage>> getMessagesStream({int limit = 20});
  Future<void> updateMessageFeedback(String messageId, String feedback);
  Future<void> saveToScanHistory(ScanResult scanData, {String? userImageUrl});
  Future<List<ScanResult>> getScanHistory({int limit = 50});
  Future<List<MealLog>> getRecentMealLogs({int limit = 30});
  Future<List<SymptomLog>> getRecentSymptomLogs({int limit = 30});
  Future<List<ScanResult>> getRecentScans({int limit = 20});
  Future<void> toggleSaveFood(ScanResult scanData);
  Future<bool> isFoodSaved(String? productName, {String? barcode});
  Future<List<ScanResult>> getSavedFoods();
  Future<List<SymptomLog>> getSymptomLogs();
  Future<String?> logSymptom(SymptomLog log);
  Future<String?> logMeal(MealLog log);
  Future<UserProfile?> getUserMetadata();
  Stream<UserProfile?> getUserMetadataStream();
  Future<void> updateOnboardingStatus(bool onboarded);
  Future<void> updatePremiumStatus(bool isPremium);
  Future<void> mergeData(String fromUid, String toUid);
  Future<void> deleteAllUserData(String uid);
  Future<String?> uploadProfilePicture(File imageFile);
  Future<void> deleteMessage(String messageId);
  Future<DailyUsage?> getUsageToday();
  Future<String?> saveInsights(AIInsight insight);
  Future<AIInsight?> getLatestInsights();
  Stream<AIInsight?> getLatestInsightsStream();
  Future<List<AIInsight>> getInsightsHistory();
  Future<void> savePatternData(List<BodyPattern> patterns);

  // Aggregation/Count methods
  Future<int> getScansCountSince(DateTime since);
  Future<int> getMealLogsCountSince(DateTime since);
  Future<int> getSymptomsCountSince(DateTime since);
}

class FirestoreServiceImpl implements FirestoreService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final StorageService _storageService;

  FirestoreServiceImpl({required FirebaseAuth auth, required FirebaseFirestore db, required StorageService storageService}) : _auth = auth, _db = db, _storageService = storageService;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference get _users => _db.collection('user_profiles');

  DocumentReference? get _userDoc {
    final uid = _uid;
    if (uid == null) return null;
    return _users.doc(uid);
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      final doc = _userDoc;
      if (doc == null) return;
      await doc.set(profile.toMap(), SetOptions(merge: true));
    } catch (e) {
      Log.e('FirestoreService: Error saving user profile', error: e);
    }
  }

  @override
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      final doc = _userDoc;
      if (doc == null) return;
      await doc.set(profile.toMap(), SetOptions(merge: true));
    } catch (e) {
      Log.e('FirestoreService: Error updating user profile', error: e);
    }
  }

  @override
  Future<void> saveNotificationPreferences(NotificationPreferences prefs) async {
    try {
      final doc = _userDoc;
      if (doc == null) return;
      await doc.set({'notificationPreferences': prefs.toMap(), 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      Log.i('FirestoreService: Notification preferences synced');
    } catch (e) {
      Log.e('FirestoreService: Error syncing notification preferences', error: e);
    }
  }

  @override
  Future<String?> saveMessage(ChatMessage message) async {
    try {
      final doc = _userDoc;
      if (doc == null) return null;
      final docRef = doc.collection('chat_history').doc();
      // 🟢 Fix: Remove the local SQLite 'id' before uploading to Firestore.
      final cloudSafeData = message.toMap()..remove('id');
      final data = {...cloudSafeData, 'firestoreId': docRef.id, 'source': message.source ?? 'chat', 'createdAt': FieldValue.serverTimestamp()};
      await docRef.set(data);
      return docRef.id;
    } catch (e) {
      Log.e('FirestoreService: Error saving message', error: e);
      return null;
    }
  }

  /// Emits messages newest-first (descending by time), matching the reversed
  /// chat list UI directly — no double-reversal confusion at call sites.
  @override
  Stream<List<ChatMessage>> getMessagesStream({int limit = 50}) {
    final doc = _userDoc;
    if (doc == null) return const Stream.empty();
    return doc.collection('chat_history').orderBy('time', descending: true).limit(limit).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => ChatMessage.fromMap({...doc.data(), 'firestoreId': doc.id})).toList();
    });
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    try {
      final doc = _userDoc;
      if (doc == null) return;
      await doc.collection('chat_history').doc(messageId).delete();
    } catch (e) {
      Log.e('FirestoreService: Error deleting message', error: e);
    }
  }

  @override
  Future<void> updateMessageFeedback(String messageId, String feedback) async {
    try {
      final doc = _userDoc;
      if (doc == null) return;
      await doc.collection('chat_history').doc(messageId).update({'feedback': feedback});
    } catch (e) {
      Log.e('FirestoreService: Error updating message feedback', error: e);
    }
  }

  @override
  Future<void> saveToScanHistory(ScanResult scanData, {String? userImageUrl}) async {
    try {
      final doc = _userDoc;
      if (doc == null) return;
      final barcode = scanData.barcode;

      // 🟢 Robust Image Selection: Prioritize parameter, then model, then existing DB record.
      // Treat empty strings as null to prevent broken images in UI.
      String? bestImageUrl = userImageUrl;
      if (bestImageUrl == null || bestImageUrl.isEmpty) {
        bestImageUrl = scanData.userImageUrl;
      }
      if (bestImageUrl != null && bestImageUrl.isEmpty) bestImageUrl = null;

      if (barcode != null && barcode.isNotEmpty) {
        final existing = await doc.collection('scan_history').where('barcode', isEqualTo: barcode).limit(1).get();
        if (existing.docs.isNotEmpty) {
          final existingData = existing.docs.first.data();
          final String? dbImageUrl = existingData['userImageUrl'];
          
          if (bestImageUrl == null || bestImageUrl.isEmpty) {
            bestImageUrl = dbImageUrl;
          }

          await existing.docs.first.reference.update({
            'timestamp': FieldValue.serverTimestamp(),
            'time': DateTime.now().toIso8601String(),
            'userImageUrl': bestImageUrl,
          });
          Log.i('FirestoreService: Updated existing scan history entry for $barcode. Image: ${bestImageUrl != null}');
          return;
        }
      }

      await doc.collection('scan_history').add({
        ...scanData.toMap(),
        'userImageUrl': bestImageUrl,
        'timestamp': FieldValue.serverTimestamp(),
        'time': DateTime.now().toIso8601String(),
      });
      Log.i('FirestoreService: Added new scan history entry. Image: ${bestImageUrl != null}');
    } catch (e) {
      Log.e('FirestoreService: Error saving to scan history', error: e);
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
      Log.e('FirestoreService: Error getting scan history', error: e);
      return [];
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
      Log.e('FirestoreService: Error getting recent meal logs', error: e);
      return [];
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
      Log.e('FirestoreService: Error getting recent symptom logs', error: e);
      return [];
    }
  }

  @override
  Future<List<ScanResult>> getRecentScans({int limit = 20}) async {
    try {
      final doc = _userDoc;
      if (doc == null) return [];
      final snapshot = await doc.collection('scan_history').orderBy('time', descending: true).limit(limit).get();
      return snapshot.docs.map((doc) => ScanResult.fromMap(doc.data())).toList();
    } catch (e) {
      Log.e('FirestoreService: Error getting recent scans', error: e);
      return [];
    }
  }

  @override
  Future<void> toggleSaveFood(ScanResult scanData) async {
    try {
      final doc = _userDoc;
      if (doc == null) return;
      final name = scanData.productName;
      final barcode = scanData.barcode;

      // 🟢 Fix: Deduplicate by barcode first, then by name.
      Query queryRef = doc.collection('saved_foods');
      if (barcode != null && barcode.isNotEmpty) {
        queryRef = queryRef.where('barcode', isEqualTo: barcode);
      } else {
        queryRef = queryRef.where('productName', isEqualTo: name);
      }

      final query = await queryRef.get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.delete();
      } else {
        await doc.collection('saved_foods').add({...scanData.toMap(), 'savedAt': FieldValue.serverTimestamp()});
      }
    } catch (e) {
      Log.e('FirestoreService: Error toggling saved food', error: e);
    }
  }

  @override
  Future<bool> isFoodSaved(String? productName, {String? barcode}) async {
    try {
      final doc = _userDoc;
      if (doc == null) return false;
      Query queryRef = doc.collection('saved_foods');
      if (barcode != null && barcode.isNotEmpty) {
        queryRef = queryRef.where('barcode', isEqualTo: barcode);
      } else if (productName != null) {
        queryRef = queryRef.where('productName', isEqualTo: productName);
      } else {
        return false;
      }

      final query = await queryRef.get();
      return query.docs.isNotEmpty;
    } catch (e) {
      Log.e('FirestoreService: Error checking if food saved', error: e);
      return false;
    }
  }

  @override
  Future<List<ScanResult>> getSavedFoods() async {
    try {
      final doc = _userDoc;
      if (doc == null) return [];
      final snapshot = await doc.collection('saved_foods').get();
      return snapshot.docs.map((doc) => ScanResult.fromMap(doc.data())).toList();
    } catch (e) {
      Log.e('FirestoreService: Error getting saved foods', error: e);
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
      Log.e('FirestoreService: Error getting symptom logs', error: e);
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
      Log.e('FirestoreService: Error logging symptom', error: e);
      return null;
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
      Log.e('FirestoreService: Error logging meal', error: e);
      return null;
    }
  }

  @override
  Future<UserProfile?> getUserMetadata() async {
    try {
      final doc = _userDoc;
      if (doc == null) return null;
      final snap = await doc.get();
      if (!snap.exists) return null;
      return UserProfile.fromMap(snap.data() as Map<String, dynamic>, uid: _uid);
    } catch (e) {
      Log.e('FirestoreService: Error getting user metadata', error: e);
      return null;
    }
  }

  @override
  Stream<UserProfile?> getUserMetadataStream() {
    final doc = _userDoc;
    if (doc == null) return Stream.value(null);
    return doc.snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromMap(doc.data() as Map<String, dynamic>, uid: _uid);
    });
  }

  @override
  Future<void> updateOnboardingStatus(bool onboarded) async {
    try {
      final doc = _userDoc;
      if (doc == null) return;
      await doc.set({'onboarded': onboarded}, SetOptions(merge: true));
    } catch (e) {
      Log.e('FirestoreService: Error updating onboarding status', error: e);
    }
  }

  /// Mirrors the on-device RevenueCat entitlement into the profile document.
  ///
  /// Premium is managed CLIENT-SIDE (purchases_flutter SDK): the SDK checks the
  /// entitlement with RevenueCat's servers, and the app persists the result
  /// here so it is available cross-device and to the aiProxy quota check.
  /// There is intentionally no server-side RevenueCat integration.
  /// Security rules shape-validate these fields (bool + 'free'|'premium').
  @override
  Future<void> updatePremiumStatus(bool isPremium) async {
    try {
      final doc = _userDoc;
      if (doc == null) return;
      await doc.set({'isPremium': isPremium, 'subscriptionStatus': isPremium ? 'premium' : 'free', 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    } catch (e) {
      Log.e('FirestoreService: Error updating premium status', error: e);
    }
  }

  // NOTE: daily_usage counters are incremented only by the aiProxy Cloud
  // Function, transactionally. Clients may only read them (UX fast-path).

  @override
  Future<void> mergeData(String fromUid, String toUid) async {
    // Migration is now primarily handled by Cloud Functions for atomicity and security
    Log.i('FirestoreService: Data migration should be handled by Cloud Function');
  }

  @override
  Future<void> deleteAllUserData(String uid) async {
    // Cascade deletion is handled by Cloud Function onUserDeleted trigger
    Log.i('FirestoreService: User data deletion triggered by Auth onDelete');
  }

  @override
  Future<String?> uploadProfilePicture(File imageFile) async {
    try {
      if (_uid == null) return null;
      final bytes = await imageFile.readAsBytes();
      final downloadUrl = await _storageService.uploadProfilePicture(bytes);

      if (downloadUrl != null) {
        final profile = await getUserMetadata();
        if (profile != null) {
          await updateUserProfile(profile.copyWith(photoUrl: downloadUrl, updatedAt: DateTime.now()));
        }
      }
      return downloadUrl;
    } catch (e) {
      Log.e('FirestoreService: Error uploading profile picture', error: e);
      return null;
    }
  }

  @override
  Future<DailyUsage?> getUsageToday() async {
    // 🟡 Fix F5: Use UTC to match server-side usage key generation.
    final String today = DateTime.now().toUtc().toIso8601String().split('T')[0];
    try {
      final doc = _userDoc;
      if (doc == null) return null;
      final snap = await doc.collection('daily_usage').doc(today).get();
      if (!snap.exists) return null;
      return DailyUsage.fromMap({...snap.data() as Map<String, dynamic>, 'uid': _uid, 'date': today});
    } catch (e) {
      Log.e('FirestoreService: Error getting daily usage', error: e);
      return null;
    }
  }

  @override
  Future<String?> saveInsights(AIInsight insight) async {
    try {
      final doc = _userDoc;
      if (doc == null) return null;
      final docRef = doc.collection('insights').doc();
      final data = {...insight.toMap(), 'firestoreId': docRef.id, 'updatedAt': FieldValue.serverTimestamp()};
      await docRef.set(data);
      return docRef.id;
    } catch (e) {
      Log.e('FirestoreService: Error saving insights', error: e);
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
      Log.e('FirestoreService: Error getting latest insights', error: e);
      return null;
    }
  }

  @override
  Stream<AIInsight?> getLatestInsightsStream() {
    final doc = _userDoc;
    if (doc == null) return Stream.value(null);
    return doc.collection('insights').orderBy('updatedAt', descending: true).limit(1).snapshots().map((snapshot) {
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
      return snapshot.docs.map((doc) => AIInsight.fromMap({...doc.data(), 'id': doc.id})).toList();
    } catch (e) {
      Log.e('FirestoreService: Error getting insights history', error: e);
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
      Log.e('FirestoreService: Error saving pattern data', error: e);
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
