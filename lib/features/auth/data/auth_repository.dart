
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_logger.dart';
import '../domain/user_model.dart';

/// Repository handling all auth-related API calls and token storage.
///
/// Mirrors the React `AuthContext.tsx` login/register/logout flow.
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

    final data = response.data as Map<String, dynamic>;
    final token = data['token'] as String;
    final userJson = data['user'] as Map<String, dynamic>;

    // Save token securely
    await _storage.write(key: 'auth_token', value: token);
    AppLogger.auth('Login successful, token stored');

    return User.fromJson(userJson);
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

    final data = response.data as Map<String, dynamic>;
    final token = data['token'] as String;
    final userJson = data['user'] as Map<String, dynamic>;

    await _storage.write(key: 'auth_token', value: token);
    AppLogger.auth('Registration successful, token stored');

    return User.fromJson(userJson);
  }

  /// Fetch the current user from stored token.
  Future<User?> getCurrentUser() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) {
      AppLogger.auth('No stored token found');
      return null;
    }

    try {
      final response = await _apiClient.get(ApiConstants.meEndpoint);
      final data = response.data as Map<String, dynamic>;
      final user = User.fromJson(data['user'] ?? data);
      AppLogger.auth('Restored session for ${user.name}');
      return user;
    } catch (e) {
      AppLogger.error('AUTH', 'Failed to restore session', e);
      await _storage.delete(key: 'auth_token');
      return null;
    }
  }

  /// Clear stored credentials.
  Future<void> logout() async {
    await _storage.delete(key: 'auth_token');
    AppLogger.auth('Logged out, token cleared');
  }

  /// Read the stored auth token.
  Future<String?> getToken() => _storage.read(key: 'auth_token');
}
