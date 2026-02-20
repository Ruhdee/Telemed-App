import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_logger.dart';

/// Floating emergency SOS button matching the React `EmergencySOS.tsx`.
///
/// Shows a pulsing red FAB that expands to reveal emergency options:
/// - Call 108 (India ambulance)
/// - Nearby hospitals (navigates to map)
class EmergencySosButton extends StatefulWidget {
  final VoidCallback? onFindHospitals;

  const EmergencySosButton({super.key, this.onFindHospitals});

  @override
  State<EmergencySosButton> createState() => _EmergencySosButtonState();
}

class _EmergencySosButtonState extends State<EmergencySosButton> {
  bool _isExpanded = false;

  Future<void> _callEmergency() async {
    AppLogger.info('SOS', 'Emergency call triggered');
    final uri = Uri.parse('tel:108');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Expanded options
        if (_isExpanded) ...[
          _SosOption(
            icon: Icons.local_hospital,
            label: 'Nearby Hospitals',
            onTap: () {
              setState(() => _isExpanded = false);
              widget.onFindHospitals?.call();
            },
          )
              .animate()
              .fadeIn(duration: 200.ms)
              .slideY(begin: 0.3, end: 0),
          const SizedBox(height: 8),
          _SosOption(
            icon: Icons.phone,
            label: 'Call 108',
            color: AppColors.error,
            onTap: _callEmergency,
          )
              .animate()
              .fadeIn(duration: 200.ms, delay: 50.ms)
              .slideY(begin: 0.3, end: 0),
          const SizedBox(height: 12),
        ],

        // Main SOS FAB
        FloatingActionButton(
          heroTag: 'sos_fab',
          backgroundColor: AppColors.error,
          onPressed: () => setState(() => _isExpanded = !_isExpanded),
          child: Icon(
            _isExpanded ? Icons.close : Icons.sos,
            color: Colors.white,
            size: 28,
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.05, 1.05),
              duration: 1000.ms,
            ),
      ],
    );
  }
}

class _SosOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _SosOption({
    required this.icon,
    required this.label,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: color?.withValues(alpha: 0.1) ?? Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: color ?? Colors.grey.shade300),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color ?? AppColors.textPrimary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color ?? AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
