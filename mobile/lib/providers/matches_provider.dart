/// Provider for managing matches state.

import 'package:flutter/material.dart';
import '../models/match.dart';
import '../services/api_service.dart';

class MatchesProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  List<LeagueGroup> _leagues = [];
  bool _isLoading = false;
  String? _error;
  bool _demo = false;

  List<LeagueGroup> get leagues => _leagues;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get demo => _demo;

  int get totalMatches =>
      _leagues.fold(0, (sum, l) => sum + l.matches.length);

  int get liveMatches =>
      _leagues.fold(0, (sum, l) => sum + l.matches.where((m) => m.isLive).length);

  Future<void> fetchTodayMatches() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _api.getTodayMatches();
      final matchesList = data['matches'] as List? ?? [];
      _leagues = matchesList.map((m) => LeagueGroup.fromJson(m)).toList();
      _demo = data['demo'] == true;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
