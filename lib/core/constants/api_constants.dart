/// Centralized API configuration for the TeleMedCare app.
/// 
/// Uses `10.0.2.2` which maps to the host machine's localhost
/// when running on an Android emulator. Change these to actual
/// server IPs/domains for physical device testing.
class ApiConstants {
  ApiConstants._();

  /// Node.js backend base URL (port 5000 from .env)
  static const String baseUrl = 'http://10.0.2.2:5000';

  /// Copilot WebSocket URL
  static const String copilotWsUrl = 'ws://10.0.2.2:5000';

  /// TomTom Maps API key
  static const String tomtomApiKey = 'AHFi7q46N4j8cgLhMASvdEWJIACzxVCl';

  /// Gemini API key (synced with backend .env)
  static const String geminiApiKey = 'AIzaSyAG7GggH036raqLZlXPno-W0dfzIK91QHg';

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
