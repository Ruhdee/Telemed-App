import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/glass_panel.dart';

class OfflineConsultationListScreen extends ConsumerStatefulWidget {
  const OfflineConsultationListScreen({super.key});

  @override
  ConsumerState<OfflineConsultationListScreen> createState() => _OfflineConsultationListScreenState();
}

class _OfflineConsultationListScreenState extends ConsumerState<OfflineConsultationListScreen> {
  bool _isLoading = true;
  List<dynamic> _consultations = [];

  @override
  void initState() {
    super.initState();
    _loadConsultations();
  }

  Future<void> _loadConsultations() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('${ApiConstants.offlineConsultationEndpoint}/patient');
      
      final data = response.data;
      if (data is Map<String, dynamic> && data['data'] != null) {
        setState(() {
          _consultations = data['data'] as List<dynamic>;
        });
      }
    } catch (e) {
      AppLogger.error('Offline Consults', 'Failed to load patient consultations', e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Video Consults'),
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
                    return _ConsultationCard(consult: consult)
                        .animate()
                        .fadeIn(delay: (index * 50).ms);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.videoOff, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          const Text('No Video Consults', style: TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

class _ConsultationCard extends StatelessWidget {
  final Map<String, dynamic> consult;

  const _ConsultationCard({required this.consult});

  @override
  Widget build(BuildContext context) {
    final status = consult['status'] ?? 'pending';
    final dateStr = consult['createdAt'];
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    consult['chiefComplaint'] ?? 'Video Consultation',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              consult['symptomsDescription'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(LucideIcons.calendar, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                Text(
                  DateFormat('MMM dd, yyyy - hh:mm a').format(date),
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
            if (consult['doctorReview'] != null && status == 'reviewed') ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(LucideIcons.checkCircle, size: 14, color: AppColors.success),
                        SizedBox(width: 6),
                        Text('Doctor Notes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.success)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      consult['doctorReview'],
                      style: const TextStyle(fontSize: 13, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;

    switch (status.toLowerCase()) {
      case 'reviewed':
        color = AppColors.success;
        icon = LucideIcons.checkCircle;
        label = 'Reviewed';
        break;
      case 'rejected':
        color = AppColors.error;
        icon = LucideIcons.xCircle;
        label = 'Rejected';
        break;
      case 'pending':
      default:
        color = AppColors.warning;
        icon = LucideIcons.clock;
        label = 'Pending';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
