/// Provider for freemium + Pro subscription state and purchases.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config/constants.dart';
import '../services/analytics_service.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

enum SubscriptionStatus { loading, free, pro }

class SubscriptionProvider extends ChangeNotifier {
  static const int freeDailyUnlockLimit = 1;

  final StorageService _storage = StorageService();
  final ApiService _api = ApiService();
  final AnalyticsService _analytics = AnalyticsService();

  SubscriptionStatus _status = SubscriptionStatus.loading;
  Offerings? _offerings;
  bool _revenueCatReady = false;
  bool _purchaseInProgress = false;
  int _dailyFreeUnlocksUsed = 0;
  String? _lastError;

  SubscriptionProvider() {
    load();
  }

  SubscriptionStatus get status => _status;
  bool get isLoading => _status == SubscriptionStatus.loading;
  bool get isPro => _status == SubscriptionStatus.pro;
  bool get isFree => _status == SubscriptionStatus.free;
  bool get purchaseInProgress => _purchaseInProgress;
  bool get revenueCatReady => _revenueCatReady;
  String? get lastError => _lastError;

  Offerings? get offerings => _offerings;
  Offering? get currentOffering => _offerings?.current;

  int get dailyFreeUnlocksUsed => _dailyFreeUnlocksUsed;
  int get dailyFreeUnlocksRemaining =>
      (freeDailyUnlockLimit - _dailyFreeUnlocksUsed).clamp(0, freeDailyUnlockLimit);
  bool get canUseDailyFreeUnlock => !isPro && dailyFreeUnlocksRemaining > 0;

  Future<void> load() async {
    _syncDailyWindow();
    _status = _storage.isProUser ? SubscriptionStatus.pro : SubscriptionStatus.free;
    notifyListeners();

    await _loadEntitlementFromBackend();
    await _initRevenueCat();
  }

  Future<void> _loadEntitlementFromBackend() async {
    try {
      final result = await _api.getEntitlements(_storage.deviceId);
      final isPro = result['is_pro'] == true;
      _setStatus(isPro ? SubscriptionStatus.pro : SubscriptionStatus.free);
      _storage.isProUser = isPro;
    } catch (_) {
      // Keep local value if backend is not reachable.
    }
  }

