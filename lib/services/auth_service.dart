import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';
import '../models/auth/auth_response.dart';
import '../models/auth/login_request.dart';
import '../models/auth/signup_request.dart';
import '../models/auth/user_model.dart';
import '../models/auth/update_profile_request.dart';
import '../models/auth/change_password_request.dart';
import 'dart:async';
import 'dart:io';

class AuthService {
  final http.Client _client;
  final FlutterSecureStorage _storage;

  AuthService({
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  Future<UserModel> signUp(SignUpRequest request) async {
  try {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/register'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode == 201) {
      return UserModel.fromJson(jsonDecode(response.body));
    }

    throw Exception(_extractAuthErrorMessage(response.statusCode, response.body));
  } on TimeoutException {
    throw Exception('The server is taking too long to respond. Please try again.');
  } on SocketException {
    throw Exception('No internet connection. Please check your network and try again.');
  }
}

  String _extractAuthErrorMessage(int statusCode, String responseBody) {
  final backendMessage = _extractErrorMessage(responseBody);

  if (statusCode == 400) {
    if (backendMessage.toLowerCase().contains('email is already registered')) {
      return 'This email is already registered. Please log in or use another email.';
    }

    return backendMessage;
  }

  if (statusCode == 401) {
    return 'Invalid email or password.';
  }

  if (statusCode == 422) {
    return 'Please check the entered data and try again.';
  }

  if (statusCode >= 500) {
    return 'A server error occurred. Please try again later.';
  }

  return backendMessage;
}

  Future<AuthResponse> login(LoginRequest request) async {
  try {
    final response = await _client.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(request.toJson()),
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      final authResponse = AuthResponse.fromJson(jsonDecode(response.body));
      await saveToken(authResponse.accessToken);
      return authResponse;
    }

    throw Exception(_extractAuthErrorMessage(response.statusCode, response.body));
  } on TimeoutException {
    throw Exception('The server is taking too long to respond. Please try again.');
  } on SocketException {
    throw Exception('No internet connection. Please check your network and try again.');
  }
}

  Future<void> changePassword(ChangePasswordRequest request) async {
  final token = await getToken();

  if (token == null || token.isEmpty) {
    throw Exception('No access token found');
  }

  final response = await _client.patch(
    Uri.parse('${ApiConfig.baseUrl}/profile/change-password'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(request.toJson()),
  );

  if (response.statusCode == 200) {
    return;
  }

  throw Exception(_extractErrorMessage(response.body));
}

  Future<UserModel> updateProfile(UpdateProfileRequest request) async {
  final token = await getToken();

  if (token == null || token.isEmpty) {
    throw Exception('No access token found');
  }

  final response = await _client.patch(
    Uri.parse('${ApiConfig.baseUrl}/profile/me'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
    body: jsonEncode(request.toJson()),
  );

  if (response.statusCode == 200) {
    return UserModel.fromJson(jsonDecode(response.body));
  }

  throw Exception(_extractErrorMessage(response.body));
}

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }

  Future<String?> getToken() async {
    return _storage.read(key: 'access_token');
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
  }

  Future<void> deleteAccount() async {
  final token = await getToken();

  if (token == null || token.isEmpty) {
    throw Exception('No access token found');
  }

  final response = await _client.delete(
    Uri.parse('${ApiConfig.baseUrl}/profile/me'),
    headers: {
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    await logout();
    return;
  }

  throw Exception(_extractErrorMessage(response.body));
}

  Future<UserModel> getCurrentUser() async {
    final token = await getToken();

    if (token == null || token.isEmpty) {
      throw Exception('No access token found');
    }

    final response = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/auth/me'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
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