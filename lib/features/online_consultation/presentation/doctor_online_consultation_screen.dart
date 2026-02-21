import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_logger.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Doctor-side video call screen.
//
// Used from the "Join Video Call" chip in DoctorDashboardScreen.
// Joins the same socket.io room as the patient to establish a WebRTC call.
// On end: pops back to doctor dashboard.
// ─────────────────────────────────────────────────────────────────────────────

const String _doctorBackendUrl = 'http://localhost:5001';

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
    _initAll();
  }

  Future<void> _initAll() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    await _openUserMedia();
    _connectSocket();
  }

  Future<void> _openUserMedia() async {
    try {
      final stream =
          await navigator.mediaDevices.getUserMedia(_mediaConstraints);
      _localStream = stream;
      _localRenderer.srcObject = stream;
      if (mounted) setState(() {
        _isInitializing = false;
        _statusMessage = 'Waiting for Patient…';
      });
      AppLogger.info('DoctorVideo', 'Local media stream opened');
    } catch (e) {
      AppLogger.error('DoctorVideo', 'Failed to open camera', e);
      if (mounted) setState(() {
        _isInitializing = false;
        _statusMessage = 'Camera unavailable. Check permissions.';
      });
    }
  }

  void _connectSocket() {
    _socket = IO.io(_doctorBackendUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket!.onConnect((_) {
      AppLogger.info('DoctorVideo', 'Socket connected, joining room: $_roomId');
      _socket!.emit('join-room', {'roomId': _roomId});
    });

    _socket!.on('room-ready', (_) async {
      AppLogger.info('DoctorVideo', 'Room ready – creating offer');
      await _createPeerConnection(isCaller: true);
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      _socket!.emit('offer', {
        'roomId': _roomId,
        'sdp': offer.sdp,
        'type': offer.type,
      });
    });

    _socket!.on('offer', (data) async {
      await _createPeerConnection(isCaller: false);
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(data['sdp'], data['type']),
      );
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);
      _socket!.emit('answer', {
        'roomId': _roomId,
        'sdp': answer.sdp,
        'type': answer.type,
      });
    });

    _socket!.on('answer', (data) async {
      await _peerConnection?.setRemoteDescription(
        RTCSessionDescription(data['sdp'], data['type']),
      );
    });

    _socket!.on('ice-candidate', (data) async {
      final candidate = RTCIceCandidate(
        data['candidate'],
        data['sdpMid'],
        data['sdpMLineIndex'],
      );
      await _peerConnection?.addCandidate(candidate);
    });
  }

  Future<void> _createPeerConnection({required bool isCaller}) async {
    _peerConnection = await createPeerConnection(_iceServers);

    _localStream?.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteRenderer.srcObject = event.streams.first;
        if (mounted) setState(() {
          _remoteConnected = true;
          _statusMessage = widget.patientName != null
              ? 'Connected to ${widget.patientName}'
              : 'Patient connected';
        });
      }
    };

    _peerConnection!.onIceCandidate = (candidate) {
      _socket!.emit('ice-candidate', {
        'roomId': _roomId,
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    _peerConnection!.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        if (mounted) setState(() {
          _remoteConnected = false;
          _statusMessage = 'Patient disconnected…';
        });
      }
    };
  }

  void _toggleMic() {
    _localStream?.getAudioTracks().forEach((t) => t.enabled = !_micOn);
    setState(() => _micOn = !_micOn);
  }

  void _toggleCamera() {
    _localStream?.getVideoTracks().forEach((t) => t.enabled = !_cameraOn);
    setState(() => _cameraOn = !_cameraOn);
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
            const Text('Video Consultation', style: TextStyle(fontSize: 13, color: Colors.white70)),
            Text(
              widget.patientName != null ? 'Patient: ${widget.patientName}' : 'Room: $_roomId',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
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
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
            )
          else
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isInitializing)
                    const CircularProgressIndicator(color: AppColors.goldPrimary)
                  else
                    Icon(LucideIcons.user, size: 64, color: Colors.white.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 15),
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
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    )
                  : Center(
                      child: Icon(LucideIcons.cameraOff,
                          color: Colors.white.withValues(alpha: 0.5), size: 24),
                    ),
            ),
          ),

          // Controls
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
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
                    child: const Icon(LucideIcons.phoneOff, color: Colors.white, size: 26),
                  ),
                ),
                const SizedBox(width: 16),
                _DoctorControlButton(
                  icon: _cameraOn ? LucideIcons.camera : LucideIcons.cameraOff,
                  isActive: _cameraOn,
                  onTap: _toggleCamera,
                ),
              ],
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
              ? Colors.white.withValues(alpha: 0.2)
              : AppColors.error.withValues(alpha: 0.8),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}
