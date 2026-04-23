import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../models/analysis_session_model.dart';
import 'auth_service.dart';

class AnalysisService {
  final http.Client _client;
  final AuthService _authService;

  AnalysisService({
    http.Client? client,
    AuthService? authService,
  })  : _client = client ?? http.Client(),
        _authService = authService ?? AuthService();

  Future<AnalysisSessionModel> uploadAnalysisVideo({
    required String mode,
    required String sourceType,
    required String filePath,
    int? selectedStyleId,
    int? selectedMoveId,
  }) async {
    final token = await _authService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No access token found');
    }

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/analysis/upload'),
    );

    request.headers['Authorization'] = 'Bearer $token';

    request.fields['mode'] = mode;
    request.fields['source_type'] = sourceType;

    if (selectedStyleId != null) {
      request.fields['selected_style_id'] = selectedStyleId.toString();
    }

    if (selectedMoveId != null) {
      request.fields['selected_move_id'] = selectedMoveId.toString();
    }

    request.files.add(await http.MultipartFile.fromPath('video', filePath));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 201) {
      return AnalysisSessionModel.fromJson(jsonDecode(response.body));
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