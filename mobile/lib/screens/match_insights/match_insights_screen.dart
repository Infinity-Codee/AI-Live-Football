/// Match Insights Screen — core prediction experience.

import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/match.dart';
import '../../providers/prediction_provider.dart';
import '../../providers/subscription_provider.dart';
import '../../providers/wallet_provider.dart';
import '../../services/analytics_service.dart';
import 'widgets/momentum_chart.dart';
import 'widgets/probability_gauge.dart';
import 'widgets/stats_comparison.dart';

class MatchInsightsScreen extends StatefulWidget {
  final MatchModel match;

  const MatchInsightsScreen({super.key, required this.match});

  @override
  State<MatchInsightsScreen> createState() => _MatchInsightsScreenState();
}

class _MatchInsightsScreenState extends State<MatchInsightsScreen> {
  bool _unlocked = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  void _checkAccess() {
    final wallet = context.read<WalletProvider>();
    final sub = context.read<SubscriptionProvider>();

    _unlocked = sub.isPro ||
        wallet.isMatchUnlocked(widget.match.id) ||
        widget.match.isFinished;

    if (_unlocked) {
      if (sub.isPro) {
        AnalyticsService().track(
          'pro_feature_used',
          properties: {'match_id': widget.match.id},
        );
      }
      if (widget.match.isNotStarted) {
        context.read<PredictionProvider>().fetchPreMatch(widget.match.id);
      } else {
        context.read<PredictionProvider>().fetchLivePrediction(widget.match.id);
      }
      _startRefreshTimer();
    }
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    if (widget.match.isLive && _unlocked) {
      _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
        if (mounted) {
          context.read<PredictionProvider>().fetchLivePrediction(widget.match.id);
        }
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _unlock() async {
    final wallet = context.read<WalletProvider>();
    final sub = context.read<SubscriptionProvider>();
    final analytics = AnalyticsService();

    // Pro users always have full access.
    if (sub.isPro) {
      wallet.unlockMatchLocally(widget.match.id);
      setState(() => _unlocked = true);
      if (widget.match.isNotStarted) {
        context.read<PredictionProvider>().fetchPreMatch(widget.match.id);
      } else {
        context.read<PredictionProvider>().fetchLivePrediction(widget.match.id);
      }
      _startRefreshTimer();
      await analytics.track(
        'pro_feature_used',
        properties: {'match_id': widget.match.id},
      );
      return;
    }

    // Free users must watch a rewarded video to unlock analysis.
    final earned = await wallet.watchAdForCredit();
    if (!earned) {
      _showSnackbar('Watch a video ad to unlock analysis, or upgrade to Pro.');
      return;
    }

    final success = await wallet.unlockMatch(widget.match.id);
    if (success) {
      setState(() => _unlocked = true);
      if (widget.match.isNotStarted) {
        context.read<PredictionProvider>().fetchPreMatch(widget.match.id);
      } else {
        context.read<PredictionProvider>().fetchLivePrediction(widget.match.id);
      }
      _startRefreshTimer();
      await analytics.track(
        'match_unlock_success',
        properties: {'match_id': widget.match.id, 'source': 'rewarded_video'},
      );
      return;
    }

    _showSnackbar('Could not unlock match right now.');
  }

  void _showSnackbar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildMatchHeader(),
                      const SizedBox(height: 20),
                      if (_unlocked)
                        _buildPredictionContent()
                      else
                        _buildLockedContent(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: AppTheme.white),
            onPressed: () => Navigator.pop(context),
          ),
          const Expanded(
            child: Text(
              'Match Insights',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_unlocked && widget.match.isLive)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppTheme.primary),
              onPressed: () => context
                  .read<PredictionProvider>()
                  .fetchLivePrediction(widget.match.id),
            )
          else
            const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildMatchHeader() {
    return Consumer<PredictionProvider>(
      builder: (_, provider, __) {
        final pred = provider.current;
        final elapsed = pred?.minute ?? widget.match.elapsed;
        final score = pred != null && pred.score.isNotEmpty
            ? pred.score
            : '${widget.match.scoreHome} - ${widget.match.scoreAway}';

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: AppTheme.radiusLg,
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            children: [
              if (widget.match.isLive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.live.withValues(alpha: 0.15),
                    borderRadius: AppTheme.radiusSm,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppTheme.live,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'LIVE  $elapsed\'',
                        style: const TextStyle(
                          color: AppTheme.live,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: _buildTeamHeader(
                      widget.match.homeTeam,
                      widget.match.homeLogo,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.bgSurface,
                      borderRadius: AppTheme.radiusMd,
                    ),
                    child: Text(
                      widget.match.isNotStarted ? 'VS' : score,
                      style: const TextStyle(
                        color: AppTheme.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: _buildTeamHeader(
                      widget.match.awayTeam,
                      widget.match.awayLogo,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPredictionContent() {
    return Consumer<PredictionProvider>(
      builder: (_, provider, __) {
        if (provider.isLoading) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: CircularProgressIndicator(color: AppTheme.primary),
          );
        }

        if (provider.current == null) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Text(
              'No prediction available',
              style: TextStyle(color: AppTheme.grey),
            ),
          );
        }

        final pred = provider.current!;
        return Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.15),
                borderRadius: AppTheme.radiusSm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.psychology, size: 16, color: AppTheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    pred.type == 'pre_match'
                        ? 'Pre-Match Analysis'
                        : 'Live AI Prediction',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ProbabilityGauge(
              prediction: pred,
              homeLogo: widget.match.homeLogo,
              awayLogo: widget.match.awayLogo,
            ),
            const SizedBox(height: 24),
            if (provider.history.isNotEmpty) ...[
              _buildSectionTitle('Momentum Timeline'),
              const SizedBox(height: 12),
              MomentumChart(history: provider.history),
              const SizedBox(height: 24),
            ],
            if (pred.stats != null) ...[
              _buildSectionTitle('Match Statistics'),
              const SizedBox(height: 12),
              StatsComparison(stats: pred.stats!),
            ],
          ],
        );
      },
    );
  }

  Widget _buildLockedContent() {
    return Consumer2<WalletProvider, SubscriptionProvider>(
      builder: (_, wallet, sub, __) {
        const buttonLabel = 'Watch Video to Unlock Analysis';

        return Container(
          margin: const EdgeInsets.only(top: 20),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: AppTheme.radiusLg,
            border: Border.all(color: AppTheme.gold.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: AppTheme.goldGradient,
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.glowShadow(AppTheme.gold),
                ),
                child: const Icon(Icons.lock, size: 36, color: Colors.black87),
              ),
              const SizedBox(height: 18),
              const Text(
                'Unlock AI Predictions',
                style: TextStyle(
                  color: AppTheme.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                sub.isPro
                    ? 'Pro users can view all analyses without ads.'
                    : 'Watch a rewarded video ad to view this analysis.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.grey, height: 1.4),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.toll, color: AppTheme.gold, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '${wallet.credits} credits',
                    style: const TextStyle(color: AppTheme.greyLight),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _unlock,
                  icon: const Icon(Icons.lock_open),
                  label: Text(buttonLabel),
                ),
              ),
              if (!sub.isPro) ...[
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/paywall'),
                  child: const Text('Go Pro: unlimited unlocks, no ads'),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildTeamHeader(String name, String logoUrl) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.bgSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.grey.withValues(alpha: 0.2)),
          ),
          child: logoUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: logoUrl,
                  fit: BoxFit.contain,
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.shield, color: AppTheme.grey),
                )
              : const Icon(Icons.shield, color: AppTheme.grey),
        ),
        const SizedBox(height: 10),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
