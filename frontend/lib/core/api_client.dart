import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  String _baseUrl = AppConstants.defaultBaseUrl;
  String? _authToken;

  String get baseUrl => _baseUrl;
  String? get authToken => _authToken;

  Future<bool> checkHealth([String? url]) async {
    final target = (url ?? _baseUrl).replaceAll(RegExp(r'/+$'), '');
    try {
      final res = await http.get(
        Uri.parse('$target/health'),
      ).timeout(const Duration(milliseconds: 1800));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedBase = prefs.getString('api_base_url');

    final candidates = <String>[
      if (savedBase != null && savedBase.isNotEmpty) savedBase,
      AppConstants.renderCloudBaseUrl,    // Live Render Cloud Hosting
      AppConstants.defaultBaseUrl,        // 127.0.0.1:8000 (Desktop, Web, USB adb reverse)
      AppConstants.localLanBaseUrl,       // 10.119.12.218:8000 (Wi-Fi LAN)
      AppConstants.androidEmulatorBaseUrl // 10.0.2.2:8000 (Android Emulator)
    ];


    String selected = savedBase ?? AppConstants.defaultBaseUrl;
    for (final candidate in candidates) {
      if (await checkHealth(candidate)) {
        selected = candidate;
        break;
      }
    }
    _baseUrl = selected;
    _authToken = prefs.getString('auth_token');
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url.replaceAll(RegExp(r'/+$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_base_url', _baseUrl);
  }

  Future<void> setAuthToken(String? token) async {
    _authToken = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('auth_token', token);
    } else {
      await prefs.remove('auth_token');
    }
  }

  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$_baseUrl$endpoint').replace(queryParameters: queryParams);
    try {
      final response = await http.get(uri, headers: _buildHeaders()).timeout(
        const Duration(seconds: 15),
      );
      return _processResponse(response);
    } on SocketException {
      throw ApiException(
        'Unable to connect to YieldCraft backend server at $_baseUrl. Ensure FastAPI is running locally.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body, Map<String, String>? queryParams}) async {
    final uri = Uri.parse('$_baseUrl$endpoint').replace(queryParameters: queryParams);
    try {
      final response = await http.post(
        uri,
        headers: _buildHeaders(),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 25));
      return _processResponse(response);
    } on SocketException {
      throw ApiException(
        'Unable to connect to YieldCraft backend server at $_baseUrl. Ensure FastAPI is running locally.',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  Future<dynamic> patch(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    try {
      final response = await http.patch(
        uri,
        headers: _buildHeaders(),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(const Duration(seconds: 15));
      return _processResponse(response);
    } on SocketException {
      throw ApiException('Unable to connect to YieldCraft backend at $_baseUrl.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  Future<dynamic> delete(String endpoint) async {
    final uri = Uri.parse('$_baseUrl$endpoint');
    try {
      final response = await http.delete(uri, headers: _buildHeaders()).timeout(
        const Duration(seconds: 15),
      );
      return _processResponse(response);
    } on SocketException {
      throw ApiException('Unable to connect to YieldCraft backend at $_baseUrl.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Network error: ${e.toString()}');
    }
  }

  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      String message = 'Server error (${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('detail')) {
          message = decoded['detail'].toString();
        }
      } catch (_) {}
      throw ApiException(message, response.statusCode);
    }
  }
}
