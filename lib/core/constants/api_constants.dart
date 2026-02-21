import 'dart:io';
import 'package:flutter/foundation.dart';

/// Centralized API configuration for the TeleMedCare app.
/// 
/// Automatically uses the correct IP based on your build type:
/// - Running from IDE/Debug: Uses emulator IP (10.0.2.2)
/// - Installed APK: Uses physical device IP (your computer's local IP)
/// 
/// SETUP: Just change `_localNetworkIp` to your computer's IP address!
/// - Windows: Run 'ipconfig' → look for IPv4 Address (e.g., 192.168.1.105)
/// - Mac/Linux: Run 'ifconfig' or 'ip addr'
class ApiConstants {
  ApiConstants._();

  /// ════════════════════════════════════════════════════════════════════
  /// 🔧 CONFIGURE THIS: Your computer's IP address on local network
  /// ════════════════════════════════════════════════════════════════════
  static const String _localNetworkIp = '10.10.10.231';  // ← Change this to YOUR IP!
  
  /// Backend server port
  static const int _port = 5001;

  /// ════════════════════════════════════════════════════════════════════
  /// 🎛️ DEVICE MODE SELECTOR
  /// - null: Auto-detect (emulator when debugging, physical otherwise)
  /// - true: Force emulator IP (10.0.2.2)
  /// - false: Force physical device IP
  /// ════════════════════════════════════════════════════════════════════
  static const bool? _forceEmulatorMode = null;  // ← null = auto, true = emulator, false = physical

  /// Determines which IP to use
  static String get _serverIp {
    // If force mode is set, use that
    if (_forceEmulatorMode != null) {
      return _forceEmulatorMode! ? '10.0.2.2' : _localNetworkIp;
    }
    
    // Auto-detect: Use emulator IP only in debug mode (when running from IDE)
    // In release/profile mode or installed APK, use physical device IP
    if (kDebugMode && Platform.isAndroid) {
      return '10.0.2.2';  // Emulator
    }
    
    return _localNetworkIp;  // Physical device
  }

  /// Backend base URL (HTTP)
  static String get baseUrl {
    final url = 'http://$_serverIp:$_port';
    if (kDebugMode) {
      print('[ApiConstants] Using baseUrl: $url');
    }
    return url;
  }

  /// WebSocket URL
  static String get copilotWsUrl {
    final url = 'ws://$_serverIp:$_port';
    if (kDebugMode) {
      print('[ApiConstants] Using wsUrl: $url');
    }
    return url;
  }

  /// TomTom Maps API key
  static const String tomtomApiKey = 'AHFi7q46N4j8cgLhMASvdEWJIACzxVCl';

  // ── Auth Endpoints ───────────────────────────────────────────
  static const String loginEndpoint = '/api/login';
  static const String registerEndpoint = '/api/register';

  // ── Doctor / Specialization (public) ─────────────────────────
  static const String doctorsEndpoint = '/api/doctors';
  static const String specializationsEndpoint = '/api/specializations';

  // ── Appointments ─────────────────────────────────────────────
  static const String appointmentsEndpoint = '/api/appointments';
  static const String doctorAppointmentsEndpoint = '/api/appointments/doctor';
  static const String patientAppointmentsEndpoint = '/api/appointments/patient';
  
  // Helper to get appointment payment confirmation endpoint
  static String appointmentPaymentEndpoint(int appointmentId) => 
      '/api/appointments/$appointmentId/confirm-payment';

  // ── Doctor Availability & Slots ──────────────────────────────
  static const String availabilityEndpoint = '/api/availability';
  static const String myAvailabilityEndpoint = '/api/availability/me';
  
  // Helper to get slots for a specific doctor
  static String doctorSlotsEndpoint(int doctorId) => 
      '/api/doctors/$doctorId/slots';

  // ── Records / OCR ────────────────────────────────────────────
  static const String scanPrescriptionEndpoint = '/api/scan-prescription';
  static const String scanBloodReportEndpoint = '/api/scan-blood-report';
  static const String prescriptionsEndpoint = '/api/prescriptions';
  static const String reportsEndpoint = '/api/reports';

  // ── Chatbot ──────────────────────────────────────────────────
  static const String chatbotEndpoint = '/api/chatbot/chat';

  // ── Offline Consultation ─────────────────────────────────────
  static const String offlineConsultationEndpoint = '/api/offline-consultation';

  // ── AI Prediction ────────────────────────────────────────────
  static const String predictEndpoint = '/api/predict';

  // ── Pharmacy ─────────────────────────────────────────────────
  static const String pharmaInventoryEndpoint = '/api/pharma/inventory';
  static const String pharmaCheckoutEndpoint = '/api/pharma/checkout';
  static const String pharmaOrdersEndpoint = '/api/pharma/orders';

  // ── Demographics ─────────────────────────────────────────────
  static const String demographicsEndpoint = '/api/demographics';

  // ── Feedback ─────────────────────────────────────────────────
  static const String feedbackEndpoint = '/api/feedback';

  // ── TomTom ───────────────────────────────────────────────────
  static String tomtomSearchUrl(double lat, double lon) =>
      'https://api.tomtom.com/search/2/nearbySearch/.json'
      '?key=$tomtomApiKey&lat=$lat&lon=$lon&radius=5000'
      '&categorySet=7321&limit=10';

  static String tomtomRouteUrl(
    double fromLat,
    double fromLon,
    double toLat,
    double toLon,
  ) =>
      'https://api.tomtom.com/routing/1/calculateRoute/'
      '$fromLat,$fromLon:$toLat,$toLon/json?key=$tomtomApiKey';
}
