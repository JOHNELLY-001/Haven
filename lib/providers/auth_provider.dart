import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_client.dart';
import '../services/api_config.dart';
import '../services/auth_token.dart';

/// Lowest-risk state choice: activates the already-declared `provider`
/// package. Keeps auth logic (loading, token, errors) out of widgets so
/// login/register stop rebuilding gradients and never get stuck.
class AuthProvider extends ChangeNotifier {
  final ApiClient _client;

  AuthProvider({ApiClient? client}) : _client = client ?? ApiClient();

  bool _loading = false;
  bool get loading => _loading;

  String? _token;
  String? get token => _token;
  bool get isLoggedIn => _token != null;

  /// Profile from the login response user object
  /// ({first_name, last_name, email, contacts}). Persisted so Profile
  /// and booking contact fields survive restarts.
  Map<String, String> _profile = {};
  String get displayName {
    final name =
        '${_profile['first_name'] ?? ''} ${_profile['last_name'] ?? ''}'
            .trim();
    return name.isEmpty ? '' : name;
  }

  String get profilePhone => _profile['contacts'] ?? '';
  String get profileEmail => _profile['email'] ?? '';
  String get role => _profile['role'] ?? 'customer';
  bool get isAdmin => role == 'admin';

  /// Account creation date returned by `/api/me` (null until it loads).
  DateTime? get memberSince =>
      DateTime.tryParse(_profile['created_at'] ?? '');

  static const _kTokenKey = 'auth_token';
  static const _kProfileKey = 'user_profile';
  // v11 defaults: KeyStore-backed AES-GCM on Android, Keychain on iOS.
  static const _storage = FlutterSecureStorage();

  Future<void> restore() async {
    _token = await _storage.read(key: _kTokenKey);
    if (_token == null) {
      // One-time migration from the old SharedPreferences store.
      final prefs = await SharedPreferences.getInstance();
      final legacy = prefs.getString(_kTokenKey);
      if (legacy != null && legacy.isNotEmpty) {
        await _storage.write(key: _kTokenKey, value: legacy);
        await prefs.remove(_kTokenKey);
        _token = legacy;
      }
    }
    final prefs = await SharedPreferences.getInstance();
    try {
      final raw = prefs.getString(_kProfileKey) ?? '';
      if (raw.isNotEmpty) {
        _profile = Map<String, String>.from(
            (json.decode(raw) as Map).map((k, v) =>
                MapEntry(k.toString(), v?.toString() ?? '')));
      }
    } catch (_) {
      _profile = {};
    }
    AuthTokenStore.set(_token);
    notifyListeners();
    // Cached profile renders instantly; refresh role/created_at in the
    // background. Failure keeps the cached values (offline start).
    if (_token != null) refreshProfile();
  }

  /// Pull the authoritative profile from `/api/me`.
  Future<void> refreshProfile() async {
    if (_token == null) return;
    try {
      final data = await _client.getJson(ApiConfig.me());
      final user = data is Map ? (data['data'] ?? data) : null;
      if (user is Map) await _applyProfile(Map<String, dynamic>.from(user));
    } catch (_) {
      // Silent: the cached profile is still valid for display.
    }
  }

  /// Merge updated profile fields (used by Edit profile).
  Future<void> applyProfilePatch(Map<String, dynamic> patch) =>
      _applyProfile(patch);

  Future<void> _applyProfile(Map<String, dynamic> user) async {
    for (final key in [
      'first_name',
      'last_name',
      'email',
      'contacts',
      'role',
      'created_at',
    ]) {
      if (user.containsKey(key) && user[key] != null) {
        _profile[key] = user[key].toString();
      }
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kProfileKey, json.encode(_profile));
    notifyListeners();
  }

  Future<void> login({required String email, required String password}) async {
    _setLoading(true);
    try {
      final data = await _client.postJson(
        ApiConfig.login(),
        {'email': email.trim(), 'password': password.trim()},
      );
      final token = _extractToken(data);
      if (token == null || token.isEmpty) {
        throw const ApiException('Login succeeded but no token was returned.');
      }
      await _persistToken(token);
      // The backend returns {token, user:{first_name,last_name,email,contacts}}.
      final user = data is Map
          ? (data['user'] ?? (data['data'] is Map ? data['data']['user'] : null))
          : null;
      if (user is Map) {
        _profile = {
          'first_name': user['first_name']?.toString() ?? '',
          'last_name': user['last_name']?.toString() ?? '',
          'email': user['email']?.toString() ?? '',
          'contacts': user['contacts']?.toString() ?? '',
          'role': user['role']?.toString() ?? 'customer',
          'created_at': user['created_at']?.toString() ?? '',
        };
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kProfileKey, json.encode(_profile));
        notifyListeners();
      }
      // Ensure role/created_at are always present, even on older responses.
      await refreshProfile();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String phone,
    required String password,
  }) async {
    _setLoading(true);
    try {
      await _client.postJson(
        ApiConfig.register(),
        {
          'first_name': firstName.trim(),
          'last_name': lastName.trim(),
          'email': email.trim(),
          'contacts': phone.trim(),
          'password': password.trim(),
        },
      );
      // Backend returns 201 without token; user proceeds to login.
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    _token = null;
    _profile = {};
    AuthTokenStore.set(null);
    await _storage.delete(key: _kTokenKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kProfileKey);
    notifyListeners();
  }

  String? _extractToken(dynamic data) {
    if (data is Map) {
      for (final key in ['token', 'access_token', 'accessToken', 'jwt']) {
        final v = data[key];
        if (v is String && v.isNotEmpty) return v;
      }
      final nested = data['data'];
      if (nested is Map) return _extractToken(nested);
    }
    return null;
  }

  Future<void> _persistToken(String? token) async {
    _token = token;
    AuthTokenStore.set(token);
    if (token != null) {
      await _storage.write(key: _kTokenKey, value: token);
    }
    notifyListeners();
  }

  void _setLoading(bool value) {
    _loading = value;
    notifyListeners();
  }
}
