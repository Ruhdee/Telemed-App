import 'dart:io';
import 'package:flutter/foundation.dart';

/// Centralized API configuration for the TeleMedCare app.
/// 
/// Automatically detects emulator vs physical device using multiple checks:
/// - Network interface analysis
/// - Platform environment variables
/// - Manual override option
/// 
/// SETUP: Just change `_localNetworkIp` to your computer's IP address!
/// - Windows: Run 'ipconfig' → look for IPv4 Address (e.g., 192.168.1.105)
/// - Mac/Linux: Run 'ifconfig' or 'ip addr'
class ApiConstants {
  ApiConstants._();

  /// ════════════════════════════════════════════════════════════════════
  /// 🔧 CONFIGURE THIS: Your computer's IP address on local network
  /// ════════════════════════════════════════════════════════════════════
  // static const String _localNetworkIp = '';  // ← Change this to YOUR IP!
  static const String _localNetworkIp = '';  // ← Change this to YOUR IP!

  /// Backend server port
  static const int _port = 5001;

  /// ════════════════════════════════════════════════════════════════════
  /// 🎛️ DEVICE MODE SELECTOR (Manual Override)
  /// - null: Auto-detect using multiple detection methods
  /// - true: Force emulator IP (10.0.2.2) - use when auto-detect fails
  /// - false: Force physical device IP - use for testing on real device
  /// ════════════════════════════════════════════════════════════════════
  static const bool? _forceEmulatorMode = null;  // ← Set to false for physical device, null for auto

  /// Cached emulator detection result
  static bool? _isEmulatorCached;

  /// Multi-method emulator detection using system properties
  static bool get _isEmulator {
    // Return cached result if available
    if (_isEmulatorCached != null) return _isEmulatorCached!;

    // Check Platform environment for emulator indicators
    if (Platform.isAndroid) {
      try {
        // Check for emulator fingerprints in environment
        // These are Android system properties that differ between emulator and physical devices
        final fingerprint = Platform.environment['ro.build.fingerprint']?.toLowerCase() ?? '';
        final model = Platform.environment['ro.product.model']?.toLowerCase() ?? '';
        final manufacturer = Platform.environment['ro.product.manufacturer']?.toLowerCase() ?? '';
        final brand = Platform.environment['ro.product.brand']?.toLowerCase() ?? '';
        final device = Platform.environment['ro.product.device']?.toLowerCase() ?? '';
        final hardware = Platform.environment['ro.hardware']?.toLowerCase() ?? '';
        final product = Platform.environment['ro.product.name']?.toLowerCase() ?? '';

        // Emulator indicators - these keywords are present on emulators
        final isEmulator = fingerprint.contains('generic') ||
            fingerprint.contains('test-keys') ||
            model.contains('sdk') ||
            model.contains('emulator') ||
            model.contains('android sdk built for') ||
            manufacturer.contains('genymotion') ||
            manufacturer.contains('unknown') ||
            (brand.contains('generic') && device.contains('generic')) ||
            product.contains('sdk') ||
            product.contains('emulator') ||
            hardware.contains('ranchu') ||
            hardware.contains('goldfish');

        _isEmulatorCached = isEmulator;
        if (kDebugMode) {
          print('[ApiConstants] Detection: ${isEmulator ? "Emulator" : "Physical device"}');
          if (kDebugMode && !isEmulator) {
            print('[ApiConstants]   Model: $model, Brand: $brand, Device: $device');
          }
        }
        return isEmulator;
      } catch (e) {
        if (kDebugMode) {
          print('[ApiConstants] Environment check failed: $e');
        }
      }
    }

    // Default: Assume physical device if no emulator indicators found
    _isEmulatorCached = false;
    if (kDebugMode) {
      print('[ApiConstants] Detection: Physical device (default)');
    }
    return false;
  }

  /// Determines which IP to use
  static String get _serverIp {
    // If force mode is set, use that
    if (_forceEmulatorMode != null) {
      final ip = _forceEmulatorMode! ? '10.0.2.2' : _localNetworkIp;
      if (kDebugMode) {
        print('[ApiConstants] Using FORCED mode: ${_forceEmulatorMode! ? "Emulator" : "Physical"} → $ip');
      }
      return ip;
    }
    
    // Auto-detect
    final isEmu = _isEmulator;
    final ip = isEmu ? '10.0.2.2' : _localNetworkIp;
    if (kDebugMode) {
      print('[ApiConstants] Auto-detected: ${isEmu ? "Emulator" : "Physical Device"} → $ip');
    }
    return ip;
  }

  /// Backend base URL (HTTP)
  static String get baseUrl {
    final url = 'http://$_serverIp:$_port';
    if (kDebugMode) {
      print('[ApiConstants] 🌐 Base URL: $url');
    }
    return url;
  }

  /// WebSocket URL
  static String get copilotWsUrl {
    final url = 'ws://$_serverIp:$_port';
    if (kDebugMode) {
      print('[ApiConstants] 🔌 WebSocket URL: $url');
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
