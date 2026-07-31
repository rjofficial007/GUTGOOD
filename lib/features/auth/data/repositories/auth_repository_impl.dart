import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gutgood/core/constants/api_constants.dart';
import 'package:gutgood/core/models/user_profile.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/firestore_service.dart';
import 'package:gutgood/core/services/purchase_service.dart';
import 'package:gutgood/core/services/storage_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/features/auth/data/models/auth_user_model.dart';
import 'package:gutgood/features/auth/domain/entities/auth_user.dart';
import 'package:gutgood/features/auth/domain/repositories/auth_repository.dart';
import 'package:gutgood/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class AuthRepositoryImpl implements AuthRepository {
  final firebase.FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final FirestoreService _firestoreService;
  final PurchaseService _purchaseService;
  final StorageService _storageService;
  final SharedPreferences _prefs;
  final AppStateService _appStateService;
  final FirebaseFunctions _firebaseFunctions;

  Future<void>? _googleSignInInitFuture;
  final _isMergingController = StreamController<bool>.broadcast();

  AuthRepositoryImpl({
    required firebase.FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
    required FirestoreService firestoreService,
    required PurchaseService purchaseService,
    required StorageService storageService,
    required SharedPreferences prefs,
    required AppStateService appStateService,
    required FirebaseFunctions firebaseFunctions,
  }) : _firebaseAuth = firebaseAuth,
       _googleSignIn = googleSignIn,
       _firestoreService = firestoreService,
       _purchaseService = purchaseService,
       _storageService = storageService,
       _prefs = prefs,
       _appStateService = appStateService,
       _firebaseFunctions = firebaseFunctions;

  Future<void> _ensureGoogleSignInInitialized() {
    return _googleSignInInitFuture ??= _googleSignIn.initialize(serverClientId: ApiConstants.googleServerClientId, clientId: Platform.isIOS ? DefaultFirebaseOptions.ios.iosClientId : null);
  }

  @override
  Stream<AuthUser?> get authStateChanges => _firebaseAuth.authStateChanges().map((user) => user != null ? AuthUserModel.fromFirebase(user) : null);

  @override
  Stream<bool> get isMerging => _isMergingController.stream;

  @override
  AuthUser? get currentUser => _firebaseAuth.currentUser != null ? AuthUserModel.fromFirebase(_firebaseAuth.currentUser!) : null;

  void _guardAgainstSilentAccountSwitch(String attemptedProvider) {
    final current = _firebaseAuth.currentUser;
    if (current != null && !current.isAnonymous) {
      Log.w('AuthRepo: Blocked $attemptedProvider switch attempt for ${current.uid}.');
      throw AuthAlreadySignedInException(currentUid: current.uid, currentEmail: current.email, attemptedProvider: attemptedProvider);
    }
  }

  @override
  Future<AuthUser?> signInAnonymously() async {
    final existing = _firebaseAuth.currentUser;

    if (existing != null && !existing.isAnonymous) {
      return AuthUserModel.fromFirebase(existing);
    }

    if (existing != null && existing.isAnonymous) {
      return AuthUserModel.fromFirebase(existing);
    }

    try {
      Log.i('AuthRepo: Signing in anonymously...');
      final userCredential = await _firebaseAuth.signInAnonymously();
      final user = userCredential.user;
      if (user == null) return null;

      final profile = UserProfile(
        uid: user.uid,
        displayName: 'Guest',
        email: 'No email synced',
        isAnonymous: true,
        authProvider: 'anonymous',
        onboarded: false,
        updatedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );
      await _firestoreService.updateUserProfile(profile);

      // 🟢 Fix: Explicitly set onboarded to false in SharedPreferences for new Guest.
      // This prevents the app from incorrectly jumping to Chat if a previous session left a stale flag.
      await _prefs.setBool('onboarded', false);

      _appStateService.notifyProfileUpdated();
      return AuthUserModel.fromFirebase(_firebaseAuth.currentUser!);
    } catch (e) {
      Log.e('AuthRepo: Anonymous sign-in failed', error: e);
      rethrow;
    }
  }

  @override
  Future<AuthUser?> signInWithGoogle() async {
    _guardAgainstSilentAccountSwitch('google.com');
    try {
      await _ensureGoogleSignInInitialized();
      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = firebase.GoogleAuthProvider.credential(idToken: googleAuth.idToken);

      final user = await _linkOrMerge(credential);
      if (user == null) return null;

      await _finalizeAuth(user, displayName: googleUser.displayName, email: googleUser.email, photoUrl: googleUser.photoUrl);
      return AuthUserModel.fromFirebase(_firebaseAuth.currentUser!);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    } catch (e) {
      Log.e('AuthRepo: Google Sign-In failed', error: e);
      rethrow;
    }
  }

  @override
  Future<AuthUser?> signInWithApple() async {
    _guardAgainstSilentAccountSwitch('apple.com');
    try {
      if (!await SignInWithApple.isAvailable()) {
        throw firebase.FirebaseAuthException(code: 'operation-not-allowed', message: 'Apple Sign In not available.');
      }

      final (appleCredential, credential) = await _requestAppleCredential();

      final user = await _linkOrMerge(
        credential,
        refreshCredential: () async {
          final (_, freshCredential) = await _requestAppleCredential();
          return freshCredential;
        },
      );
      if (user == null) return null;

      final appleName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
      await _finalizeAuth(user, displayName: appleName.isNotEmpty ? appleName : null, email: appleCredential.email, photoUrl: user.photoURL);
      return AuthUserModel.fromFirebase(_firebaseAuth.currentUser!);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return null;
      rethrow;
    } catch (e) {
      Log.e('AuthRepo: Apple Sign In failed', error: e);
      rethrow;
    }
  }

  Future<(AuthorizationCredentialAppleID, firebase.AuthCredential)> _requestAppleCredential() async {
    final rawNonce = _generateNonce();
    final hashedNonce = _sha256ofString(rawNonce);

    final appleCredential = await SignInWithApple.getAppleIDCredential(scopes: const [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName], nonce: hashedNonce);

    final firebaseCredential = firebase.AppleAuthProvider.credentialWithIDToken(
      appleCredential.identityToken!,
      rawNonce,
      firebase.AppleFullPersonName(givenName: appleCredential.givenName, familyName: appleCredential.familyName),
    );

    return (appleCredential, firebaseCredential);
  }

  @override
  Future<AuthUser?> signInWithEmailAndPassword(String email, String password) async {
    _guardAgainstSilentAccountSwitch('password');
    try {
      final credential = firebase.EmailAuthProvider.credential(email: email, password: password);
      final user = await _linkOrMerge(credential);
      if (user == null) return null;
      await _finalizeAuth(user, email: email);
      return AuthUserModel.fromFirebase(_firebaseAuth.currentUser!);
    } catch (e) {
      Log.e('AuthRepo: Email sign-in failed', error: e);
      rethrow;
    }
  }

  @override
  Future<AuthUser?> signUpWithEmailAndPassword(String email, String password) async {
    final current = _firebaseAuth.currentUser;

    if (current != null && current.isAnonymous) {
      try {
        final credential = firebase.EmailAuthProvider.credential(email: email, password: password);
        final user = await _linkOrMerge(credential);
        if (user == null) return null;
        await _finalizeAuth(user, email: email);
        return AuthUserModel.fromFirebase(_firebaseAuth.currentUser!);
      } catch (e) {
        Log.e('AuthRepo: Email upgrade failed', error: e);
        rethrow;
      }
    }

    _guardAgainstSilentAccountSwitch('password (sign up)');
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
      if (userCredential.user == null) return null;
      await _finalizeAuth(userCredential.user!, email: email);
      return AuthUserModel.fromFirebase(_firebaseAuth.currentUser!);
    } catch (e) {
      Log.e('AuthRepo: Email sign-up failed', error: e);
      rethrow;
    }
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> sendSignInLinkToEmail(String email) async {
    final actionCodeSettings = firebase.ActionCodeSettings(
      url: ApiConstants.magicLinkUrl,
      handleCodeInApp: true,
      androidPackageName: 'com.gutgood.app',
      androidInstallApp: true,
      androidMinimumVersion: '1',
      iOSBundleId: 'com.gutgood.app',
    );
    await _firebaseAuth.sendSignInLinkToEmail(email: email, actionCodeSettings: actionCodeSettings);
  }

  @override
  Future<AuthUser?> signInWithEmailLink(String email, String emailLink) async {
    _guardAgainstSilentAccountSwitch('emailLink');
    final credential = firebase.EmailAuthProvider.credentialWithLink(email: email, emailLink: emailLink);
    final user = await _linkOrMerge(credential);
    if (user == null) return null;
    await _finalizeAuth(user, email: email);
    return AuthUserModel.fromFirebase(_firebaseAuth.currentUser!);
  }

  @override
  Future<AuthUser?> linkWithGoogle() async {
    _requireActiveSession('linkWithGoogle');
    await _ensureGoogleSignInInitialized();
    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;
    final credential = firebase.GoogleAuthProvider.credential(idToken: googleAuth.idToken);
    final user = await _linkOrMerge(credential);
    if (user == null) return null;
    await _finalizeAuth(user, displayName: googleUser.displayName, email: googleUser.email, photoUrl: googleUser.photoUrl);
    return AuthUserModel.fromFirebase(_firebaseAuth.currentUser!);
  }

  @override
  Future<AuthUser?> linkWithApple() async {
    _requireActiveSession('linkWithApple');
    if (!await SignInWithApple.isAvailable()) {
      throw firebase.FirebaseAuthException(code: 'operation-not-allowed', message: 'Apple Sign In not available.');
    }

    final (appleCredential, credential) = await _requestAppleCredential();
    final user = await _linkOrMerge(
      credential,
      refreshCredential: () async {
        final (_, freshCredential) = await _requestAppleCredential();
        return freshCredential;
      },
    );
    if (user == null) return null;

    final appleName = '${appleCredential.givenName ?? ''} ${appleCredential.familyName ?? ''}'.trim();
    await _finalizeAuth(user, displayName: appleName.isNotEmpty ? appleName : null, email: appleCredential.email, photoUrl: user.photoURL);
    return AuthUserModel.fromFirebase(_firebaseAuth.currentUser!);
  }

  void _requireActiveSession(String action) {
    if (_firebaseAuth.currentUser == null) {
      throw StateError('AuthRepo: $action requires an active session.');
    }
  }

  Future<firebase.User?> _linkOrMerge(firebase.AuthCredential credential, {Future<firebase.AuthCredential> Function()? refreshCredential}) async {
    final anonymousUser = _firebaseAuth.currentUser;
    final bool isAnonymousActive = anonymousUser != null && anonymousUser.isAnonymous;
    final String? anonymousUid = isAnonymousActive ? anonymousUser.uid : null;

    if (!isAnonymousActive) {
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      return userCredential.user;
    }

    try {
      final userCredential = await anonymousUser.linkWithCredential(credential);
      return userCredential.user;
    } on firebase.FirebaseAuthException catch (e) {
      if (e.code == 'provider-already-linked') {
        return _firebaseAuth.currentUser;
      }

      if (e.code == 'credential-already-in-use' || e.code == 'email-already-in-use') {
        _isMergingController.add(true);
        try {
          firebase.AuthCredential finalCredential = credential;
          if (credential.providerId == 'apple.com' && refreshCredential != null) {
            finalCredential = await refreshCredential();
          }

          // 🟢 Fix: Persist the conflict data BEFORE switching the session.
          // This allows recovery if the app is killed before the merge is confirmed.
          if (anonymousUid != null) {
            await _prefs.setString('pending_merge_anon_uid', anonymousUid);
            await _prefs.setString('pending_merge_provider', credential.providerId);
          }

          final permanentCredential = await _firebaseAuth.signInWithCredential(finalCredential);
          final permanentUser = permanentCredential.user!;

          if (anonymousUid != null && anonymousUid != permanentUser.uid) {
            throw AuthMergeConflictException(anonymousUid: anonymousUid, permanentUid: permanentUser.uid, email: permanentUser.email ?? 'Unknown', attemptedProvider: credential.providerId);
          }
          return permanentUser;
        } finally {
          _isMergingController.add(false);
        }
      }
      rethrow;
    }
  }

  @override
  Future<void> confirmMerge(String anonymousUid, String permanentUid) async {
    _isMergingController.add(true);
    _appStateService.setMigrating(true);
    try {
      // 🟢 Fix: Reset session before migration to ensure clean state
      _appStateService.resetSession();

      // 🟢 Fix: Move the merge server-side to bypass Security Rules and ensure idempotency.
      final result = await _firebaseFunctions.httpsCallable('mergeAnonymousAccount').call({'anonymousUid': anonymousUid});

      final bool alreadyMerged = result.data['alreadyMerged'] ?? false;
      Log.i('AuthRepo: Cloud merge call successful. alreadyMerged: $alreadyMerged');

      // Local migration is now handled by Firestore's native merge and Cloud Functions.
      // Firestore's offline persistence will automatically reconcile the local cache.

      final user = _firebaseAuth.currentUser;
      if (user != null) {
        await _finalizeAuth(user);
      }

      // 🟢 Fix: Explicitly ensure 'onboarded' status is true after successful merge
      await _prefs.setBool('onboarded', true);

      // Cleanup persistence
      await _prefs.remove('pending_merge_anon_uid');
      await _prefs.remove('pending_merge_provider');
    } catch (e) {
      Log.e('AuthRepo: confirmMerge failed', error: e);
      rethrow;
    } finally {
      _appStateService.setMigrating(false);
      _isMergingController.add(false);
    }
  }

  Future<void> _finalizeAuth(firebase.User user, {String? displayName, String? email, String? photoUrl}) async {
    final existingProfile = await _firestoreService.getUserMetadata();

    String? bestName = (displayName != null && displayName.isNotEmpty) ? displayName : null;
    bestName ??= (user.displayName != null && user.displayName!.isNotEmpty) ? user.displayName : null;
    bestName ??= (existingProfile?.displayName != null && existingProfile!.displayName!.isNotEmpty) ? existingProfile.displayName : null;

    String? bestEmail = (email != null && email.isNotEmpty) ? email : null;
    bestEmail ??= (user.email != null && user.email!.isNotEmpty) ? user.email : null;
    bestEmail ??= (existingProfile?.email != null && existingProfile!.email!.isNotEmpty) ? existingProfile.email : null;

    String? bestPhoto = (photoUrl != null && photoUrl.isNotEmpty) ? photoUrl : null;
    bestPhoto ??= (user.photoURL != null && user.photoURL!.isNotEmpty) ? user.photoURL : null;
    bestPhoto ??= (existingProfile?.photoUrl != null && existingProfile!.photoUrl!.isNotEmpty) ? existingProfile.photoUrl : null;

    bool needsReload = false;
    if (bestName != null && bestName != user.displayName) {
      await user.updateDisplayName(bestName);
      needsReload = true;
    }
    if (bestPhoto != null && bestPhoto != user.photoURL) {
      await user.updatePhotoURL(bestPhoto);
      needsReload = true;
    }
    if (needsReload) await user.reload();

    String? provider = user.providerData.isNotEmpty ? user.providerData.first.providerId : null;
    if (provider == null && !user.isAnonymous) {
      if (user.email != null) provider = 'password';
    }

    final profile = (existingProfile ?? UserProfile(uid: user.uid, updatedAt: DateTime.now(), createdAt: DateTime.now())).copyWith(
      displayName: bestName,
      email: bestEmail,
      photoUrl: bestPhoto,
      isAnonymous: false,
      authProvider: provider,
      updatedAt: DateTime.now(),
    );

    await _firestoreService.updateUserProfile(profile);

    // Persist onboarding status locally for fast-track checking on restart
    if (profile.onboarded) {
      await _prefs.setBool('onboarded', true);
    }

    await _purchaseService.login(user.uid);

    _appStateService.notifyProfileUpdated();
  }

  @override
  Future<void> abandonMerge() async {
    Log.i('AuthRepo: Abandoning merge. Clearing pending state.');
    await _prefs.remove('pending_merge_anon_uid');
    await _prefs.remove('pending_merge_provider');
    _appStateService.setPendingMergeConflict(null);
  }

  @override
  Future<void> signOut() async {
    _appStateService.setLoggingOut(true);
    try {
      await _firebaseAuth.signOut();
      await _googleSignIn.signOut();
      await _purchaseService.logout();
      await _clearUserSessionData();
      _appStateService.resetSession();
    } catch (e) {
      Log.w('AuthRepo: Sign out warning: $e');
    } finally {
      _appStateService.setLoggingOut(false);
    }
  }

  @override
  Future<void> deleteAccount() async {
    final user = _firebaseAuth.currentUser;
    if (user == null) return;
    final uid = user.uid;
    _appStateService.setLoggingOut(true);
    try {
      // 🟢 Fix: Delete auth user FIRST before destroying cloud data.
      // This ensures that if re-authentication is required, the user still has their data.
      await user.delete();

      await _firestoreService.deleteAllUserData(uid);
      await _storageService.deleteAllUserFiles(uid);
      await _purchaseService.logout();
      await _clearUserSessionData();
      _appStateService.resetSession();
    } finally {
      _appStateService.setLoggingOut(false);
    }
  }

  Future<void> _clearUserSessionData() async {
    // Only clear keys that are strictly user-session related or linked to a specific UID.
    // Preserve device-level settings like theme, onboarding status (for the device), and notification schedules.
    final keys = _prefs.getKeys();
    final toRemove = <String>[];

    for (final key in keys) {
      // Common session-related keys or keys that include the UID
      if (key.startsWith('last_firebase_sync_') || key == 'login_email' || key == 'is_premium' || key == 'onboarded') {
        toRemove.add(key);
      }
    }

    for (final key in toRemove) {
      await _prefs.remove(key);
    }

    Log.d('AuthRepo: User session data cleared. Preserving device preferences.');
  }

  @override
  Future<void> updateDisplayName(String name) async {
    final user = _firebaseAuth.currentUser;
    if (user != null) {
      await user.updateDisplayName(name);
      await user.reload();
    }
  }

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
