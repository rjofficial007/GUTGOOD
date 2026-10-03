import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:gutgood/core/utils/logger_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

abstract class PurchaseService {
  Future<void> initialize();
  bool get isPremium;
  Stream<bool> get premiumStatusStream;
  Future<List<Package>> fetchOffers();
  Future<bool> purchasePackage(Package package);
  Future<bool> restorePurchases();
  Future<void> login(String uid);
  Future<void> logout();
  void setProStatusForDebug(bool isPro);
  void dispose();
}

class PurchaseServiceImpl implements PurchaseService {
  bool _isPremium = false;
  bool _isConfigured = false;
  final _premiumStatusController = StreamController<bool>.broadcast();

  @override
  bool get isPremium => _isPremium;

  @override
  Stream<bool> get premiumStatusStream => _premiumStatusController.stream;


  // Intentionally iOS-only for now: the Google key is left empty, so RevenueCat
  // configuration fails (benignly — errors are caught and logged) and purchases
  // are unavailable on Android. Accepted decision R4; fill in before Android
  // launch (docs/ACCEPTED_RISKS.md).
  static const String _googleApiKey = '';
  static const String _appleApiKey = 'appl_NQQoVWhHEKFUOXvpiOFeDCBezCm';
  static const String _offering = 'premium_offering';

  @override
  Future<void> initialize() async {
    try {
      // Debug log level in all build modes is intentional for now (accepted:
      // verbose payment internals in release logs — R4, docs/ACCEPTED_RISKS.md).
      await Purchases.setLogLevel(LogLevel.debug);
      final apiKey = Platform.isAndroid ? _googleApiKey : _appleApiKey;
      AppLogger.payments('Configuring with API Key: $apiKey'); // R4: key logged intentionally (public SDK key)
      final configuration = PurchasesConfiguration(apiKey);
      await Purchases.configure(configuration);
      _isConfigured = true;

      _listenForPurchaseUpdates();
      await checkProSubscriptionStatus();

      AppLogger.payments('Initialized');
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
      _premiumStatusController.add(isProUser);
      AppLogger.payments('Status updated -> $_isPremium');
    }
  }

  @override
  Future<List<Package>> fetchOffers() async {
    try {
      AppLogger.payments('Fetching offerings...');
      final offerings = await Purchases.getOfferings();
      await printAllOfferings(offerings);

      final targetOffering = offerings.all[_offering];
      if (targetOffering == null) {
        AppLogger.warning('PurchaseService: Specific offering "$_offering" not found in offerings.all');
      }

      return targetOffering?.availablePackages ?? [];
    } on PlatformException catch (e) {
      AppLogger.error('PurchaseService: Fetch offers failed', error: e);
      return [];
    }
  }

  Future<void> printAllOfferings(Offerings offeringsData) async {
    try {
      if (offeringsData.all.isEmpty) {
        Logger.debug('No offerings found.');
        return;
      }

      // Loop through all offerings
      offeringsData.all.forEach((offeringId, offering) {
        Logger.premium('Offering: ${offering.identifier}');
        Logger.premium('Description: ${offering.serverDescription}');

        // Loop through all packages in this offering
        for (var package in offering.availablePackages) {
          Logger.premium('Package Details:');
          Logger.premium('Identifier: ${package.identifier}');
          Logger.premium('Package Type: ${package.packageType}');
          Logger.premium('Store Product:');
          Logger.premium('\tIdentifier: ${package.storeProduct.identifier}');
          Logger.premium('\tDescription: ${package.storeProduct.description}');
          Logger.premium('\tTitle: ${package.storeProduct.title}');
          Logger.premium('\tPrice: ${package.storeProduct.price}');
          Logger.premium('\tPrice String: ${package.storeProduct.priceString}');
          Logger.premium('\tCurrency Code: ${package.storeProduct.currencyCode}');

          Logger.premium('\tDiscounts: ${package.storeProduct.discounts}');
          Logger.premium('\tProduct Category: ${package.storeProduct.productCategory}');
          Logger.premium('\tDefault Option: ${package.storeProduct.defaultOption}');
          Logger.premium('\tSubscription Options: ${package.storeProduct.subscriptionOptions}');
          Logger.premium('\tPresented Offering Identifier: ${package.storeProduct.presentedOfferingContext}');
          Logger.premium('\tSubscription Period: ${package.storeProduct.subscriptionPeriod}');

          if (package.storeProduct.introductoryPrice != null) {
            Logger.premium('Introductory Price:');
            Logger.premium('\tPrice: ${package.storeProduct.introductoryPrice!.price}');
            Logger.premium('\tPrice String: ${package.storeProduct.introductoryPrice!.priceString}');
            Logger.premium('\tPeriod: ${package.storeProduct.introductoryPrice!.period}');
            Logger.premium('\tCycles: ${package.storeProduct.introductoryPrice!.cycles}');
            Logger.premium('\tPeriod Unit: ${package.storeProduct.introductoryPrice!.periodUnit}');
            Logger.premium('\tPeriod Number of Units: ${package.storeProduct.introductoryPrice!.periodNumberOfUnits}');
          }

          Logger.premium('Product Category: ${package.storeProduct.productCategory}');
          Logger.premium('Default Option: ${package.storeProduct.defaultOption}');
          Logger.premium('Subscription Period: ${package.storeProduct.subscriptionPeriod}');
          Logger.premium('Offering Identifier: ${package.presentedOfferingContext}');
          Logger.premium('------------------------------------');
        }
      });
    } catch (e) {
      Logger.error('Error fetching offerings: $e');
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
      if (errorCode == PurchasesErrorCode.purchaseCancelledError) {
        return false;
      }
      AppLogger.error('PurchaseService: Purchase failed', error: e);
      rethrow;
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
    _premiumStatusController.add(isPro);
    AppLogger.payments('Debug status -> $_isPremium');
  }

  @override
  void dispose() {
    _premiumStatusController.close();
  }
}
