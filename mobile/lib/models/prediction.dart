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
