import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_logger.dart';
import '../../../shared/widgets/emergency_sos_button.dart';
import '../../../shared/widgets/chatbot_widget.dart';

/// Dashboard shell with bottom navigation bar.
///
/// Replaces the React app's sidebar layout. Contains 5 tabs:
/// Home, Consult, AI, Records, More.
class DashboardShell extends ConsumerStatefulWidget {
  final Widget child;

  const DashboardShell({super.key, required this.child});

  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<DashboardShell> {
  int _currentIndex = 0;

  static const _tabs = [
    ('/dashboard', 'Home', LucideIcons.home),
    ('/dashboard/triage', 'Triage', LucideIcons.stethoscope),
    ('/dashboard/ai-diagnosis', 'AI', LucideIcons.brain),
    ('/dashboard/records', 'Records', LucideIcons.fileText),
    ('/dashboard/pharmacy', 'Pharmacy', LucideIcons.pill),
  ];

  void _onTabTapped(int index) {
    final path = _tabs[index].$1;
    AppLogger.nav('Tab navigation: ${_tabs[index].$2} → $path');
    setState(() => _currentIndex = index);
    context.go(path);
  }

  @override
  Widget build(BuildContext context) {
    // Sync tab index with current location
    final location = GoRouterState.of(context).uri.path;
    for (int i = 0; i < _tabs.length; i++) {
      if (location == _tabs[i].$1) {
        if (_currentIndex != i) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _currentIndex = i);
          });
        }
        break;
      }
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: AppColors.goldDark,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        elevation: 12,
        selectedFontSize: 12,
        unselectedFontSize: 11,
        items: _tabs.map((t) {
          return BottomNavigationBarItem(
            icon: Icon(t.$3),
            label: t.$2,
          );
        }).toList(),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const ChatbotWidget(),
          const SizedBox(height: 8),
          EmergencySosButton(
            onFindHospitals: () => context.go('/dashboard/map'),
          ),
        ],
      ),
    );
  }
}
