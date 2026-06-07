/// HTTP API service for communicating with the FastAPI backend.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  final String _base = AppConstants.baseUrl;

  // Fail fast instead of spinning forever when the backend is unreachable.
  static const Duration _timeout = Duration(seconds: 12);

  Future<Map<String, dynamic>> _get(String path) async {
    final resp = await http.get(Uri.parse('$_base$path')).timeout(_timeout);
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    }
    throw Exception('API Error ${resp.statusCode}: ${resp.body}');
  }

  // ─── Matches ───────────────────────────────────────
  Future<Map<String, dynamic>> getTodayMatches() => _get('/matches/today');
  Future<Map<String, dynamic>> getMatchDetail(int id) => _get('/matches/$id');
  Future<Map<String, dynamic>> getLiveStats(int id) => _get('/matches/$id/live-stats');

  // ─── Predictions ───────────────────────────────────
  Future<Map<String, dynamic>> getPreMatchPrediction(int matchId) =>
      _get('/predictions/$matchId/pre-match');
  Future<Map<String, dynamic>> getLivePrediction(int matchId) =>
      _get('/predictions/$matchId');
  Future<Map<String, dynamic>> getPredictionHistory(int matchId) =>
      _get('/predictions/$matchId/history');

  // ─── Standings ─────────────────────────────────────
  Future<Map<String, dynamic>> getStandings(int leagueId, {int? season}) =>
      _get('/standings/$leagueId?season=${season ?? _currentSeason()}');

  /// Starting year of the current football season (api-football convention).
  int _currentSeason() {
    final now = DateTime.now();
    return now.month >= 7 ? now.year : now.year - 1;
  }
}
