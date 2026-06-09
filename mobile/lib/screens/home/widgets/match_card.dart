/// Match Card — displays a single match with team logos, score, and status

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/theme.dart';
import '../../../config/app_strings.dart';
import '../../../models/match.dart';

class MatchCard extends StatelessWidget {
  final MatchModel match;

  const MatchCard({super.key, required this.match});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _onTap(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: AppTheme.radiusMd,
          border: match.isLive
              ? Border.all(color: AppTheme.live.withValues(alpha: 0.4), width: 1)
              : null,
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          children: [
            // Status row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStatus(),
                if (match.isLive) ...[
                  const SizedBox(width: 8),
                  _buildLiveBadge(),
                ],
              ],
            ),
            const SizedBox(height: 12),
            // Teams row
            Row(
              children: [
                // Home team
                Expanded(child: _buildTeam(match.homeTeam, match.homeLogo, true)),
                // Score or time
                _buildCenter(),
                // Away team
                Expanded(child: _buildTeam(match.awayTeam, match.awayLogo, false)),
              ],
            ),
            // AI insights badge for live matches (free for everyone)
            if (match.isLive) ...[
              const SizedBox(height: 10),
              _buildInsightsBadge(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatus() {
    if (match.isFinished) {
      return Text(
        tr('match.ft'),
        style: const TextStyle(color: AppTheme.grey, fontSize: 12),
      );
    }
    if (match.isLive) {
      return Text(
        '${match.elapsed}\'',
        style: const TextStyle(
          color: AppTheme.live,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      );
    }
    // Not started — show kick-off time
    return Text(
      _formatTime(match.kickOff),
      style: const TextStyle(color: AppTheme.grey, fontSize: 12),
    );
  }

  Widget _buildLiveBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.live.withValues(alpha: 0.15),
        borderRadius: AppTheme.radiusSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppTheme.live,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            tr('match.live'),
            style: const TextStyle(
              color: AppTheme.live,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeam(String name, String logo, bool isHome) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: logo.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: logo,
                  width: 40,
                  height: 40,
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.shield, size: 36, color: AppTheme.grey),
                )
              : const Icon(Icons.shield, size: 36, color: AppTheme.grey),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppTheme.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCenter() {
    if (match.isNotStarted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Text(
          tr('match.vs'),
          style: const TextStyle(
            color: AppTheme.grey,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: AppTheme.radiusSm,
      ),
      child: Text(
        '${match.scoreHome} - ${match.scoreAway}',
        style: const TextStyle(
          color: AppTheme.white,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildInsightsBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.15),
        borderRadius: AppTheme.radiusSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.insights, size: 14, color: AppTheme.primary),
          const SizedBox(width: 6),
          Text(
            tr('match.aiAvailable'),
            style: const TextStyle(
                color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  void _onTap(BuildContext context) {
    Navigator.pushNamed(context, '/match', arguments: match);
  }

  String _formatTime(String isoDate) {
    try {
      // Always show kick-off in Turkey time (UTC+3, no DST) regardless of the
      // device's timezone. The backend stores times in UTC; treat the value as
      // UTC even if the explicit marker is missing, then add Turkey's offset.
      final hasTz =
          isoDate.endsWith('Z') || RegExp(r'[+-]\d\d:?\d\d$').hasMatch(isoDate);
      final utc = DateTime.parse(hasTz ? isoDate : '${isoDate}Z').toUtc();
      final tr = utc.add(const Duration(hours: 3));
      return '${tr.hour.toString().padLeft(2, '0')}:${tr.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '--:--';
    }
  }
}
