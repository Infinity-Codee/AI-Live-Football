/// Wallet & Subscription screen.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/wallet_provider.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchBalance();
      context.read<SubscriptionProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: SafeArea(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Text(
                  'Wallet & Plans',
                  style: TextStyle(
                    color: AppTheme.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Expanded(
                child: Consumer2<WalletProvider, SubscriptionProvider>(
                  builder: (_, wallet, sub, __) => SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildPlanCard(sub),
                        const SizedBox(height: 16),
                        _buildCreditCard(wallet),
                        const SizedBox(height: 16),
                        _buildDailyFreeCard(sub),
                        const SizedBox(height: 16),
                        if (!sub.isPro) _buildWatchAdCard(wallet),
                        if (!sub.isPro) const SizedBox(height: 16),
                        _buildStats(wallet),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(SubscriptionProvider sub) {
    final isPro = sub.isPro;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: isPro ? AppTheme.primaryGradient : AppTheme.goldGradient,
        borderRadius: AppTheme.radiusLg,
        boxShadow: AppTheme.glowShadow(isPro ? AppTheme.primary : AppTheme.gold),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isPro ? Icons.verified : Icons.workspace_premium,
                color: isPro ? Colors.white : Colors.black87,
              ),
              const SizedBox(width: 8),
              Text(
                isPro ? 'Pro Active' : 'Free Plan',
                style: TextStyle(
                  color: isPro ? Colors.white : Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isPro
                ? 'Unlimited live unlocks. Ads removed.'
                : 'Watch a rewarded video before each match analysis.',
            style: TextStyle(
              color: isPro ? Colors.white70 : Colors.black54,
            ),
          ),
          if (!isPro) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/paywall'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Upgrade to Pro'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCreditCard(WalletProvider wallet) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: AppTheme.radiusLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.toll, color: AppTheme.gold, size: 18),
              SizedBox(width: 8),
              Text(
                'Available Credits',
                style: TextStyle(color: AppTheme.greyLight),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '${wallet.credits}',
            style: const TextStyle(
              color: AppTheme.white,
              fontSize: 44,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyFreeCard(SubscriptionProvider sub) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: AppTheme.radiusLg,
      ),
      child: Row(
        children: [
          const Icon(Icons.play_circle, color: AppTheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              sub.isPro
                  ? 'Pro has unlimited live unlocks.'
                  : 'Free users must watch a video ad to unlock each analysis.',
              style: const TextStyle(color: AppTheme.greyLight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWatchAdCard(WalletProvider wallet) {
    return GestureDetector(
      onTap: () async {
        final earned = await wallet.watchAdForCredit();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              earned ? '+1 credit earned!' : 'Ad not available right now.',
            ),
            backgroundColor: earned ? AppTheme.primary : AppTheme.bgSurface,
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppTheme.goldGradient,
          borderRadius: AppTheme.radiusLg,
          boxShadow: AppTheme.glowShadow(AppTheme.gold),
        ),
        child: const Row(
          children: [
            Icon(Icons.play_circle, size: 30, color: Colors.black87),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Watch Rewarded Ad',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                ),
              ),
            ),
            Text(
              '+1',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStats(WalletProvider wallet) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: AppTheme.radiusLg,
      ),
      child: Row(
        children: [
          Expanded(
            child: _statItem(
              Icons.play_circle,
              '${wallet.totalAdsWatched}',
              'Ads Watched',
            ),
          ),
          Container(width: 1, height: 40, color: AppTheme.bgSurface),
          Expanded(
            child: _statItem(
              Icons.toll,
              '${wallet.credits}',
              'Credits Left',
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.white,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppTheme.grey, fontSize: 12)),
      ],
    );
  }
}
