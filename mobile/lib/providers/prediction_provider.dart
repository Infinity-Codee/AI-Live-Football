/// Provider for prediction state and momentum history.

import 'package:flutter/material.dart';
import '../models/prediction.dart';
import '../services/api_service.dart';

class PredictionProvider extends ChangeNotifier {
  final ApiService _api = ApiService();

  PredictionModel? _current;
  List<MomentumPoint> _history = [];
  bool _isLoading = false;
  String? _error;

  PredictionModel? get current => _current;
  List<MomentumPoint> get history => _history;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPreMatch(int matchId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.getPreMatchPrediction(matchId);
      _current = PredictionModel.fromJson(data);
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchLivePrediction(int matchId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _api.getLivePrediction(matchId);
      _current = PredictionModel.fromJson(data);
      _error = null;

      // Also fetch history for the momentum chart
      await fetchHistory(matchId);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchHistory(int matchId) async {
    try {
      final data = await _api.getPredictionHistory(matchId);
      final list = data['history'] as List? ?? [];
      _history = list.map((h) => MomentumPoint.fromJson(h)).toList();
    } catch (_) {
      // Non-critical
    }
    notifyListeners();
  }

  void clear() {
    _current = null;
    _history = [];
    _error = null;
    notifyListeners();
  }
}
