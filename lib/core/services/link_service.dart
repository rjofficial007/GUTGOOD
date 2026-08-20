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
  LinkServiceImpl({
    required AuthRepository authRepository,
    required SharedPreferences prefs,
    required FirebaseAuth firebaseAuth,
    required AppStateService appStateService,
  }) : _authRepository = authRepository,
       _prefs = prefs,
       _firebaseAuth = firebaseAuth,
       _appStateService = appStateService;
  final AuthRepository _authRepository;
  final SharedPreferences _prefs;
  final FirebaseAuth _firebaseAuth;
  final AppStateService _appStateService;

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;

  @override
  Future<void> init() async {
    AppLogger.deepLink('Initializing...');

    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        AppLogger.info(
          'LinkService: Found initial link on launch: $initialUri',
        );
        await _handleLink(initialUri);
      }
    } catch (e) {
      AppLogger.error('LinkService: Error getting initial link', error: e);
    }

    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleLink,
      onError: (err) =>
          AppLogger.error('LinkService: Stream error', error: err),
    );

    await _checkAppleCredentialState();
    await _checkPendingMerge();
  }

  Future<void> _checkPendingMerge() async {
    final anonUid = _prefs.getString('pending_merge_anon_uid');
    final provider = _prefs.getString('pending_merge_provider');
    final currentUser = _firebaseAuth.currentUser;

    if (anonUid != null && currentUser != null && !currentUser.isAnonymous) {
      AppLogger.info(
        'LinkService: Found pending merge conflict for $anonUid. Re-surfacing prompt.',
      );
      _appStateService.setPendingMergeConflict({
        'anonymousUid': anonUid,
        'permanentUid': currentUser.uid,
        'email': currentUser.email ?? 'Unknown',
        'attemptedProvider': provider ?? 'Unknown',
      });
    }
  }

  Future<void> _handleLink(Uri uri) async {
    final link = uri.toString();
    AppLogger.deepLink('Incoming link received: $link');
    AppLogger.debug(
      'LinkService: URI Details - Host: ${uri.host}, Path: ${uri.path}, Query: ${uri.queryParameters}',
    );

    var effectiveLink = link;
    var effectiveUri = uri;

    // 🟢 Fix: Firebase Hosting often wraps the actual auth link in a 'link' parameter.
    // We must unwrap it first to handle ANY action (signIn, verifyEmail, etc.)
    final nestedLink = uri.queryParameters['link'];
    if (nestedLink != null) {
      try {
        final nestedUri = Uri.parse(nestedLink);
        if (nestedUri.queryParameters.containsKey('oobCode')) {
          AppLogger.deepLink('Successfully unwrapped nested Firebase link.');
          effectiveLink = nestedLink;
          effectiveUri = nestedUri;
        }
      } catch (e) {
        AppLogger.debug('LinkService: Found "link" param but it is not a valid URI.');
      }
    }

    if (_firebaseAuth.isSignInWithEmailLink(effectiveLink)) {
      await _handleSignInLink(effectiveLink);
    } else if (effectiveUri.queryParameters.containsKey('oobCode')) {
      await _handleActionCodeLink(effectiveUri);
    } else {
      AppLogger.info(
        'LinkService: Link is not a recognized Firebase Auth link.',
      );
    }
  }

  Future<void> _handleSignInLink(String link) async {
    AppLogger.info(
      'LinkService: Valid Email Sign-in Link detected. Proceeding with verification.',
    );
    _appStateService.setVerifyingAuth(true);
    final email = _prefs.getString('login_email');

    if (email != null) {
      AppLogger.deepLink('Attempting sign-in for email: $email');
      try {
        final user = await _authRepository.signInWithEmailLink(
          email,
          link,
        );
        if (user != null) {
          AppLogger.deepLink('Sign-in successful for ${user.email}');
          await _prefs.remove('login_email');
        } else {
          AppLogger.warning(
            'LinkService: signInWithEmailLink returned null user.',
          );
          _appStateService.setEmailLinkError(
            'Failed to complete sign-in. Link may be invalid or expired.',
          );
        }
      } catch (e) {
        AppLogger.error('LinkService: Sign-in process failed', error: e);
        _appStateService.setEmailLinkError(
          'An error occurred during sign-in. Please try again.',
        );
      } finally {
        await Future.delayed(const Duration(milliseconds: 1500));
        _appStateService.setVerifyingAuth(false);
      }
    } else {
      AppLogger.warning(
        'LinkService: No cached login_email found. Saving link for later.',
      );
      await Future.delayed(const Duration(milliseconds: 1000));
      _appStateService
        ..setVerifyingAuth(false)
        ..setPendingEmailLink(link);
    }
  }

  Future<void> _handleActionCodeLink(Uri uri) async {
    final oobCode = uri.queryParameters['oobCode']!;
    final mode = uri.queryParameters['mode'];

    AppLogger.deepLink('Action Code Link detected. Mode: $mode');

    if (mode == 'verifyEmail') {
      _appStateService.setVerifyingAuth(true);
      try {
        await _firebaseAuth.applyActionCode(oobCode);
        AppLogger.deepLink('Email verification successful via app.');
        await _firebaseAuth.currentUser?.reload();
        _appStateService.notifyProfileUpdated();
      } catch (e) {
        AppLogger.error('LinkService: Email verification failed', error: e);
      } finally {
        await Future.delayed(const Duration(milliseconds: 1500));
        _appStateService.setVerifyingAuth(false);
      }
    } else if (mode == 'resetPassword') {
      // Handle password reset if needed, for now just log
      AppLogger.deepLink('Password reset link detected. OOB: $oobCode');
    }
  }

  Future<void> _checkAppleCredentialState() async {
    if (kIsWeb || !Platform.isIOS) return;

    final user = _firebaseAuth.currentUser;
    if (user == null) return;
    final appleProviderData = user.providerData.where(
      (p) => p.providerId == 'apple.com',
    );
    if (appleProviderData.isEmpty) return;

    final appleUid = appleProviderData.first.uid;
    if (appleUid == null) return;

    try {
      final credentialState = await SignInWithApple.getCredentialState(
        appleUid,
      );
      if (credentialState == CredentialState.revoked) {
        AppLogger.warning('LinkService: Apple credential revoked externally.');
        await _authRepository.signOut();
      }
    } catch (e) {
      AppLogger.error(
        'LinkService: Apple credential check failed (Expected in some dev environments)',
        error: e,
      );
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
