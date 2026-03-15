/// Momentum Chart — line chart showing prediction history over time

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../config/theme.dart';
import '../../../models/prediction.dart';

class MomentumChart extends StatelessWidget {
  final List<MomentumPoint> history;

  const MomentumChart({super.key, required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: AppTheme.radiusLg,
        boxShadow: AppTheme.cardShadow,
      ),
      child: Column(
        children: [
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot('Home Win', AppTheme.homeWin),
              const SizedBox(width: 16),
              _legendDot('Draw', AppTheme.draw),
              const SizedBox(width: 16),
              _legendDot('Away Win', AppTheme.awayWin),
            ],
          ),
          const SizedBox(height: 16),
          // Chart
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppTheme.bgSurface,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 25,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}%',
                        style: const TextStyle(
                          color: AppTheme.grey,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval: _getInterval(),
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}\'',
                        style: const TextStyle(
                          color: AppTheme.grey,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 90,
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  // Home win line
                  _buildLine(
                    history.map((p) => FlSpot(p.minute.toDouble(), p.homeWinProb * 100)).toList(),
                    AppTheme.homeWin,
                  ),
                  // Draw line
                  _buildLine(
                    history.map((p) => FlSpot(p.minute.toDouble(), p.drawProb * 100)).toList(),
                    AppTheme.draw,
                  ),
                  // Away win line
                  _buildLine(
                    history.map((p) => FlSpot(p.minute.toDouble(), p.awayWinProb * 100)).toList(),
                    AppTheme.awayWin,
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppTheme.bgSurface,
                    getTooltipItems: (spots) => spots.map((s) {
                      final color = s.bar.color ?? AppTheme.grey;
                      return LineTooltipItem(
                        '${s.y.toStringAsFixed(1)}%',
                        TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  LineChartBarData _buildLine(List<FlSpot> spots, Color color) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      color: color,
      barWidth: 2.5,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
          radius: index == spots.length - 1 ? 4 : 2,
          color: color,
          strokeWidth: 0,
        ),
      ),
      belowBarData: BarAreaData(
        show: true,
        color: color.withValues(alpha: 0.08),
      ),
    );
  }

  double _getInterval() {
    if (history.length <= 5) return 15;
    if (history.length <= 10) return 10;
    return 15;
  }

  Widget _legendDot(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: AppTheme.grey, fontSize: 11)),
      ],
    );
  }
}
