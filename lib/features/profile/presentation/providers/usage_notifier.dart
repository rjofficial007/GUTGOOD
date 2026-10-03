import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/features/auth/domain/repositories/auth_repository.dart';
import 'package:gutgood/infrastructure/firebase/firestore/usage_firestore_service.dart';

class UsageNotifier with ChangeNotifier {
  UsageNotifier(this._firestoreService, this._authRepository, this._appStateService) {
    _initUsageStream();
    _appStateService.sessionReset.addListener(_onSessionReset);
    _authSub = _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        _initUsageStream();
      } else {
        _onSessionReset();
      }
    });
  }

  final UsageFirestoreService _firestoreService;
  final AuthRepository _authRepository;
  final AppStateService _appStateService;

  DailyUsage? _usage;
  StreamSubscription<DailyUsage?>? _usageSub;
  StreamSubscription? _authSub;

  void _initUsageStream() {
    _usageSub?.cancel();
    final user = _authRepository.currentUser;
    if (user == null) return;

    if (user.isAnonymous) {
      _usageSub = _firestoreService.getLifetimeUsageStream().listen((usage) {
        _usage = usage;
        notifyListeners();
      });
    } else {
      _usageSub = _firestoreService.getUsageTodayStream().listen((usage) {
        _usage = usage;
        notifyListeners();
      });
    }
  }

  DailyUsage? get usage => _usage;

  int get maxChats => _authRepository.currentUser?.isAnonymous == true ? 2 : 5;
  int get maxScans => _authRepository.currentUser?.isAnonymous == true ? 2 : 3;

  @override
  void dispose() {
    _usageSub?.cancel();
    _authSub?.cancel();
    _appStateService.sessionReset.removeListener(_onSessionReset);
    super.dispose();
  }

  void _onSessionReset() {
    _usageSub?.cancel();
    _usage = null;
    notifyListeners();
  }
}
