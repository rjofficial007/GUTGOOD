import 'package:flutter/foundation.dart';
import 'package:gutgood/core/models/models.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/features/auth/domain/repositories/auth_repository.dart';
import 'package:gutgood/infrastructure/firebase/firestore/auth_firestore_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/usage_firestore_service.dart';
import 'package:gutgood/infrastructure/payments/purchase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class UsageService {
  Future<bool> isPremium();
  Future<bool> canChat();
  Future<bool> canScan();

  /// Whether a background summary may spend system quota (K-6/P2-5).
  /// Summaries share the daily `system` budget with classification and lose
  /// the tiebreak — this reserves the last units for intent routing.
  Future<bool> canSummarize();
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
  UsageServiceImpl({
    required AuthRepository authRepository,
    required AuthFirestoreService authFirestoreService,
    required UsageFirestoreService usageFirestoreService,
    required PurchaseService purchaseService,
    required SharedPreferences prefs,
  }) : _authRepository = authRepository,
       _authFirestoreService = authFirestoreService,
       _usageFirestoreService = usageFirestoreService,
       _purchaseService = purchaseService,
       _prefs = prefs;

  final AuthRepository _authRepository;
  final AuthFirestoreService _authFirestoreService;
  final UsageFirestoreService _usageFirestoreService;
  final PurchaseService _purchaseService;
  final SharedPreferences _prefs;

  // Kept in sync with functions/src/config.ts LIMITS.
  static const int maxFreeChats = 5;
  static const int maxFreeScans = 3;
  static const int maxGuestChats = 2;
  static const int maxGuestScans = 2;
  static const int maxSystemRegistered = 20;
  static const int maxSystemGuest = 10;

  /// System-quota units never spent on summaries (K-6): classification shares
  /// the budget and must keep working for heavy chatters.
  static const int systemSummaryReserve = 2;

  String? get _uid => _authRepository.currentUser?.uid;

  @override
  Future<bool> isPremium() async {
    if (_purchaseService.isPremium) return true;

    final uid = _uid;
    if (uid == null) return false;

    final profile = await _authFirestoreService.getUserMetadata();
    if (profile != null && profile.isPremium) return true;

    return _prefs.getBool('is_premium') ?? false;
  }

  Future<DailyUsage> _getTodayUsage() async {
    final uid = _uid;
    if (uid == null) return const DailyUsage(uid: '', date: '');

    // 🟡 Fix: Use local date to match timezone-aware server usage key generation.
    final date = DateTime.now().toIso8601String().split('T')[0];

    try {
      final cloudUsage = await _usageFirestoreService.getUsageToday();
      if (cloudUsage != null) return cloudUsage;
    } catch (e) {
      AppLogger.warning('UsageService: Cloud usage fetch failed: $e');
    }

    return DailyUsage(uid: uid, date: date);
  }

  @override
  Future<bool> canChat() async {
    if (await isPremium()) return true;
    final isAnon = _authRepository.currentUser?.isAnonymous != false;

    if (isAnon) {
      final usage = await _usageFirestoreService.getLifetimeUsage();
      final allowed = usage.chatCount < maxGuestChats;
      AppLogger.debug('UsageService: canChat? $allowed (lifetime guest: ${usage.chatCount}/$maxGuestChats)');
      return allowed;
    }

    final usage = await _getTodayUsage();
    final allowed = usage.chatCount < maxFreeChats;
    AppLogger.debug('UsageService: canChat? $allowed (daily free: ${usage.chatCount}/$maxFreeChats)');
    return allowed;
  }

  @override
  Future<bool> canScan() async {
    if (await isPremium()) return true;
    final isAnon = _authRepository.currentUser?.isAnonymous != false;

    if (isAnon) {
      final usage = await _usageFirestoreService.getLifetimeUsage();
      final allowed = usage.scanCount < maxGuestScans;
      AppLogger.debug('UsageService: canScan? $allowed (lifetime guest: ${usage.scanCount}/$maxGuestScans)');
      return allowed;
    }

    final usage = await _getTodayUsage();
    final allowed = usage.scanCount < maxFreeScans;
    AppLogger.debug('UsageService: canScan? $allowed (daily free: ${usage.scanCount}/$maxFreeScans)');
    return allowed;
  }

  @override
  Future<bool> canSummarize() async {
    if (await isPremium()) return true;
    final isAnon = _authRepository.currentUser?.isAnonymous != false;

    if (isAnon) {
      final usage = await _usageFirestoreService.getLifetimeUsage();
      final allowed = usage.systemCount < maxSystemGuest - systemSummaryReserve;
      AppLogger.debug('UsageService: canSummarize? $allowed (lifetime guest system: ${usage.systemCount}/$maxSystemGuest)');
      return allowed;
    }

    final usage = await _getTodayUsage();
    final allowed = usage.systemCount < maxSystemRegistered - systemSummaryReserve;
    AppLogger.debug('UsageService: canSummarize? $allowed (daily free system: ${usage.systemCount}/$maxSystemRegistered)');
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
    // flag. The Firestore copy is not written because this override only
    // affects this device's UI state. (Under the client-side premium model the
    // profile's isPremium field is client-writable by design — not
    // server-reserved; see docs/ACCEPTED_RISKS.md R1.)
    await _prefs.setBool('is_premium', isPremium);
    _purchaseService.setProStatusForDebug(isPremium);
  }
}
