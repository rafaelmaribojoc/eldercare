import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/utils/backend_config.dart';

/// Repository for analytics/statistics data
class AnalyticsRepository {
  void _log(String message) {
    if (kDebugMode) {
      print('[AnalyticsRepository] $message');
    }
  }

  /// Attempt to call a backend analytics endpoint, trying multiple URLs.
  Future<Map<String, dynamic>> _fetchAnalytics(String path) async {
    final resolvedUrl = await BackendConfig.getBackendUrl();
    final urlCandidates = <String>[
      '$resolvedUrl/analytics/$path',
    ];

    http.Response? httpResponse;
    Object? lastError;

    for (final url in urlCandidates) {
      try {
        httpResponse = await http.get(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
        ).timeout(const Duration(seconds: 15));
        if (httpResponse.statusCode == 200) break;
      } catch (e) {
        lastError = e;
      }
    }

    if (httpResponse != null && httpResponse.statusCode == 200) {
      return jsonDecode(httpResponse.body) as Map<String, dynamic>;
    }

    _log('Failed to fetch analytics/$path. Last error: $lastError');
    throw Exception('Failed to fetch analytics data');
  }

  /// Executive overview: occupancy, demographics, form summary
  Future<Map<String, dynamic>> getOverview() => _fetchAnalytics('overview');

  /// Form statistics: by unit, turnaround time, monthly trends
  Future<Map<String, dynamic>> getFormStats() => _fetchAnalytics('forms');

  /// Incident trends and ward breakdown
  Future<Map<String, dynamic>> getIncidentStats() =>
      _fetchAnalytics('incidents');

  /// Resident population trends: admissions, discharges, categories
  Future<Map<String, dynamic>> getResidentStats() =>
      _fetchAnalytics('residents');
}
