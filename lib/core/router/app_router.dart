
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/user_model.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/landing/presentation/landing_screen.dart';
import '../../features/dashboard/presentation/dashboard_shell.dart';
import '../../features/dashboard/presentation/dashboard_home_screen.dart';
import '../../features/triage/presentation/triage_screen.dart';
import '../../features/ai_diagnosis/presentation/ai_diagnosis_list_screen.dart';
import '../../features/ai_diagnosis/presentation/ai_diagnosis_detail_screen.dart';
import '../../features/records/presentation/records_screen.dart';
import '../../features/pharmacy/presentation/pharmacy_screen.dart';
import '../../features/pharmacy/presentation/pharmacy_cart_screen.dart';
import '../../features/map/presentation/hospital_map_screen.dart';
import '../../features/doctor/presentation/doctor_dashboard_screen.dart';
import '../../features/nurse/presentation/nurse_dashboard_screen.dart';
import '../../features/offline_consultation/presentation/offline_consultation_screen.dart';
import '../../features/offline_consultation/presentation/offline_consultation_list_screen.dart';
import '../../features/offline_consultation/presentation/offline_consultation_review_screen.dart';
import '../../features/demographics/presentation/demographics_screen.dart';
import '../../features/feedback/presentation/feedback_screen.dart';
import '../../features/services/presentation/services_screen.dart';
import '../utils/app_logger.dart';

/// GoRouter configuration matching the React `next.config.ts` routing structure.
///
/// Routes:
///   /           → Landing page
///   /login      → Login screen
///   /register   → Register screen
///   /dashboard  → Patient dashboard (ShellRoute with bottom nav)
///     /dashboard/triage        → AI triage
///     /dashboard/ai-diagnosis  → AI diagnosis list
///     /dashboard/ai-diagnosis/:id → Disease model form
///     /dashboard/records       → Health records
///     /dashboard/pharmacy      → Pharmacy
///     /dashboard/map           → Hospital map
///   /doctor     → Doctor dashboard
///   /nurse      → Nurse dashboard

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,

    // Redirect based on auth state
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final user = authState.valueOrNull;
      final isLoggedIn = user != null;
      final isOnAuth = state.uri.path == '/login' || state.uri.path == '/register';
      final isOnLanding = state.uri.path == '/';

      // Still loading auth state — don't redirect
      if (isLoading) return null;

      // Not logged in and trying to access protected routes
      if (!isLoggedIn && !isOnAuth && !isOnLanding) {
        AppLogger.nav('Redirecting to / (not authenticated)');
        return '/';
      }

      // Logged in and on login/register → redirect to role-based dashboard
      if (isLoggedIn && (isOnAuth || isOnLanding)) {
        final destination = _roleBasedRoute(user.role);
        AppLogger.nav('Redirecting to $destination (authenticated as ${user.role.name})');
        return destination;
      }

      return null;
    },

    routes: [
      // Landing
      GoRoute(
        path: '/',
        name: 'landing',
        builder: (context, state) => LandingScreen(
          onLogin: () => context.go('/login'),
          onRegister: () => context.go('/register'),
        ),
      ),

      // Auth
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Patient Dashboard (ShellRoute for bottom nav)
      ShellRoute(
        builder: (context, state, child) {
          return DashboardShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardHomeScreen(),
          ),
          GoRoute(
            path: '/dashboard/triage',
            name: 'triage',
            builder: (context, state) => const TriageScreen(),
          ),
          GoRoute(
            path: '/dashboard/ai-diagnosis',
            name: 'ai-diagnosis',
            builder: (context, state) => const AiDiagnosisListScreen(),
          ),
          GoRoute(
            path: '/dashboard/ai-diagnosis/:id',
            name: 'ai-diagnosis-detail',
            builder: (context, state) => AiDiagnosisDetailScreen(
              modelId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/dashboard/records',
            name: 'records',
            builder: (context, state) => const RecordsScreen(),
          ),
          GoRoute(
            path: '/dashboard/pharmacy',
            name: 'pharmacy',
            builder: (context, state) => const PharmacyScreen(),
          ),
          GoRoute(
            path: '/dashboard/pharmacy-cart',
            name: 'pharmacy-cart',
            builder: (context, state) => const PharmacyCartScreen(),
          ),
          GoRoute(
            path: '/dashboard/map',
            name: 'hospital-map',
            builder: (context, state) => const HospitalMapScreen(),
          ),
          GoRoute(
            path: '/dashboard/consultation',
            name: 'consultation',
            builder: (context, state) => const OfflineConsultationScreen(),
          ),
          GoRoute(
            path: '/dashboard/consultation-history',
            name: 'consultation-history',
            builder: (context, state) => const OfflineConsultationListScreen(),
          ),
          GoRoute(
            path: '/dashboard/demographics',
            name: 'demographics',
            builder: (context, state) => const DemographicsScreen(),
          ),
          GoRoute(
            path: '/dashboard/feedback',
            name: 'feedback',
            builder: (context, state) => const FeedbackScreen(),
          ),
          GoRoute(
            path: '/dashboard/services',
            name: 'services',
            builder: (context, state) => const ServicesScreen(),
          ),
        ],
      ),

      // Doctor Dashboard
      GoRoute(
        path: '/doctor',
        name: 'doctor-dashboard',
        builder: (context, state) => const DoctorDashboardScreen(),
      ),
      GoRoute(
        path: '/doctor/consultation-review',
        name: 'doctor-consultation-review',
        builder: (context, state) => const OfflineConsultationReviewScreen(),
      ),

      // Nurse Dashboard
      GoRoute(
        path: '/nurse',
        name: 'nurse-dashboard',
        builder: (context, state) => const NurseDashboardScreen(),
      ),
    ],
  );
});

/// Map user roles to their dashboard routes.
String _roleBasedRoute(UserRole role) {
  switch (role) {
    case UserRole.doctor:
      return '/doctor';
    case UserRole.nurse:
      return '/nurse';
    case UserRole.patient:
    case UserRole.pharmacist:
    case UserRole.admin:
      return '/dashboard';
  }
}
