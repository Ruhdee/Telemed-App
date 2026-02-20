import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import '../utils/app_logger.dart';

/// Dio-based HTTP client with auth token injection and logging.
///
/// All API calls go through this client so we get consistent
/// error handling, token management, and debug logging.
class ApiClient {
  late final Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    // ── Auth Interceptor ───────────────────────────────────────
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          AppLogger.api(
            '→ ${options.method} ${options.path}',
            options.data,
          );
          handler.next(options);
        },
        onResponse: (response, handler) {
          AppLogger.api(
            '← ${response.statusCode} ${response.requestOptions.path}',
          );
          handler.next(response);
        },
        onError: (error, handler) {
          AppLogger.error(
            'API',
            '✖ ${error.requestOptions.method} ${error.requestOptions.path} '
            '→ ${error.response?.statusCode ?? 'NETWORK_ERROR'}',
            error.message,
          );
          handler.next(error);
        },
      ),
    );
  }

  Dio get dio => _dio;

  // ── Convenience methods ──────────────────────────────────────

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) =>
      _dio.get<T>(path, queryParameters: queryParameters);

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) =>
      _dio.post<T>(path, data: data, queryParameters: queryParameters);

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
  }) =>
      _dio.put<T>(path, data: data);

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
  }) =>
      _dio.patch<T>(path, data: data);

  Future<Response<T>> delete<T>(String path) => _dio.delete<T>(path);

  /// Upload a file using multipart form data.
  Future<Response<T>> uploadFile<T>(
    String path, {
    required String fieldName,
    required String filePath,
    required String fileName,
  }) async {
    final formData = FormData.fromMap({
      fieldName: await MultipartFile.fromFile(filePath, filename: fileName),
    });
    return _dio.post<T>(path, data: formData);
  }
}
