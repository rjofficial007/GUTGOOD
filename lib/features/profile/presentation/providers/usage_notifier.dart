import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gutgood/core/di/injection_container.dart';
import 'package:gutgood/core/models/daily_usage.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/services/firestore/usage_firestore_service.dart';
import 'package:gutgood/features/auth/domain/repositories/auth_repository.dart';

class UsageNotifier with ChangeNotifier {
  UsageNotifier(this._firestoreService, this._authRepository) {
    _initUsageStream();
    sl<AppStateService>().sessionReset.addListener(_onSessionReset);
    _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        _initUsageStream();
      } else {
        _onSessionReset();
      }
    });
  }

  final UsageFirestoreService _firestoreService;
  final AuthRepository _authRepository;

  DailyUsage? _usage;
  StreamSubscription<DailyUsage?>? _usageSub;

  void _initUsageStream() {
    _usageSub?.cancel();
    _usageSub = _firestoreService.getUsageTodayStream().listen((usage) {
      _usage = usage;
      notifyListeners();
    });
  }

  DailyUsage? get usage => _usage;

  int get maxChats => _authRepository.currentUser?.isAnonymous == true ? 2 : 5;
  int get maxScans => _authRepository.currentUser?.isAnonymous == true ? 2 : 3;

  @override
  void dispose() {
    _usageSub?.cancel();
    sl<AppStateService>().sessionReset.removeListener(_onSessionReset);
    super.dispose();
  }

  void _onSessionReset() {
    _usageSub?.cancel();
    _usage = null;
    notifyListeners();
  }
}
