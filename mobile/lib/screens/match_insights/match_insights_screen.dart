/// Match Insights Screen — core prediction experience.

import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../config/app_strings.dart';
import '../../models/match.dart';
import '../../providers/prediction_provider.dart';
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
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Defer until after the first frame so provider notifyListeners() calls
    // don't fire during build (avoids "setState() called during build").
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkAccess();
    });
  }

  void _checkAccess() {
    // All predictions are free — load immediately, no unlock required.
    if (widget.match.isNotStarted) {
      context.read<PredictionProvider>().fetchPreMatch(widget.match.id);
    } else {
      context.read<PredictionProvider>().fetchLivePrediction(widget.match.id);
    }
    _startRefreshTimer();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    if (widget.match.isLive) {
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
                      _buildPredictionContent(),
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
          Expanded(
            child: Text(
              tr('insights.title'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppTheme.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (widget.match.isLive)
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
                        '${tr('match.live')}  $elapsed\'',
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
                      widget.match.isNotStarted ? tr('match.vs') : score,
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
          return Padding(
            padding: const EdgeInsets.all(40),
            child: Text(
              tr('insights.noPrediction'),
              style: const TextStyle(color: AppTheme.grey),
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
                        ? tr('insights.preMatch')
                        : tr('insights.liveAi'),
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
              _buildSectionTitle(tr('insights.momentum')),
              const SizedBox(height: 12),
              MomentumChart(history: provider.history),
              const SizedBox(height: 24),
            ],
            if (pred.stats != null) ...[
              _buildSectionTitle(tr('insights.statistics')),
              const SizedBox(height: 12),
              StatsComparison(stats: pred.stats!),
            ],
          ],
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
