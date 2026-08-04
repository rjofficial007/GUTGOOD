import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

abstract class PurchaseService {
  Future<void> initialize();
  bool get isPremium;
  bool get isConfigured;
  Future<List<Package>> fetchOffers();
  Future<bool> purchasePackage(Package package);
  Future<bool> restorePurchases();
  Future<void> login(String uid);
  Future<void> logout();
  void setProStatusForDebug(bool isPro);
}

class PurchaseServiceImpl implements PurchaseService {
  bool _isPremium = false;
  bool _isConfigured = false;

  @override
  bool get isPremium => _isPremium;

  @override
  bool get isConfigured => _isConfigured;

  static const String _googleApiKey = '';
  static const String _appleApiKey = 'appl_NQQoVWhHEKFUOXvpiOFeDCBezCm';
  static const String _offering = 'premium_offering';

  @override
  Future<void> initialize() async {
    try {
      await Purchases.setLogLevel(LogLevel.debug);
      final configuration = PurchasesConfiguration(Platform.isAndroid ? _googleApiKey : _appleApiKey);
      await Purchases.configure(configuration);
      _isConfigured = true;

      _listenForPurchaseUpdates();
      await checkProSubscriptionStatus();

      AppLogger.premium('PurchaseService: Initialized');
    } catch (e, s) {
      AppLogger.error('PurchaseService: Initialization failed', error: e, stackTrace: s);
    }
  }

  void _listenForPurchaseUpdates() {
    try {
      Purchases.addCustomerInfoUpdateListener(_updateProStatus);
    } on PlatformException catch (e) {
      AppLogger.error('PurchaseService: Listener error', error: e);
    }
  }

  Future<void> checkProSubscriptionStatus() async {
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      _updateProStatus(customerInfo);
    } on PlatformException catch (e) {
      AppLogger.error('PurchaseService: Status check failed', error: e);
    }
  }

  void _updateProStatus(CustomerInfo customerInfo) {
    final isProUser = customerInfo.entitlements.active.isNotEmpty;
    if (_isPremium != isProUser) {
      _isPremium = isProUser;
      AppLogger.premium('PurchaseService: Status updated -> $_isPremium');
    }
  }

  @override
  Future<List<Package>> fetchOffers() async {
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.all[_offering]?.availablePackages ?? [];
    } on PlatformException catch (e) {
      AppLogger.error('PurchaseService: Fetch offers failed', error: e);
      return [];
    }
  }

  @override
  Future<bool> purchasePackage(Package package) async {
    try {
      final purchase = await Purchases.purchase(PurchaseParams.package(package));
      _updateProStatus(purchase.customerInfo);
      return purchase.customerInfo.entitlements.active.isNotEmpty;
    } on PlatformException catch (e) {
      final errorCode = PurchasesErrorHelper.getErrorCode(e);
      if (errorCode != PurchasesErrorCode.purchaseCancelledError) {
        AppLogger.error('PurchaseService: Purchase failed', error: e);
      }
      return false;
    }
  }

  @override
  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await Purchases.restorePurchases();
      _updateProStatus(customerInfo);
      return customerInfo.entitlements.active.isNotEmpty;
    } on PlatformException catch (e) {
      AppLogger.error('PurchaseService: Restore failed', error: e);
      return false;
    }
  }

  @override
  Future<void> login(String uid) async {
    try {
      final currentAppUserId = await Purchases.appUserID;
      if (currentAppUserId == uid) return;
      final result = await Purchases.logIn(uid);
      _updateProStatus(result.customerInfo);
    } catch (e) {
      AppLogger.error('PurchaseService: Login failed ($uid)', error: e);
    }
  }

  @override
  Future<void> logout() async {
    if (!_isConfigured) return;
    try {
      final customerInfo = await Purchases.logOut();
      _updateProStatus(customerInfo);
    } catch (e) {
      AppLogger.error('PurchaseService: Logout failed', error: e);
    }
  }

  @override
  void setProStatusForDebug(bool isPro) {
    _isPremium = isPro;
    AppLogger.premium('PurchaseService: Debug status -> $_isPremium');
  }
}
