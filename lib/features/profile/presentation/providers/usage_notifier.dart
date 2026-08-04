import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gutgood/core/models/daily_usage.dart';
import 'package:gutgood/core/services/firestore_service.dart';
import 'package:gutgood/features/auth/domain/repositories/auth_repository.dart';

class UsageNotifier with ChangeNotifier {
  final FirestoreService _firestoreService;
  final AuthRepository _authRepository;

  DailyUsage? _usage;
  StreamSubscription<DailyUsage?>? _usageSub;

  UsageNotifier(this._firestoreService, this._authRepository) {
    _initUsageStream();
    _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        _initUsageStream();
      }
    });
  }

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
    super.dispose();
  }
}
