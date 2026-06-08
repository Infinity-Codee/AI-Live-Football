/// Data model for AI prediction result.

class PredictionModel {
  final int matchId;
  final String type; // "pre_match" or "live"
  final int minute;
  final double homeWinProb;
  final double drawProb;
  final double awayWinProb;
  final String homeTeam;
  final String awayTeam;
  final String score;
  final Map<String, dynamic>? stats;

  PredictionModel({
    required this.matchId,
    this.type = 'live',
    this.minute = 0,
    this.homeWinProb = 0.33,
    this.drawProb = 0.34,
    this.awayWinProb = 0.33,
    this.homeTeam = '',
    this.awayTeam = '',
    this.score = '0 - 0',
    this.stats,
  });

  factory PredictionModel.fromJson(Map<String, dynamic> json) {
    return PredictionModel(
      matchId: json['match_id'] ?? 0,
      type: json['type'] ?? 'live',
      minute: json['minute'] ?? 0,
      homeWinProb: (json['home_win_prob'] ?? 0.33).toDouble(),
      drawProb: (json['draw_prob'] ?? 0.34).toDouble(),
      awayWinProb: (json['away_win_prob'] ?? 0.33).toDouble(),
      homeTeam: json['home_team'] ?? '',
      awayTeam: json['away_team'] ?? '',
      score: json['score'] ?? '0 - 0',
      stats: json['stats'],
    );
  }

  /// Percentage strings for display
  String get homePercent => '${(homeWinProb * 100).toStringAsFixed(1)}%';
  String get drawPercent => '${(drawProb * 100).toStringAsFixed(1)}%';
  String get awayPercent => '${(awayWinProb * 100).toStringAsFixed(1)}%';

  /// True only when the data source actually provided match stats. Many
  /// friendlies / lower-tier matches have no coverage (all zeros), so we hide
  /// the stats section in that case instead of showing an empty all-zero panel.
  bool get hasStatsData {
    final s = stats;
    if (s == null) return false;
    const keys = [
      'shots_home', 'shots_away', 'corners_home', 'corners_away',
      'red_cards_home', 'red_cards_away',
    ];
    final anyCore = keys.any((k) => ((s[k] ?? 0) as num) > 0);
    final extra = s['extra'];
    final anyExtra = extra is Map && extra.isNotEmpty;
    return anyCore || anyExtra;
  }
}

/// A single point in the momentum timeline.
class MomentumPoint {
  final int minute;
  final double homeWinProb;
  final double drawProb;
  final double awayWinProb;

  MomentumPoint({
    required this.minute,
    required this.homeWinProb,
    required this.drawProb,
    required this.awayWinProb,
  });

  factory MomentumPoint.fromJson(Map<String, dynamic> json) {
    return MomentumPoint(
      minute: json['minute'] ?? 0,
      homeWinProb: (json['home_win_prob'] ?? 0).toDouble(),
      drawProb: (json['draw_prob'] ?? 0).toDouble(),
      awayWinProb: (json['away_win_prob'] ?? 0).toDouble(),
    );
  }
}
