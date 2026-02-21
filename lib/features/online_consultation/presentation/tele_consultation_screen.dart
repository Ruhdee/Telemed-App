import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:go_router/go_router.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:async';
import 'dart:io';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_logger.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/glass_panel.dart';
import '../../auth/providers/auth_provider.dart';
import '../../offline_consultation/data/offline_consultation_db.dart';
import '../../offline_consultation/data/offline_consultation_sync.dart';
import 'package:uuid/uuid.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Tele-Consultation Screen (mirrors web /dashboard/consultation page)
//
// Tab 0 – Live Video: WebRTC peer-to-peer video call via flutter_webrtc +
//          socket.io signaling on the same backend used by the web client.
// Tab 1 – Offline/Async: Chief complaint form + camera video/photo submit,
//          stored in SQLite and synced when online (same as OfflineConsultationScreen logic).
// ─────────────────────────────────────────────────────────────────────────────

const String _backendUrl = 'http://localhost:5001';
const String _defaultRoomId = 'consultation-room-1';

class TeleConsultationScreen extends ConsumerStatefulWidget {
  /// Optional room ID passed from appointment booking (via GoRouter extra).
  final String? roomId;

  const TeleConsultationScreen({super.key, this.roomId});

  @override
  ConsumerState<TeleConsultationScreen> createState() =>
      _TeleConsultationScreenState();
}

