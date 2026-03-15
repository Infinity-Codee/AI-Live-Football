/// Probability Gauge — circular gauge showing Home / Draw / Away probabilities

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_gauges/gauges.dart';
import '../../../config/theme.dart';
import '../../../models/prediction.dart';

class ProbabilityGauge extends StatelessWidget {
  final PredictionModel prediction;
  final String homeLogo;
  final String awayLogo;

  const ProbabilityGauge({
    super.key,
    required this.prediction,
    this.homeLogo = '',
    this.awayLogo = '',
  });

  @override
  Widget build(BuildContext context) {
    final h = prediction.homeWinProb * 100;
    final d = prediction.drawProb * 100;
    final a = prediction.awayWinProb * 100;

    // Find the leading outcome
    String leader;
    String leaderLogo;
    Color leaderColor;
    double leaderValue;
    if (h >= d && h >= a) {
      leader = prediction.homeTeam.isNotEmpty ? prediction.homeTeam : 'Home';
      leaderLogo = homeLogo;
      leaderColor = AppTheme.homeWin;
      leaderValue = h;
    } else if (a >= h && a >= d) {
      leader = prediction.awayTeam.isNotEmpty ? prediction.awayTeam : 'Away';
      leaderLogo = awayLogo;
      leaderColor = AppTheme.awayWin;
      leaderValue = a;
    } else {
      leader = 'Draw';
      leaderLogo = '';
      leaderColor = AppTheme.draw;
      leaderValue = d;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: AppTheme.radiusLg,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // Gauge
          SizedBox(
            height: 220,
            child: SfRadialGauge(
              axes: <RadialAxis>[
                RadialAxis(
                  startAngle: 180,
                  endAngle: 0,
                  minimum: 0,
                  maximum: 100,
                  showLabels: false,
                  showTicks: false,
                  axisLineStyle: const AxisLineStyle(
                    thickness: 20,
                    color: AppTheme.bgSurface,
                    cornerStyle: CornerStyle.bothCurve,
                  ),
                  ranges: <GaugeRange>[
                    GaugeRange(
                      startValue: 0,
                      endValue: h,
                      color: AppTheme.homeWin,
                      startWidth: 20,
                      endWidth: 20,
                    ),
                    GaugeRange(
                      startValue: h,
                      endValue: h + d,
                      color: AppTheme.draw,
                      startWidth: 20,
                      endWidth: 20,
                    ),
                    GaugeRange(
                      startValue: h + d,
                      endValue: 100,
                      color: AppTheme.awayWin,
                      startWidth: 20,
                      endWidth: 20,
                    ),
                  ],
                  annotations: <GaugeAnnotation>[
                    GaugeAnnotation(
                      widget: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildLeaderLogo(leaderLogo),
                          const SizedBox(height: 8),
                          Text(
                            '${leaderValue.toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: leaderColor,
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            leader,
                            style: const TextStyle(
                              color: AppTheme.greyLight,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      positionFactor: 0.6,
                      angle: 90,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Probability bars
          Row(
            children: [
              _buildProbLabel(
                prediction.homeTeam.isNotEmpty ? prediction.homeTeam : 'Home',
                prediction.homePercent,
                AppTheme.homeWin,
                logoUrl: homeLogo,
              ),
              const SizedBox(width: 8),
              _buildProbLabel(
                'Draw',
                prediction.drawPercent,
                AppTheme.draw,
              ),
              const SizedBox(width: 8),
              _buildProbLabel(
                prediction.awayTeam.isNotEmpty ? prediction.awayTeam : 'Away',
                prediction.awayPercent,
                AppTheme.awayWin,
                logoUrl: awayLogo,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProbLabel(
    String label,
    String percent,
    Color color, {
    String logoUrl = '',
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: AppTheme.radiusSm,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              percent,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (logoUrl.isNotEmpty) ...[
                  _buildSmallLogo(logoUrl),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppTheme.grey,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderLogo(String logoUrl) {
    if (logoUrl.isEmpty) {
      return Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          shape: BoxShape.circle,
          border: Border.all(color: AppTheme.grey.withValues(alpha: 0.2)),
        ),
        child: const Icon(Icons.shield, color: AppTheme.grey),
      );
    }
    return Container(
      width: 54,
      height: 54,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.grey.withValues(alpha: 0.2)),
      ),
      child: CachedNetworkImage(
        imageUrl: logoUrl,
        fit: BoxFit.contain,
        errorWidget: (_, __, ___) => const Icon(Icons.shield, color: AppTheme.grey),
      ),
    );
  }

  Widget _buildSmallLogo(String logoUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: CachedNetworkImage(
        imageUrl: logoUrl,
        width: 18,
        height: 18,
        fit: BoxFit.contain,
        errorWidget: (_, __, ___) =>
            const Icon(Icons.shield, size: 14, color: AppTheme.grey),
      ),
    );
  }
}
