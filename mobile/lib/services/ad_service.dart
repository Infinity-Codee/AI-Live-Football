/// AdMob Rewarded Video Ad manager.

import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../config/constants.dart';

class AdService {
  static final AdService _instance = AdService._();
  factory AdService() => _instance;
  AdService._();

  RewardedAd? _rewardedAd;
  bool _isLoading = false;

  /// Initialize AdMob SDK
  Future<void> initialize() async {
    await MobileAds.instance.initialize();
    loadRewardedAd();
  }

  /// Load a rewarded ad in the background
  void loadRewardedAd() {
    if (_isLoading || _rewardedAd != null) return;
    _isLoading = true;

    RewardedAd.load(
      adUnitId: AppConstants.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isLoading = false;
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isLoading = false;
          // Retry after a short delay
          Future.delayed(const Duration(seconds: 5), loadRewardedAd);
        },
      ),
    );
  }

  /// Show rewarded ad and return true if user earned the reward.
  Future<bool> showRewardedAd() async {
    final ad = _rewardedAd;
    if (ad == null) {
      loadRewardedAd();
      return false;
    }

    final completer = Completer<bool>();
    bool earned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd(); // Pre-load next ad
        if (!completer.isCompleted) completer.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    try {
      await ad.show(
        onUserEarnedReward: (ad, reward) {
          earned = true;
        },
      );
    } catch (_) {
      if (!completer.isCompleted) completer.complete(false);
      _rewardedAd = null;
      loadRewardedAd();
    }

    return completer.future;
  }

  bool get isAdReady => _rewardedAd != null;
}
