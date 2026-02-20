import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_logger.dart';
import '../../../shared/widgets/glass_panel.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';

/// Doctor dashboard matching `doctor/page.tsx`.
///
/// Shows incoming appointments, queue, AI copilot, and action buttons.
/// Uses a different bottom nav layout than patient.
class DoctorDashboardScreen extends ConsumerWidget {
  const DoctorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final dashState = ref.watch(dashboardProvider);
    final userName = authState.valueOrNull?.name ?? 'Doctor';

    AppLogger.nav('Doctor dashboard rendered for $userName');

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Doctor Dashboard', style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w400)),
            Text('Dr. ${userName.split(' ').first}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
            // Stats row
            Row(
              children: [
                _StatCard(label: 'Today\'s Queue', value: '${dashState.appointments.length}', icon: LucideIcons.users, color: const Color(0xFF3B82F6)),
                const SizedBox(width: 12),
                const _StatCard(label: 'Completed', value: '0', icon: LucideIcons.checkCircle, color: Color(0xFF10B981)),
              ],
            ).animate().fadeIn(),

            const SizedBox(height: 16),

            Row(
              children: [
                const _StatCard(label: 'Pending SOAP', value: '0', icon: LucideIcons.fileText, color: Color(0xFFF59E0B)),
                const SizedBox(width: 12),
                const _StatCard(label: 'High Risk', value: '0', icon: LucideIcons.alertTriangle, color: Color(0xFFEF4444)),
              ],
            ).animate().fadeIn(delay: 100.ms),

            const SizedBox(height: 28),

            // Quick Actions
            Text('Actions', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ActionChip(icon: LucideIcons.stethoscope, label: 'AI Copilot', onTap: () {}),
                _ActionChip(icon: LucideIcons.fileText, label: 'SOAP Notes', onTap: () {}),
                _ActionChip(icon: LucideIcons.video, label: 'Review Videos', onTap: () => context.push('/doctor/consultation-review')),
                _ActionChip(icon: LucideIcons.pill, label: 'Prescribe', onTap: () {}),
              ],
            ).animate().fadeIn(delay: 200.ms),

            const SizedBox(height: 28),

            // Appointment Queue
            Text('Patient Queue', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),

            if (dashState.appointments.isEmpty)
              GlassPanel(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(LucideIcons.inbox, size: 40, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        const Text('No patients in queue', style: TextStyle(color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
              ).animate().fadeIn()
            else
              ...dashState.appointments.asMap().entries.map((entry) {
                final appt = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassPanel(
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: AppColors.goldLight,
                          child: Text(appt.patientName[0], style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.goldDark)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(appt.patientName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              Text(appt.chiefComplaint, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        if (appt.riskLevel != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _riskColor(appt.riskLevel!).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              appt.riskLevel!.toUpperCase(),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _riskColor(appt.riskLevel!)),
                            ),
                          ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: (entry.key * 60).ms);
              }),
          ],
        ),
      ),
    );
  }

  Color _riskColor(String level) {
    switch (level) {
      case 'high': return AppColors.riskHigh;
      case 'medium': return AppColors.riskMedium;
      default: return AppColors.riskLow;
    }
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.icon, required this.color});

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

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionChip({required this.icon, required this.label, required this.onTap});

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
