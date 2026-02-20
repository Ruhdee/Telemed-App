import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/glass_panel.dart';

class OfflineConsultationReviewScreen extends ConsumerStatefulWidget {
  const OfflineConsultationReviewScreen({super.key});

  @override
  ConsumerState<OfflineConsultationReviewScreen> createState() => _OfflineConsultationReviewScreenState();
}

class _OfflineConsultationReviewScreenState extends ConsumerState<OfflineConsultationReviewScreen> {
  bool _isLoading = true;
  List<dynamic> _consultations = [];

  @override
  void initState() {
    super.initState();
    _loadPendingConsultations();
  }

  Future<void> _loadPendingConsultations() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('${ApiConstants.offlineConsultationEndpoint}/pending');
      
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        setState(() {
          _consultations = data['data'] as List<dynamic>;
        });
      }
    } catch (e) {
      AppLogger.error('Offline Review', 'Failed to load pending queue', e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitReview(String id, String notes) async {
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.patch(
        '${ApiConstants.offlineConsultationEndpoint}/$id/status',
        data: {
          'status': 'reviewed',
          'doctorReview': notes,
        },
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Review submitted successfully')),
        );
        _loadPendingConsultations(); // Reload
      }
    } catch (e) {
      AppLogger.error('Offline Review', 'Failed to submit review', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text('Failed to submit review: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Consultations'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _consultations.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _consultations.length,
                  itemBuilder: (context, index) {
                    final consult = _consultations[index];
                    return _ReviewCard(
                      consult: consult,
                      onSubmitReview: (notes) => _submitReview(consult['_id'], notes),
                    ).animate().fadeIn(delay: (index * 50).ms);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.checkSquare, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          const Text('All caught up!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('No pending offline consultations to review.', style: TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatefulWidget {
  final Map<String, dynamic> consult;
  final Function(String) onSubmitReview;

  const _ReviewCard({required this.consult, required this.onSubmitReview});

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool _isExpanded = false;
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final patientName = widget.consult['patientId']?['name'] ?? 'Unknown Patient';
    final dateStr = widget.consult['createdAt'];
    late DateTime date;
    try {
      date = dateStr != null ? DateTime.parse(dateStr) : DateTime.now();
    } catch (_) {
      date = DateTime.now();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.goldPrimary,
                child: Text(patientName[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              title: Text(patientName, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(DateFormat('MMM dd, hh:mm a').format(date)),
              trailing: IconButton(
                icon: Icon(_isExpanded ? LucideIcons.chevronUp : LucideIcons.chevronDown),
                onPressed: () => setState(() => _isExpanded = !_isExpanded),
              ),
            ),
            
            if (_isExpanded) ...[
              const Divider(),
              const SizedBox(height: 8),
              _buildDetailRow('Complaint', widget.consult['chiefComplaint'] ?? ''),
              _buildDetailRow('Symptoms', widget.consult['symptomsDescription'] ?? ''),
              if (widget.consult['mediaUrl'] != null)
                 _buildMediaLink(widget.consult['mediaUrl'], widget.consult['mediaType']),
              
              const SizedBox(height: 16),
              const Text('Doctor Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add assessment and prescription notes...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Submit Review & Notify Patient',
                variant: AppButtonVariant.primary,
                width: double.infinity,
                onPressed: () {
                  if (_notesController.text.isNotEmpty) {
                    widget.onSubmitReview(_notesController.text);
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildMediaLink(String url, String? type) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.goldPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(type == 'video' ? LucideIcons.video : LucideIcons.image, color: AppColors.goldDark, size: 20),
          const SizedBox(width: 12),
          Text(type == 'video' ? 'View Patient Video' : 'View Patient Image', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.goldDark)),
        ],
      ),
    );
  }
}