  Future<void> _initRevenueCat() async {
    final apiKey = Platform.isIOS
        ? AppConstants.revenueCatAppleApiKey
        : AppConstants.revenueCatGoogleApiKey;

    if (apiKey.isEmpty) {
      _revenueCatReady = false;
      notifyListeners();
      return;
    }

    try {
      final config = PurchasesConfiguration(apiKey)..appUserID = _storage.deviceId;
      await Purchases.configure(config);
      _revenueCatReady = true;
      await refreshEntitlements();
      await loadOfferings();
    } catch (e) {
      _revenueCatReady = false;
      _lastError = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadOfferings() async {
    if (!_revenueCatReady) return;
    try {
      _offerings = await Purchases.getOfferings();
    } catch (_) {
      // Keep screen functional even if offerings fetch fails.
    }
    notifyListeners();
  }

  Future<void> refreshEntitlements() async {
    if (!_revenueCatReady) return;
    try {
      final info = await Purchases.getCustomerInfo();
      await _applyCustomerInfo(info, source: 'revenuecat_refresh');
    } catch (_) {
      // Ignore transient errors.
    }
  }

  Future<bool> purchasePro({required bool yearly}) async {
    if (!_revenueCatReady) {
      _lastError = 'RevenueCat is not configured yet.';
      notifyListeners();
      return false;
    }

    _purchaseInProgress = true;
    _lastError = null;
    notifyListeners();

    await _analytics.track(
      'paywall_cta_click',
      properties: {'plan': yearly ? 'yearly' : 'monthly'},
    );

    try {
      await loadOfferings();
      final package = _findPackage(
        yearly: yearly,
        offerings: _offerings,
      );
      if (package == null) {
        _lastError = 'No package found for selected plan.';
        _purchaseInProgress = false;
        notifyListeners();
        return false;
      }

      final customerInfo = await Purchases.purchasePackage(package);
      await _applyCustomerInfo(customerInfo, source: 'purchase');
      final ok = isPro;
      if (ok) {
        await _analytics.track(
          'purchase_success',
          properties: {'plan': yearly ? 'yearly' : 'monthly'},
        );
      }
      _purchaseInProgress = false;
      notifyListeners();
      return ok;
    } on PlatformException catch (e) {
      _lastError = e.message ?? 'Purchase failed.';
      _purchaseInProgress = false;
      notifyListeners();
      return false;
    } catch (e) {
      _lastError = e.toString();
      _purchaseInProgress = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> restorePurchases() async {
    if (!_revenueCatReady) return false;

    _purchaseInProgress = true;
    _lastError = null;
    notifyListeners();

    try {
      final info = await Purchases.restorePurchases();
      await _applyCustomerInfo(info, source: 'restore');
      await _analytics.track(
        'purchase_restore',
        properties: {'is_pro': isPro},
      );
      _purchaseInProgress = false;
      notifyListeners();
      return isPro;
    } on PlatformException catch (e) {
      _lastError = e.message ?? 'Restore failed.';
      _purchaseInProgress = false;
      notifyListeners();
      return false;
    } catch (e) {
      _lastError = e.toString();
      _purchaseInProgress = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _applyCustomerInfo(CustomerInfo info, {required String source}) async {
    final entitlement =
        info.entitlements.active[AppConstants.proEntitlementId];
    final proActive = entitlement != null;

    _storage.isProUser = proActive;
    _setStatus(proActive ? SubscriptionStatus.pro : SubscriptionStatus.free);

    try {
      final expirationRaw = entitlement?.expirationDate;
      await _api.syncEntitlements(
        deviceId: _storage.deviceId,
        isPro: proActive,
        source: source,
        proExpiresAt: expirationRaw?.toString(),
      );
    } catch (_) {
      // Backend sync failure should not block entitlement usage on device.
    }
  }

  bool consumeDailyFreeUnlock() {
    _syncDailyWindow();
    if (!canUseDailyFreeUnlock) return false;

    _dailyFreeUnlocksUsed += 1;
    _storage.dailyFreeUnlocksUsed = _dailyFreeUnlocksUsed;
    _storage.dailyFreeUnlockDate = _todayKey();
    notifyListeners();
    return true;
  }

  void _setStatus(SubscriptionStatus value) {
    if (_status != value) {
      _status = value;
      notifyListeners();
    }
  }

  Package? _findPackage({required bool yearly, Offerings? offerings}) {
    final available = offerings?.current?.availablePackages ?? const <Package>[];
    final productId = yearly
        ? AppConstants.proYearlyProductId
        : AppConstants.proMonthlyProductId;

    for (final pkg in available) {
      if (pkg.storeProduct.identifier == productId) {
        return pkg;
      }
    }

    for (final pkg in available) {
      if (yearly && pkg.packageType == PackageType.annual) return pkg;
      if (!yearly && pkg.packageType == PackageType.monthly) return pkg;
    }

    return available.isNotEmpty ? available.first : null;
  }

  void _syncDailyWindow() {
    final today = _todayKey();
    if (_storage.dailyFreeUnlockDate != today) {
      _dailyFreeUnlocksUsed = 0;
      _storage.dailyFreeUnlockDate = today;
      _storage.dailyFreeUnlocksUsed = 0;
      return;
    }
    _dailyFreeUnlocksUsed = _storage.dailyFreeUnlocksUsed;
  }

  String _todayKey() {
    final now = DateTime.now();
    final mm = now.month.toString().padLeft(2, '0');
    final dd = now.day.toString().padLeft(2, '0');
    return '${now.year}-$mm-$dd';
  }
}
