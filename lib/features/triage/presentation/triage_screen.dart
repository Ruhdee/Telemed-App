import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/constants/api_constants.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/glass_panel.dart';
import '../../auth/providers/auth_provider.dart';

/// AI Triage screen matching the React `triage/page.tsx`.
///
/// Symptom form → submits to /api/triage → displays AI risk assessment.
class TriageScreen extends ConsumerStatefulWidget {
  const TriageScreen({super.key});

  @override
  ConsumerState<TriageScreen> createState() => _TriageScreenState();
}

class _TriageScreenState extends ConsumerState<TriageScreen> {
  final _chiefComplaintController = TextEditingController();
  final _symptomsController = TextEditingController();
  String _severity = 'moderate';
  String _duration = 'days';
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  @override
  void dispose() {
    _chiefComplaintController.dispose();
    _symptomsController.dispose();
    super.dispose();
  }

  Future<void> _submitTriage() async {
    if (_chiefComplaintController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _result = null;
    });

    AppLogger.ai('Submitting triage: ${_chiefComplaintController.text}');

    try {
      // Build a structured triage prompt for the chatbot/Gemini endpoint
      final triagePrompt = 'Act as a medical triage assistant. '
          'Assess the following patient symptoms and provide a risk level '
          '(low, moderate, high, emergency), recommended action, and brief explanation.\n\n'
          'Chief complaint: ${_chiefComplaintController.text}\n'
          'Additional symptoms: ${_symptomsController.text}\n'
          'Severity: $_severity\n'
          'Duration: $_duration';

      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.post(
        ApiConstants.chatbotEndpoint,
        data: {
          'message': triagePrompt,
          'language': 'en',
        },
      );

      final data = response.data as Map<String, dynamic>;
      final reply = data['reply'] as String? ?? 'No assessment available.';

      setState(() {
        _result = {
          'assessment': reply,
          'chiefComplaint': _chiefComplaintController.text,
          'severity': _severity,
        };
        _isLoading = false;
      });
      AppLogger.ai('Triage result received', _result);
    } catch (e) {
      AppLogger.error('AI', 'Triage submission failed', e);
      setState(() => _isLoading = false);
      if (mounted) {
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.translate('triageFailed')}: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(loc.translate('aiSymptomTriage'))),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            GlassPanel(
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF0891B2)]),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(LucideIcons.stethoscope, color: Colors.white, size: 24),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(loc.translate('aiPoweredTriage'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        Text(loc.translate('describeSymptoms'), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),

            const SizedBox(height: 24),

            // Chief Complaint
            Text('${loc.translate('chiefComplaint')} *', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _chiefComplaintController,
              decoration: InputDecoration(
                hintText: loc.translate('symptomsHint'),
              ),
            ),

            const SizedBox(height: 20),

            // Symptoms Description
            Text(loc.translate('describeYourSymptoms'), style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _symptomsController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: loc.translate('symptomsDetail'),
              ),
            ),

            const SizedBox(height: 20),

            // Severity & Duration row
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.translate('severity'), style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _severity,
                        items: [
                          DropdownMenuItem(value: 'mild', child: Text(loc.translate('mild'))),
                          DropdownMenuItem(value: 'moderate', child: Text(loc.translate('moderate'))),
                          DropdownMenuItem(value: 'severe', child: Text(loc.translate('severe'))),
                        ],
                        onChanged: (v) => setState(() => _severity = v ?? 'moderate'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(loc.translate('duration'), style: Theme.of(context).textTheme.labelLarge),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: _duration,
                        items: [
                          DropdownMenuItem(value: 'hours', child: Text(loc.translate('hours'))),
                          DropdownMenuItem(value: 'days', child: Text(loc.translate('days'))),
                          DropdownMenuItem(value: 'weeks', child: Text(loc.translate('weeks'))),
                          DropdownMenuItem(value: 'months', child: Text(loc.translate('months'))),
                        ],
                        onChanged: (v) => setState(() => _duration = v ?? 'days'),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Submit button
            AppButton(
              label: loc.translate('analyzeSymptoms'),
              variant: AppButtonVariant.primary,
              isLoading: _isLoading,
              onPressed: _submitTriage,
              width: double.infinity,
              icon: const Icon(LucideIcons.brain, color: Colors.white, size: 18),
            ),

            if (_result != null) ...[
              const SizedBox(height: 28),
              _TriageResult(result: _result!).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Triage Result Card ─────────────────────────────────────────

class _TriageResult extends StatelessWidget {
  final Map<String, dynamic> result;

  const _TriageResult({required this.result});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final assessment = result['assessment'] as String? ?? 'No assessment available.';
    final severity = result['severity'] as String? ?? 'moderate';

    return GlassPanel(
      borderColor: _severityColor(severity).withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _severityColor(severity).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _severityColor(severity).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.stethoscope, size: 14, color: _severityColor(severity)),
                    const SizedBox(width: 6),
                    Text(
                      loc.translate('aiTriageAssessment').toUpperCase(),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _severityColor(severity)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(loc.translate('assessment'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 6),
          Text(assessment, style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.alertTriangle, size: 14, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    loc.translate('aiAssessmentDisclaimer'),
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _severityColor(String level) {
    switch (level) {
      case 'severe': return AppColors.riskHigh;
      case 'moderate': return AppColors.riskMedium;
      default: return AppColors.riskLow;
    }
  }
}

