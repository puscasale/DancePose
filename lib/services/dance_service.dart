import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../models/dance_move_model.dart';
import '../models/dance_style_model.dart';
import '../models/favorites_response_model.dart';
import 'auth_service.dart';

class DanceService {
  final http.Client _client;
  final AuthService _authService;

  DanceService({
    http.Client? client,
    AuthService? authService,
  })  : _client = client ?? http.Client(),
        _authService = authService ?? AuthService();

  Future<List<DanceStyleModel>> getStyles() async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/styles/'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(response.body);
      return decoded.map((item) => DanceStyleModel.fromJson(item)).toList();
    }

    throw Exception('Could not load dance styles');
  }

  Future<List<DanceMoveModel>> getMovesByStyle(int styleId) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/moves/style/$styleId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(response.body);
      return decoded.map((item) => DanceMoveModel.fromJson(item)).toList();
    }

    throw Exception('Could not load dance moves');
  }

  Future<FavoritesResponseModel> getFavorites() async {
    final token = await _authService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No access token found');
    }

    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/favorites/'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return FavoritesResponseModel.fromJson(jsonDecode(response.body));
    }

    throw Exception(_extractErrorMessage(response.body));
  }

  Future<void> addFavoriteStyle(int styleId) async {
    await _authorizedWrite('/favorites/styles/$styleId', method: 'POST');
  }

  Future<void> removeFavoriteStyle(int styleId) async {
    await _authorizedWrite('/favorites/styles/$styleId', method: 'DELETE');
  }

  Future<void> addFavoriteMove(int moveId) async {
    await _authorizedWrite('/favorites/moves/$moveId', method: 'POST');
  }

  Future<void> removeFavoriteMove(int moveId) async {
    await _authorizedWrite('/favorites/moves/$moveId', method: 'DELETE');
  }

  Future<void> _authorizedWrite(
    String path, {
    required String method,
  }) async {
    final token = await _authService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No access token found');
    }

    late http.Response response;

    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = {
      'Authorization': 'Bearer $token',
    };

    if (method == 'POST') {
      response = await _client.post(uri, headers: headers);
    } else {
      response = await _client.delete(uri, headers: headers);
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_extractErrorMessage(response.body));
    }
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