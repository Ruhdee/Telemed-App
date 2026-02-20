import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_logger.dart';
import '../../../shared/widgets/glass_panel.dart';
import '../../auth/providers/auth_provider.dart';

/// Nurse dashboard matching `nurse/page.tsx`.
///
/// Shows vitals tracking, patient assignment, and task management.
class NurseDashboardScreen extends ConsumerWidget {
  const NurseDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userName = authState.valueOrNull?.name ?? 'Nurse';

    AppLogger.nav('Nurse dashboard rendered for $userName');

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nurse Station', style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w400)),
            Text(userName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(LucideIcons.bell), onPressed: () {}),
          IconButton(
            icon: const Icon(LucideIcons.logOut, color: AppColors.error),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats
            Row(
              children: const [
                _NurseStatCard(label: 'Assigned', value: '5', icon: LucideIcons.users, color: Color(0xFF3B82F6)),
                SizedBox(width: 12),
                _NurseStatCard(label: 'Vitals Due', value: '3', icon: LucideIcons.activity, color: Color(0xFFF59E0B)),
              ],
            ).animate().fadeIn(),

            const SizedBox(height: 16),

            Row(
              children: const [
                _NurseStatCard(label: 'Completed', value: '12', icon: LucideIcons.checkCircle, color: Color(0xFF10B981)),
                SizedBox(width: 12),
                _NurseStatCard(label: 'Alerts', value: '1', icon: LucideIcons.alertTriangle, color: Color(0xFFEF4444)),
              ],
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 28),

            // Actions
            Text('Quick Actions', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _NurseAction(icon: LucideIcons.activity, label: 'Record Vitals', onTap: () {}),
                _NurseAction(icon: LucideIcons.syringe, label: 'Administer Meds', onTap: () {}),
                _NurseAction(icon: LucideIcons.clipboardList, label: 'Patient Notes', onTap: () {}),
                _NurseAction(icon: LucideIcons.bell, label: 'Send Alert', onTap: () {}),
              ],
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 28),

            // Assigned Patients
            Text('Assigned Patients', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            ..._mockPatients.asMap().entries.map((entry) {
              final i = entry.key;
              final p = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassPanel(
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.goldLight,
                        child: Text(p.$1[0], style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.goldDark)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.$1, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                            Text(p.$2, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: p.$3 ? AppColors.warning.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          p.$3 ? 'Due' : 'Done',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: p.$3 ? AppColors.warning : AppColors.success),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: (i * 60).ms);
            }),
          ],
        ),
      ),
    );
  }

  static const _mockPatients = [
    ('Raj Sharma', 'Room 201 • BP check due', true),
    ('Priya Das', 'Room 104 • Post-op monitoring', false),
    ('Amit Patel', 'Room 305 • Vitals stable', true),
    ('Sneha Kulkarni', 'Room 212 • Discharge prep', false),
    ('Rahul Verma', 'Room 108 • IV drip pending', true),
  ];
}

class _NurseStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _NurseStatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GlassPanel(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NurseAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _NurseAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppColors.goldLight.withValues(alpha: 0.3),
      side: BorderSide(color: AppColors.goldPrimary.withValues(alpha: 0.3)),
    );
  }
}
