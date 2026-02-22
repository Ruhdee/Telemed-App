import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/utils/app_logger.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/domain/user_model.dart';

class Appointment {
  final String id;
  final String doctorName;
  final String patientName;
  final String chiefComplaint;
  final String? riskLevel;
  final String status;
  final DateTime scheduledDate;

  Appointment({
    required this.id,
    required this.doctorName,
    required this.patientName,
    required this.chiefComplaint,
    this.riskLevel,
    required this.status,
    required this.scheduledDate,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['_id'] ?? json['id']?.toString() ?? '',
      doctorName: (json['doctorId'] is Map)
          ? (json['doctorId']['name'] ?? 'Unknown Doctor')
          : json['doctorName'] ?? 'Unknown Doctor',
      patientName: (json['patientId'] is Map)
          ? (json['patientId']['name'] ?? 'Unknown Patient')
          : json['patientName'] ?? 'Unknown Patient',
      chiefComplaint: json['symptoms'] ?? json['chiefComplaint'] ?? 'General Consultation',
      riskLevel: json['riskLevel'],
      status: json['status'] ?? 'pending',
      scheduledDate: json['date'] != null ? DateTime.tryParse(json['date']) ?? DateTime.now() : DateTime.now(),
    );
  }
}

class VitalSign {
  final String label;
  final String value;
  final String unit;
  final String icon;

  VitalSign({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
  });
}

class DashboardState {
  final bool isLoading;
  final List<VitalSign> vitals;
  final List<Appointment> appointments;

  DashboardState({
    this.isLoading = false,
    this.vitals = const [],
    this.appointments = const [],
  });

  DashboardState copyWith({
    bool? isLoading,
    List<VitalSign>? vitals,
    List<Appointment>? appointments,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      vitals: vitals ?? this.vitals,
      appointments: appointments ?? this.appointments,
    );
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final authState = ref.watch(authProvider);
  return DashboardNotifier(ref.read(apiClientProvider), authState.valueOrNull);
});

class DashboardNotifier extends StateNotifier<DashboardState> {
  final ApiClient _apiClient;
  final User? _user;

  DashboardNotifier(this._apiClient, this._user) : super(DashboardState()) {
    if (_user != null) {
      _loadDashboard();
    }
  }

  Future<void> _loadDashboard() async {
    state = state.copyWith(isLoading: true);
    try {
      if (_user!.role == UserRole.doctor) {
        state = state.copyWith(vitals: [
          VitalSign(label: 'Total Patients', value: '124', unit: '', icon: 'users'),
          VitalSign(label: 'Avg Rating', value: '4.8', unit: '⭐', icon: 'star'),
        ]);
        await _fetchDoctorAppointments();
      } else {
        await _fetchPatientData();
      }
    } catch (e) {
      AppLogger.error('Dashboard', 'Failed to load', e);
    } finally {
      if (mounted) state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _fetchPatientData() async {
    // Hardcoded vitals matching web frontend (dashboard/page.tsx)
    List<VitalSign> vitals = [
      VitalSign(label: 'Heart Rate', value: '72', unit: 'bpm', icon: 'heart'),
      VitalSign(label: 'BP', value: '120/80', unit: 'mmHg', icon: 'activity'),
      VitalSign(label: 'Sleep', value: '7h 30m', unit: '', icon: 'moon'),
    ];

    List<Appointment> appointments = [];
    try {
      final apptRes = await _apiClient.get(ApiConstants.patientAppointmentsEndpoint);
      final data = apptRes.data;
      if (data != null) {
        final List list = data is List ? data : (data['data'] ?? []);
        appointments = list.map((e) => Appointment.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      AppLogger.error('Dashboard', 'Failed to fetch appointments', e);
    }

    if (mounted) state = state.copyWith(vitals: vitals, appointments: appointments);
  }

  Future<void> _fetchDoctorAppointments() async {
    List<Appointment> appointments = [];
    try {
      final apptRes = await _apiClient.get(ApiConstants.doctorAppointmentsEndpoint);
      final data = apptRes.data;
      if (data != null) {
        final List list = data is List ? data : (data['data'] ?? []);
        appointments = list.map((e) => Appointment.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      AppLogger.error('Dashboard', 'Failed to fetch doctor appointments', e);
    }

    if (mounted) state = state.copyWith(appointments: appointments);
  }
}
