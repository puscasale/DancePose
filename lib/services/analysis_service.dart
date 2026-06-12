import 'dart:async';
import 'dart:convert';
import 'dart:io';

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
      throw Exception('Your session has expired. Please log in again.');
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

    try {
      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 5),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        return AnalysisSessionModel.fromJson(jsonDecode(response.body));
      }

      throw Exception(_extractUserFriendlyMessage(response.statusCode, response.body));
    } on TimeoutException {
      throw Exception(
        'The analysis is taking too long. Please try again with a shorter video.',
      );
    } on SocketException {
      throw Exception(
        'No internet connection. Please check your network and try again.',
      );
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');

      if (message.trim().isEmpty) {
        throw Exception('Something went wrong while uploading the video.');
      }

      throw Exception(message);
    }
  }

  String _extractUserFriendlyMessage(int statusCode, String responseBody) {
    final backendMessage = _extractBackendMessage(responseBody);

    if (statusCode == 400) {
      if (backendMessage.toLowerCase().contains('unsupported video format')) {
        return 'Unsupported video format. Please upload an MP4, MOV, AVI or MKV file.';
      }

      if (backendMessage.toLowerCase().contains('no video file')) {
        return 'No video file was selected. Please choose or record a video first.';
      }

      return 'The selected video could not be processed. Please try another video.';
    }

    if (statusCode == 401 || statusCode == 403) {
      return 'Your session has expired. Please log in again.';
    }

    if (statusCode == 404) {
      return 'The analysis session could not be found.';
    }

    if (statusCode >= 500) {
      return 'The video analysis failed on the server. Please try again with a clearer or shorter video.';
    }

    return backendMessage;
  }

  String _extractBackendMessage(String responseBody) {
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