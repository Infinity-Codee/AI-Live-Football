/// HTTP API service for communicating with the FastAPI backend.

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class ApiService {
  static final ApiService _instance = ApiService._();
  factory ApiService() => _instance;
  ApiService._();

  final String _base = AppConstants.baseUrl;

  Future<Map<String, dynamic>> _get(String path) async {
    final resp = await http.get(Uri.parse('$_base$path'));
    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    }
    throw Exception('API Error ${resp.statusCode}: ${resp.body}');
  }

  Future<Map<String, dynamic>> _post(
    String path, Map<String, dynamic> body,
  ) async {
    final resp = await http.post(
      Uri.parse('$_base$path'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
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

  // ─── Wallet ────────────────────────────────────────
  Future<Map<String, dynamic>> registerDevice(String deviceId) =>
      _post('/wallet/register', {'device_id': deviceId});
  Future<Map<String, dynamic>> getBalance(String deviceId) =>
      _get('/wallet/balance?device_id=$deviceId');
  Future<Map<String, dynamic>> addReward(String deviceId) =>
      _post('/wallet/reward', {'device_id': deviceId});
  Future<Map<String, dynamic>> spendCredit(String deviceId, int matchId) =>
      _post('/wallet/spend', {'device_id': deviceId, 'match_id': matchId});
  Future<Map<String, dynamic>> getTransactions(String deviceId) =>
      _get('/wallet/transactions?device_id=$deviceId');

  // ─── Billing / Entitlements ───────────────────────
  Future<Map<String, dynamic>> getEntitlements(String deviceId) =>
      _get('/billing/entitlements?device_id=$deviceId');

  Future<Map<String, dynamic>> syncEntitlements({
    required String deviceId,
    required bool isPro,
    String source = 'client',
    String? proExpiresAt,
  }) =>
      _post('/billing/entitlements/sync', {
        'device_id': deviceId,
        'is_pro': isPro,
        'source': source,
        if (proExpiresAt != null) 'pro_expires_at': proExpiresAt,
      });

  // ─── Analytics ────────────────────────────────────
  Future<Map<String, dynamic>> trackMonetizationEvent({
    required String deviceId,
    required String eventName,
    Map<String, dynamic>? properties,
  }) =>
      _post('/events/monetization', {
        'device_id': deviceId,
        'event_name': eventName,
        'properties': properties ?? <String, dynamic>{},
      });

  // ─── Standings ─────────────────────────────────────
  Future<Map<String, dynamic>> getStandings(int leagueId, {int season = 2024}) =>
      _get('/standings/$leagueId?season=$season');
}
