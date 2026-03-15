/// Provider for wallet/credit management.

import 'package:flutter/material.dart';
import '../services/analytics_service.dart';
import '../services/api_service.dart';
import '../services/ad_service.dart';
import '../services/storage_service.dart';

class WalletProvider extends ChangeNotifier {
  final ApiService _api = ApiService();
  final AdService _adService = AdService();
  final StorageService _storage = StorageService();
  final AnalyticsService _analytics = AnalyticsService();

  int _credits = 0;
  int _totalAdsWatched = 0;
  bool _isLoading = false;
  String? _message;

  int get credits => _credits;
  int get totalAdsWatched => _totalAdsWatched;
  bool get isLoading => _isLoading;
  String? get message => _message;
  bool get isAdReady => _adService.isAdReady;

  /// Register device and get initial credits
  Future<void> registerAndFetch() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.registerDevice(_storage.deviceId);
      _credits = data['credits'] ?? 0;
      await fetchBalance();
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  /// Fetch current balance
  Future<void> fetchBalance() async {
    try {
      final data = await _api.getBalance(_storage.deviceId);
      _credits = data['credits'] ?? 0;
      _totalAdsWatched = data['total_ads_watched'] ?? 0;
    } catch (_) {}
    notifyListeners();
  }

  /// Watch ad and earn credit
  Future<bool> watchAdForCredit() async {
    _message = null;
    notifyListeners();

    final earned = await _adService.showRewardedAd();
    if (earned) {
      try {
        final data = await _api.addReward(_storage.deviceId);
        _credits = data['credits'] ?? _credits;
        _message = data['message'];
      } catch (_) {
        // Still count locally
        _credits += 1;
        _message = '+1 credit!';
      }
      await _analytics.track('rewarded_watched');
      notifyListeners();
      return true;
    }
    _message = 'Ad not available. Try again!';
    notifyListeners();
    return false;
  }

  /// Spend credit to unlock a match
  Future<bool> unlockMatch(int matchId) async {
    // Already unlocked locally?
    if (_storage.isMatchUnlocked(matchId)) return true;

    if (_credits < 1) {
      _message = 'Not enough credits!';
      notifyListeners();
      return false;
    }

    try {
      final data = await _api.spendCredit(_storage.deviceId, matchId);
      _credits = data['credits'] ?? _credits;
      _message = data['message'];
      _storage.unlockMatch(matchId);
      notifyListeners();
      return true;
    } catch (_) {
      // Fallback: if backend spend fails transiently, keep UX working locally.
      if (_credits >= 1) {
        _credits -= 1;
        _message = 'Match unlocked!';
        _storage.unlockMatch(matchId);
        notifyListeners();
        return true;
      }
      _message = 'Unable to unlock match right now. Please try again.';
      notifyListeners();
      return false;
    }
  }

  void unlockMatchLocally(int matchId) {
    _storage.unlockMatch(matchId);
    notifyListeners();
  }

  bool isMatchUnlocked(int matchId) => _storage.isMatchUnlocked(matchId);
}
