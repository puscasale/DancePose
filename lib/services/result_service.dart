import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../models/analysis_result_model.dart';
import 'auth_service.dart';

class ResultService {
  final http.Client _client;
  final AuthService _authService;

  ResultService({
    http.Client? client,
    AuthService? authService,
  })  : _client = client ?? http.Client(),
        _authService = authService ?? AuthService();

  Future<AnalysisResultModel> getResultForSession(int sessionId) async {
    final token = await _authService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('Your session has expired. Please log in again.');
    }

    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/results/session/$sessionId'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return AnalysisResultModel.fromJson(jsonDecode(response.body));
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