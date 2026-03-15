/// App-wide constants

class AppConstants {
  // Change this to your actual backend URL
  // Use 10.0.2.2 for Android Emulator:
  // static const String baseUrl = 'http://10.0.2.2:8000/api';
  
  // Use localhost for iOS Simulator or macOS app:
  static const String baseUrl = 'http://localhost:8000/api';

  // RevenueCat (set your public SDK keys)
  static const String revenueCatAppleApiKey = '';
  static const String revenueCatGoogleApiKey = '';
  static const String proEntitlementId = 'pro';
  static const String proMonthlyProductId = 'pro_monthly';
  static const String proYearlyProductId = 'pro_yearly';

  // AdMob IDs (replace with your real IDs)
  static const String admobAppId = 'ca-app-pub-3940256099942544~3347511713'; // test
  static const String admobIosAppId = 'ca-app-pub-3940256099942544~1458002511'; // test
  static const String rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917'; // test
  static const String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111'; // test

  // Credit system
  static const int creditsPerAd = 1;
  static const int creditsPerMatch = 1;

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
