import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../theme/app_colors.dart';

/// Network diagnostic screen to test connectivity
class NetworkDiagnosticScreen extends StatefulWidget {
  const NetworkDiagnosticScreen({super.key});

  @override
  State<NetworkDiagnosticScreen> createState() => _NetworkDiagnosticScreenState();
}

class _NetworkDiagnosticScreenState extends State<NetworkDiagnosticScreen> {
  String _status = 'Tap "Test Connection" to start';
  bool _isLoading = false;
  Color _statusColor = AppColors.textSecondary;

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing connection...';
      _statusColor = AppColors.goldPrimary;
    });

    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ));

      // Test 1: Ping base URL
      final baseUrl = ApiConstants.baseUrl;
      _updateStatus('Testing: $baseUrl', AppColors.goldPrimary);
      
      final response = await dio.get('$baseUrl/api/doctors');
      
      if (response.statusCode == 200) {
        _updateStatus(
          '✅ SUCCESS!\n'
          'Connected to: $baseUrl\n'
          'Status: ${response.statusCode}\n'
          'Response time: ${response.extra['rt']?.toString() ?? 'N/A'}',
          Colors.green,
        );
      } else {
        _updateStatus(
          '❌ Unexpected status: ${response.statusCode}',
          AppColors.error,
        );
      }
    } catch (e) {
      String errorMsg = '❌ CONNECTION FAILED\n\n';
      
      if (e is DioException) {
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
            errorMsg += 'Connection Timeout\n'
                'Backend not responding within 10 seconds.\n\n'
                'Checklist:\n'
                '✓ Is backend running? (npm run dev)\n'
                '✓ Is IP correct? ${ApiConstants.baseUrl}\n'
                '✓ Are you on same WiFi?\n'
                '✓ Is firewall blocking port 5001?';
            break;
          case DioExceptionType.connectionError:
            errorMsg += 'Connection Error\n'
                'Cannot reach the server.\n\n'
                'Checklist:\n'
                '✓ Verify IP address in api_constants.dart\n'
                '✓ Backend running on correct port?\n'
                '✓ Phone and PC on same network?\n'
                '✓ Try accessing ${ApiConstants.baseUrl} in phone browser';
            break;
          case DioExceptionType.receiveTimeout:
            errorMsg += 'Receive Timeout\n'
                'Server taking too long to respond.';
            break;
          default:
            errorMsg += 'Error: ${e.type.name}\n'
                'Message: ${e.message}';
        }
      } else {
        errorMsg += 'Unknown error: ${e.toString()}';
      }
      
      _updateStatus(errorMsg, AppColors.error);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _updateStatus(String message, Color color) {
    if (mounted) {
      setState(() {
        _status = message;
        _statusColor = color;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Network Diagnostics'),
        backgroundColor: AppColors.goldPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Configuration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Base URL', ApiConstants.baseUrl),
                    _buildInfoRow('Timeout', '30 seconds'),
                    _buildInfoRow('Protocol', 'HTTP (Cleartext)'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testConnection,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.network_check),
              label: Text(_isLoading ? 'Testing...' : 'Test Connection'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Card(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    _status,
                    style: TextStyle(
                      color: _statusColor,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }
}