class _TeleConsultationScreenState
    extends ConsumerState<TeleConsultationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tele-Consultation'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.goldPrimary,
          labelColor: AppColors.goldPrimary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(icon: Icon(LucideIcons.video), text: 'Live Video'),
            Tab(icon: Icon(LucideIcons.videoOff), text: 'Offline / Async'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        // Keep live video session alive when switching tabs
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _LiveVideoTab(roomId: widget.roomId ?? _defaultRoomId),
          const _OfflineConsultationTab(),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 0 – Live Video (WebRTC)
// ─────────────────────────────────────────────────────────────────────────────

class _LiveVideoTab extends StatefulWidget {
  final String roomId;
  const _LiveVideoTab({required this.roomId});

  @override
  State<_LiveVideoTab> createState() => _LiveVideoTabState();
}

class _LiveVideoTabState extends State<_LiveVideoTab> with WidgetsBindingObserver {
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();

  MediaStream? _localStream;
  RTCPeerConnection? _peerConnection;
  IO.Socket? _socket;

  bool _micOn = true;
  bool _cameraOn = true;
  bool _remoteConnected = false;
  bool _isInitializing = true;
  bool _isOnline = true;
  String _statusMessage = 'Initializing camera…';
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  // ICE servers – Google STUN (same as web useWebRTC hook)
  static const Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ],
  };

  // Constraints matching the web side (720p preferred)
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
    WidgetsBinding.instance.addObserver(this);
    _initAll();
    _checkInitialConnectivity();
    _watchConnectivity();
  }

  Future<void> _initAll() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    await _openUserMedia();
    _connectSocket();
  }

  Future<void> _checkInitialConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    _updateConnectionStatus(results);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (mounted && _isOnline != online) {
      setState(() => _isOnline = online);
    }
  }

  void _watchConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkInitialConnectivity();
    }
  }

  Future<void> _openUserMedia() async {
    try {
      final stream = await navigator.mediaDevices.getUserMedia(_mediaConstraints);
      _localStream = stream;
      _localRenderer.srcObject = stream;
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _statusMessage = 'Waiting for Doctor…';
        });
      }
      AppLogger.info('LiveVideo', 'Local media stream opened');
    } catch (e) {
      AppLogger.error('LiveVideo', 'Failed to open camera', e);
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _statusMessage = 'Camera unavailable. Check permissions.';
        });
      }
    }
  }

  // ── Socket.io signaling (mirrors web useWebRTC.ts) ───────────────────────

  void _connectSocket() {
    _socket = IO.io(_backendUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    _socket!.onConnect((_) {
      AppLogger.info('LiveVideo', 'Socket connected, joining room: ${widget.roomId}');
      _socket!.emit('join-room', {'roomId': widget.roomId});
    });

    _socket!.on('room-ready', (_) async {
      AppLogger.info('LiveVideo', 'Room ready – creating peer connection as caller');
      await _createPeerConnection(isCaller: true);
      final offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      _socket!.emit('offer', {
        'roomId': widget.roomId,
        'sdp': offer.sdp,
        'type': offer.type,
      });
    });

    _socket!.on('offer', (data) async {
      AppLogger.info('LiveVideo', 'Received offer – answering as callee');
      await _createPeerConnection(isCaller: false);
      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(data['sdp'], data['type']),
      );
      final answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);
      _socket!.emit('answer', {
        'roomId': widget.roomId,
        'sdp': answer.sdp,
        'type': answer.type,
      });
    });

    _socket!.on('answer', (data) async {
      AppLogger.info('LiveVideo', 'Received answer');
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

    _socket!.onDisconnect((_) {
      AppLogger.info('LiveVideo', 'Socket disconnected');
    });
  }

  Future<void> _createPeerConnection({required bool isCaller}) async {
    _peerConnection = await createPeerConnection(_iceServers);

    // Add local tracks to peer connection
    _localStream?.getTracks().forEach((track) {
      _peerConnection!.addTrack(track, _localStream!);
    });

    // Listen for remote stream
    _peerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteRenderer.srcObject = event.streams.first;
        if (mounted) {
          setState(() => _remoteConnected = true);
        }
        AppLogger.info('LiveVideo', 'Remote stream received');
      }
    };

    // Send ICE candidates to remote peer
    _peerConnection!.onIceCandidate = (candidate) {
      _socket!.emit('ice-candidate', {
        'roomId': widget.roomId,
        'candidate': candidate.candidate,
        'sdpMid': candidate.sdpMid,
        'sdpMLineIndex': candidate.sdpMLineIndex,
      });
    };

    _peerConnection!.onConnectionState = (state) {
      AppLogger.info('LiveVideo', 'Peer connection state: $state');
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        if (mounted) {
          setState(() {
            _remoteConnected = false;
            _statusMessage = 'Connection lost. Waiting for Doctor…';
          });
        }
      }
    };
  }

  void _toggleMic() {
    _localStream?.getAudioTracks().forEach((track) {
      track.enabled = !_micOn;
    });
    setState(() => _micOn = !_micOn);
  }

  void _toggleCamera() {
    _localStream?.getVideoTracks().forEach((track) {
      track.enabled = !_cameraOn;
    });
    setState(() => _cameraOn = !_cameraOn);
  }

  void _endCall() {
    _peerConnection?.close();
    _socket?.disconnect();
    _localStream?.dispose();
    if (mounted) { context.pop(); }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySubscription?.cancel();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    _peerConnection?.close();
    _socket?.disconnect();
    _localStream?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Online status bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          color: _isOnline
              ? AppColors.success.withValues(alpha: 0.1)
              : AppColors.error.withValues(alpha: 0.1),
          child: Row(
            children: [
              Icon(
                _isOnline ? LucideIcons.wifi : LucideIcons.wifiOff,
                size: 14,
                color: _isOnline ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 6),
              Text(
                _isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  fontSize: 12,
                  color: _isOnline ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                'Room: ${widget.roomId}',
                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
        ),

        // Video area
        Expanded(
          child: Stack(
            children: [
              // Remote video (fullscreen / main)
              if (_remoteConnected)
                RTCVideoView(
                  _remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                )
              else
                Container(
                  color: const Color(0xFF111827),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_isInitializing)
                          const CircularProgressIndicator(color: AppColors.goldPrimary)
                        else
                          Icon(LucideIcons.video, size: 56, color: Colors.white.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text(
                          _statusMessage,
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ),

              // Local video PiP (top-right corner)
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
                      ? Transform(
                          alignment: Alignment.center,
                          transform: Matrix4.rotationY(3.14159), // mirror effect
                          child: RTCVideoView(
                            _localRenderer,
                            mirror: true,
                            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                          ),
                        )
                      : Center(
                          child: Icon(LucideIcons.cameraOff,
                              color: Colors.white.withValues(alpha: 0.5), size: 24),
                        ),
                ),
              ),

              // Controls bar (bottom)
              Positioned(
                bottom: 24,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Mic toggle
                    _ControlButton(
                      icon: _micOn ? LucideIcons.mic : LucideIcons.micOff,
                      isActive: _micOn,
                      onTap: _toggleMic,
                    ),
                    const SizedBox(width: 16),

                    // End call
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

                    // Camera toggle
                    _ControlButton(
                      icon: _cameraOn ? LucideIcons.camera : LucideIcons.cameraOff,
                      isActive: _cameraOn,
                      onTap: _toggleCamera,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Control button widget (mic / camera)
// ─────────────────────────────────────────────────────────────────────────────

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ControlButton({required this.icon, required this.isActive, required this.onTap});

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

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1 – Offline / Async Consultation
// (Mirrors the Offline section of the web consultation/page.tsx)
// ─────────────────────────────────────────────────────────────────────────────

class _OfflineConsultationTab extends ConsumerStatefulWidget {
  const _OfflineConsultationTab();

  @override
  ConsumerState<_OfflineConsultationTab> createState() =>
      _OfflineConsultationTabState();
}

class _OfflineConsultationTabState
    extends ConsumerState<_OfflineConsultationTab> {
  final _formKey = GlobalKey<FormState>();
  final _chiefComplaintController = TextEditingController();
  final _symptomsController = TextEditingController();

  File? _mediaFile;
  String? _mediaType;
  bool _isSaving = false;
  bool _submitted = false;

  @override
  void dispose() {
    _chiefComplaintController.dispose();
    _symptomsController.dispose();
    super.dispose();
  }

  Future<void> _pickMedia({required bool isVideo}) async {
    final picker = ImagePicker();
    final picked = isVideo
        ? await picker.pickVideo(
            source: ImageSource.camera,
            maxDuration: const Duration(seconds: 10),
          )
        : await picker.pickImage(source: ImageSource.camera);

    if (picked != null) {
      setState(() {
        _mediaFile = File(picked.path);
        _mediaType = isVideo ? 'video' : 'photo';
      });
      AppLogger.info('OfflineTab', 'Media selected: ${picked.path}');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_mediaFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please record a video or take a photo'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final consultation = {
        'id': const Uuid().v4(),
        'chiefComplaint': _chiefComplaintController.text,
        'symptomsDescription': _symptomsController.text,
        'mediaPath': _mediaFile!.path,
        'mediaType': _mediaType,
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      };

      await OfflineConsultationDb.instance.save(consultation);

      // Trigger background sync
      final syncService = OfflineConsultationSync(ref.read(apiClientProvider));
      syncService.syncPending();

      if (mounted) {
        setState(() {
          _submitted = true;
          _mediaFile = null;
          _mediaType = null;
          _chiefComplaintController.clear();
          _symptomsController.clear();
        });

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _submitted = false);
        });
      }
    } catch (e) {
      AppLogger.error('OfflineTab', 'Failed to save', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success banner
            if (_submitted)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.checkCircle, color: AppColors.success, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Consultation saved! Will be uploaded when online.',
                        style: TextStyle(color: AppColors.success, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // Intro text
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(LucideIcons.videoOff, color: AppColors.goldPrimary, size: 20),
                      const SizedBox(width: 8),
                      Text('Offline Symptom Report',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Record a 10s video or take a photo and describe your symptoms. A doctor will review and follow up.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Patient details form
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Patient Details',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _chiefComplaintController,
                    decoration: const InputDecoration(
                      labelText: 'Chief Complaint',
                      hintText: 'e.g., Headache for 3 days',
                      prefixIcon: Icon(LucideIcons.alertCircle, size: 18),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _symptomsController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Symptoms Description',
                      hintText: 'Describe your symptoms in detail…',
                      prefixIcon: Padding(
                        padding: EdgeInsets.only(bottom: 60),
                        child: Icon(LucideIcons.fileText, size: 18),
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Required field' : null,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Media upload
            GlassPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Media Upload',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (_mediaFile != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _mediaType == 'video' ? LucideIcons.video : LucideIcons.image,
                            size: 32,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _mediaType == 'video' ? 'Video recorded' : 'Photo captured',
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  _mediaFile!.path.split(Platform.pathSeparator).last,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() {
                              _mediaFile = null;
                              _mediaType = null;
                            }),
                            icon: const Icon(LucideIcons.trash2, color: AppColors.error, size: 18),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          label: 'Record Video',
                          icon: const Icon(LucideIcons.video, size: 18),
                          variant: AppButtonVariant.outline,
                          onPressed: () => _pickMedia(isVideo: true),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: AppButton(
                          label: 'Take Photo',
                          icon: const Icon(LucideIcons.camera, size: 18),
                          variant: AppButtonVariant.outline,
                          onPressed: () => _pickMedia(isVideo: false),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            AppButton(
              label: 'Submit Report',
              variant: AppButtonVariant.primary,
              width: double.infinity,
              isLoading: _isSaving,
              onPressed: _submit,
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
