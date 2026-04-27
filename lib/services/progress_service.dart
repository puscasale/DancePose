import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../models/progress_history_item.dart';
import '../models/progress_stats_model.dart';
import 'auth_service.dart';

class ProgressService {
  final http.Client _client;
  final AuthService _authService;

  ProgressService({
    http.Client? client,
    AuthService? authService,
  })  : _client = client ?? http.Client(),
        _authService = authService ?? AuthService();

  Future<List<ProgressHistoryItem>> getHistory() async {
    final token = await _authService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No access token found');
    }

    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/progress/history'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(response.body);
      return decoded.map((item) => ProgressHistoryItem.fromJson(item)).toList();
    }

    throw Exception(_extractErrorMessage(response.body));
  }

  Future<ProgressStatsModel> getStats() async {
    final token = await _authService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No access token found');
    }

    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/progress/stats'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return ProgressStatsModel.fromJson(jsonDecode(response.body));
    }

    throw Exception(_extractErrorMessage(response.body));
  }

  String _extractErrorMessage(String responseBody) {
    try {
      final decoded = jsonDecode(responseBody);
      if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
        return decoded['detail'].toString();
      }
      return 'Something went wrong';
    } catch (_) {
      return 'Something went wrong';
    }
  }
}