import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../providers/subscription_provider.dart';
import '../../services/analytics_service.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  @override
  void initState() {
    super.initState();
    AnalyticsService().track('paywall_view');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().loadOfferings();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: SafeArea(
          child: Consumer<SubscriptionProvider>(
            builder: (_, sub, __) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon:
                              const Icon(Icons.arrow_back_ios, color: AppTheme.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            'Upgrade to Pro',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppTheme.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 48),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _heroCard(),
                    const SizedBox(height: 16),
                    _featureComparison(),
                    const SizedBox(height: 20),
                    _planButton(
                      title: 'Pro Monthly',
                      subtitle: '\$4.99 / month',
                      onTap: sub.purchaseInProgress
                          ? null
                          : () async {
                              final ok =
                                  await context.read<SubscriptionProvider>().purchasePro(
                                        yearly: false,
                                      );
                              if (ok && mounted) Navigator.pop(context);
                            },
                    ),
                    const SizedBox(height: 12),
                    _planButton(
                      title: 'Pro Yearly',
                      subtitle: '\$39.99 / year (save 33%)',
                      highlighted: true,
                      onTap: sub.purchaseInProgress
                          ? null
                          : () async {
                              final ok =
                                  await context.read<SubscriptionProvider>().purchasePro(
                                        yearly: true,
                                      );
                              if (ok && mounted) Navigator.pop(context);
                            },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: sub.purchaseInProgress
                            ? null
                            : () async {
                                await context
                                    .read<SubscriptionProvider>()
                                    .restorePurchases();
                              },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: AppTheme.white.withValues(alpha: 0.35),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text(
                          'Restore Purchases',
                          style: TextStyle(color: AppTheme.white),
                        ),
                      ),
                    ),
                    if (sub.purchaseInProgress) ...[
                      const SizedBox(height: 12),
                      const Center(
                        child: CircularProgressIndicator(color: AppTheme.primary),
                      ),
                    ],
                    if (sub.lastError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        sub.lastError!,
                        style: const TextStyle(color: Colors.orangeAccent),
                      ),
                    ],
                    if (!sub.revenueCatReady) ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Set RevenueCat API keys in AppConstants to enable purchases.',
                        style: TextStyle(color: AppTheme.grey),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: AppTheme.radiusLg,
        boxShadow: AppTheme.glowShadow(AppTheme.primary),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'FootAI Pro',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Unlimited live unlocks, no ads, faster access to premium AI insights.',
            style: TextStyle(color: Colors.white70, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _featureComparison() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: AppTheme.radiusLg,
      ),
      child: const Column(
        children: [
          _FeatureRow(
            title: 'Daily free live unlocks',
            freeValue: '1/day',
            proValue: 'Unlimited',
          ),
          SizedBox(height: 10),
          _FeatureRow(
            title: 'Rewarded ads required',
            freeValue: 'Yes',
            proValue: 'No',
          ),
          SizedBox(height: 10),
          _FeatureRow(
            title: 'Access to live AI insights',
            freeValue: 'Limited',
            proValue: 'Priority',
          ),
        ],
      ),
    );
  }

  Widget _planButton({
    required String title,
    required String subtitle,
    bool highlighted = false,
    required VoidCallback? onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: highlighted ? AppTheme.gold : AppTheme.primary,
          foregroundColor: highlighted ? Colors.black87 : Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: highlighted ? Colors.black54 : Colors.white70,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String title;
  final String freeValue;
  final String proValue;

  const _FeatureRow({
    required this.title,
    required this.freeValue,
    required this.proValue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: Text(
            title,
            style: const TextStyle(color: AppTheme.greyLight),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            freeValue,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppTheme.grey),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            proValue,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}
