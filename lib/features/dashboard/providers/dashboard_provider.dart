import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/app_logger.dart';

/// Dashboard state providers for appointments, vitals, and timeline data.

// ── Appointment Model ─────────────────────────────────────────

class Appointment {
  final String id;
  final String patientName;
  final String patientEmail;
  final String doctorName;
  final String chiefComplaint;
  final String symptomsDescription;
  final String status;
  final DateTime scheduledDate;
  final int? riskScore;
  final String? riskLevel;

  const Appointment({
    required this.id,
    required this.patientName,
    required this.patientEmail,
    required this.doctorName,
    required this.chiefComplaint,
    required this.symptomsDescription,
    required this.status,
    required this.scheduledDate,
    this.riskScore,
    this.riskLevel,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      patientName: json['patientName'] as String? ?? 'Unknown',
      patientEmail: json['patientEmail'] as String? ?? '',
      doctorName: json['doctorName'] as String? ?? 'Dr. Unknown',
      chiefComplaint: json['chiefComplaint'] as String? ?? '',
      symptomsDescription: json['symptomsDescription'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      scheduledDate: DateTime.tryParse(json['scheduledDate']?.toString() ?? '') ?? DateTime.now(),
      riskScore: json['aiTriage']?['score'] as int?,
      riskLevel: json['aiTriage']?['riskLevel'] as String?,
    );
  }
}

// ── Vitals Model ──────────────────────────────────────────────

class VitalSign {
  final String label;
  final String value;
  final String unit;
  final String icon;
  final double? trend; // positive = up, negative = down

  const VitalSign({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    this.trend,
  });
}

// ── Dashboard State ───────────────────────────────────────────

class DashboardState {
  final List<Appointment> appointments;
  final List<VitalSign> vitals;
  final bool isLoading;
  final String? error;

  const DashboardState({
    this.appointments = const [],
    this.vitals = const [],
    this.isLoading = false,
    this.error,
  });

  DashboardState copyWith({
    List<Appointment>? appointments,
    List<VitalSign>? vitals,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      appointments: appointments ?? this.appointments,
      vitals: vitals ?? this.vitals,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ── Dashboard Notifier ────────────────────────────────────────

class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier() : super(const DashboardState(isLoading: true)) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    AppLogger.state('Loading dashboard data');
    // Set mock vitals data (mirrors React dashboard page's hardcoded vitals)
    state = state.copyWith(
      isLoading: false,
      vitals: const [
        VitalSign(label: 'Heart Rate', value: '72', unit: 'bpm', icon: 'heart', trend: 0.5),
        VitalSign(label: 'SpO2', value: '98', unit: '%', icon: 'activity', trend: 0.1),
        VitalSign(label: 'Blood Glucose', value: '110', unit: 'mg/dL', icon: 'droplet', trend: -0.3),
        VitalSign(label: 'Blood Pressure', value: '120/80', unit: 'mmHg', icon: 'gauge', trend: 0.0),
      ],
    );
    AppLogger.state('Dashboard data loaded');
  }

  /// Add or update an appointment (called from Socket.IO events).
  void addAppointment(Appointment appt) {
    AppLogger.state('New appointment: ${appt.id}');
    final existing = state.appointments.toList();
    final idx = existing.indexWhere((a) => a.id == appt.id);
    if (idx >= 0) {
      existing[idx] = appt;
    } else {
      existing.insert(0, appt);
    }
    state = state.copyWith(appointments: existing);
  }

  /// Set appointments list.
  void setAppointments(List<Appointment> appointments) {
    state = state.copyWith(appointments: appointments);
    AppLogger.state('Appointments updated: ${appointments.length} items');
  }
}

// ── Providers ──────────────────────────────────────────────────

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  return DashboardNotifier();
});
