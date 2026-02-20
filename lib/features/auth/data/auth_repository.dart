import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_logger.dart';
import '../domain/user_model.dart';

/// Repository handling all auth-related API calls and token storage.
///
/// Mirrors the React `AuthContext.tsx` login/register/logout flow.
///
/// The backend returns a **flat** JSON response:
/// ```json
/// { "id": 1, "name": "...", "email": "...", "role": "patient", "token": "..." }
/// ```
class AuthRepository {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthRepository(this._apiClient);

  /// Login with email, password, and optional role.
  /// Returns the authenticated [User] on success.
  Future<User> login(String email, String password, {UserRole? role}) async {
    AppLogger.auth('Attempting login for $email (role: ${role?.name ?? "auto"})');

    final response = await _apiClient.post(
      ApiConstants.loginEndpoint,
      data: {
        'email': email,
        'password': password,
        if (role != null) 'role': role.name,
      },
    );

    // Backend returns flat JSON: { id, name, email, role, token, password, ... }
    final data = response.data as Map<String, dynamic>;
    final token = data['token'] as String;

    // Save token and name securely
    await _storage.write(key: 'auth_token', value: token);
    if (data['name'] != null) {
      await _storage.write(key: 'user_name', value: data['name']);
    }
    AppLogger.auth('Login successful, token stored');

    return User.fromJson(data);
  }

  /// Register a new user.
  Future<User> register(
    String name,
    String email,
    String password, {
    UserRole role = UserRole.patient,
  }) async {
    AppLogger.auth('Attempting registration: $name ($email, role: ${role.name})');

    final response = await _apiClient.post(
      ApiConstants.registerEndpoint,
      data: {
        'name': name,
        'email': email,
        'password': password,
        'role': role.name,
      },
    );

    // Backend returns flat JSON: { id, name, email, role, token, ... }
    final data = response.data as Map<String, dynamic>;
    final token = data['token'] as String;

    await _storage.write(key: 'auth_token', value: token);
    await _storage.write(key: 'user_name', value: name);
    AppLogger.auth('Registration successful, token stored');

    return User.fromJson(data);
  }

  /// Fetch the current user from stored token.
  ///
  /// Since the backend has no `/api/auth/me` endpoint, we decode
  /// the JWT locally to extract user info (id, email, role).
  Future<User?> getCurrentUser() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) {
      AppLogger.auth('No stored token found');
      return null;
    }

    try {
      // Decode JWT payload (middle segment, base64url)
      final parts = token.split('.');
      if (parts.length != 3) {
        AppLogger.error('AUTH', 'Invalid JWT format');
        await _storage.delete(key: 'auth_token');
        return null;
      }

      final payload = _decodeJwtPayload(parts[1]);
      
      // Check expiration
      final exp = payload['exp'] as int?;
      if (exp != null) {
        final expiry = DateTime.fromMillisecondsSinceEpoch(exp * 1000);
        if (DateTime.now().isAfter(expiry)) {
          AppLogger.auth('Token expired, clearing session');
          await _storage.delete(key: 'auth_token');
          return null;
        }
      }

      // JWT payload has: { id, email, role, iat, exp }
      final name = await _storage.read(key: 'user_name');
      final user = User.fromJwt(payload, storedName: name);
      AppLogger.auth('Restored session for ${user.name} (from JWT)');
      return user;
    } catch (e) {
      AppLogger.error('AUTH', 'Failed to restore session from JWT', e);
      await _storage.delete(key: 'auth_token');
      return null;
    }
  }

  /// Decode a base64-url-encoded JWT payload segment.
  Map<String, dynamic> _decodeJwtPayload(String encoded) {
    // Add padding if needed
    String normalized = encoded.replaceAll('-', '+').replaceAll('_', '/');
    switch (normalized.length % 4) {
      case 0:
        break;
      case 2:
        normalized += '==';
        break;
      case 3:
        normalized += '=';
        break;
      default:
        throw FormatException('Invalid base64 string');
    }
    final decoded = utf8.decode(base64.decode(normalized));
    return json.decode(decoded) as Map<String, dynamic>;
  }

  /// Clear stored credentials.
  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_name');
    AppLogger.auth('Logged out, token cleared');
  }

  /// Read the stored auth token.
  Future<String?> getToken() => _storage.read(key: 'auth_token');
}
