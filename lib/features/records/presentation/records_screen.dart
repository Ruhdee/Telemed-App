import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/constants/api_constants.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/glass_panel.dart';
import '../../auth/providers/auth_provider.dart';


/// Health records screen matching `records/page.tsx`.
///
/// Displays uploaded prescriptions/reports and allows OCR upload.
class RecordsScreen extends ConsumerStatefulWidget {
  const RecordsScreen({super.key});

  @override
  ConsumerState<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends ConsumerState<RecordsScreen> {
  final List<Map<String, dynamic>> _records = [];
  bool _isLoading = false;
  bool _isUploading = false;
  String? _ocrResult;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    AppLogger.info('RECORDS', 'Loading health records');

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get(ApiConstants.prescriptionsEndpoint);
      final data = response.data;
      if (data is List) {
        setState(() {
          _records.addAll(data.cast<Map<String, dynamic>>());
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
      AppLogger.info('RECORDS', 'Loaded ${_records.length} records');
    } catch (e) {
      AppLogger.error('RECORDS', 'Failed to load records', e);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _uploadAndOcr() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked == null) return;

    setState(() {
      _isUploading = true;
      _ocrResult = null;
    });

    AppLogger.info('RECORDS', 'Uploading image for OCR: ${picked.path}');

    try {
      final apiClient = ref.read(apiClientProvider);
      
      final response = await apiClient.uploadFile(
        ApiConstants.scanPrescriptionEndpoint,
        fieldName: 'prescription',
        filePath: picked.path,
        fileName: 'prescription.jpg',
      );

      final data = response.data as Map<String, dynamic>;
      setState(() {
        _ocrResult = data['text'] as String? ?? 'No text detected';
        _isUploading = false;
      });
      AppLogger.info('RECORDS', 'OCR completed successfully');
    } catch (e) {
      AppLogger.error('RECORDS', 'OCR failed', e);
      setState(() => _isUploading = false);
      if (mounted) {
        final errorLoc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${errorLoc.translate('ocrFailed')}: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('healthRecords')),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.camera),
            tooltip: loc.translate('scanPrescription'),
            onPressed: _uploadAndOcr,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.goldPrimary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Upload section
                  GlassPanel(
                    child: Column(
                      children: [
                        Icon(LucideIcons.scanLine, size: 36, color: AppColors.goldPrimary),
                        const SizedBox(height: 12),
                        Text(loc.translate('scanPrescription'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(loc.translate('takePhotoToExtract'), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        const SizedBox(height: 16),
                        AppButton(
                          label: _isUploading ? 'Processing...' : 'Capture & Scan',
                          variant: AppButtonVariant.primary,
                          isLoading: _isUploading,
                          onPressed: _uploadAndOcr,
                          icon: const Icon(LucideIcons.camera, color: Colors.white, size: 18),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(),

                  // OCR result
                  if (_ocrResult != null) ...[
                    const SizedBox(height: 16),
                    GlassPanel(
                      borderColor: AppColors.goldPrimary.withValues(alpha: 0.3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(loc.translate('extractedText'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(_ocrResult!, style: const TextStyle(fontSize: 13, height: 1.5)),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 300.ms),
                  ],

                  const SizedBox(height: 28),

                  // Records list
                  Text(loc.translate('yourRecords'), style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 12),

                  if (_records.isEmpty)
                    GlassPanel(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(LucideIcons.fileText, size: 40, color: AppColors.textMuted),
                              const SizedBox(height: 12),
                              Text(loc.translate('noRecordsUploadedYet'), style: const TextStyle(color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn()
                  else
                    ...List.generate(_records.length, (i) {
                      final r = _records[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GlassPanel(
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.goldLight,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(LucideIcons.fileText, color: AppColors.goldDark, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      r['doctorName']?.toString() ?? 'Prescription',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                    Text(
                                      r['createdAt']?.toString() ?? '',
                                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(LucideIcons.download, size: 18, color: AppColors.textMuted),
                            ],
                          ),
                        ).animate().fadeIn(delay: (i * 60).ms),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}
