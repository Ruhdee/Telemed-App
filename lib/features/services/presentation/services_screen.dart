import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/constants/api_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/glass_panel.dart';

class ServicesScreen extends ConsumerStatefulWidget {
  const ServicesScreen({super.key});

  @override
  ConsumerState<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends ConsumerState<ServicesScreen> {
  int _currentStep = 1;
  
  // Step 1: Specializations
  bool _isLoadingSpecs = true;
  List<dynamic> _specializations = [];
  Map<String, dynamic>? _selectedSpec;

  // Step 2: Doctors in Specialization
  bool _isLoadingDoctors = false;
  List<dynamic> _doctors = [];
  Map<String, dynamic>? _selectedDoctor;

  // Step 3: Appointment Booking
  final _symptomsController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _appointmentType = 'Video'; // Video, Audio, In-Person
  bool _isBooking = false;

  @override
  void initState() {
    super.initState();
    _loadSpecializations();
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  Future<void> _loadSpecializations() async {
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get(ApiConstants.specializationsEndpoint);
      if (response.data != null && response.data is Map<String, dynamic>) {
        setState(() {
          _specializations = response.data['data'] as List<dynamic>? ?? [];
        });
      }
    } catch (e) {
      AppLogger.error('Services', 'Failed to load specializations', e);
    } finally {
      if (mounted) setState(() => _isLoadingSpecs = false);
    }
  }

  Future<void> _loadDoctorsForSpec(String specName) async {
    setState(() => _isLoadingDoctors = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('${ApiConstants.specializationsEndpoint}/$specName');
      if (response.data != null && response.data is Map<String, dynamic>) {
        setState(() {
          _doctors = response.data['data'] as List<dynamic>? ?? [];
        });
      }
    } catch (e) {
      AppLogger.error('Services', 'Failed to load doctors for $specName', e);
    } finally {
      if (mounted) setState(() => _isLoadingDoctors = false);
    }
  }

  Future<void> _bookAppointment() async {
    if (_symptomsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your symptoms'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isBooking = true);
    try {
      final apiClient = ref.read(apiClientProvider);
      await apiClient.post(
        ApiConstants.appointmentsEndpoint,
        data: {
          'doctorId': _selectedDoctor!['_id'] ?? _selectedDoctor!['id'],
          'date': _selectedDate.toIso8601String(),
          'type': _appointmentType,
          'symptoms': _symptomsController.text,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Appointment booked successfully!'), backgroundColor: AppColors.success),
        );
        context.pop();
      }
    } catch (e) {
      AppLogger.error('Services', 'Failed to book', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to book appointment: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        leading: _currentStep > 1
            ? IconButton(
                icon: const Icon(LucideIcons.arrowLeft),
                onPressed: () => setState(() => _currentStep--),
              )
            : null,
      ),
      body: Column(
        children: [
          _buildProgressIndicator(),
          Expanded(
            child: _currentStep == 1
                ? _buildStep1Specializations()
                : _currentStep == 2
                    ? _buildStep2Doctors()
                    : _buildStep3Booking(),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepCircle(1, 'Service'),
          _buildStepLine(2),
          _buildStepCircle(2, 'Doctor'),
          _buildStepLine(3),
          _buildStepCircle(3, 'Book'),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? AppColors.goldPrimary : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? AppColors.goldPrimary : Colors.grey.shade600,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int targetStep) {
    final isActive = _currentStep >= targetStep;
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
        color: isActive ? AppColors.goldPrimary : Colors.grey.shade200,
      ),
    );
  }

  Widget _buildStep1Specializations() {
    if (_isLoadingSpecs) return const Center(child: CircularProgressIndicator());
    if (_specializations.isEmpty) {
      return const Center(child: Text('No specializations available', style: TextStyle(color: AppColors.textMuted)));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: _specializations.length,
      itemBuilder: (context, index) {
        final spec = _specializations[index];
        final name = spec['name'] ?? 'Unknown';
        
        return InkWell(
          onTap: () {
            setState(() {
              _selectedSpec = spec;
              _currentStep = 2;
            });
            _loadDoctorsForSpec(name);
          },
          borderRadius: BorderRadius.circular(16),
          child: GlassPanel(
            borderColor: Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.goldPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.stethoscope, color: AppColors.goldPrimary),
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep2Doctors() {
    if (_isLoadingDoctors) return const Center(child: CircularProgressIndicator());
    if (_doctors.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(LucideIcons.userX, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('No doctors available for ${_selectedSpec?['name']}', style: const TextStyle(color: AppColors.textMuted)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _doctors.length,
      itemBuilder: (context, index) {
        final doc = _doctors[index];
        final name = doc['userId']?['name'] ?? doc['name'] ?? 'Unknown';
        final exp = doc['experience'] ?? 0;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassPanel(
            borderColor: Colors.transparent,
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppColors.goldPrimary,
                child: Icon(LucideIcons.user, color: Colors.white),
              ),
              title: Text('Dr. $name', style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('$exp years experience\n${_selectedSpec?['name']}', style: const TextStyle(fontSize: 12)),
              trailing: AppButton(
                label: 'Book',
                variant: AppButtonVariant.primary,
                onPressed: () {
                  setState(() {
                    _selectedDoctor = doc;
                    _currentStep = 3;
                  });
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStep3Booking() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassPanel(
            child: Row(
              children: [
                const CircleAvatar(backgroundColor: AppColors.goldPrimary, child: Icon(LucideIcons.user, color: Colors.white)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dr. ${_selectedDoctor?['userId']?['name'] ?? _selectedDoctor?['name'] ?? 'Unknown'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${_selectedSpec?['name'] ?? ''}', style: const TextStyle(color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          const Text('Date & Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (date != null) {
                if (!context.mounted) return;
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(_selectedDate),
                );
                if (time != null) {
                  setState(() {
                    _selectedDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                  });
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.calendar, size: 20, color: AppColors.goldPrimary),
                  const SizedBox(width: 12),
                  Text(DateFormat('MMM dd, yyyy - hh:mm a').format(_selectedDate), style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          const Text('Consultation Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _appointmentType,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            items: ['Video', 'Audio', 'In-Person'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (v) => setState(() => _appointmentType = v!),
          ),

          const SizedBox(height: 24),
          const Text('Symptoms', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          TextField(
            controller: _symptomsController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Briefly describe your symptoms...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          
          const SizedBox(height: 32),
          AppButton(
            label: 'Confirm Booking',
            variant: AppButtonVariant.primary,
            width: double.infinity,
            isLoading: _isBooking,
            onPressed: _bookAppointment,
          ),
        ],
      ),
    );
  }
}
