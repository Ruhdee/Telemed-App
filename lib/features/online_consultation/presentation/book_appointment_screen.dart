import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/glass_panel.dart';

/// Patient Appointment Booking Screen
/// Matches the web frontend BookAppointmentModal.tsx functionality
class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _apiClient = ApiClient();
  final _symptomsController = TextEditingController();

  int _currentStep = 0;
  List<Doctor> _doctors = [];
  int? _selectedDoctorId;
  DateTime _selectedDate = DateTime.now();
  int? _selectedSlotId;
  String _appointmentType = 'Video Consult';
  List<DoctorSlot> _availableSlots = [];

  bool _isLoadingDoctors = false;
  bool _isLoadingSlots = false;
  bool _isBooking = false;
  bool _isPaymentProcessing = false;
  int? _createdAppointmentId;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  @override
  void dispose() {
    _symptomsController.dispose();
    super.dispose();
  }

  Future<void> _fetchDoctors() async {
    setState(() {
      _isLoadingDoctors = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiClient.get(ApiConstants.doctorsEndpoint);

      if (response.data is List) {
        setState(() {
          _doctors = (response.data as List)
              .map((json) => Doctor.fromJson(json))
              .toList();
          _isLoadingDoctors = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch doctors: $e';
        _isLoadingDoctors = false;
      });
    }
  }

  Future<void> _fetchSlots() async {
    if (_selectedDoctorId == null) return;

    setState(() {
      _isLoadingSlots = true;
      _errorMessage = null;
      _selectedSlotId = null;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final response = await _apiClient.get(
        '${ApiConstants.doctorSlotsEndpoint(_selectedDoctorId!)}?date=$dateStr',
      );

      if (response.data is List) {
        setState(() {
          _availableSlots = (response.data as List)
              .map((json) => DoctorSlot.fromJson(json))
              .toList();
          _isLoadingSlots = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch slots: $e';
        _isLoadingSlots = false;
      });
    }
  }

  Future<void> _bookAppointment() async {
    if (_selectedDoctorId == null || _selectedSlotId == null) {
      setState(() {
        _errorMessage = 'Please select a doctor and time slot';
      });
      return;
    }

    setState(() {
      _isBooking = true;
      _errorMessage = null;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

      final response = await _apiClient.post(
        ApiConstants.appointmentsEndpoint,
        data: {
          'doctorId': _selectedDoctorId,
          'date': dateStr,
          'slotId': _selectedSlotId,
          'symptoms': _symptomsController.text.trim(),
          'type': _appointmentType,
        },
      );

      if (response.data is Map && response.data['id'] != null) {
        setState(() {
          _createdAppointmentId = response.data['id'] as int;
          _isBooking = false;
          _currentStep = 3; // Move to payment step
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to book appointment: $e';
        _isBooking = false;
      });
    }
  }

  Future<void> _confirmPayment() async {
    if (_createdAppointmentId == null) return;

    setState(() {
      _isPaymentProcessing = true;
      _errorMessage = null;
    });

    try {
      // Simulate payment processing delay
      await Future.delayed(const Duration(seconds: 2));

      final paymentId = 'GPAY-${DateTime.now().millisecondsSinceEpoch}';

      final response = await _apiClient.post(
        ApiConstants.appointmentPaymentEndpoint(_createdAppointmentId!),
        data: {'paymentId': paymentId},
      );

      if (response.statusCode == 200) {
        setState(() {
          _isPaymentProcessing = false;
          _currentStep = 4; // Move to success step
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Payment confirmation failed: $e';
        _isPaymentProcessing = false;
      });
    }
  }

  String _formatTime(String timeStr) {
    final parts = timeStr.split(':');
    if (parts.length < 2) return timeStr;

    int hours = int.parse(parts[0]);
    final minutes = parts[1];
    final period = hours >= 12 ? 'PM' : 'AM';

    hours = hours % 12;
    if (hours == 0) hours = 12;

    return '$hours:$minutes $period';
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(loc.translate('bookingAppointment')),
        backgroundColor: AppColors.goldPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Step indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStepIndicator(0, loc.translate('doctor')),
                    _buildStepConnector(0),
                    _buildStepIndicator(1, loc.translate('date')),
                    _buildStepConnector(1),
                    _buildStepIndicator(2, loc.translate('review')),
                    _buildStepConnector(2),
                    _buildStepIndicator(3, loc.translate('payment')),
                  ],
                ),
              ),
            ),

            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

            // Step content
            if (_currentStep == 0) _buildDoctorSelectionStep(loc),
            if (_currentStep == 1) _buildDetailsStep(loc),
            if (_currentStep == 2) _buildReviewStep(loc),
            if (_currentStep == 3) _buildPaymentStep(loc),
            if (_currentStep == 4) _buildSuccessStep(loc),
          ],
        ),
      ),
    );
  }

  Widget _buildStepIndicator(int stepIndex, String label) {
    final isActive = _currentStep == stepIndex;
    final isCompleted = _currentStep > stepIndex;

    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted || isActive
                ? AppColors.goldPrimary
                : Colors.grey.shade300,
          ),
          child: Center(
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : Text(
                    '${stepIndex + 1}',
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
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(int stepIndex) {
    final isCompleted = _currentStep > stepIndex;
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.only(bottom: 20),
      color: isCompleted ? AppColors.goldPrimary : Colors.grey.shade300,
    );
  }

  Widget _buildDoctorSelectionStep(AppLocalizations loc) {
    return GlassPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.translate('selectDoctor'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          if (_isLoadingDoctors)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const CircularProgressIndicator(
                      color: AppColors.goldPrimary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      loc.translate('loadingDoctors'),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else if (_doctors.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: Text(loc.translate('noDoctorsAvailable'))),
            )
          else
            ..._doctors.map((doctor) {
              final isSelected = _selectedDoctorId == doctor.id;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedDoctorId = doctor.id;
                  });
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.goldLight : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.goldPrimary
                          : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: AppColors.goldLight,
                        child: Text(
                          doctor.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.goldPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dr. ${doctor.name}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              doctor.specialization,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.goldPrimary,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),

          const SizedBox(height: 20),

          AppButton(
            label: loc.translate('next'),
            variant: AppButtonVariant.primary,
            onPressed: _selectedDoctorId != null
                ? () {
                    setState(() => _currentStep = 1);
                    _fetchSlots();
                  }
                : null,
            width: double.infinity,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsStep(AppLocalizations loc) {
    return GlassPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.translate('scheduleAndSymptoms'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // Date Selection
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(
              Icons.calendar_today,
              color: AppColors.goldPrimary,
            ),
            title: Text(loc.translate('selectDate')),
            subtitle: Text(
              DateFormat('EEEE, MMM d, yyyy').format(_selectedDate),
            ),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
              );
              if (picked != null) {
                setState(() {
                  _selectedDate = picked;
                  _selectedSlotId = null;
                });
                _fetchSlots();
              }
            },
          ),
          const Divider(),

          // Time Slots
          const SizedBox(height: 16),
          Text(
            loc.translate('availableTimes'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          if (_isLoadingSlots)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const CircularProgressIndicator(
                      color: AppColors.goldPrimary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      loc.translate('loadingSlots'),
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            )
          else if (_availableSlots.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Text(loc.translate('noSlotsForDate'))),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableSlots.map((slot) {
                final isFull =
                    slot.status == 'full' ||
                    slot.bookedCount >= slot.maxCapacity;
                final isSelected = _selectedSlotId == slot.id;
                return GestureDetector(
                  onTap: isFull
                      ? null
                      : () => setState(() => _selectedSlotId = slot.id),
                  child: Opacity(
                    opacity: isFull ? 0.5 : 1.0,
                    child: Stack(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isFull
                                ? Colors.grey.shade200
                                : isSelected
                                ? AppColors.goldPrimary
                                : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isFull
                                  ? Colors.grey.shade300
                                  : isSelected
                                  ? AppColors.goldPrimary
                                  : AppColors.goldPrimary.withValues(
                                      alpha: 0.4,
                                    ),
                              width: 2,
                            ),
                          ),
                          child: Text(
                            _formatTime(slot.startTime),
                            style: TextStyle(
                              color: isFull
                                  ? Colors.grey.shade500
                                  : isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (isFull)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200.withValues(
                                  alpha: 0.8,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                loc.translate('slotFull'),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 20),

          // Symptoms
          TextFormField(
            controller: _symptomsController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: loc.translate('symptomsReason'),
              hintText: loc.translate('symptomsPlaceholder'),
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 20),

          // Appointment Type
          Text(
            loc.translate('consultationType'),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _appointmentType = 'Video Consult'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _appointmentType == 'Video Consult'
                          ? AppColors.goldLight
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _appointmentType == 'Video Consult'
                            ? AppColors.goldPrimary
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      loc.translate('videoConsult'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      setState(() => _appointmentType = 'Offline Review'),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _appointmentType == 'Offline Review'
                          ? AppColors.goldLight
                          : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _appointmentType == 'Offline Review'
                            ? AppColors.goldPrimary
                            : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      loc.translate('offlineReview'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: loc.translate('back'),
                  variant: AppButtonVariant.secondary,
                  onPressed: () => setState(() => _currentStep = 0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: loc.translate('review'),
                  variant: AppButtonVariant.primary,
                  onPressed: () {
                    if (_selectedSlotId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(loc.translate('pleaseSelectSlot')),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }
                    if (_symptomsController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(loc.translate('pleaseFillSymptoms')),
                          backgroundColor: AppColors.error,
                        ),
                      );
                      return;
                    }
                    setState(() {
                      _errorMessage = null;
                      _currentStep = 2;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep(AppLocalizations loc) {
    final selectedDoctor = _doctors.firstWhere(
      (d) => d.id == _selectedDoctorId,
      orElse: () => Doctor(id: 0, name: '?', specialization: ''),
    );
    final selectedSlot = _availableSlots.firstWhere(
      (s) => s.id == _selectedSlotId,
      orElse: () => DoctorSlot(
        id: 0,
        startTime: '--',
        endTime: '--',
        status: 'available',
        bookedCount: 0,
        maxCapacity: 1,
      ),
    );

    return GlassPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.translate('confirmDetails'),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            loc.translate('reviewDetailsSubtitle'),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildDetailRow(
                  loc.translate('doctor'),
                  '${loc.translate('dr')} ${selectedDoctor.name}',
                ),
                const Divider(height: 24),
                _buildDetailRow(
                  loc.translate('date'),
                  DateFormat('MMM d, yyyy').format(_selectedDate),
                ),
                const Divider(height: 24),
                _buildDetailRow(
                  loc.translate('time'),
                  _formatTime(selectedSlot.startTime),
                ),
                const Divider(height: 24),
                _buildDetailRow(loc.translate('type'), _appointmentType),
                const Divider(height: 24),
                _buildDetailRow(
                  loc.translate('fee'),
                  '₹200.00',
                  isHighlighted: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: loc.translate('back'),
                  variant: AppButtonVariant.secondary,
                  onPressed: () => setState(() => _currentStep = 1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: loc.translate('continueToPayment'),
                  variant: AppButtonVariant.primary,
                  isLoading: _isBooking,
                  onPressed: _bookAppointment,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isHighlighted
                ? AppColors.goldPrimary
                : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStep(AppLocalizations loc) {
    return GlassPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.credit_card, size: 64, color: AppColors.goldPrimary),
          const SizedBox(height: 16),
          Text(
            loc.translate('scanAndPay'),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            loc.translate('scanQrInstruction'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.shade200,
                width: 2,
                style: BorderStyle.solid,
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.qr_code,
                  size: 200,
                  color: AppColors.goldPrimary,
                ),
                const SizedBox(height: 8),
                Text(
                  loc.translate('gpayQrCode'),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          AppButton(
            label: loc.translate('payAmount'),
            variant: AppButtonVariant.primary,
            isLoading: _isPaymentProcessing,
            onPressed: _confirmPayment,
            width: double.infinity,
          ),

          const SizedBox(height: 12),

          TextButton(
            onPressed: () => setState(() => _currentStep = 2),
            child: Text(loc.translate('backToReview')),
          ),

          const SizedBox(height: 8),
          Text(
            loc.translate('byClickingPayConfirm'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStep(AppLocalizations loc) {
    return GlassPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green,
            ),
            child: const Icon(Icons.check, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 24),
          Text(
            loc.translate('appointmentBookedTitle'),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            loc.translate('appointmentConfirmedDesc'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          AppButton(
            label: loc.translate('done'),
            variant: AppButtonVariant.primary,
            onPressed: () => Navigator.of(context).pop(),
            width: double.infinity,
          ),
        ],
      ),
    );
  }
}

/// Doctor Model
class Doctor {
  final int id;
  final String name;
  final String specialization;

  Doctor({required this.id, required this.name, required this.specialization});

  factory Doctor.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    return Doctor(
      id: rawId is int ? rawId : int.tryParse(rawId.toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      specialization: json['specialization']?.toString() ?? 'General',
    );
  }
}

/// Doctor Slot Model
class DoctorSlot {
  final int id;
  final String startTime;
  final String endTime;
  final String status;
  final int bookedCount;
  final int maxCapacity;

  DoctorSlot({
    required this.id,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.bookedCount,
    required this.maxCapacity,
  });

  factory DoctorSlot.fromJson(Map<String, dynamic> json) {
    int _toInt(dynamic v) =>
        v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;
    return DoctorSlot(
      id: _toInt(json['id']),
      startTime: json['startTime']?.toString() ?? '',
      endTime: json['endTime']?.toString() ?? '',
      status: json['status']?.toString() ?? 'available',
      bookedCount: _toInt(json['bookedCount']),
      maxCapacity: _toInt(json['maxCapacity']),
    );
  }
}
