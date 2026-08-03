import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/features/auth/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

abstract class LinkService {
  Future<void> init();
  Future<void> checkOnResume();
  void dispose();
}

class LinkServiceImpl implements LinkService {
  final AuthRepository _authRepository;
  final SharedPreferences _prefs;
  final FirebaseAuth _firebaseAuth;
  final AppStateService _appStateService;

  LinkServiceImpl({required AuthRepository authRepository, required SharedPreferences prefs, required FirebaseAuth firebaseAuth, required AppStateService appStateService})
    : _authRepository = authRepository,
      _prefs = prefs,
      _firebaseAuth = firebaseAuth,
      _appStateService = appStateService;

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  Future<void> init() async {
    Log.i('LinkService: Initializing...');

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleLink(initialUri);
      }
    } catch (e) {
      Log.e('LinkService: Error getting initial link', error: e);
    }

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) => _handleLink(uri), onError: (err) => Log.e('LinkService: Stream error', error: err));

    await _checkAppleCredentialState();
    await _checkPendingMerge();
  }

  Future<void> _checkPendingMerge() async {
    final anonUid = _prefs.getString('pending_merge_anon_uid');
    final provider = _prefs.getString('pending_merge_provider');
    final currentUser = _firebaseAuth.currentUser;

    if (anonUid != null && currentUser != null && !currentUser.isAnonymous) {
      Log.i('LinkService: Found pending merge conflict for $anonUid. Re-surfacing prompt.');
      _appStateService.setPendingMergeConflict({'anonymousUid': anonUid, 'permanentUid': currentUser.uid, 'email': currentUser.email ?? 'Unknown', 'attemptedProvider': provider ?? 'Unknown'});
    }
  }

  void _handleLink(Uri uri) async {
    final String link = uri.toString();
    Log.i('LinkService: Handling link -> $link');

    String effectiveLink = link;

    // 🟢 Fix: Firebase Hosting/Dynamic Links often wrap the auth link in a 'link' parameter.
    // We must unwrap it to find the 'oobCode' required by FirebaseAuth.
    if (!_firebaseAuth.isSignInWithEmailLink(effectiveLink)) {
      final nestedLink = uri.queryParameters['link'];
      if (nestedLink != null && _firebaseAuth.isSignInWithEmailLink(nestedLink)) {
        Log.i('LinkService: Unwrapped nested auth link found.');
        effectiveLink = nestedLink;
      }
    }

    if (_firebaseAuth.isSignInWithEmailLink(effectiveLink)) {
      _appStateService.setVerifyingAuth(true);
      final String? email = _prefs.getString('login_email');

      if (email != null) {
        try {
          final user = await _authRepository.signInWithEmailLink(email, effectiveLink);
          if (user != null) {
            await _prefs.remove('login_email');
          } else {
            _appStateService.setEmailLinkError('Failed to complete sign-in. Link may be invalid.');
          }
        } catch (e) {
          Log.e('LinkService: Sign-in failed', error: e);
          _appStateService.setEmailLinkError('An error occurred. Please try again.');
        } finally {
          await Future.delayed(const Duration(milliseconds: 1500));
          _appStateService.setVerifyingAuth(false);
        }
      } else {
        await Future.delayed(const Duration(milliseconds: 1000));
        _appStateService.setVerifyingAuth(false);
        _appStateService.setPendingEmailLink(effectiveLink);
      }
    }
  }

  Future<void> _checkAppleCredentialState() async {
    if (kIsWeb || !Platform.isIOS) return;

    final user = _firebaseAuth.currentUser;
    if (user == null) return;
    final appleProviderData = user.providerData.where((p) => p.providerId == 'apple.com');
    if (appleProviderData.isEmpty) return;

    final appleUid = appleProviderData.first.uid;
    if (appleUid == null) return;

    try {
      final credentialState = await SignInWithApple.getCredentialState(appleUid);
      if (credentialState == CredentialState.revoked) {
        Log.w('LinkService: Apple credential revoked externally.');
        await _authRepository.signOut();
      }
    } catch (e) {
      Log.e('LinkService: Apple credential check failed (Expected in some dev environments)', error: e);
    }
  }

  @override
  Future<void> checkOnResume() async {
    await _checkAppleCredentialState();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
  }
}
