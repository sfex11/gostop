import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import 'signaling_service.dart';

/// P2P 연결 상태
enum P2PConnectionState {
  disconnected,
  connecting,
  connected,
  failed,
}

/// WebRTC DataChannel 기반 P2P 서비스
///
/// 역할:
/// - WebRTC PeerConnection 관리
/// - DataChannel을 통한 게임 메시지 송수신
/// - ICE 후보 교환 (Signaling 서비스 연동)
class WebRtcService {
  final SignalingService signaling;
  final bool isHost;

  RTCPeerConnection? _peerConnection;
  RTCDataChannel? _dataChannel;

  final _messageController = StreamController<String>.broadcast();
  final _stateController = StreamController<P2PConnectionState>.broadcast();

  P2PConnectionState _state = P2PConnectionState.disconnected;
  StreamSubscription<SignalEvent>? _signalSub;
  bool _disposed = false;

  /// ICE 서버 설정 (STUN/TURN)
  static const _iceServers = <Map<String, dynamic>>[
    {'urls': 'stun:stun.l.google.com:19302'},
    {'urls': 'stun:stun1.l.google.com:19302'},
  ];

  WebRtcService({required this.signaling, required this.isHost});

  /// 수신 메시지 스트림
  Stream<String> get messages => _messageController.stream;

  /// 연결 상태 스트림
  Stream<P2PConnectionState> get connectionState => _stateController.stream;

  /// 현재 연결 상태
  P2PConnectionState get state => _state;

  void _setState(P2PConnectionState newState) {
    _state = newState;
    if (!_disposed) {
      _stateController.add(newState);
    }
  }

  /// P2P 연결 초기화
  Future<void> initialize() async {
    _setState(P2PConnectionState.connecting);

    // PeerConnection 생성
    final config = <String, dynamic>{
      'iceServers': _iceServers,
    };

    _peerConnection = await createPeerConnection(config);

    // ICE 후보 수집 → Signaling으로 전송
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      signaling.sendSignal({
        'type': 'ice-candidate',
        'candidate': candidate.toMap(),
      });
    };

    // 연결 상태 모니터링
    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      switch (state) {
        case RTCPeerConnectionState.RTCPeerConnectionStateConnected:
          _setState(P2PConnectionState.connected);
        case RTCPeerConnectionState.RTCPeerConnectionStateFailed:
          _setState(P2PConnectionState.failed);
        case RTCPeerConnectionState.RTCPeerConnectionStateDisconnected:
        case RTCPeerConnectionState.RTCPeerConnectionStateClosed:
          _setState(P2PConnectionState.disconnected);
        default:
          break;
      }
    };

    // Signaling 메시지 수신 처리
    _signalSub = signaling.events.listen(_onSignalEvent);

    if (isHost) {
      await _createDataChannel();
    } else {
      _peerConnection!.onDataChannel = (RTCDataChannel channel) {
        _setupDataChannel(channel);
      };
    }
  }

  /// Host: DataChannel 생성
  Future<void> _createDataChannel() async {
    final channelInit = RTCDataChannelInit()
      ..ordered = true
      ..maxRetransmits = 3;

    final channel =
        await _peerConnection!.createDataChannel('game', channelInit);
    _setupDataChannel(channel);
  }

  void _setupDataChannel(RTCDataChannel channel) {
    _dataChannel = channel;

    channel.onMessage = (RTCDataChannelMessage message) {
      if (!_disposed) {
        _messageController.add(message.text);
      }
    };

    channel.onDataChannelState = (RTCDataChannelState state) {
      debugPrint('WebRtcService: DataChannel state=$state');
      if (state == RTCDataChannelState.RTCDataChannelOpen) {
        _setState(P2PConnectionState.connected);
      }
    };
  }

  /// Signaling 이벤트 처리
  Future<void> _onSignalEvent(SignalEvent event) async {
    if (event.type != SignalEventType.signal || event.data == null) return;

    final data = event.data!;
    final signalType = data['type'] as String?;

    switch (signalType) {
      case 'offer':
        await _handleOffer(data);
      case 'answer':
        await _handleAnswer(data);
      case 'ice-candidate':
        await _handleIceCandidate(data);
    }
  }

  /// Host: SDP Offer 생성 및 전송
  Future<void> createOffer() async {
    if (_peerConnection == null) return;

    final offer = await _peerConnection!.createOffer();
    await _peerConnection!.setLocalDescription(offer);

    signaling.sendSignal({
      'type': 'offer',
      'sdp': offer.sdp,
    });
  }

  /// Client: SDP Offer 수신 → Answer 생성
  Future<void> _handleOffer(Map<String, dynamic> data) async {
    if (_peerConnection == null) return;

    final offer = RTCSessionDescription(data['sdp'] as String?, 'offer');
    await _peerConnection!.setRemoteDescription(offer);

    final answer = await _peerConnection!.createAnswer();
    await _peerConnection!.setLocalDescription(answer);

    signaling.sendSignal({
      'type': 'answer',
      'sdp': answer.sdp,
    });
  }

  /// Host: SDP Answer 수신
  Future<void> _handleAnswer(Map<String, dynamic> data) async {
    if (_peerConnection == null) return;

    final answer = RTCSessionDescription(data['sdp'] as String?, 'answer');
    await _peerConnection!.setRemoteDescription(answer);
  }

  /// ICE Candidate 수신
  Future<void> _handleIceCandidate(Map<String, dynamic> data) async {
    if (_peerConnection == null) return;

    final candidateMap = data['candidate'] as Map<String, dynamic>;
    final candidate = RTCIceCandidate(
      candidateMap['candidate'] as String?,
      candidateMap['sdpMid'] as String?,
      candidateMap['sdpMLineIndex'] as int?,
    );
    await _peerConnection!.addCandidate(candidate);
  }

  /// 게임 메시지 전송
  void sendMessage(String message) {
    if (_dataChannel?.state == RTCDataChannelState.RTCDataChannelOpen) {
      _dataChannel!.send(RTCDataChannelMessage(message));
    } else {
      debugPrint('WebRtcService: DataChannel이 열려있지 않음');
    }
  }

  /// 연결 해제
  Future<void> disconnect() async {
    _signalSub?.cancel();
    _signalSub = null;
    _dataChannel?.close();
    _dataChannel = null;
    await _peerConnection?.close();
    _peerConnection = null;
    _setState(P2PConnectionState.disconnected);
  }

  /// 리소스 해제
  Future<void> dispose() async {
    _disposed = true;
    await disconnect();
    _messageController.close();
    _stateController.close();
  }
}
