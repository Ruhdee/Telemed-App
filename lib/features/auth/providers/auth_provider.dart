import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/app_logger.dart';
import '../data/auth_repository.dart';
import '../domain/user_model.dart';

// ── Providers ──────────────────────────────────────────────────

/// Singleton API client provider.
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

/// Auth repository provider.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(apiClientProvider));
});

/// Auth state — holds the currently logged-in user (or null).
final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier(ref.read(authRepositoryProvider));
});

// ── Auth Notifier ──────────────────────────────────────────────

/// Manages authentication state (mirrors React `AuthContext`).
///
/// Exposes [login], [register], [logout], and auto-restores session
/// on app start via [checkSession].
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AsyncValue.loading()) {
    checkSession();
  }

  /// Try to restore a session from stored token.
  Future<void> checkSession() async {
    AppLogger.state('Checking for existing auth session');
    try {
      final user = await _repo.getCurrentUser();
      state = AsyncValue.data(user);
      AppLogger.state('Session check complete: ${user?.name ?? "no session"}');
    } catch (e, st) {
      AppLogger.error('STATE', 'Session check failed', e, st);
      state = const AsyncValue.data(null);
    }
  }

  /// Login with email and password.
  Future<void> login(String email, String password, {UserRole? role}) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repo.login(email, password, role: role);
      state = AsyncValue.data(user);
      AppLogger.state('Auth state → logged in as ${user.name} (${user.role.name})');
    } catch (e, st) {
      AppLogger.error('STATE', 'Login failed', e, st);
      state = AsyncValue.error(e, st);
    }
  }

  /// Register a new account.
  Future<void> register(
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
    state = const AsyncValue.loading();
    try {
      final user = await _repo.register(
        name,
        email,
        password,
        role: role,
        phone: phone,
        specialization: specialization,
        experience: experience,
        shift: shift,
        registrationNumber: registrationNumber,
        hospitalName: hospitalName,
        qualification: qualification,
      );
      state = AsyncValue.data(user);
      AppLogger.state('Auth state → registered as ${user.name}');
    } catch (e, st) {
      AppLogger.error('STATE', 'Registration failed', e, st);
      state = AsyncValue.error(e, st);
    }
  }

  /// Logout the current user.
  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncValue.data(null);
    AppLogger.state('Auth state → logged out');
  }
}
