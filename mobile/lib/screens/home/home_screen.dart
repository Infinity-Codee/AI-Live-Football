/// Home Screen — Today's matches grouped by league

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../config/theme.dart';
import '../../config/app_strings.dart';
import '../../providers/matches_provider.dart';
import 'widgets/league_section.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MatchesProvider>().fetchTodayMatches();
    });

    // Auto-refresh the dashboard every 5 minutes
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      if (mounted) {
        context.read<MatchesProvider>().fetchTodayMatches();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleController>(); // rebuild on language switch
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.darkGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildDemoBanner(),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          // Logo
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: AppTheme.radiusMd,
            ),
            child: const Icon(Icons.sports_soccer, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FootAI Insight',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Consumer<MatchesProvider>(
                builder: (_, mp, __) => Text(
                  '${mp.totalMatches} ${tr('home.matchesToday')} • ${mp.liveMatches} ${tr('home.live')}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primary,
                      ),
                ),
              ),
            ],
          ),
          const Spacer(),
          // Language toggle (EN / TR)
          GestureDetector(
            onTap: () => LocaleController.instance.toggle(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: AppTheme.radiusXl,
                border: Border.all(
                  color: AppTheme.primary.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.language, color: AppTheme.primary, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    LocaleController.instance.isTurkish ? 'TR' : 'EN',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoBanner() {
    return Consumer<MatchesProvider>(
      builder: (_, mp, __) {
        if (!mp.demo) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.gold.withValues(alpha: 0.15),
            borderRadius: AppTheme.radiusSm,
            border: Border.all(color: AppTheme.gold.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppTheme.gold, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  tr('home.demoBanner'),
                  style: const TextStyle(
                    color: AppTheme.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    return Consumer<MatchesProvider>(
      builder: (_, provider, __) {
        if (provider.isLoading) {
          return _buildShimmer();
        }

        if (provider.error != null && provider.leagues.isEmpty) {
          return _buildError(provider);
        }

        if (provider.leagues.isEmpty) {
          return _buildEmpty();
        }

        return RefreshIndicator(
          color: AppTheme.primary,
          backgroundColor: AppTheme.bgCard,
          onRefresh: () => provider.fetchTodayMatches(),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            itemCount: provider.leagues.length,
            itemBuilder: (context, index) {
              final league = provider.leagues[index];
              return LeagueSection(league: league);
            },
          ),
        );
      },
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppTheme.bgCard,
      highlightColor: AppTheme.bgSurface,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          height: 100,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: AppTheme.radiusMd,
          ),
        ),
      ),
    );
  }

  Widget _buildError(MatchesProvider provider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off, size: 64, color: AppTheme.grey),
          const SizedBox(height: 16),
          Text(
            tr('home.errorTitle'),
            style: const TextStyle(color: AppTheme.grey, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            tr('home.errorSub'),
            style: TextStyle(color: AppTheme.grey.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => provider.fetchTodayMatches(),
            icon: const Icon(Icons.refresh),
            label: Text(tr('home.retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.sports_soccer, size: 64, color: AppTheme.grey),
          const SizedBox(height: 16),
          Text(
            tr('home.emptyTitle'),
            style: const TextStyle(color: AppTheme.grey, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            tr('home.emptySub'),
            style: TextStyle(color: AppTheme.grey.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }
}
