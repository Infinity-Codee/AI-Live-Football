/// Lightweight localization: an English/Turkish string table plus a global
/// `tr()` lookup and a [LocaleController] that rebuilds the app on language
/// change. No code generation or extra packages required.

import 'package:flutter/widgets.dart';
import '../services/storage_service.dart';

/// Holds the current language ('en' | 'tr') and notifies listeners on change.
/// The whole app is wrapped in a ListenableBuilder on this controller, so a
/// language switch rebuilds every screen and `tr()` returns the new language.
class LocaleController extends ChangeNotifier {
  LocaleController._();
  static final LocaleController instance = LocaleController._();

  String _lang = 'en';
  String get lang => _lang;
  bool get isTurkish => _lang == 'tr';

  /// Load the saved language (call once at startup, after StorageService.init).
  void load() {
    _lang = StorageService().language;
  }

  void setLang(String lang) {
    if (lang == _lang) return;
    _lang = lang;
    StorageService().language = lang;
    notifyListeners();
  }

  void toggle() => setLang(_lang == 'en' ? 'tr' : 'en');
}

/// Translate [key] for the current language. Falls back to English, then [key].
String tr(String key) {
  final entry = AppStrings.map[key];
  if (entry == null) return key;
  return entry[LocaleController.instance.lang] ?? entry['en'] ?? key;
}

