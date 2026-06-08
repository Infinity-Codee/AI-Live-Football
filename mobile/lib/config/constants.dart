/// App-wide constants

class AppConstants {
  /// Backend base URL. Defaults to the deployed cloud server so the app works
  /// anywhere out of the box (and a stray build can never point at localhost).
  /// For local development, override at build time:
  ///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
  static const String _cloudBaseUrl =
      'https://footai-backend-tuymd.ondigitalocean.app/api';

  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL');
    if (override.isNotEmpty) return override;
    return _cloudBaseUrl;
  }

  // Cache/refresh intervals
  static const int refreshIntervalSeconds = 300; // 5 minutes

  // Popular league IDs (API-Football)
  static const Map<int, Map<String, String>> popularLeagues = {
    39: {'name': 'Premier League', 'logo': 'https://media.api-sports.io/football/leagues/39.png'},
    307: {'name': 'Roshn Saudi League', 'logo': 'https://media.api-sports.io/football/leagues/307.png'},
    140: {'name': 'La Liga', 'logo': 'https://media.api-sports.io/football/leagues/140.png'},
    203: {'name': 'Süper Lig', 'logo': 'https://media.api-sports.io/football/leagues/203.png'},
    135: {'name': 'Serie A', 'logo': 'https://media.api-sports.io/football/leagues/135.png'},
    78: {'name': 'Bundesliga', 'logo': 'https://media.api-sports.io/football/leagues/78.png'},
    61: {'name': 'Ligue 1', 'logo': 'https://media.api-sports.io/football/leagues/61.png'},
    2: {'name': 'Champions League', 'logo': 'https://media.api-sports.io/football/leagues/2.png'},
    3: {'name': 'Europa League', 'logo': 'https://media.api-sports.io/football/leagues/3.png'},
  };
}
