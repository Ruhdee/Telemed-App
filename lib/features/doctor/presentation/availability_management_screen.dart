import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/glass_panel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Doctor Availability Management Screen
/// Matches the web frontend AvailabilityManager.tsx functionality
class AvailabilityManagementScreen extends StatefulWidget {
  const AvailabilityManagementScreen({super.key});

  @override
  State<AvailabilityManagementScreen> createState() => _AvailabilityManagementScreenState();
}

class _AvailabilityManagementScreenState extends State<AvailabilityManagementScreen> {
  final _apiClient = ApiClient();
  final _storage = const FlutterSecureStorage();
  
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 17, minute: 0);
  int _slotDuration = 30;
  int _maxCapacity = 1;
  
  List<DoctorSlot> _slots = [];
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    _fetchSlots();
  }

  Future<void> _fetchSlots() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final token = await _storage.read(key: 'auth_token');
      final userData = await _storage.read(key: 'user_data');
      
      if (token == null || userData == null) {
        throw Exception('Not authenticated');
      }

      final userJson = jsonDecode(userData) as Map<String, dynamic>;
      final doctorId = userJson['id'];
      if (doctorId == null) throw Exception('Doctor ID not found');

      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final response = await _apiClient.get(
        '${ApiConstants.doctorSlotsEndpoint(int.parse(doctorId.toString()))}?date=$dateStr',
      );

      if (response.data is List) {
        setState(() {
          _slots = (response.data as List)
              .map((json) => DoctorSlot.fromJson(json))
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to fetch slots: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAvailability() async {
    // Validate times
    final startMinutes = _startTime.hour * 60 + _startTime.minute;
    final endMinutes = _endTime.hour * 60 + _endTime.minute;
    
    if (startMinutes >= endMinutes) {
      setState(() {
        _errorMessage = 'Start time must be before end time';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      final startTimeStr = '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';
      final endTimeStr = '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}';

      final response = await _apiClient.post(
        ApiConstants.availabilityEndpoint,
        data: {
          'date': dateStr,
          'startTime': startTimeStr,
          'endTime': endTimeStr,
          'slotDuration': _slotDuration,
          'maxCapacity': _maxCapacity,
        },
      );

      if (response.data is Map && response.data['generatedSlots'] != null) {
        setState(() {
          _slots = (response.data['generatedSlots'] as List)
              .map((json) => DoctorSlot.fromJson(json))
              .toList();
          _successMessage = 'Availability saved and slots generated successfully!';
          _isSaving = false;
        });

        // Clear success message after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _successMessage = null);
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to save availability: $e';
        _isSaving = false;
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
        title: const Text('Manage Availability'),
        backgroundColor: AppColors.goldPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GlassPanel(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configure Time Slots',
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
                        setState(() => _selectedDate = picked);
                        _fetchSlots();
                      }
                    },
                  ),
                  const Divider(),

                  // Start Time
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time, color: AppColors.goldPrimary),
                    title: const Text('Start Time'),
                    subtitle: Text(_startTime.format(context)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _startTime,
                      );
                      if (picked != null) {
                        setState(() => _startTime = picked);
                      }
                    },
                  ),
                  const Divider(),

                  // End Time
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.access_time_filled, color: AppColors.goldPrimary),
                    title: const Text('End Time'),
                    subtitle: Text(_endTime.format(context)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _endTime,
                      );
                      if (picked != null) {
                        setState(() => _endTime = picked);
                      }
                    },
                  ),
                  const Divider(),

                  // Slot Duration
                  Row(
                    children: [
                      const Icon(Icons.timer_outlined, color: AppColors.goldPrimary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Slot Duration (minutes)'),
                            DropdownButton<int>(
                              value: _slotDuration,
                              isExpanded: true,
                              items: [15, 20, 30, 45, 60].map((duration) {
                                return DropdownMenuItem(
                                  value: duration,
                                  child: Text('$duration mins'),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _slotDuration = value);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(),

                  // Max Capacity
                  Row(
                    children: [
                      const Icon(Icons.people_outline, color: AppColors.goldPrimary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Max Patients per Slot'),
                            Slider(
                              value: _maxCapacity.toDouble(),
                              min: 1,
                              max: 10,
                              divisions: 9,
                              label: _maxCapacity.toString(),
                              activeColor: AppColors.goldPrimary,
                              onChanged: (value) {
                                setState(() => _maxCapacity = value.toInt());
                              },
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _maxCapacity.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Error/Success Messages
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  if (_successMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  if (_errorMessage != null || _successMessage != null)
                    const SizedBox(height: 16),

                  // Save Button
                  AppButton(
                    label: 'Generate & Save Slots',
                    variant: AppButtonVariant.primary,
                    isLoading: _isSaving,
                    onPressed: _saveAvailability,
                    width: double.infinity,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Generated Slots Display
            GlassPanel(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Generated Slots for ${DateFormat('MMM d, yyyy').format(_selectedDate)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_isLoading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (_slots.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          'No slots configured for this date yet.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: _slots.map((slot) {
                        final isFull = slot.status == 'full' || 
                                       slot.bookedCount >= slot.maxCapacity;
                        final isPartial = slot.bookedCount > 0 && !isFull;
                        
                        Color backgroundColor;
                        Color textColor;
                        
                        if (isFull) {
                          backgroundColor = Colors.red.shade50;
                          textColor = Colors.red.shade700;
                        } else if (isPartial) {
                          backgroundColor = Colors.orange.shade50;
                          textColor = Colors.orange.shade800;
                        } else {
                          backgroundColor = Colors.green.shade50;
                          textColor = Colors.green.shade700;
                        }

                        return Container(
                          width: 110,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: backgroundColor,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: textColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                _formatTime(slot.startTime),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatTime(slot.endTime),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textColor.withOpacity(0.8),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${slot.bookedCount}/${slot.maxCapacity}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
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
