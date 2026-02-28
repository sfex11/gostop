import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// 시그널링 이벤트 타입
enum SignalEventType {
  roomCreated,
  roomJoined,
  peerJoined,
  signal,
  error,
  disconnected,
  matchFound,
}

/// 시그널링 이벤트
class SignalEvent {
  final SignalEventType type;
  final Map<String, dynamic>? data;
  final String? error;

  const SignalEvent({required this.type, this.data, this.error});
}

/// 시그널링 서비스 (WebSocket 기반)
///
/// 역할:
/// - 방 생성/참가 (코드 매칭)
/// - 랜덤 매칭 대기열
/// - WebRTC SDP/ICE 후보 교환
class SignalingService {
  final String serverUrl;
  WebSocketChannel? _channel;
  final _eventController = StreamController<SignalEvent>.broadcast();
  String? _currentRoomId;
  bool _disposed = false;

  SignalingService({required this.serverUrl});

  /// 시그널링 이벤트 스트림
  Stream<SignalEvent> get events => _eventController.stream;

  /// 현재 방 ID
  String? get currentRoomId => _currentRoomId;

  /// 연결 상태
  bool get isConnected => _channel != null;

  /// 서버에 연결
  Future<void> connect() async {
    if (_disposed) return;
    try {
      final uri = Uri.parse(serverUrl);
      _channel = WebSocketChannel.connect(uri);
      await _channel!.ready;

      _channel!.stream.listen(
        (message) {
          _handleMessage(message as String);
        },
        onError: (error) {
          _eventController.add(SignalEvent(
            type: SignalEventType.error,
            error: error.toString(),
          ));
        },
        onDone: () {
          _eventController.add(const SignalEvent(
            type: SignalEventType.disconnected,
          ));
          _channel = null;
        },
      );
    } catch (e) {
      _eventController.add(SignalEvent(
        type: SignalEventType.error,
        error: '서버 연결 실패: $e',
      ));
    }
  }

  void _handleMessage(String raw) {
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final event = json['event'] as String;

      switch (event) {
        case 'room-created':
          _currentRoomId = json['roomId'] as String;
          _eventController.add(SignalEvent(
            type: SignalEventType.roomCreated,
            data: {'roomId': _currentRoomId},
          ));
        case 'room-joined':
          _currentRoomId = json['roomId'] as String;
          _eventController.add(SignalEvent(
            type: SignalEventType.roomJoined,
            data: json,
          ));
        case 'peer-joined':
          _eventController.add(SignalEvent(
            type: SignalEventType.peerJoined,
            data: json,
          ));
        case 'signal':
          _eventController.add(SignalEvent(
            type: SignalEventType.signal,
            data: json,
          ));
        case 'match-found':
          _currentRoomId = json['roomId'] as String;
          _eventController.add(SignalEvent(
            type: SignalEventType.matchFound,
            data: json,
          ));
        case 'error':
          _eventController.add(SignalEvent(
            type: SignalEventType.error,
            error: json['message'] as String? ?? '알 수 없는 오류',
          ));
      }
    } catch (e) {
      debugPrint('SignalingService: 메시지 파싱 오류: $e');
    }
  }

  void _send(Map<String, dynamic> data) {
    if (_channel == null) {
      debugPrint('SignalingService: 연결되지 않음');
      return;
    }
    _channel!.sink.add(jsonEncode(data));
  }

  /// 방 생성 (코드 기반 매칭)
  void createRoom() {
    final roomId = _generateRoomCode();
    _send({
      'event': 'create-room',
      'roomId': roomId,
    });
  }

  /// 방 참가 (코드 입력)
  void joinRoom(String roomId) {
    _send({
      'event': 'join-room',
      'roomId': roomId.toUpperCase(),
    });
  }

  /// 랜덤 매칭 대기열 참가
  void joinMatchmaking() {
    _send({
      'event': 'join-matchmaking',
    });
  }

  /// 랜덤 매칭 대기열 취소
  void cancelMatchmaking() {
    _send({
      'event': 'cancel-matchmaking',
    });
  }

  /// WebRTC 시그널 전송 (SDP Offer/Answer, ICE Candidate)
  void sendSignal(Map<String, dynamic> signalData) {
    _send({
      'event': 'signal',
      'roomId': _currentRoomId,
      ...signalData,
    });
  }

  /// 방 나가기
  void leaveRoom() {
    if (_currentRoomId != null) {
      _send({
        'event': 'leave-room',
        'roomId': _currentRoomId,
      });
      _currentRoomId = null;
    }
  }

  /// 6자리 영대문자 방 코드 생성
  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // 혼동 가능한 I,O,0,1 제외
    final rng = Random();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  /// 연결 해제
  void disconnect() {
    leaveRoom();
    _channel?.sink.close();
    _channel = null;
  }

  /// 리소스 해제
  void dispose() {
    _disposed = true;
    disconnect();
    _eventController.close();
  }
}
