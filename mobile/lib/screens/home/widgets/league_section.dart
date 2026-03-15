/// League section header + match cards list

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/theme.dart';
import '../../../models/match.dart';
import 'match_card.dart';

class LeagueSection extends StatelessWidget {
  final LeagueGroup league;

  const LeagueSection({super.key, required this.league});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // League header
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
          child: Row(
            children: [
              if (league.leagueLogo.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: league.leagueLogo,
                    width: 24,
                    height: 24,
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.emoji_events, size: 20, color: AppTheme.gold),
                  ),
                ),
              if (league.leagueLogo.isNotEmpty) const SizedBox(width: 10),
              Expanded(
                child: Text(
                  league.leagueName,
                  style: const TextStyle(
                    color: AppTheme.greyLight,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.bgSurface,
                  borderRadius: AppTheme.radiusSm,
                ),
                child: Text(
                  league.country,
                  style: const TextStyle(
                    color: AppTheme.grey,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Match cards
        ...league.matches.map((match) => MatchCard(match: match)),
        const SizedBox(height: 8),
      ],
    );
  }
}
