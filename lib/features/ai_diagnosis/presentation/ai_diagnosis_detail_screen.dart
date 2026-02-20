import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'dart:io';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/constants/api_constants.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/glass_panel.dart';
import '../data/disease_config.dart';

/// AI Diagnosis detail/form screen matching `ai-diagnosis/[id]/page.tsx`.
///
/// Dynamic form generated from [DiseaseConfig.inputs] for the selected model.
class AiDiagnosisDetailScreen extends StatefulWidget {
  final String modelId;

  const AiDiagnosisDetailScreen({super.key, required this.modelId});

  @override
  State<AiDiagnosisDetailScreen> createState() => _AiDiagnosisDetailScreenState();
}

class _AiDiagnosisDetailScreenState extends State<AiDiagnosisDetailScreen> {
  late final DiseaseConfig _config;
  final Map<String, dynamic> _formValues = {};
  File? _selectedImage;
  bool _isLoading = false;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _config = diseaseModels.firstWhere(
      (m) => m.id == widget.modelId,
      orElse: () => diseaseModels.first,
    );
    AppLogger.nav('AI Diagnosis detail: ${_config.name}');
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
      AppLogger.info('AI', 'Image selected: ${picked.path}');
    }
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _result = null;
    });

    AppLogger.ai('Submitting ${_config.id} prediction', _formValues);

    try {
      final dio = Dio();
      final endpoint = '${ApiConstants.aiBaseUrl}/predict/${_config.id}';

      Response response;
      if (_selectedImage != null) {
        final formData = FormData.fromMap({
          'image': await MultipartFile.fromFile(_selectedImage!.path),
          ..._formValues,
        });
        response = await dio.post(endpoint, data: formData);
      } else {
        response = await dio.post(endpoint, data: _formValues);
      }

      setState(() {
        _result = response.data as Map<String, dynamic>;
        _isLoading = false;
      });
      AppLogger.ai('Prediction result', _result);
    } catch (e) {
      AppLogger.error('AI', 'Prediction failed', e);
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Prediction failed: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_config.name)),
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
                      gradient: AppColors.goldGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_config.icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_config.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        Text(_config.description, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(),

            const SizedBox(height: 24),

            // Dynamic form
            ...List.generate(_config.inputs.length, (i) {
              final input = _config.inputs[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildInput(input),
              ).animate().fadeIn(delay: (i * 60).ms);
            }),

            const SizedBox(height: 8),

            AppButton(
              label: 'Run Prediction',
              variant: AppButtonVariant.primary,
              isLoading: _isLoading,
              onPressed: _submit,
              width: double.infinity,
              icon: const Icon(LucideIcons.brain, color: Colors.white, size: 18),
            ),

            if (_result != null) ...[
              const SizedBox(height: 24),
              _PredictionResult(result: _result!).animate().fadeIn(duration: 400.ms),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInput(DiseaseInput input) {
    switch (input.type) {
      case InputType.number:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(input.label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            TextField(
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: input.placeholder ?? 'Enter ${input.label.toLowerCase()}',
              ),
              onChanged: (v) => _formValues[input.key] = double.tryParse(v) ?? 0,
            ),
          ],
        );

      case InputType.select:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(input.label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            DropdownButtonFormField<dynamic>(
              decoration: const InputDecoration(),
              items: input.options?.map((o) {
                return DropdownMenuItem(value: o.value, child: Text(o.label));
              }).toList(),
              onChanged: (v) => _formValues[input.key] = v,
            ),
          ],
        );

      case InputType.text:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(input.label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 6),
            TextField(
              decoration: InputDecoration(hintText: input.placeholder ?? 'Enter ${input.label.toLowerCase()}'),
              onChanged: (v) => _formValues[input.key] = v,
            ),
          ],
        );

      case InputType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(input.label, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover, width: double.infinity),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.upload, size: 32, color: AppColors.textMuted),
                            const SizedBox(height: 8),
                            Text('Tap to upload image', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        );
    }
  }
}

// ── Prediction Result ──────────────────────────────────────────

class _PredictionResult extends StatelessWidget {
  final Map<String, dynamic> result;

  const _PredictionResult({required this.result});

  @override
  Widget build(BuildContext context) {
    final prediction = result['prediction']?.toString() ?? result['result']?.toString() ?? 'No result';
    final confidence = result['confidence'] as double? ?? result['probability'] as double? ?? 0.0;

    return GlassPanel(
      borderColor: AppColors.goldPrimary.withValues(alpha: 0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Prediction Result', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(LucideIcons.activity, size: 20, color: AppColors.goldPrimary),
              const SizedBox(width: 8),
              Text(prediction, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            ],
          ),
          if (confidence > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Confidence: ', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
                Text('${(confidence * 100).toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: confidence,
                backgroundColor: Colors.grey.shade200,
                color: AppColors.goldPrimary,
                minHeight: 6,
              ),
            ),
          ],
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
                const Expanded(
                  child: Text(
                    'AI prediction only. Consult a medical professional for diagnosis.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
