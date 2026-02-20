/// Centralized API configuration for the TeleMedCare app.
/// 
/// Uses `10.0.2.2` which maps to the host machine's localhost
/// when running on an Android emulator. Change these to actual
/// server IPs/domains for physical device testing.
class ApiConstants {
  ApiConstants._();

  /// Node.js backend base URL
  static const String baseUrl = 'http://10.0.2.2:5001';

  /// Python AI services base URL (ai-triage / diabetes)
  static const String aiBaseUrl = 'http://10.0.2.2:8000';

  /// Copilot WebSocket URL
  static const String copilotWsUrl = 'ws://10.0.2.2:8100';

  /// TomTom Maps API key (from React frontend)
  static const String tomtomApiKey = 'AHFi7q46N4j8cgLhMASvdEWJIACzxVCl';

  /// Gemini API key (from React frontend)
  static const String geminiApiKey = 'AIzaSyARkBi6grFCBI0Taq7-NUvOFFRGXuMIxkY';

  // ── API Endpoints ────────────────────────────────────────────

  // Auth
  static const String loginEndpoint = '/api/auth/login';
  static const String registerEndpoint = '/api/auth/register';
  static const String meEndpoint = '/api/auth/me';

  // Appointments
  static const String appointmentsEndpoint = '/api/appointments';
  static const String doctorAppointmentsEndpoint = '/api/appointments/doctor';

  // Records / OCR
  static const String scanPrescriptionEndpoint = '/api/scan-prescription';
  static const String scanBloodReportEndpoint = '/api/scan-blood-report';

  // Chatbot
  static const String chatbotEndpoint = '/api/chatbot/chat';

  // Triage
  static const String triageEndpoint = '/api/triage';

  // SOAP
  static const String soapEndpoint = '/api/soap';

  // TomTom
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
