/// Stats Comparison — visual bars comparing match statistics

import 'package:flutter/material.dart';
import '../../../config/theme.dart';

class StatsComparison extends StatelessWidget {
  final Map<String, dynamic> stats;

  const StatsComparison({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: AppTheme.radiusLg,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          _buildStatRow(
            'Shots',
            stats['shots_home'] ?? 0,
            stats['shots_away'] ?? 0,
          ),
          const SizedBox(height: 16),
          _buildStatRow(
            'Corners',
            stats['corners_home'] ?? 0,
            stats['corners_away'] ?? 0,
          ),
          const SizedBox(height: 16),
          _buildExtraRow('Ball Possession', 'possession', isPercent: true),
          const SizedBox(height: 16),
          _buildExtraRow('Fouls', 'fouls'),
          const SizedBox(height: 16),
          _buildExtraRow('Yellow Cards', 'yellow_cards', isYellowCard: true),
          const SizedBox(height: 16),
          _buildExtraRow('Offsides', 'offsides'),
          const SizedBox(height: 16),
          _buildStatRow(
            'Red Cards',
            stats['red_cards_home'] ?? 0,
            stats['red_cards_away'] ?? 0,
            isRedCard: true,
          ),
        ],
      ),
    );
  }

  Widget _buildExtraRow(String label, String key, {bool isPercent = false, bool isYellowCard = false}) {
    final extra = stats['extra'] as Map<String, dynamic>? ?? {};
    final homeData = extra['home'] as Map<String, dynamic>? ?? {};
    final awayData = extra['away'] as Map<String, dynamic>? ?? {};

    int homeVal = 0;
    int awayVal = 0;
    String homeStr = isPercent ? "0%" : "0";
    String awayStr = isPercent ? "0%" : "0";

    if (isPercent) {
      homeStr = homeData[key]?.toString() ?? "0%";
      awayStr = awayData[key]?.toString() ?? "0%";
      homeVal = int.tryParse(homeStr.replaceAll('%', '')) ?? 0;
      awayVal = int.tryParse(awayStr.replaceAll('%', '')) ?? 0;
    } else {
      homeVal = (homeData[key] is int) ? homeData[key] : (int.tryParse(homeData[key]?.toString() ?? '0') ?? 0);
      awayVal = (awayData[key] is int) ? awayData[key] : (int.tryParse(awayData[key]?.toString() ?? '0') ?? 0);
      homeStr = homeVal.toString();
      awayStr = awayVal.toString();
    }

    final total = (homeVal + awayVal).clamp(1, 999);
    final homeRatio = homeVal / total;
    final awayRatio = awayVal / total;

    return _buildCustomRow(label, homeStr, awayStr, homeRatio, awayRatio, isYellowCard: isYellowCard);
  }

  Widget _buildCustomRow(String label, String homeStr, String awayStr, double homeRatio, double awayRatio, {bool isYellowCard = false, bool isRedCard = false}) {
    return Column(
      children: [
        // Values
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              homeStr,
              style: TextStyle(
                color: isRedCard ? AppTheme.red : (isYellowCard ? Colors.amber : AppTheme.white),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              label,
              style: const TextStyle(color: AppTheme.grey, fontSize: 13),
            ),
            Text(
              awayStr,
              style: TextStyle(
                color: isRedCard ? AppTheme.red : (isYellowCard ? Colors.amber : AppTheme.white),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        // Bars
        Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerRight,
                child: FractionallySizedBox(
                  widthFactor: homeRatio,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: isRedCard ? AppTheme.red : (isYellowCard ? Colors.amber : AppTheme.homeWin),
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(3)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: awayRatio,
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: isRedCard ? AppTheme.red : (isYellowCard ? Colors.amber : AppTheme.awayWin),
                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(3)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, int home, int away, {bool isRedCard = false}) {
    final total = (home + away).clamp(1, 999);
    final homeRatio = home / total;
    final awayRatio = away / total;
    return _buildCustomRow(label, home.toString(), away.toString(), homeRatio, awayRatio, isRedCard: isRedCard);
  }
}
