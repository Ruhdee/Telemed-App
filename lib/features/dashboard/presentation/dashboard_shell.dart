import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';

class DashboardShell extends ConsumerWidget {
  final Widget child;

  const DashboardShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final user = ref.watch(authProvider).valueOrNull;
    final userName = user?.name ?? 'User';
    final userEmail = user?.email ?? 'patient@telemed.com';
    final userRole = user?.role.name.toUpperCase() ?? 'PATIENT';

    int currentIndex = _calculateSelectedIndex(location);

    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: Text('$userName ($userRole)'),
              accountEmail: Text(userEmail),
              decoration: const BoxDecoration(gradient: AppColors.goldGradient),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(LucideIcons.user, color: AppColors.goldDark),
              ),
            ),
            _DrawerItem(icon: LucideIcons.user, label: 'Demographics', onTap: () => _onItemTapped(1, context)),
            _DrawerItem(icon: LucideIcons.calendar, label: 'Services & Booking', onTap: () => _onItemTapped(2, context)),
            _DrawerItem(icon: LucideIcons.video, label: 'Tele-Consultation', onTap: () => context.go('/dashboard/consultation')),
            _DrawerItem(icon: LucideIcons.videoOff, label: 'Offline Consultation', onTap: () => context.go('/dashboard/offline-consultation')),
            _DrawerItem(icon: LucideIcons.history, label: 'Consultation History', onTap: () => context.go('/dashboard/consultation-history')),
            _DrawerItem(icon: LucideIcons.fileText, label: 'Health Records', onTap: () => context.go('/dashboard/records')),
            _DrawerItem(icon: LucideIcons.pill, label: 'Pharmacy', onTap: () => context.go('/dashboard/pharmacy')),
            _DrawerItem(icon: LucideIcons.mapPin, label: 'Hospital Map', onTap: () => context.go('/dashboard/map')),
            _DrawerItem(icon: LucideIcons.brain, label: 'AI Diagnosis', onTap: () => context.go('/dashboard/ai-diagnosis')),
            _DrawerItem(icon: LucideIcons.stethoscope, label: 'AI Triage', onTap: () => context.go('/dashboard/triage')),
            _DrawerItem(icon: LucideIcons.star, label: 'Feedback', onTap: () => context.go('/dashboard/feedback')),
          ],
        ),
      ),
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => _onItemTapped(index, context),
        selectedItemColor: AppColors.goldPrimary,
        unselectedItemColor: AppColors.textMuted,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.user), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.calendar), label: 'Services'),
          BottomNavigationBarItem(icon: Icon(LucideIcons.video), label: 'Consult'),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(String location) {
    if (location.startsWith('/dashboard/demographics')) return 1;
    if (location.startsWith('/dashboard/services')) return 2;
    if (location.startsWith('/dashboard/consultation') || location.startsWith('/dashboard/offline-consultation')) return 3;
    return 0; // Home is default
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/dashboard/demographics');
        break;
      case 2:
        context.go('/dashboard/services');
        break;
      case 3:
        context.go('/dashboard/consultation');
        break;
    }
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textPrimary),
      title: Text(label),
      onTap: () {
        Navigator.pop(context); // Close drawer
        onTap();
      },
    );
  }
}
