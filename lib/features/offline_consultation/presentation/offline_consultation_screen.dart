import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_logger.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/glass_panel.dart';
import '../data/offline_consultation_db.dart';
import '../data/offline_consultation_sync.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class OfflineConsultationScreen extends ConsumerStatefulWidget {
  const OfflineConsultationScreen({super.key});

  @override
  ConsumerState<OfflineConsultationScreen> createState() => _OfflineConsultationScreenState();
}

class _OfflineConsultationScreenState extends ConsumerState<OfflineConsultationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _chiefComplaintController = TextEditingController();
  final _symptomsController = TextEditingController();

  File? _mediaFile;
  String? _mediaType;
  bool _isSaving = false;

  @override
  void dispose() {
    _chiefComplaintController.dispose();
    _symptomsController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia({required bool isVideo}) async {
    final picker = ImagePicker();
    final picked = isVideo
        ? await picker.pickVideo(source: ImageSource.camera, maxDuration: const Duration(seconds: 10))
        : await picker.pickImage(source: ImageSource.camera);

    if (picked != null) {
      setState(() {
        _mediaFile = File(picked.path);
        _mediaType = isVideo ? 'video' : 'photo';
      });
      AppLogger.info('OfflineConsultation', 'Media selected: ${picked.path}');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_mediaFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please record a video or take a photo'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final consultation = {
        'id': const Uuid().v4(),
        'chiefComplaint': _chiefComplaintController.text,
        'symptomsDescription': _symptomsController.text,
        'mediaPath': _mediaFile!.path,
        'mediaType': _mediaType,
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      };

      await OfflineConsultationDb.instance.save(consultation);

      // Trigger background sync
      final syncService = OfflineConsultationSync(ref.read(apiClientProvider));
      syncService.syncPending();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Consultation saved offline & will sync automatically'), backgroundColor: AppColors.success),
        );
        context.pop();
      }
    } catch (e) {
      AppLogger.error('OfflineConsultation', 'Failed to save', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Failed to save: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Offline Consultation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Patient Details', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _chiefComplaintController,
                      decoration: const InputDecoration(labelText: 'Chief Complaint', hintText: 'e.g., Headache for 3 days'),
                      validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _symptomsController,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Symptoms Description', hintText: 'Describe your symptoms in detail'),
                      validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Media Upload', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    if (_mediaFile != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                        child: Column(
                          children: [
                            Icon(_mediaType == 'video' ? LucideIcons.video : LucideIcons.image, size: 48, color: AppColors.textMuted),
                            const SizedBox(height: 8),
                            Text('Media Selected', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                             label: 'Record Video',
                             icon: const Icon(LucideIcons.video, size: 18),
                             variant: AppButtonVariant.outline,
                             onPressed: () => _pickMedia(isVideo: true),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppButton(
                             label: 'Take Photo',
                             icon: const Icon(LucideIcons.camera, size: 18),
                             variant: AppButtonVariant.outline,
                             onPressed: () => _pickMedia(isVideo: false),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              AppButton(
                label: 'Submit Offline Consultation',
                variant: AppButtonVariant.primary,
                width: double.infinity,
                isLoading: _isSaving,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
