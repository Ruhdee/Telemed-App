import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../shared/widgets/glass_panel.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';

/// Patient dashboard home screen matching the React `dashboard/page.tsx`.
///
/// Shows vitals cards, upcoming appointments, quick actions grid,
/// and a health timeline.
class DashboardHomeScreen extends ConsumerWidget {
  const DashboardHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final dashState = ref.watch(dashboardProvider);
    final userName = authState.valueOrNull?.name.split(' ').first ?? 'User';
    final loc = AppLocalizations.of(context);

    AppLogger.nav('Dashboard home rendered for $userName');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.menu),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${loc.translate('good')} ${_getGreeting(loc)}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
                fontWeight: FontWeight.w400,
              ),
            ),
            Text(
              userName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
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
      body: dashState.isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.goldPrimary),
            )
          : RefreshIndicator(
              color: AppColors.goldPrimary,
              onRefresh: () async {
                AppLogger.info('DASHBOARD', 'Pull-to-refresh triggered');
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Vitals Cards ──────────────────────────
                    Text(
                      loc.translate('todaysVitals'),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 100,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: dashState.vitals.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 12),
                        itemBuilder: (_, i) {
                          final v = dashState.vitals[i];
                          return _VitalCard(vital: v, index: i);
                        },
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Quick Actions ─────────────────────────
                    Text(
                      loc.translate('quickActions'),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      children: [
                        _QuickAction(
                          icon: LucideIcons.video,
                          label: loc.translate('videoConsult'),
                          color: const Color(0xFF3B82F6),
                          onTap: () => context.go('/dashboard/consultation'),
                        ),
                        _QuickAction(
                          icon: LucideIcons.brain,
                          label: loc.translate('aiDiagnosis'),
                          color: const Color(0xFF8B5CF6),
                          onTap: () => context.go('/dashboard/ai-diagnosis'),
                        ),
                        _QuickAction(
                          icon: LucideIcons.fileText,
                          label: loc.translate('healthRecords'),
                          color: const Color(0xFF10B981),
                          onTap: () => context.go('/dashboard/records'),
                        ),
                        _QuickAction(
                          icon: LucideIcons.pill,
                          label: loc.translate('pharmacy'),
                          color: const Color(0xFFF59E0B),
                          onTap: () => context.go('/dashboard/pharmacy'),
                        ),
                        _QuickAction(
                          icon: LucideIcons.mapPin,
                          label: loc.translate('hospitalMap'),
                          color: const Color(0xFFEF4444),
                          onTap: () => context.go('/dashboard/map'),
                        ),
                        _QuickAction(
                          icon: LucideIcons.stethoscope,
                          label: loc.translate('aiTriage'),
                          color: const Color(0xFF06B6D4),
                          onTap: () => context.go('/dashboard/triage'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    // ── Upcoming Appointments ─────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          loc.translate('upcomingAppointments'),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            loc.translate('viewAll'),
                            style: const TextStyle(
                              color: AppColors.goldPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (dashState.appointments.isEmpty)
                      GlassPanel(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Icon(
                                  LucideIcons.calendar,
                                  size: 40,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  loc.translate('noAppointments'),
                                  style: const TextStyle(
                                    color: AppColors.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: () =>
                                      context.go('/dashboard/book-appointment'),
                                  child: Text(
                                    loc.translate('bookConsultation'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).animate().fadeIn()
                    else
                      ...dashState.appointments
                          .take(3)
                          .toList()
                          .asMap()
                          .entries
                          .map((entry) {
                            final appt = entry.value;
                            return Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _AppointmentCard(appointment: appt),
                                )
                                .animate()
                                .fadeIn(delay: (entry.key * 80).ms)
                                .slideX(begin: 0.03, end: 0);
                          }),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  String _getGreeting(AppLocalizations loc) {
    final hour = DateTime.now().hour;
    if (hour < 12) return loc.translate('morning');
    if (hour < 17) return loc.translate('afternoon');
    return loc.translate('evening');
  }
}

// ── Vital Card ─────────────────────────────────────────────────

class _VitalCard extends StatelessWidget {
  final VitalSign vital;
  final int index;

  const _VitalCard({required this.vital, required this.index});

  IconData get _icon {
    switch (vital.icon) {
      case 'heart':
        return LucideIcons.heart;
      case 'activity':
        return LucideIcons.activity;
      case 'droplet':
        return LucideIcons.droplet;
      case 'gauge':
        return LucideIcons.gauge;
      case 'moon':
        return LucideIcons.moon;
      case 'clock':
        return LucideIcons.clock;
      default:
        return LucideIcons.activity;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      child: SizedBox(
        width: 120,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(_icon, size: 16, color: AppColors.goldPrimary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    vital.label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  vital.value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Text(
                    vital.unit,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 80).ms).slideX(begin: 0.05, end: 0);
  }
}

// ── Quick Action ───────────────────────────────────────────────

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Appointment Card ───────────────────────────────────────────

class _AppointmentCard extends StatelessWidget {
  final Appointment appointment;

  const _AppointmentCard({required this.appointment});

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          // Risk indicator
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: _riskColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.doctorName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  appointment.chiefComplaint.isEmpty
                      ? 'General Consultation'
                      : appointment.chiefComplaint,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  appointment.status[0].toUpperCase() +
                      appointment.status.substring(1),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _statusColor,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _formatDate(appointment.scheduledDate),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color get _riskColor {
    switch (appointment.riskLevel) {
      case 'high':
        return AppColors.riskHigh;
      case 'medium':
        return AppColors.riskMedium;
      default:
        return AppColors.riskLow;
    }
  }

  Color get _statusColor {
    switch (appointment.status) {
      case 'completed':
        return AppColors.success;
      case 'in-progress':
        return AppColors.info;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = date.difference(now);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Tomorrow';
    return '${date.day}/${date.month}';
  }
}
