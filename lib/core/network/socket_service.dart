import 'package:socket_io_client/socket_io_client.dart' as io;
import '../constants/api_constants.dart';
import '../utils/app_logger.dart';

/// Socket.IO wrapper for real-time communication.
///
/// Mirrors the React app's socket.io-client usage for:
/// - Appointment updates (new / status change)
/// - Joining personal rooms for targeted events
class SocketService {
  io.Socket? _socket;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  /// Connect to the Socket.IO server.
  void connect({String? authToken}) {
    AppLogger.socket('Attempting connection to ${ApiConstants.baseUrl}');

    _socket = io.io(
      ApiConstants.baseUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      _isConnected = true;
      AppLogger.socket('Connected successfully');

      // Join personal room for targeted events (mirrors React behavior)
      if (authToken != null) {
        _socket!.emit('join-personal-room', {'token': authToken});
        AppLogger.socket('Emitted join-personal-room');
      }
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      AppLogger.socket('Disconnected');
    });

    _socket!.onConnectError((error) {
      AppLogger.error('SOCKET', 'Connection error', error);
    });

    _socket!.onError((error) {
      AppLogger.error('SOCKET', 'Socket error', error);
    });

    _socket!.connect();
  }

  /// Listen to a specific event.
  void on(String event, Function(dynamic) callback) {
    _socket?.on(event, (data) {
      AppLogger.socket('Event received: $event', data);
      callback(data);
    });
  }

  /// Emit an event to the server.
  void emit(String event, [dynamic data]) {
    AppLogger.socket('Emitting event: $event', data);
    _socket?.emit(event, data);
  }

  /// Disconnect and clean up.
  void disconnect() {
    AppLogger.socket('Disconnecting...');
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
  }
}
