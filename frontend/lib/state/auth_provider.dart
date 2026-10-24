import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_client.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _api = ApiClient();

  bool _isLoading = false;
  String? _errorMessage;
  String? _userUid;
  String? _userFullName;
  String? _userEmail;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _userUid != null;
  String? get userUid => _userUid;
  String? get userFullName => _userFullName;
  String? get userEmail => _userEmail;

  Future<void> checkSession() => checkExistingSession();

  Future<void> checkExistingSession() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _userUid = prefs.getString('user_uid');
      _userFullName = prefs.getString('user_full_name');
      _userEmail = prefs.getString('user_email');
      final token = prefs.getString('auth_token') ?? _userUid;
      if (token != null && token.isNotEmpty) {
        await _api.setAuthToken(token);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.post('/api/v1/auth/register', body: {
        'full_name': fullName,
        'email': email,
        'password': password,
      });

      if (res is Map<String, dynamic>) {
        _userUid = res['uid'];
        _userFullName = res['full_name'];
        _userEmail = res['email'];

        // Store session token
        await _api.setAuthToken(_userUid);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_uid', _userUid!);
        await prefs.setString('auth_token', _userUid!);
        await prefs.setString('user_full_name', _userFullName ?? '');
        await prefs.setString('user_email', _userEmail ?? '');

        _isLoading = false;
        notifyListeners();
        return true;
      }
      throw ApiException('Unexpected server response');
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _api.post('/api/v1/auth/login', body: {
        'email': email,
        'password': password,
      });

      if (res is Map<String, dynamic>) {
        _userUid = res['uid'];
        _userFullName = res['full_name'];
        _userEmail = res['email'];

        await _api.setAuthToken(_userUid);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_uid', _userUid!);
        await prefs.setString('auth_token', _userUid!);
        await prefs.setString('user_full_name', _userFullName ?? '');
        await prefs.setString('user_email', _userEmail ?? '');

        _isLoading = false;
        notifyListeners();
        return true;
      }
      throw ApiException('Invalid credentials or response');
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _userUid = null;
    _userFullName = null;
    _userEmail = null;
    await _api.setAuthToken(null);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_uid');
    await prefs.remove('user_full_name');
    await prefs.remove('user_email');
    await prefs.remove('auth_token');
    await prefs.remove('active_farm_id');

    notifyListeners();
  }
}
