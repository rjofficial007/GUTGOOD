import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:gutgood/core/models/user/notification_preferences.dart';
import 'package:gutgood/core/models/user/user_profile.dart';
import 'package:gutgood/core/services/storage_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';

abstract class AuthFirestoreService {
  Future<void> saveUserProfile(UserProfile profile);
  Future<void> updateUserProfile(UserProfile profile);
  Future<UserProfile?> getUserMetadata();
  Stream<UserProfile?> getUserMetadataStream();
  Future<void> updatePremiumStatus(bool isPremium);
  Future<void> saveNotificationPreferences(NotificationPreferences prefs);
  Future<void> saveFcmToken(String token);
  Future<void> clearFcmToken();
  Future<String?> uploadProfilePicture(File imageFile);
  Future<void> deleteUserData();
}

class AuthFirestoreServiceImpl implements AuthFirestoreService {
  AuthFirestoreServiceImpl({required FirebaseAuth auth, required FirebaseFirestore db, required StorageService storageService}) : _auth = auth, _db = db, _storageService = storageService;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final StorageService _storageService;

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
      AppLogger.error('AuthFirestoreService: Error saving user profile', error: e);
    }
  }

  @override
  Future<void> updateUserProfile(UserProfile profile) async {
    try {
      final doc = _userDoc;
      if (doc == null) return;
      // 🟢 Fix: Use set with merge: true instead of update() to ensure the
      // operation succeeds even if the document hasn't been fully initialized
      // in Firestore yet (common during fast onboarding flows).
      await doc.set(profile.toUpdateMap(), SetOptions(merge: true));
    } catch (e) {
      AppLogger.error('AuthFirestoreService: Error updating user profile', error: e);
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
      AppLogger.error('AuthFirestoreService: Error getting user metadata', error: e);
      return null;
    }
  }

  @override
  Stream<UserProfile?> getUserMetadataStream() {
    final doc = _userDoc;
    if (doc == null) return Stream.value(null);
    return doc
        .snapshots()
        .handleError((e) {
          if (e.toString().contains('permission-denied')) {
            AppLogger.firestore('Metadata stream closed (permission-denied)');
          } else {
            throw e;
          }
        })
        .map((doc) {
          if (!doc.exists) return null;
          return UserProfile.fromMap(doc.data() as Map<String, dynamic>, uid: _uid);
        });
  }

  @override
  Future<void> updatePremiumStatus(bool isPremium) async {
    try {
      final doc = _userDoc;
      if (doc == null) return;
      // Client-side premium model (intentional): these fields are
      // client-writable per firestore.rules and are the value the backend quota
      // check trusts. This is a soft paywall, NOT a security boundary — any
      // client can self-grant premium; see docs/ACCEPTED_RISKS.md R1.
      await doc.set({'isPremium': isPremium, 'subscriptionStatus': isPremium ? 'premium' : 'free', 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    } catch (e) {
      AppLogger.error('AuthFirestoreService: Error updating premium status', error: e);
    }
  }

  @override
  Future<void> saveNotificationPreferences(NotificationPreferences prefs) async {
    try {
      final doc = _userDoc;
      if (doc == null) return;
      await doc.set({'notificationPreferences': prefs.toMap(), 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    } catch (e) {
      AppLogger.error('AuthFirestoreService: Error syncing notification preferences', error: e);
    }
  }

  @override
  Future<void> saveFcmToken(String token) async {
    try {
      final doc = _userDoc;
      if (doc == null) return;
      await doc.set({'fcmToken': token, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    } catch (e) {
      AppLogger.error('AuthFirestoreService: Error syncing FCM token', error: e);
    }
  }

  @override
  Future<void> clearFcmToken() async {
    try {
      final doc = _userDoc;
      if (doc == null) return;
      final snap = await doc.get();
      if (!snap.exists) return;
      await doc.set({'fcmToken': FieldValue.delete(), 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    } catch (e) {
      AppLogger.error('AuthFirestoreService: Error clearing FCM token', error: e);
    }
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
      AppLogger.error('AuthFirestoreService: Error uploading profile picture', error: e);
      return null;
    }
  }

  @override
  Future<void> deleteUserData() async {
    try {
      final doc = _userDoc;
      if (doc != null) {
        final snap = await doc.get();
        if (snap.exists) {
          // 1. Delete the root profile document.
          // Sub-collections like scan_history are handled by the Cloud Function backstop
          // or recursive delete if we had it, but here we just hit the root for immediate UI effect.
          await doc.delete();
        }
      }

      // 2. Clear Firestore persistence to ensure a fresh start on this device.
      // FirebaseFirestore requires terminate() before clearPersistence().
      try {
        await _db.terminate();
        await _db.clearPersistence();
      } catch (e) {
        AppLogger.error('AuthFirestoreService: Could not clear persistence', error: e);
      }

      AppLogger.firestore('AuthFirestoreService: User data purged client-side');
    } catch (e) {
      AppLogger.error('AuthFirestoreService: Error purging user data', error: e);
    }
  }
}
