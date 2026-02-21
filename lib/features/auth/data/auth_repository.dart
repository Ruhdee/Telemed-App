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

    final user = User.fromJson(data);

    // Save token and user securely
    await _storage.write(key: 'auth_token', value: token);
    await _storage.write(key: 'user_data', value: jsonEncode(user.toJson()));
    
    AppLogger.auth('Login successful, token stored');

    return user;
  }

  /// Register a new user.
  Future<User> register(
    String name,
    String email,
    String password, {
    UserRole role = UserRole.patient,
    String? phone,
    String? specialization,
    int? experience,
    String? shift,
    String? registrationNumber,
    String? hospitalName,
    String? qualification,
  }) async {
    AppLogger.auth('Attempting registration: $name ($email, role: ${role.name})');

    final requestData = {
      'name': name,
      'email': email,
      'password': password,
      'role': role.name,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      if (specialization != null && specialization.isNotEmpty) 'specialization': specialization,
      if (experience != null) 'experience': experience,
      if (shift != null && shift.isNotEmpty) 'shift': shift,
      if (registrationNumber != null && registrationNumber.isNotEmpty) 'registrationNumber': registrationNumber,
      if (hospitalName != null && hospitalName.isNotEmpty) 'hospitalName': hospitalName,
      if (qualification != null && qualification.isNotEmpty) 'qualification': qualification,
    };

    final response = await _apiClient.post(
      ApiConstants.registerEndpoint,
      data: requestData,
    );

    // Backend returns flat JSON: { id, name, email, role, token, ... }
    final data = response.data as Map<String, dynamic>;
    final token = data['token'] as String;

    final user = User.fromJson(data);

    await _storage.write(key: 'auth_token', value: token);
    await _storage.write(key: 'user_data', value: jsonEncode(user.toJson()));
    
    AppLogger.auth('Registration successful, token stored');

    return user;
  }

  /// Fetch the current user from stored token.
  ///
  /// Since the backend has no `/api/auth/me` endpoint, we decode
  /// the JWT locally to extract user info (id, email, role).
  Future<User?> getCurrentUser() async {
    final token = await _storage.read(key: 'auth_token');
    final userJson = await _storage.read(key: 'user_data');
    
    if (token == null || userJson == null) {
      AppLogger.auth('No stored token or user found');
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

      // Restore full User object from cache
      final userMap = jsonDecode(userJson) as Map<String, dynamic>;
      final user = User.fromJson(userMap);
      
      AppLogger.auth('Restored session for ${user.name} (from SecureStorage)');
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
    await _storage.delete(key: 'user_data');
    await _storage.delete(key: 'user_name'); // Clear deprecated key too
    AppLogger.auth('Logged out, token cleared');
  }

  /// Read the stored auth token.
  Future<String?> getToken() => _storage.read(key: 'auth_token');
}
