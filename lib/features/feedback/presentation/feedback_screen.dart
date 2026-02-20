import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/glass_panel.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _commentController = TextEditingController();
  List<dynamic> _doctors = [];
  String? _selectedDoctorId;
  int _rating = 0;
  bool _isLoadingDoctors = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get(ApiConstants.doctorsEndpoint);
      final data = response.data;
      if (data != null) {
        setState(() {
          _doctors = (data is List ? data : (data['data'] as List? ?? [])).cast<dynamic>();
        });
      }
    } catch (e) {
      AppLogger.error('Feedback', 'Failed to load doctors', e);
    } finally {
      if (mounted) setState(() => _isLoadingDoctors = false);
    }
  }

  Future<void> _submitFeedback() async {
    if (_selectedDoctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a doctor'), backgroundColor: AppColors.error),
      );
      return;
    }
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a rating'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post(
        ApiConstants.feedbackEndpoint,
        data: {
          'doctorId': _selectedDoctorId,
          'rating': _rating,
          'comment': _commentController.text,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback submitted successfully!'), backgroundColor: AppColors.success),
        );
        context.pop();
      }
    } catch (e) {
      AppLogger.error('Feedback', 'Failed to submit', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit feedback: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Doctor Feedback')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your feedback helps us improve our services and recognize our outstanding doctors.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select Doctor', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  if (_isLoadingDoctors)
                    const Center(child: CircularProgressIndicator())
                  else if (_doctors.isEmpty)
                    const Text('No doctors available', style: TextStyle(color: AppColors.textMuted))
                  else
                    DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                      hint: const Text('Choose a doctor'),
                      initialValue: _selectedDoctorId,
                      items: _doctors.map((d) {
                        return DropdownMenuItem<String>(
                          value: d['_id']?.toString() ?? d['id']?.toString(),
                          child: Text('Dr. ${d['userId']?['name'] ?? d['name'] ?? 'Unknown'} - ${d['specialization'] ?? ''}', overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedDoctorId = v),
                    ),
                  
                  const SizedBox(height: 24),
                  const Text('Rating', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starValue = index + 1;
                      return IconButton(
                        icon: Icon(
                          starValue <= _rating ? LucideIcons.star : LucideIcons.star,
                          color: starValue <= _rating ? AppColors.goldPrimary : Colors.grey.shade300,
                          size: 40,
                        ),
                        onPressed: () => setState(() => _rating = starValue),
                      );
                    }),
                  ),
                  
                  const SizedBox(height: 24),
                  const Text('Additional Comments (Optional)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Share your experience...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            AppButton(
              label: 'Submit Feedback',
              variant: AppButtonVariant.primary,
              width: double.infinity,
              isLoading: _isSubmitting,
              onPressed: _submitFeedback,
            ),
          ],
        ),
      ),
    );
  }
}
