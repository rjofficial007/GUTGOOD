import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/features/auth/domain/entities/auth_user.dart';
import 'package:gutgood/features/auth/domain/repositories/auth_repository.dart';

class GutAuthNotifier with ChangeNotifier {
  GutAuthNotifier(this._repository, this._appStateService) {
    _user = _repository.currentUser;
    _authSub = _repository.authStateChanges.listen((user) {
      _user = user;
      _authReady = true;
      notifyListeners();
    });
    _mergingSub = _repository.isMerging.listen((merging) {
      _isMerging = merging;
      notifyListeners();
    });
    _appStateService.profileUpdated.addListener(notifyListeners);
  }
  final AuthRepository _repository;
  final AppStateService _appStateService;

  AuthUser? _user;
  bool _isLoading = false;
  bool _isMerging = false;
  bool _authReady = false;

  late final StreamSubscription<AuthUser?> _authSub;
  late final StreamSubscription<bool> _mergingSub;

  AuthUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isMerging => _isMerging;
  bool get authReady => _authReady;
  bool get isAuthenticated => _user != null;
  bool get isAnonymous => _user?.isAnonymous ?? true;

  Future<T> _withLoading<T>(Future<T> Function() action) async {
    _setLoading(true);
    try {
      return await action();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> confirmMerge(String anonymousUid, String permanentUid) async {
    // isMerging state is handled by the repository stream
    await _repository.confirmMerge(anonymousUid, permanentUid);
  }

  Future<void> abandonMerge() async {
    await _repository.abandonMerge();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub.cancel();
    _mergingSub.cancel();
    _appStateService.profileUpdated.removeListener(notifyListeners);
    super.dispose();
  }

  Future<AuthUser?> signInAnonymously() =>
      _withLoading(_repository.signInAnonymously);

  Future<AuthUser?> signInWithGoogle() =>
      _withLoading(_repository.signInWithGoogle);

  Future<AuthUser?> signInWithApple() =>
      _withLoading(_repository.signInWithApple);

  Future<AuthUser?> linkWithGoogle() =>
      _withLoading(_repository.linkWithGoogle);

  Future<AuthUser?> linkWithApple() => _withLoading(_repository.linkWithApple);

  Future<AuthUser?> signInWithEmailAndPassword(String email, String password) =>
      _withLoading(
        () => _repository.signInWithEmailAndPassword(email, password),
      );

  Future<AuthUser?> signUpWithEmailAndPassword(String email, String password) =>
      _withLoading(
        () => _repository.signUpWithEmailAndPassword(email, password),
      );

  Future<void> sendPasswordResetEmail(String email) =>
      _withLoading(() => _repository.sendPasswordResetEmail(email));

  Future<void> sendSignInLinkToEmail(String email) =>
      _withLoading(() => _repository.sendSignInLinkToEmail(email));

  Future<AuthUser?> signInWithEmailLink(String email, String emailLink) =>
      _withLoading(() => _repository.signInWithEmailLink(email, emailLink));

  Future<void> signOut() => _withLoading(_repository.signOut);

  Future<void> deleteAccount() => _withLoading(_repository.deleteAccount);

  Future<void> reauthenticateWithPassword(String password) =>
      _withLoading(() => _repository.reauthenticateWithPassword(password));

  Future<void> reauthenticateWithProvider(String providerId) =>
      _withLoading(() => _repository.reauthenticateWithProvider(providerId));

  /// The provider id (`google.com`, `apple.com`, `password`, ...) the
  /// current user last signed in with, used to decide which re-auth flow
  /// to present when [deleteAccount] throws [ReauthenticationRequiredException].
  String? get currentAuthProvider => _repository.currentUser?.authProvider;

  @override
  void notifyListeners() {
    // Guard against notifying during build if needed, though usually handled by ChangeNotifier
    super.notifyListeners();
  }
}
