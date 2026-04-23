import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../models/dance_move_model.dart';
import '../models/dance_style_model.dart';

class DanceService {
  final http.Client _client;

  DanceService({http.Client? client}) : _client = client ?? http.Client();

  Future<List<DanceStyleModel>> getStyles() async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/styles/'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(response.body);
      return decoded
          .map((item) => DanceStyleModel.fromJson(item))
          .toList();
    }

    throw Exception('Could not load dance styles');
  }

  Future<List<DanceMoveModel>> getMovesByStyle(int styleId) async {
    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/moves/style/$styleId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> decoded = jsonDecode(response.body);
      return decoded
          .map((item) => DanceMoveModel.fromJson(item))
          .toList();
    }

    throw Exception('Could not load dance moves');
  }
}