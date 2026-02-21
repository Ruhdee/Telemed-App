import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/glass_panel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Patient Appointment Booking Screen
/// Matches the web frontend BookAppointmentModal.tsx functionality  
class BookAppointmentScreen extends StatefulWidget {
  const BookAppointmentScreen({super.key});

  @override
  State<BookAppointmentScreen> createState() => _BookAppointmentScreenState();
}

class _BookAppointmentScreenState extends State<BookAppointmentScreen> {
  final _apiClient = ApiClient();
  final _storage = const FlutterSecureStorage();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book Appointment'),
        backgroundColor: AppColors.goldPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Step indicator
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildStepIndicator(0, 'Doctor'),
                  _buildStepConnector(0),
                  _buildStepIndicator(1, 'Details'),
                  _buildStepConnector(1),
                  _buildStepIndicator(2, 'Review'),
                  _buildStepConnector(2),
                  _buildStepIndicator(3, 'Payment'),
                ],
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
            if (_currentStep == 0) _buildDoctorSelectionStep(),
            if (_currentStep == 1) _buildDetailsStep(),
            if (_currentStep == 2) _buildReviewStep(),
            if (_currentStep == 3) _buildPaymentStep(),
            if (_currentStep == 4) _buildSuccessStep(),
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

  Widget _buildDoctorSelectionStep() {
    return GlassPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select a Doctor',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          if (_isLoadingDoctors)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_doctors.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('No doctors available'),
              ),
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
                      color: isSelected ? AppColors.goldPrimary : Colors.grey.shade300,
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
            label: 'Next',
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

  Widget _buildDetailsStep() {
    return GlassPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Schedule & Symptoms',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // Date Selection
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today, color: AppColors.goldPrimary),
            title: const Text('Select Date'),
            subtitle: Text(DateFormat('EEEE, MMM d, yyyy').format(_selectedDate)),
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
          const Text(
            'Available Times',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          if (_isLoadingSlots)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_availableSlots.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('No slots available for this date'),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableSlots
                  .where((slot) => 
                      slot.status == 'available' && 
                      slot.bookedCount < slot.maxCapacity)
                  .map((slot) {
                final isSelected = _selectedSlotId == slot.id;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedSlotId = slot.id);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.goldPrimary : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? AppColors.goldPrimary : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: Text(
                      _formatTime(slot.startTime),
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
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
            decoration: const InputDecoration(
              labelText: 'Symptoms / Reason',
              hintText: 'Describe your symptoms (e.g., fever, headache)...',
              alignLabelWithHint: true,
            ),
          ),

          const SizedBox(height: 20),

          // Appointment Type
          const Text(
            'Consultation Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _appointmentType = 'Video Consult'),
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
                    child: const Text(
                      'Video Consult',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _appointmentType = 'Offline Review'),
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
                    child: const Text(
                      'Offline Review',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.bold),
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
                  label: 'Back',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => setState(() => _currentStep = 0),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Review',
                  variant: AppButtonVariant.primary,
                  onPressed: (_selectedSlotId != null && 
                             _symptomsController.text.trim().isNotEmpty)
                      ? () {
                          if (_selectedSlotId == null) {
                            setState(() {
                              _errorMessage = 'Please select a time slot';
                            });
                            return;
                          }
                          if (_symptomsController.text.trim().isEmpty) {
                            setState(() {
                              _errorMessage = 'Please describe your symptoms';
                            });
                            return;
                          }
                          setState(() => _currentStep = 2);
                        }
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    final selectedDoctor = _doctors.firstWhere((d) => d.id == _selectedDoctorId);
    final selectedSlot = _availableSlots.firstWhere((s) => s.id == _selectedSlotId);

    return GlassPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Confirm Details',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
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
                _buildDetailRow('Doctor', 'Dr. ${selectedDoctor.name}'),
                const Divider(height: 24),
                _buildDetailRow('Date', DateFormat('MMM d, yyyy').format(_selectedDate)),
                const Divider(height: 24),
                _buildDetailRow('Time', _formatTime(selectedSlot.startTime)),
                const Divider(height: 24),
                _buildDetailRow('Type', _appointmentType),
                const Divider(height: 24),
                _buildDetailRow('Fee', '₹200.00', isHighlighted: true),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Back',
                  variant: AppButtonVariant.secondary,
                  onPressed: () => setState(() => _currentStep = 1),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Continue to Payment',
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

  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isHighlighted ? AppColors.goldPrimary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentStep() {
    return GlassPanel(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(
            Icons.payment,
            size: 64,
            color: AppColors.goldPrimary,
          ),
          const SizedBox(height: 16),
          const Text(
            'Scan & Pay',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Scan the QR code below using GPay to pay ₹200',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.goldPrimary, width: 2),
            ),
            child: const Column(
              children: [
                Icon(Icons.qr_code, size: 200, color: AppColors.goldPrimary),
                SizedBox(height: 8),
                Text(
                  'GPay QR Code',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          AppButton(
            label: 'Pay ₹200',
            variant: AppButtonVariant.primary,
            isLoading: _isPaymentProcessing,
            onPressed: _confirmPayment,
            width: double.infinity,
          ),

          const SizedBox(height: 12),

          TextButton(
            onPressed: () => setState(() => _currentStep = 2),
            child: const Text('Back to Review'),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
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
            child: const Icon(
              Icons.check,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Appointment Booked!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your appointment has been confirmed. You will receive a notification shortly with the consultation details.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 32),
          AppButton(
            label: 'Done',
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

  Doctor({
    required this.id,
    required this.name,
    required this.specialization,
  });

  factory Doctor.fromJson(Map<String, dynamic> json) {
    return Doctor(
      id: json['id'] as int,
      name: json['name'] as String,
      specialization: json['specialization'] as String? ?? 'General',
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
    return DoctorSlot(
      id: json['id'] as int,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      status: json['status'] as String,
      bookedCount: json['bookedCount'] as int,
      maxCapacity: json['maxCapacity'] as int,
    );
  }
}
