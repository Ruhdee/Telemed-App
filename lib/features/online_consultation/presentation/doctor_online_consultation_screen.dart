import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/constants/api_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Doctor-side video call screen.
//
// Used from the "Join Video Call" chip in DoctorDashboardScreen.
// Joins the same socket.io room as the patient to establish a WebRTC call.
// On end: pops back to doctor dashboard.
// ─────────────────────────────────────────────────────────────────────────────

class DoctorOnlineConsultationScreen extends StatefulWidget {
  final String? roomId;
  final String? patientName;

  const DoctorOnlineConsultationScreen({
    super.key,
    this.roomId,
    this.patientName,
  });

  @override
  State<DoctorOnlineConsultationScreen> createState() =>
      _DoctorOnlineConsultationScreenState();
}

class _DoctorOnlineConsultationScreenState
    extends State<DoctorOnlineConsultationScreen> {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  MediaStream? _localStream;
  RTCPeerConnection? _peerConnection;
  IO.Socket? _socket;

  bool _micOn = true;
  bool _cameraOn = true;
  bool _remoteConnected = false;
  bool _isInitializing = true;
  String _statusMessage = 'Initializing camera…';

  String? _peerId;

  String get _roomId => widget.roomId ?? 'consultation-room-1';

  static const Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
  };

  static const Map<String, dynamic> _mediaConstraints = {
    'audio': true,
    'video': {
      'facingMode': 'user',
      'width': {'ideal': 1280},
      'height': {'ideal': 720},
    },
  };

  @override
  void initState() {
    super.initState();
    // Initialize async without blocking
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAll();
    });
  }

  Future<void> _initAll() async {
    print('[DoctorVideo] Starting initialization...');
    try {
      await _localRenderer.initialize();
      print('[DoctorVideo] Local renderer initialized');
      await _remoteRenderer.initialize();
      print('[DoctorVideo] Remote renderer initialized');
      _connectSocket();
      await _openUserMedia();
      print('[DoctorVideo] Initialization complete');
    } catch (e) {
      print('[DoctorVideo] ERROR during initialization: $e');
      AppLogger.error('DoctorVideo', 'Initialization failed', e);
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _statusMessage = 'Failed to initialize. Please restart.';
        });
      }
    }
  }

  Future<void> _openUserMedia() async {
    print(
      '[DoctorVideo] Opening user media with constraints: $_mediaConstraints',
    );
    try {
      final stream = await navigator.mediaDevices.getUserMedia(
        _mediaConstraints,
      );
      _localStream = stream;
      _localRenderer.srcObject = stream;
      print('[DoctorVideo] Local media stream opened successfully');
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _statusMessage = 'Waiting for Patient…';
        });
      }
      AppLogger.info('DoctorVideo', 'Local media stream opened');

      if (_socket?.connected == true) {
        print('[DoctorVideo] Socket already connected, joining room: $_roomId');
        AppLogger.info(
          'DoctorVideo',
          'Socket already connected, joining room: $_roomId',
        );
        _socket!.emit('join-room', _roomId);
      } else {
        print(
          '[DoctorVideo] Socket not yet connected, will join room on connect',
        );
      }
    } catch (e) {
      print('[DoctorVideo] ERROR: Failed to open camera - $e');
      AppLogger.error('DoctorVideo', 'Failed to open camera', e);
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _statusMessage = 'Camera unavailable. Check permissions.';
        });
      }
    }
  }

  void _connectSocket() {
    print('[DoctorVideo] Connecting to socket at: ${ApiConstants.baseUrl}');
    _socket = IO.io(ApiConstants.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket!.onConnect((_) {
      print(
        '[DoctorVideo] Socket connected successfully - socket.id: ${_socket!.id}',
      );
      AppLogger.info('DoctorVideo', 'Socket connected');
      if (_localStream != null) {
        print('[DoctorVideo] Local stream ready, joining room: $_roomId');
        AppLogger.info(
          'DoctorVideo',
          'Local stream ready, joining room: $_roomId',
        );
        _socket!.emit('join-room', _roomId);
      } else {
        print('[DoctorVideo] Socket connected but local stream not yet ready');
      }
    });

    _socket!.on('user-connected', (userId) async {
      print('[DoctorVideo] New user connected: $userId - creating offer');
      AppLogger.info('DoctorVideo', 'New user connected: $userId');
      _peerId = userId as String;
      await _createPeerConnection(isCaller: true);
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      print('[DoctorVideo] Sending offer to: $_peerId');
      _socket!.emit('offer', {
        'target': _peerId,
        'sdp': {'type': offer.type, 'sdp': offer.sdp},
      });
    });

    _socket!.on('offer', (data) async {
      print('[DoctorVideo] Received offer from: ${data['caller']}');
      AppLogger.info('DoctorVideo', 'Received offer from: ${data['caller']}');
      _peerId = data['caller'] as String;
      await _createPeerConnection(isCaller: false);
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(data['sdp']['sdp'], data['sdp']['type']),
      );
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);
      print('[DoctorVideo] Sending answer to: $_peerId');
      _socket!.emit('answer', {
        'target': _peerId,
        'sdp': {'type': answer.type, 'sdp': answer.sdp},
      });
    });

    _socket!.on('answer', (data) async {
      print('[DoctorVideo] Received answer from: ${data['caller']}');
      AppLogger.info('DoctorVideo', 'Received answer from: ${data['caller']}');
      await _peerConnection?.setRemoteDescription(
        RTCSessionDescription(data['sdp']['sdp'], data['sdp']['type']),
      );
      print('[DoctorVideo] Remote description set successfully');
    });

    _socket!.on('ice-candidate', (data) async {
      print('[DoctorVideo] Received ICE candidate');
      final candidateData = data['candidate'];
      final candidate = RTCIceCandidate(
        candidateData['candidate'],
        candidateData['sdpMid'],
        candidateData['sdpMLineIndex'],
      );
      await _peerConnection?.addCandidate(candidate);
    });

    _socket!.onDisconnect((_) {
      print('[DoctorVideo] Socket disconnected');
      AppLogger.info('DoctorVideo', 'Socket disconnected');
    });

    _socket!.onError((error) {
      print('[DoctorVideo] ERROR: Socket error - $error');
      AppLogger.error('DoctorVideo', 'Socket error', error);
    });

    _socket!.onConnectError((error) {
      print('[DoctorVideo] ERROR: Socket connection error - $error');
      AppLogger.error('DoctorVideo', 'Socket connection error', error);
    });
  }

  Future<void> _createPeerConnection({required bool isCaller}) async {
    print('[DoctorVideo] Creating peer connection (isCaller: $isCaller)');
    _peerConnection = await createPeerConnection(_iceServers);

    final trackCount = _localStream?.getTracks().length ?? 0;
    print('[DoctorVideo] Adding $trackCount local tracks to peer connection');
    _localStream?.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    _peerConnection!.onTrack = (event) {
      print(
        '[DoctorVideo] Received remote track (streams: ${event.streams.length})',
      );
      if (event.streams.isNotEmpty) {
        final remoteStream = event.streams.first;
        print(
          '[DoctorVideo] Remote stream has ${remoteStream.getVideoTracks().length} video tracks and ${remoteStream.getAudioTracks().length} audio tracks',
        );
        _remoteRenderer.srcObject = remoteStream;
        if (mounted)
          setState(() {
            _remoteConnected = true;
            _statusMessage = widget.patientName != null
                ? 'Connected to ${widget.patientName}'
                : 'Patient connected';
          });
        print('[DoctorVideo] Remote stream set to renderer successfully');
      } else {
        print('[DoctorVideo] WARNING: onTrack event but no streams available');
      }
    };

    _peerConnection!.onIceCandidate = (candidate) {
      if (_peerId != null) {
        print('[DoctorVideo] Sending ICE candidate to: $_peerId');
        _socket!.emit('ice-candidate', {
          'target': _peerId,
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        });
      } else {
        print(
          '[DoctorVideo] WARNING: ICE candidate generated but no peer ID available',
        );
      }
    };

    _peerConnection!.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        if (mounted)
          setState(() {
            _remoteConnected = false;
            _statusMessage = 'Patient disconnected…';
          });
      }
    };
  }

  void _toggleMic() {
    print('[DoctorVideo] Toggling mic from $_micOn to ${!_micOn}');
    setState(() {
      _micOn = !_micOn;
      _localStream?.getAudioTracks().forEach((track) {
        track.enabled = _micOn;
        print('[DoctorVideo] Audio track enabled set to: $_micOn');
      });
    });
  }

  void _toggleCamera() {
    print('[DoctorVideo] Toggling camera from $_cameraOn to ${!_cameraOn}');
    setState(() {
      _cameraOn = !_cameraOn;
      _localStream?.getVideoTracks().forEach((track) {
        track.enabled = _cameraOn;
        print('[DoctorVideo] Video track enabled set to: $_cameraOn');
      });
    });
  }

  void _endCall() {
    _peerConnection?.close();
    _socket?.disconnect();
    _localStream?.dispose();
    if (mounted) context.pop();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _peerConnection?.close();
    _socket?.disconnect();
    _localStream?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        backgroundColor: Colors.black54,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Video Consultation',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            Text(
              widget.patientName != null
                  ? 'Patient: ${widget.patientName}'
                  : 'Room: $_roomId',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
          onPressed: _endCall,
        ),
      ),
      body: Stack(
        children: [
          // Remote (patient) video fullscreen
          if (_remoteConnected)
            RTCVideoView(
              _remoteRenderer,
              mirror: false,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            )
          else
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isInitializing)
                    const CircularProgressIndicator(
                      color: AppColors.goldPrimary,
                    )
                  else
                    Icon(
                      LucideIcons.user,
                      size: 64,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),

          // Local (doctor) PiP
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              width: 110,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
                color: Colors.black54,
              ),
              clipBehavior: Clip.hardEdge,
              child: _cameraOn
                  ? RTCVideoView(
                      _localRenderer,
                      mirror: true,
                      objectFit:
                          RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    )
                  : Center(
                      child: Icon(
                        LucideIcons.cameraOff,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 24,
                      ),
                    ),
            ),
          ),

          // Controls
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _DoctorControlButton(
                    icon: _micOn ? LucideIcons.mic : LucideIcons.micOff,
                    isActive: _micOn,
                    onTap: _toggleMic,
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: _endCall,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        LucideIcons.phoneOff,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  _DoctorControlButton(
                    icon: _cameraOn
                        ? LucideIcons.camera
                        : LucideIcons.cameraOff,
                    isActive: _cameraOn,
                    onTap: _toggleCamera,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DoctorControlButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _DoctorControlButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withValues(alpha: 0.3)
              : AppColors.error.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
