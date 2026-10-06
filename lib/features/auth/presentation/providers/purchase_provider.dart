import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gutgood/core/services/app_state_service.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:gutgood/infrastructure/firebase/analytics_service.dart';
import 'package:gutgood/infrastructure/firebase/firestore/auth_firestore_service.dart';
import 'package:gutgood/infrastructure/payments/purchase_service.dart';
import 'package:gutgood/infrastructure/platform/internet_connection_checker.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PurchaseActionType { purchase, restore }

class PurchaseProvider extends ChangeNotifier {
  PurchaseProvider({
    required PurchaseService purchaseService,
    required InternetConnectionChecker connectionChecker,
    required AppStateService appStateService,
    required SharedPreferences prefs,
    required AuthFirestoreService authFirestoreService,
    required AnalyticsService analyticsService,
  }) : _purchaseService = purchaseService,
       _connectionChecker = connectionChecker,
       _appStateService = appStateService,
       _prefs = prefs,
       _authFirestoreService = authFirestoreService,
       _analyticsService = analyticsService {
    _isPremium = _purchaseService.isPremium;
    fetchOfferings();
    _appStateService.sessionReset.addListener(_onSessionReset);

    // 🟢 Fix: Listen for live subscription updates (expiry, renewals, etc.)
    // to ensure the Firestore profile (aiProxy quota check) stays in sync.
    _premiumSubscription = _purchaseService.premiumStatusStream.listen((active) {
      if (_isPremium != active) {
        _isPremium = active;
        _persistPremiumStatus(active);
        notifyListeners();
      }
    });
  }

  final PurchaseService _purchaseService;
  final InternetConnectionChecker _connectionChecker;
  final AppStateService _appStateService;
  final SharedPreferences _prefs;
  final AuthFirestoreService _authFirestoreService;
  final AnalyticsService _analyticsService;

  StreamSubscription<bool>? _premiumSubscription;
  List<Package> _packages = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedPackageIdentifier;
  bool _isPurchasing = false;
  PurchaseActionType? _actionType;
  bool _isPremium = false;

  List<Package> get packages => _packages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get selectedPackageIdentifier => _selectedPackageIdentifier;
  bool get isPurchasing => _isPurchasing;
  PurchaseActionType? get actionType => _actionType;
  bool get isPremium => _isPremium;

  Future<void> fetchOfferings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (!_connectionChecker.isInternetAvailable.value) {
        _errorMessage = 'No internet connection available.';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final packages = await _purchaseService.fetchOffers();

      if (packages.isEmpty) {
        _errorMessage = 'No subscription plans available.';
        _packages = [];
      } else {
        _packages = packages;
        _selectedPackageIdentifier = _packages.firstWhere((p) => p.storeProduct.subscriptionPeriod == 'P1Y', orElse: () => _packages.first).identifier;
        await _analyticsService.logEvent(name: 'offerings_fetched', parameters: {'count': _packages.length});
      }
    } catch (e) {
      AppLogger.error('PurchaseProvider: Fetch offerings failed', error: e);
      _errorMessage = 'Failed to load plans.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> purchasePackage(Package package) async {
    _isPurchasing = true;
    _actionType = PurchaseActionType.purchase;
    _errorMessage = null;
    notifyListeners();

    await _analyticsService.logEvent(name: 'purchase_started', parameters: {'package_id': package.identifier, 'price': package.storeProduct.price});

    try {
      final success = await _purchaseService.purchasePackage(package);
      await _analyticsService.logEvent(name: 'purchase_completed', parameters: {'package_id': package.identifier, 'success': success});
      await _updatePremiumStatusFromService();
      return success;
    } catch (e) {
      AppLogger.error('PurchaseProvider: Purchase failed', error: e);
      rethrow;
    } finally {
      _isPurchasing = false;
      notifyListeners();
    }
  }

  Future<bool> restorePurchases() async {
    _isPurchasing = true;
    _actionType = PurchaseActionType.restore;
    // A new action supersedes any previous fetch error, so loading and
    // error states are never shown at the same time.
    _errorMessage = null;
    _appStateService.setRestoringPurchases(true);
    notifyListeners();

    await _analyticsService.logEvent(name: 'restore_started');

    try {
      final restored = await _purchaseService.restorePurchases();
      await _analyticsService.logEvent(name: 'restore_completed', parameters: {'success': restored});
      await _updatePremiumStatusFromService();
      return restored;
    } catch (e) {
      AppLogger.error('PurchaseProvider: Restore failed', error: e);
      return false;
    } finally {
      _isPurchasing = false;
      _appStateService.setRestoringPurchases(false);
      notifyListeners();
    }
  }

  void selectPackage(String identifier) {
    _selectedPackageIdentifier = identifier;
    notifyListeners();
  }

  Future<void> retryFetchOfferings() async {
    await fetchOfferings();
  }

  Future<void> _updatePremiumStatusFromService() async {
    final active = _purchaseService.isPremium;
    if (_isPremium != active) {
      _isPremium = active;
      await _persistPremiumStatus(active);
      notifyListeners();
    }
  }

  Future<void> _persistPremiumStatus(bool active) async {
    // Persist locally for the read-path fast lane.
    await _prefs.setBool('is_premium', active);

    // Client-side premium model: the entitlement truth comes from the
    // RevenueCat SDK on-device (PurchaseService). We mirror it into Firestore
    // so it is available cross-device and to the aiProxy quota check. There
    // is intentionally no server-side RevenueCat integration.
    await _authFirestoreService.updatePremiumStatus(active);
  }

  @override
  void dispose() {
    _appStateService.sessionReset.removeListener(_onSessionReset);
    _premiumSubscription?.cancel();
    super.dispose();
  }

  void _onSessionReset() {
    _isPremium = false;
    _packages = [];
    _errorMessage = null;
    _isPurchasing = false;
    notifyListeners();
  }

  void setPremiumForDebug(bool value) {
    // if (kDebugMode) {
      _isPremium = value;
      _purchaseService.setProStatusForDebug(value);
      _persistPremiumStatus(value);
      notifyListeners();
    // }
  }
}
