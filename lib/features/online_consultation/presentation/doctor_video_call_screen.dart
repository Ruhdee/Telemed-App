import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:go_router/go_router.dart';
import 'dart:async';

import '../../../core/theme/app_colors.dart';
import '../../../core/constants/api_constants.dart';

/// Doctor Video Call Screen - Clean implementation following flutter_webrtc best practices
///
/// Handles WebRTC peer-to-peer video calls with socket.io signaling.
/// Matches the web client implementation for compatibility.
class DoctorVideoCallScreen extends StatefulWidget {
  final String roomId;
  final String? patientName;

  const DoctorVideoCallScreen({
    super.key,
    required this.roomId,
    this.patientName,
  });

  @override
  State<DoctorVideoCallScreen> createState() => _DoctorVideoCallScreenState();
}

class _DoctorVideoCallScreenState extends State<DoctorVideoCallScreen>
    with WidgetsBindingObserver {
  // WebRTC Components
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;

  // Socket.IO for signaling
  IO.Socket? _socket;

  // State variables
  bool _isInitialized = false;
  bool _isMicMuted = false;
  bool _isCameraOff = false;
  bool _isRemoteConnected = false;
  bool _hasEverConnected = false; // Track if connection was ever established
  String _statusText = 'Initializing...';
  String? _remotePeerId;
  Timer? _reconnectionTimer;
  bool _isReconnecting = false;
  int _reconnectionAttempts = 0;
  static const int _maxReconnectionAttempts =
      12; // Increased for better reconnection
  static const Duration _reconnectionDelay = Duration(
    seconds: 20,
  ); // Increased for stability
  static const Duration _iceCheckDelay = Duration(
    seconds: 15,
  ); // Increased for network recovery

  // ICE Configuration
  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
  };

  // Media constraints optimized for Android emulator
  final Map<String, dynamic> _mediaConstraints = {
    'audio': {
      'echoCancellation': true,
      'noiseSuppression': true,
      'autoGainControl': true,
      'sampleRate': 48000,
      'channelCount': 1, // Mono to reduce emulator load
    },
    'video': {
      'facingMode': 'user',
      'width': {'ideal': 1280},
      'height': {'ideal': 720},
    },
  };

  // Offer/Answer constraints
  final Map<String, dynamic> _sdpConstraints = {
    'mandatory': {'OfferToReceiveAudio': true, 'OfferToReceiveVideo': true},
    'optional': [],
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print('[DoctorVideo] Initializing for room: ${widget.roomId}');
    // Defer initialization to after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('[DoctorVideo] App lifecycle state: $state');

    if (state == AppLifecycleState.paused) {
      // App moved to background
      print('[DoctorVideo] App paused - maintaining connection');
    } else if (state == AppLifecycleState.resumed) {
      // App resumed
      print('[DoctorVideo] App resumed - checking connection');
      _checkConnectionHealth();
    } else if (state == AppLifecycleState.inactive) {
      // App transitioning (e.g., during phone call)
      print('[DoctorVideo] App inactive');
    }
  }

  /// Check connection health and attempt reconnection if needed
  Future<void> _checkConnectionHealth() async {
    if (_peerConnection == null) return;

    try {
      final connectionState = await _peerConnection!.getConnectionState();
      final iceState = await _peerConnection!.getIceConnectionState();

      print(
        '[DoctorVideo] Health check - Connection: $connectionState, ICE: $iceState',
      );

      if (connectionState ==
              RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          connectionState ==
              RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          iceState == RTCIceConnectionState.RTCIceConnectionStateFailed ||
          iceState == RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
        print('[DoctorVideo] Connection unhealthy - attempting recovery');
        await _attemptReconnection();
      }
    } catch (e) {
      print('[DoctorVideo] Error checking connection health: $e');
    }
  }

  /// Main initialization sequence
  Future<void> _initialize() async {
    try {
      setState(() => _statusText = 'Setting up renderers...');

      // 1. Initialize video renderers
      await _localRenderer.initialize();
      await _remoteRenderer.initialize();
      print('[DoctorVideo] Renderers initialized');

      // 2. Get user media
      setState(() => _statusText = 'Accessing camera...');
      await _getUserMedia();

      // 3. Connect to signaling server
      setState(() => _statusText = 'Connecting...');
      await _connectSignaling();

      setState(() {
        _isInitialized = true;
        _statusText = 'Waiting for patient...';
      });
      print('[DoctorVideo] Initialization complete');
    } catch (e) {
      print('[DoctorVideo] ERROR during initialization: $e');
      setState(() {
        _statusText = 'Failed to initialize: $e';
      });
      _showError('Failed to initialize video call: $e');
    }
  }

  /// Get local media stream (camera + microphone)
  Future<void> _getUserMedia() async {
    try {
      final stream = await navigator.mediaDevices.getUserMedia(
        _mediaConstraints,
      );
      _localStream = stream;
      _localRenderer.srcObject = stream;
      print(
        '[DoctorVideo] Got user media - Audio tracks: ${stream.getAudioTracks().length}, Video tracks: ${stream.getVideoTracks().length}',
      );
    } catch (e) {
      print('[DoctorVideo] ERROR getting user media: $e');
      throw Exception('Camera/microphone access denied');
    }
  }

  /// Connect to socket.io signaling server
  Future<void> _connectSignaling() async {
    _socket = IO.io(
      ApiConstants.baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) {
      print('[DoctorVideo] Socket connected - ID: ${_socket!.id}');
      // Join room after connection
      _socket!.emit('join-room', widget.roomId);
      print('[DoctorVideo] Joined room: ${widget.roomId}');
    });

    _socket!.on('user-connected', (userId) {
      print('[DoctorVideo] User connected: $userId');
      _remotePeerId = userId.toString();
      _call(userId.toString());
    });

    _socket!.on('offer', (data) async {
      print('[DoctorVideo] Received offer');
      await _handleOffer(data);
    });

    _socket!.on('answer', (data) async {
      print('[DoctorVideo] Received answer');
      await _handleAnswer(data);
    });

    _socket!.on('ice-candidate', (data) async {
      print('[DoctorVideo] Received ICE candidate');
      await _handleIceCandidate(data);
    });

    _socket!.onDisconnect((_) {
      print('[DoctorVideo] Socket disconnected');
      if (mounted) {
        setState(() {
          _statusText = 'Disconnected from server';
          _isRemoteConnected = false;
        });
      }
    });

    _socket!.onConnectError((error) {
      print('[DoctorVideo] Connection error: $error');
    });

    _socket!.connect();
  }

  /// Create peer connection
  Future<RTCPeerConnection> _createPeerConnection() async {
    print('[DoctorVideo] Creating peer connection');

    final pc = await createPeerConnection(_iceServers, _sdpConstraints);

    // Add local stream to peer connection
    if (_localStream != null) {
      final tracks = _localStream!.getTracks();
      if (tracks.isNotEmpty) {
        for (final track in tracks) {
          if (track != null) {
            try {
              await pc.addTrack(track, _localStream!);
            } catch (e) {
              print('[DoctorVideo] Error adding track: $e');
            }
          }
        }
        print('[DoctorVideo] Added ${tracks.length} local tracks');
      } else {
        print('[DoctorVideo] WARNING: No tracks in local stream');
      }
    } else {
      print('[DoctorVideo] WARNING: Local stream is null');
    }

    // Handle incoming remote stream
    pc.onTrack = (event) {
      print(
        '[DoctorVideo] onTrack - Received remote ${event.track.kind} track',
      );
      if (event.streams.isNotEmpty) {
        final remoteStream = event.streams[0];
        print(
          '[DoctorVideo] Setting remote stream - Audio: ${remoteStream.getAudioTracks().length}, Video: ${remoteStream.getVideoTracks().length}',
        );
        _remoteRenderer.srcObject = remoteStream;
        if (mounted) {
          setState(() {
            _isRemoteConnected = true;
            _statusText = 'Connected to ${widget.patientName ?? "patient"}';
          });
        }
      }
    };

    // Handle ICE candidates
    pc.onIceCandidate = (candidate) {
      if (candidate != null && _remotePeerId != null) {
        print('[DoctorVideo] Sending ICE candidate');
        _socket!.emit('ice-candidate', {
          'target': _remotePeerId,
          'candidate': {
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        });
      }
    };

    // Handle connection state changes
    pc.onConnectionState = (state) {
      print('[DoctorVideo] Connection state: $state');
      if (!mounted) return;

      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        setState(() {
          _statusText = 'Connected';
          _isReconnecting = false;
          _reconnectionAttempts = 0;
          _hasEverConnected = true; // Mark that we've connected successfully
        });
        _cancelReconnectionTimer();
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        print('[DoctorVideo] Connection failed');
        if (_hasEverConnected) {
          print(
            '[DoctorVideo] Was previously connected - will attempt reconnection',
          );
          setState(() {
            _statusText = 'Connection failed';
            _isRemoteConnected = false;
          });
          _scheduleReconnection();
        } else {
          print('[DoctorVideo] Initial connection failed - waiting for peer');
          setState(() => _statusText = 'Connection failed. Waiting...');
        }
      } else if (state ==
          RTCPeerConnectionState.RTCPeerConnectionStateDisconnected) {
        print('[DoctorVideo] Connection disconnected');
        if (_hasEverConnected) {
          print(
            '[DoctorVideo] Was previously connected - monitoring for recovery',
          );
          setState(() {
            _statusText = 'Connection interrupted...';
            _isRemoteConnected = false;
          });
          _scheduleReconnection();
        } else {
          print('[DoctorVideo] Still negotiating initial connection');
        }
      } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        print('[DoctorVideo] Connection closed');
        setState(() {
          _statusText = 'Call ended';
          _isRemoteConnected = false;
        });
      }
    };

    // Handle ICE connection state
    pc.onIceConnectionState = (state) {
      print('[DoctorVideo] ICE connection state: $state');
      if (!mounted) return;

      if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        print('[DoctorVideo] ICE connection established');
        setState(() => _hasEverConnected = true);
        _cancelReconnectionTimer();
      } else if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        if (_hasEverConnected) {
          print('[DoctorVideo] ICE connection failed - attempting ICE restart');
          _handleIceConnectionFailure();
        } else {
          print(
            '[DoctorVideo] ICE failed during initial setup - may need manual intervention',
          );
          if (mounted) {
            setState(() => _statusText = 'Connection setup failed');
          }
        }
      } else if (state ==
          RTCIceConnectionState.RTCIceConnectionStateDisconnected) {
        if (_hasEverConnected) {
          print(
            '[DoctorVideo] ICE disconnected - will monitor for reconnection',
          );
          // Give it some time to reconnect automatically
          Future.delayed(_iceCheckDelay, () {
            if (mounted) _checkConnectionHealth();
          });
        } else {
          print(
            '[DoctorVideo] ICE disconnected - still in initial negotiation phase',
          );
        }
      }
    };

    // Handle ICE gathering state
    pc.onIceGatheringState = (state) {
      print('[DoctorVideo] ICE gathering state: $state');
    };

    return pc;
  }

  /// Initiate call (create offer)
  Future<void> _call(String targetUserId) async {
    try {
      print('[DoctorVideo] Creating offer for: $targetUserId');
      _peerConnection = await _createPeerConnection();

      final offer = await _peerConnection!.createOffer(_sdpConstraints);
      await _peerConnection!.setLocalDescription(offer);

      _socket!.emit('offer', {
        'target': targetUserId,
        'sdp': {'type': offer.type, 'sdp': offer.sdp},
      });
      print('[DoctorVideo] Offer sent');
    } catch (e) {
      print('[DoctorVideo] ERROR creating offer: $e');
    }
  }

  /// Handle incoming offer
  Future<void> _handleOffer(dynamic data) async {
    try {
      final callerId = data['caller'].toString();
      _remotePeerId = callerId;

      _peerConnection = await _createPeerConnection();

      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(data['sdp']['sdp'], data['sdp']['type']),
      );

      final answer = await _peerConnection!.createAnswer(_sdpConstraints);
      await _peerConnection!.setLocalDescription(answer);

      _socket!.emit('answer', {
        'target': callerId,
        'sdp': {'type': answer.type, 'sdp': answer.sdp},
      });
      print('[DoctorVideo] Answer sent to: $callerId');
    } catch (e) {
      print('[DoctorVideo] ERROR handling offer: $e');
    }
  }

  /// Handle incoming answer
  Future<void> _handleAnswer(dynamic data) async {
    try {
      await _peerConnection?.setRemoteDescription(
        RTCSessionDescription(data['sdp']['sdp'], data['sdp']['type']),
      );
      print('[DoctorVideo] Remote description set');
    } catch (e) {
      print('[DoctorVideo] ERROR handling answer: $e');
    }
  }

  /// Handle incoming ICE candidate
  Future<void> _handleIceCandidate(dynamic data) async {
    try {
      final candidateMap = data['candidate'];
      final candidate = RTCIceCandidate(
        candidateMap['candidate'],
        candidateMap['sdpMid'],
        candidateMap['sdpMLineIndex'],
      );
      await _peerConnection?.addCandidate(candidate);
      print('[DoctorVideo] ICE candidate added');
    } catch (e) {
      print('[DoctorVideo] ERROR adding ICE candidate: $e');
    }
  }

  /// Toggle microphone
  void _toggleMic() {
    if (_localStream != null) {
      final audioTrack = _localStream!.getAudioTracks().first;
      audioTrack.enabled = _isMicMuted;
      setState(() {
        _isMicMuted = !_isMicMuted;
      });
      print('[DoctorVideo] Mic ${_isMicMuted ? "muted" : "unmuted"}');
    }
  }

  /// Toggle camera
  void _toggleCamera() {
    if (_localStream != null) {
      final videoTrack = _localStream!.getVideoTracks().first;
      videoTrack.enabled = _isCameraOff;
      setState(() {
        _isCameraOff = !_isCameraOff;
      });
      print('[DoctorVideo] Camera ${_isCameraOff ? "off" : "on"}');
    }
  }

  /// Handle ICE connection failure with restart
  Future<void> _handleIceConnectionFailure() async {
    if (_peerConnection == null || _isReconnecting) return;

    try {
      print('[DoctorVideo] Attempting ICE restart');
      setState(() => _isReconnecting = true);

      // Trigger ICE restart
      await _peerConnection!.restartIce();

      // Create new offer with ICE restart
      if (_remotePeerId != null) {
        final offer = await _peerConnection!.createOffer(_sdpConstraints);
        await _peerConnection!.setLocalDescription(offer);

        _socket!.emit('offer', {
          'target': _remotePeerId,
          'sdp': {'type': offer.type, 'sdp': offer.sdp},
        });
        print('[DoctorVideo] ICE restart offer sent');
      }
    } catch (e) {
      print('[DoctorVideo] Error during ICE restart: $e');
      setState(() => _isReconnecting = false);
    }
  }

  /// Schedule reconnection attempt
  void _scheduleReconnection() {
    if (_reconnectionTimer != null && _reconnectionTimer!.isActive) {
      return; // Already scheduled
    }

    _reconnectionTimer = Timer(_reconnectionDelay, () {
      if (mounted) _attemptReconnection();
    });
  }

  /// Cancel reconnection timer
  void _cancelReconnectionTimer() {
    _reconnectionTimer?.cancel();
    _reconnectionTimer = null;
  }

  /// Attempt to reconnect
  Future<void> _attemptReconnection() async {
    if (_isReconnecting || _reconnectionAttempts >= _maxReconnectionAttempts) {
      print(
        '[DoctorVideo] Max reconnection attempts ($_maxReconnectionAttempts) reached',
      );
      if (mounted) {
        setState(() {
          _statusText = 'Connection lost. Please rejoin.';
        });
      }
      return;
    }

    if (!mounted) return;

    setState(() {
      _isReconnecting = true;
      _reconnectionAttempts++;
      _statusText =
          'Reconnecting... (${_reconnectionAttempts}/$_maxReconnectionAttempts)';
    });

    print('[DoctorVideo] Reconnection attempt ${_reconnectionAttempts}');

    try {
      // Check socket connection first
      if (_socket == null || !_socket!.connected) {
        print('[DoctorVideo] Socket disconnected, reconnecting socket');
        _socket?.connect();
        await Future.delayed(const Duration(seconds: 5));
      }

      // Attempt ICE restart if peer connection exists
      if (_peerConnection != null && _remotePeerId != null) {
        await _handleIceConnectionFailure();
      }

      // Schedule next attempt if still not connected
      Future.delayed(_reconnectionDelay, () {
        if (!_isRemoteConnected && mounted) {
          _attemptReconnection();
        }
      });
    } catch (e) {
      print('[DoctorVideo] Reconnection error: $e');
      if (mounted) {
        setState(() {
          _isReconnecting = false;
        });
      }
    }
  }

  /// End call and cleanup
  Future<void> _endCall() async {
    print('[DoctorVideo] Ending call');

    _localStream?.getTracks().forEach((track) => track.stop());
    await _localStream?.dispose();

    await _peerConnection?.close();
    await _peerConnection?.dispose();

    _socket?.disconnect();
    _socket?.dispose();

    await _localRenderer.dispose();
    await _remoteRenderer.dispose();

    if (mounted) {
      context.pop();
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  @override
  void dispose() {
    print('[DoctorVideo] Disposing');
    WidgetsBinding.instance.removeObserver(this);
    _cancelReconnectionTimer();
    _localStream?.getTracks().forEach((track) => track.stop());
    _localStream?.dispose();
    _peerConnection?.close();
    _peerConnection?.dispose();
    _socket?.disconnect();
    _socket?.dispose();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF111827),
      appBar: AppBar(
        backgroundColor: Colors.black87,
        title: Text(
          widget.patientName != null
              ? 'Call with ${widget.patientName}'
              : 'Video Call',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.x, color: Colors.white),
          onPressed: _endCall,
        ),
      ),
      body: Stack(
        children: [
          // Remote video (full screen)
          if (_isRemoteConnected)
            Positioned.fill(
              child: RTCVideoView(
                _remoteRenderer,
                mirror: false,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              ),
            )
          else
            Positioned.fill(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (!_isInitialized)
                      const CircularProgressIndicator(
                        color: AppColors.goldPrimary,
                      )
                    else
                      Icon(
                        LucideIcons.userCircle2,
                        size: 80,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    const SizedBox(height: 24),
                    Text(
                      _statusText,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          // Local video (PiP)
          if (_isInitialized)
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                width: 120,
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                  color: Colors.black87,
                ),
                clipBehavior: Clip.hardEdge,
                child: _isCameraOff
                    ? Center(
                        child: Icon(
                          LucideIcons.cameraOff,
                          color: Colors.white.withOpacity(0.5),
                          size: 32,
                        ),
                      )
                    : RTCVideoView(
                        _localRenderer,
                        mirror: true,
                        objectFit:
                            RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                      ),
              ),
            ),

          // Room info badge
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.video,
                    size: 16,
                    color: _isRemoteConnected
                        ? AppColors.success
                        : Colors.white.withOpacity(0.5),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Room: ${widget.roomId}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
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
                // Mic button
                _CallControlButton(
                  icon: _isMicMuted ? LucideIcons.micOff : LucideIcons.mic,
                  onTap: _isInitialized ? _toggleMic : null,
                  isActive: !_isMicMuted,
                ),
                const SizedBox(width: 16),

                // End call button
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
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Camera button
                _CallControlButton(
                  icon: _isCameraOff
                      ? LucideIcons.cameraOff
                      : LucideIcons.camera,
                  onTap: _isInitialized ? _toggleCamera : null,
                  isActive: !_isCameraOff,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Control button widget
class _CallControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final bool isActive;

  const _CallControlButton({
    required this.icon,
    required this.onTap,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withOpacity(0.3)
              : AppColors.error.withOpacity(0.9),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}
