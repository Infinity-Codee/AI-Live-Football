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

  // ─── Language ('en' | 'tr') ────────────────────────
  String get language => _prefs.getString('app_language') ?? 'en';
  set language(String value) => _prefs.setString('app_language', value);
}
