/// Local storage service using SharedPreferences.

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  static final StorageService _instance = StorageService._();
  factory StorageService() => _instance;
  StorageService._();

  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // ─── Device ID ─────────────────────────────────────
  String get deviceId {
    String? id = _prefs.getString('device_id');
    if (id == null) {
      id = const Uuid().v4();
      _prefs.setString('device_id', id);
    }
    return id;
  }

  // ─── Onboarding ────────────────────────────────────
  bool get hasSeenOnboarding => _prefs.getBool('onboarding_seen') ?? false;
  set hasSeenOnboarding(bool value) => _prefs.setBool('onboarding_seen', value);

  // ─── Subscription ──────────────────────────────────
  bool get isProUser => _prefs.getBool('is_pro_user') ?? false;
  set isProUser(bool value) => _prefs.setBool('is_pro_user', value);

  int get dailyFreeUnlocksUsed => _prefs.getInt('daily_free_unlocks_used') ?? 0;
  set dailyFreeUnlocksUsed(int value) =>
      _prefs.setInt('daily_free_unlocks_used', value);

  String? get dailyFreeUnlockDate => _prefs.getString('daily_free_unlock_date');
  set dailyFreeUnlockDate(String? value) {
    if (value == null) {
      _prefs.remove('daily_free_unlock_date');
      return;
    }
    _prefs.setString('daily_free_unlock_date', value);
  }

  // ─── Unlocked matches (local quick check) ──────────
  Set<int> get unlockedMatches {
    final list = _prefs.getStringList('unlocked_matches') ?? [];
    return list.map((e) => int.parse(e)).toSet();
  }

  void unlockMatch(int matchId) {
    final set = unlockedMatches;
    set.add(matchId);
    _prefs.setStringList('unlocked_matches', set.map((e) => e.toString()).toList());
  }

  bool isMatchUnlocked(int matchId) => unlockedMatches.contains(matchId);
}
