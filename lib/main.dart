import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_logger.dart';

/// Application entry point.
///
/// Sets up [ProviderScope] for Riverpod state management and
/// [MaterialApp.router] with [GoRouter] for declarative navigation.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.info('APP', '🚀 TeleMedCare starting...');

  runApp(
    const ProviderScope(
      child: TeleMedCareApp(),
    ),
  );
}

/// Root application widget.
///
/// Consumes the [appRouterProvider] via Riverpod to react to auth state
/// changes and applies the global [AppTheme.lightTheme].
class TeleMedCareApp extends ConsumerWidget {
  const TeleMedCareApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    AppLogger.info('APP', 'Building root widget');

    return MaterialApp.router(
      title: 'TeleMedCare',
      theme: AppTheme.lightTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
