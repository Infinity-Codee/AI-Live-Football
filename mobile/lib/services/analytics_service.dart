/// Minimal monetization analytics service.

import 'api_service.dart';
import 'storage_service.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._();
  factory AnalyticsService() => _instance;
  AnalyticsService._();

  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  Future<void> track(String eventName, {Map<String, dynamic>? properties}) async {
    try {
      await _api.trackMonetizationEvent(
        deviceId: _storage.deviceId,
        eventName: eventName,
        properties: properties ?? const <String, dynamic>{},
      );
    } catch (_) {
      // Analytics must never break core UX.
    }
  }
}