class AppStrings {
  static const Map<String, Map<String, String>> map = {
    // ── Splash ──────────────────────────────────────────
    'splash.tagline': {
      'en': 'AI-Powered Match Predictions',
      'tr': 'Yapay Zeka Destekli Maç Tahminleri',
    },

    // ── Onboarding ──────────────────────────────────────
    'onboarding.skip': {'en': 'Skip', 'tr': 'Atla'},
    'onboarding.next': {'en': 'Next', 'tr': 'İleri'},
    'onboarding.getStarted': {'en': 'Get Started', 'tr': 'Başla'},
    'onboarding.title1': {
      'en': 'AI-Powered Predictions',
      'tr': 'Yapay Zeka Tahminleri',
    },
    'onboarding.sub1': {
      'en': 'Our AI analyzes match momentum\nto predict outcomes in real time',
      'tr': 'Yapay zekamız maç momentumunu analiz ederek\nsonuçları anlık olarak tahmin eder',
    },
    'onboarding.title2': {
      'en': 'Real-Time Momentum',
      'tr': 'Anlık Momentum',
    },
    'onboarding.sub2': {
      'en': 'Watch win probabilities change\nas the match unfolds',
      'tr': 'Maç ilerledikçe kazanma olasılıklarının\ndeğişimini izleyin',
    },
    'onboarding.title3': {
      'en': 'Free for Everyone',
      'tr': 'Herkese Ücretsiz',
    },
    'onboarding.sub3': {
      'en': 'All live predictions and stats,\ncompletely free. No ads, no limits.',
      'tr': 'Tüm canlı tahminler ve istatistikler,\ntamamen ücretsiz. Reklam yok, sınır yok.',
    },

    // ── Bottom navigation ───────────────────────────────
    'nav.home': {'en': 'Home', 'tr': 'Ana Sayfa'},
    'nav.standings': {'en': 'Standings', 'tr': 'Puan Durumu'},

    // ── Home ────────────────────────────────────────────
    'home.matchesToday': {'en': 'matches today', 'tr': 'maç bugün'},
    'home.live': {'en': 'live', 'tr': 'canlı'},
    'home.demoBanner': {
      'en': 'Demo data — add an API key to see live scores',
      'tr': 'Demo veriler — canlı skorlar için API anahtarı ekleyin',
    },
    'home.errorTitle': {'en': 'Could not load matches', 'tr': 'Maçlar yüklenemedi'},
    'home.errorSub': {
      'en': 'Check your connection and try again',
      'tr': 'Bağlantınızı kontrol edip tekrar deneyin',
    },
    'home.retry': {'en': 'Retry', 'tr': 'Tekrar Dene'},
    'home.emptyTitle': {'en': 'No matches today', 'tr': 'Bugün maç yok'},
    'home.emptySub': {
      'en': 'Check back later for upcoming matches',
      'tr': 'Yaklaşan maçlar için daha sonra tekrar bakın',
    },

    // ── Match card / status ─────────────────────────────
    'match.vs': {'en': 'VS', 'tr': 'VS'},
    'match.live': {'en': 'LIVE', 'tr': 'CANLI'},
    'match.ft': {'en': 'Full Time', 'tr': 'Maç Sonu'},
    'match.upcoming': {'en': 'Upcoming', 'tr': 'Yaklaşan'},
    'match.aiAvailable': {'en': 'AI Insights', 'tr': 'Yapay Zeka Analizi'},
    'match.tapForInsights': {'en': 'Tap for AI analysis', 'tr': 'Yapay zeka analizi için dokun'},

    // ── Match insights ──────────────────────────────────
    'insights.title': {'en': 'Match Insights', 'tr': 'Maç Analizi'},
    'insights.preMatch': {'en': 'Pre-Match Analysis', 'tr': 'Maç Öncesi Analiz'},
    'insights.liveAi': {'en': 'Live AI Prediction', 'tr': 'Canlı Yapay Zeka Tahmini'},
    'insights.noPrediction': {'en': 'No prediction available', 'tr': 'Tahmin mevcut değil'},
    'insights.momentum': {'en': 'Momentum Timeline', 'tr': 'Momentum Zaman Çizelgesi'},
    'momentum.homeWin': {'en': 'Home Win', 'tr': 'Ev Sahibi'},
    'momentum.draw': {'en': 'Draw', 'tr': 'Beraberlik'},
    'momentum.awayWin': {'en': 'Away Win', 'tr': 'Deplasman'},
    'insights.momentumEmpty': {
      'en': 'Momentum builds as the match progresses',
      'tr': 'Momentum maç ilerledikçe oluşur',
    },
    'insights.statistics': {'en': 'Match Statistics', 'tr': 'Maç İstatistikleri'},
    'insights.aiAnalysis': {'en': 'AI Analysis', 'tr': 'Yapay Zeka Analizi'},
    'insights.aiLoading': {
      'en': 'Generating AI analysis...',
      'tr': 'Yapay zeka analizi oluşturuluyor...',
    },

    // ── Probability gauge ───────────────────────────────
    'gauge.home': {'en': 'HOME', 'tr': 'EV'},
    'gauge.draw': {'en': 'DRAW', 'tr': 'BERABERE'},
    'gauge.away': {'en': 'AWAY', 'tr': 'DEPLASMAN'},
    'gauge.winProb': {'en': 'Win Probability', 'tr': 'Kazanma Olasılığı'},

    // ── Stats comparison ────────────────────────────────
    'stats.shots': {'en': 'Shots', 'tr': 'Şutlar'},
    'stats.corners': {'en': 'Corners', 'tr': 'Kornerler'},
    'stats.redCards': {'en': 'Red Cards', 'tr': 'Kırmızı Kartlar'},
    'stats.possession': {'en': 'Possession', 'tr': 'Topa Sahip Olma'},
    'stats.fouls': {'en': 'Fouls', 'tr': 'Fauller'},
    'stats.yellowCards': {'en': 'Yellow Cards', 'tr': 'Sarı Kartlar'},
    'stats.offsides': {'en': 'Offsides', 'tr': 'Ofsaytlar'},

    // ── Standings ───────────────────────────────────────
    'standings.title': {'en': 'Standings', 'tr': 'Puan Durumu'},
    'standings.empty': {'en': 'No standings available', 'tr': 'Puan durumu mevcut değil'},
    'standings.error': {'en': 'Could not load standings', 'tr': 'Puan durumu yüklenemedi'},
    'standings.colTeam': {'en': 'Team', 'tr': 'Takım'},
    'standings.colP': {'en': 'P', 'tr': 'O'},
    'standings.colW': {'en': 'W', 'tr': 'G'},
    'standings.colD': {'en': 'D', 'tr': 'B'},
    'standings.colL': {'en': 'L', 'tr': 'M'},
    'standings.colPts': {'en': 'Pts', 'tr': 'P'},
  };
}
