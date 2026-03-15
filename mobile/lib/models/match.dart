/// Data model for a football match.

class MatchModel {
  final int id;
  final int fixtureId;
  final String leagueName;
  final int leagueId;
  final String leagueLogo;
  final String country;
  final String homeTeam;
  final String awayTeam;
  final String homeLogo;
  final String awayLogo;
  final String status;
  final int elapsed;
  final int scoreHome;
  final int scoreAway;
  final String kickOff;
  final double oddHome;
  final double oddDraw;
  final double oddAway;
  final int tournamentType;
  final bool isLive;

  MatchModel({
    required this.id,
    required this.fixtureId,
    this.leagueName = '',
    this.leagueId = 0,
    this.leagueLogo = '',
    this.country = '',
    this.homeTeam = '',
    this.awayTeam = '',
    this.homeLogo = '',
    this.awayLogo = '',
    this.status = 'NS',
    this.elapsed = 0,
    this.scoreHome = 0,
    this.scoreAway = 0,
    this.kickOff = '',
    this.oddHome = 0,
    this.oddDraw = 0,
    this.oddAway = 0,
    this.tournamentType = 0,
    this.isLive = false,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'] ?? 0,
      fixtureId: json['fixture_id'] ?? 0,
      leagueName: json['league_name'] ?? '',
      leagueId: json['league_id'] ?? 0,
      leagueLogo: json['league_logo'] ?? '',
      country: json['country'] ?? '',
      homeTeam: json['home_team'] ?? '',
      awayTeam: json['away_team'] ?? '',
      homeLogo: json['home_logo'] ?? '',
      awayLogo: json['away_logo'] ?? '',
      status: json['status'] ?? 'NS',
      elapsed: json['elapsed'] ?? 0,
      scoreHome: json['score_home'] ?? 0,
      scoreAway: json['score_away'] ?? 0,
      kickOff: json['kick_off'] ?? '',
      oddHome: (json['odd_home'] ?? 0).toDouble(),
      oddDraw: (json['odd_draw'] ?? 0).toDouble(),
      oddAway: (json['odd_away'] ?? 0).toDouble(),
      tournamentType: json['tournament_type'] ?? 0,
      isLive: json['is_live'] ?? false,
    );
  }

  bool get isNotStarted => status == 'NS' || status == 'TBD';
  bool get isFinished => status == 'FT' || status == 'AET' || status == 'PEN';
}

/// A group of matches under one league.
class LeagueGroup {
  final String leagueName;
  final String leagueLogo;
  final String country;
  final List<MatchModel> matches;

  LeagueGroup({
    required this.leagueName,
    this.leagueLogo = '',
    this.country = '',
    required this.matches,
  });

  factory LeagueGroup.fromJson(Map<String, dynamic> json) {
    return LeagueGroup(
      leagueName: json['league_name'] ?? '',
      leagueLogo: json['league_logo'] ?? '',
      country: json['country'] ?? '',
      matches: (json['matches'] as List? ?? [])
          .map((m) => MatchModel.fromJson(m))
          .toList(),
    );
  }
}
