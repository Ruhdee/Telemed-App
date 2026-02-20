import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_logger.dart';
import '../../../shared/widgets/glass_panel.dart';
import '../data/disease_config.dart';

/// AI Diagnosis model list, matching `ai-diagnosis/page.tsx`.
///
/// Grid of disease models that navigate to the detail/input screen.
class AiDiagnosisListScreen extends StatelessWidget {
  const AiDiagnosisListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    AppLogger.nav('AI Diagnosis list screen');

    return Scaffold(
      appBar: AppBar(title: const Text('AI Diagnosis Models')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: diseaseModels.length,
        itemBuilder: (context, index) {
          final model = diseaseModels[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlassPanel(
              borderColor: Colors.transparent,
              child: InkWell(
                onTap: () {
                  AppLogger.nav('Selected model: ${model.id}');
                  context.go('/dashboard/ai-diagnosis/${model.id}');
                },
                borderRadius: BorderRadius.circular(16),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: AppColors.goldGradient,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(model.icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(model.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                          const SizedBox(height: 4),
                          Text(model.description, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textMuted),
                  ],
                ),
              ),
            ).animate().fadeIn(delay: (index * 60).ms).slideX(begin: 0.03, end: 0),
          );
        },
      ),
    );
  }
}
