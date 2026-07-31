import 'package:flutter/foundation.dart';
import 'package:gutgood/core/models/daily_usage.dart';
import 'package:gutgood/core/services/firestore_service.dart';
import 'package:gutgood/core/services/purchase_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/features/auth/domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class UsageService {
  Future<bool> isPremium();
  Future<bool> canChat();
  Future<bool> canScan();
  Future<void> resetLimitsForTesting();
  Future<void> setPremiumForTesting(bool isPremium);
}

/// Read-only free-tier gate used as a UX fast-path (so the paywall appears
/// BEFORE the user wastes a request).
///
/// IMPORTANT: This service no longer INCREMENTS usage. Counters are consumed
/// transactionally by the `aiProxy` Cloud Function, which is the authoritative
/// gate — the client could previously reset its own counters (audit §3.1).
class UsageServiceImpl implements UsageService {
  final AuthRepository _authRepository;
  final FirestoreService _firestoreService;
  final PurchaseService _purchaseService;
  final SharedPreferences _prefs;

  UsageServiceImpl({
    required AuthRepository authRepository,
    required FirestoreService firestoreService,
    required PurchaseService purchaseService,
    required SharedPreferences prefs,
  }) : _authRepository = authRepository,
       _firestoreService = firestoreService,
       _purchaseService = purchaseService,
       _prefs = prefs;

  // Kept in sync with functions/src/config.ts LIMITS.
  static const int maxFreeChats = 5;
  static const int maxFreeScans = 3;
  static const int maxGuestChats = 2;
  static const int maxGuestScans = 2;

  String? get _uid => _authRepository.currentUser?.uid;

  @override
  Future<bool> isPremium() async {
    if (_purchaseService.isPremium) return true;

    final uid = _uid;
    if (uid == null) return false;

    final profile = await _firestoreService.getUserMetadata();
    if (profile != null && profile.isPremium) return true;

    return _prefs.getBool('is_premium') ?? false;
  }

  Future<DailyUsage> _getTodayUsage() async {
    final uid = _uid;
    if (uid == null) return const DailyUsage(uid: '', date: '');

    final date = DateTime.now().toIso8601String().split('T')[0];

    try {
      final DailyUsage? cloudUsage = await _firestoreService.getUsageToday();
      if (cloudUsage != null) return cloudUsage;
    } catch (e) {
      Log.w('UsageService: Cloud usage fetch failed: $e');
    }

    return DailyUsage(uid: uid, date: date);
  }

  @override
  Future<bool> canChat() async {
    if (await isPremium()) return true;
    final DailyUsage usage = await _getTodayUsage();
    final isAnon = _authRepository.currentUser?.isAnonymous != false;
    final limit = isAnon ? maxGuestChats : maxFreeChats;

    final allowed = usage.chatCount < limit;
    Log.d('UsageService: canChat? $allowed (${usage.chatCount}/$limit, guest: $isAnon)');
    return allowed;
  }

  @override
  Future<bool> canScan() async {
    if (await isPremium()) return true;
    final DailyUsage usage = await _getTodayUsage();
    final isAnon = _authRepository.currentUser?.isAnonymous != false;
    final limit = isAnon ? maxGuestScans : maxFreeScans;

    final allowed = usage.scanCount < limit;
    Log.d('UsageService: canScan? $allowed (${usage.scanCount}/$limit, guest: $isAnon)');
    return allowed;
  }

  @override
  Future<void> resetLimitsForTesting() async {
    if (!kDebugMode) return;
    if (_uid == null) return;
    await _prefs.setBool('is_premium', false);
    _purchaseService.setProStatusForDebug(false);
  }

  @override
  Future<void> setPremiumForTesting(bool isPremium) async {
    if (!kDebugMode) return;
    if (_uid == null) return;
    // Debug-only override: persists locally and flips the in-memory RevenueCat
    // flag. The Firestore copy is intentionally NOT written — the security
    // rules reserve that field for the server.
    await _prefs.setBool('is_premium', isPremium);
    _purchaseService.setProStatusForDebug(isPremium);
  }
}
