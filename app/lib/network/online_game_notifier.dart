import 'dart:async';
import 'dart:math';

import 'package:engine/engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_notifier.dart';
import 'game_message.dart';
import 'signaling_service.dart';
import 'webrtc_service.dart';

/// 온라인 연결 상태
enum OnlineState {
  disconnected,
  waitingInRoom,
  matchmaking,
  connecting,
  playing,
  opponentDisconnected,
}

/// 온라인 게임 UI 상태
class OnlineGameUiState {
  final GameUiState gameUiState;
  final OnlineState onlineState;
  final bool isHost;

  /// 내 플레이어 인덱스 (Host=0, Client=1)
  final int myPlayerIndex;
  final String? roomCode;
  final String? errorMessage;

  const OnlineGameUiState({
    required this.gameUiState,
    this.onlineState = OnlineState.disconnected,
    this.isHost = false,
    this.myPlayerIndex = 0,
    this.roomCode,
    this.errorMessage,
  });

  OnlineGameUiState copyWith({
    GameUiState? gameUiState,
    OnlineState? onlineState,
    bool? isHost,
    int? myPlayerIndex,
    String? roomCode,
    String? errorMessage,
  }) {
    return OnlineGameUiState(
      gameUiState: gameUiState ?? this.gameUiState,
      onlineState: onlineState ?? this.onlineState,
      isHost: isHost ?? this.isHost,
      myPlayerIndex: myPlayerIndex ?? this.myPlayerIndex,
      roomCode: roomCode ?? this.roomCode,
      errorMessage: errorMessage,
    );
  }

  /// 내 턴인지
  bool get isMyTurn =>
      gameUiState.gameState.currentPlayer == myPlayerIndex &&
      !gameUiState.aiThinking;

  /// 고/스톱 선택 대기 중인지 (내가)
  bool get isMyGoStopChoice =>
      gameUiState.gameState.phase == GamePhase.goStop &&
      gameUiState.gameState.currentPlayer == myPlayerIndex;
}

/// 온라인 게임 컨트롤러
///
/// Host-Client 모델:
/// - Host(Player 0): 게임 상태 관리, 입력 검증, 덱 셔플
/// - Client(Player 1): 입력 전송, 상태 수신, UI 렌더링
class OnlineGameNotifier extends Notifier<OnlineGameUiState> {
  SignalingService? _signaling;
  WebRtcService? _webrtc;
  StreamSubscription<SignalEvent>? _signalSub;
  StreamSubscription<String>? _messageSub;
  StreamSubscription<P2PConnectionState>? _stateSub;

  int _turnCounter = 0;
  int? _gameSeed;
  GameConfig _config = GameConfig.standard;
  Timer? _reconnectTimer;

  @override
  OnlineGameUiState build() {
    return OnlineGameUiState(
      gameUiState: GameUiState(
        gameState: GameState.newGame(playerCount: 2),
      ),
    );
  }

  /// 게임 규칙 설정
  void setConfig(GameConfig config) {
    _config = config;
  }

  // === 방 생성/참가 ===

  /// Host: 방 생성
  Future<void> createRoom(String serverUrl) async {
    await _initSignaling(serverUrl);
    _signaling!.createRoom();
    state = state.copyWith(
      onlineState: OnlineState.waitingInRoom,
      isHost: true,
      myPlayerIndex: 0,
    );
  }

  /// Client: 방 참가
  Future<void> joinRoom(String serverUrl, String roomCode) async {
    await _initSignaling(serverUrl);
    _signaling!.joinRoom(roomCode);
    state = state.copyWith(
      onlineState: OnlineState.connecting,
      isHost: false,
      myPlayerIndex: 1,
      roomCode: roomCode,
    );
  }

  /// 랜덤 매칭
  Future<void> startMatchmaking(String serverUrl) async {
    await _initSignaling(serverUrl);
    _signaling!.joinMatchmaking();
    state = state.copyWith(
      onlineState: OnlineState.matchmaking,
    );
  }

  /// 매칭 취소
  void cancelMatchmaking() {
    _signaling?.cancelMatchmaking();
    state = state.copyWith(onlineState: OnlineState.disconnected);
  }

  Future<void> _initSignaling(String serverUrl) async {
    _cleanup();
    _signaling = SignalingService(serverUrl: serverUrl);

    _signalSub = _signaling!.events.listen(_onSignalEvent);
    await _signaling!.connect();
  }

  void _onSignalEvent(SignalEvent event) {
    switch (event.type) {
      case SignalEventType.roomCreated:
        state = state.copyWith(
          roomCode: event.data?['roomId'] as String?,
        );
      case SignalEventType.peerJoined:
        // Host: 상대 참가 → WebRTC 연결 시작
        _startWebRtc(isHost: true);
      case SignalEventType.roomJoined:
        // Client: 방 참가 성공 → WebRTC 대기
        _startWebRtc(isHost: false);
      case SignalEventType.matchFound:
        final isHost = event.data?['isHost'] as bool? ?? false;
        state = state.copyWith(
          isHost: isHost,
          myPlayerIndex: isHost ? 0 : 1,
          roomCode: event.data?['roomId'] as String?,
          onlineState: OnlineState.connecting,
        );
        _startWebRtc(isHost: isHost);
      case SignalEventType.error:
        state = state.copyWith(
          errorMessage: event.error,
        );
      case SignalEventType.disconnected:
        state = state.copyWith(
          onlineState: OnlineState.opponentDisconnected,
          errorMessage: '서버 연결이 끊어졌습니다',
        );
      case SignalEventType.signal:
        break; // WebRTC에서 처리
    }
  }

  Future<void> _startWebRtc({required bool isHost}) async {
    _webrtc = WebRtcService(signaling: _signaling!, isHost: isHost);

    _messageSub = _webrtc!.messages.listen(_onGameMessage);
    _stateSub = _webrtc!.connectionState.listen(_onConnectionState);

    await _webrtc!.initialize();

    if (isHost) {
      await _webrtc!.createOffer();
    }
  }

  void _onConnectionState(P2PConnectionState p2pState) {
    switch (p2pState) {
      case P2PConnectionState.connected:
        if (state.isHost) {
          _startGameAsHost();
        }
        state = state.copyWith(onlineState: OnlineState.playing);
      case P2PConnectionState.disconnected:
        if (state.onlineState == OnlineState.playing) {
          state = state.copyWith(
            onlineState: OnlineState.opponentDisconnected,
            errorMessage: '상대방 연결이 끊어졌습니다',
          );
          _startReconnectTimer();
        }
      case P2PConnectionState.failed:
        state = state.copyWith(
          onlineState: OnlineState.disconnected,
          errorMessage: 'P2P 연결 실패',
        );
      case P2PConnectionState.connecting:
        break;
    }
  }

  // === 게임 로직 ===

  /// Host: 게임 시작 (덱 셔플 + 초기화)
  void _startGameAsHost() {
    _gameSeed = DateTime.now().millisecondsSinceEpoch;
    _turnCounter = 0;

    final gs = GameState.newGame(
      playerCount: 2,
      random: Random(_gameSeed!),
      config: _config,
    );

    // Client에게 게임 초기화 메시지 전송
    final initMsg = GameMessage.gameInit(
      seed: _gameSeed!,
      config: _config.toJson(),
    );
    _sendMessage(initMsg);

    state = state.copyWith(
      gameUiState: GameUiState(gameState: gs),
      onlineState: OnlineState.playing,
    );
  }

  /// 수신 게임 메시지 처리
  void _onGameMessage(String raw) {
    try {
      final msg = GameMessage.fromJsonString(raw);

      switch (msg.type) {
        case GameMessageType.gameInit:
          _handleGameInit(msg);
        case GameMessageType.playCard:
          _handlePlayCard(msg);
        case GameMessageType.selectMatch:
          _handleSelectMatch(msg);
        case GameMessageType.selectCaptureMatch:
          _handleSelectCaptureMatch(msg);
        case GameMessageType.chooseGo:
          _handleChooseGo(msg);
        case GameMessageType.chooseStop:
          _handleChooseStop(msg);
        case GameMessageType.ping:
          _sendMessage(GameMessage.pong());
        case GameMessageType.pong:
          break;
        case GameMessageType.stateHash:
        case GameMessageType.syncRequest:
        case GameMessageType.fullSync:
          break;
      }
    } catch (e) {
      debugPrint('OnlineGameNotifier: 메시지 처리 오류: $e');
    }
  }

  /// Client: 게임 초기화 수신
  void _handleGameInit(GameMessage msg) {
    _gameSeed = msg.data!['seed'] as int;
    final configJson = msg.data!['config'] as Map<String, dynamic>;
    _config = GameConfigSerialization.fromJson(configJson);
    _turnCounter = 0;

    final gs = GameState.newGame(
      playerCount: 2,
      random: Random(_gameSeed!),
      config: _config,
    );

    state = state.copyWith(
      gameUiState: GameUiState(gameState: gs),
      onlineState: OnlineState.playing,
    );
  }

  /// 상대 카드 플레이 처리
  void _handlePlayCard(GameMessage msg) {
    final gs = state.gameUiState.gameState;
    if (gs.currentPlayer == state.myPlayerIndex) return; // 내 턴이면 무시

    final cardName = msg.data!['card'] as String;
    final matchName = msg.data?['chosenMatch'] as String?;
    final card = CardSerializer.fromName(cardName);
    final chosenMatch =
        matchName != null ? CardSerializer.fromName(matchName) : null;

    if (card == null) return;

    var newGs = gs.playCard(card, chosenMatch: chosenMatch);
    newGs = newGs.resolveCapture(chosenMatch: chosenMatch);
    _updateGameState(newGs);
  }

  void _handleSelectMatch(GameMessage msg) {
    // 상대가 2장 매칭 선택한 경우 — play_card에서 이미 처리
  }

  void _handleSelectCaptureMatch(GameMessage msg) {
    final gs = state.gameUiState.gameState;
    final matchName = msg.data!['chosenMatch'] as String;
    final chosen = CardSerializer.fromName(matchName);
    if (chosen == null) return;

    final newGs = gs.resolveCapture(chosenMatch: chosen);
    _updateGameState(newGs);
  }

  void _handleChooseGo(GameMessage msg) {
    final gs = state.gameUiState.gameState;
    if (gs.phase != GamePhase.goStop) return;

    final newGs = gs.chooseGo();
    final goCount = gs.goCount[gs.currentPlayer] + 1;

    state = state.copyWith(
      gameUiState: state.gameUiState.copyWith(
        gameState: newGs,
        message: '상대 ${goCount}고!',
        event: GameEvent.goChosen,
        lastGoCount: goCount,
      ),
    );
  }

  void _handleChooseStop(GameMessage msg) {
    final gs = state.gameUiState.gameState;
    if (gs.phase != GamePhase.goStop) return;

    final newGs = gs.chooseStop();
    final result = GameResult.fromState(newGs);
    state = state.copyWith(
      gameUiState: state.gameUiState.copyWith(
        gameState: newGs,
        result: result,
        message: _endMessage(newGs),
        event: GameEvent.stopChosen,
      ),
    );
  }

  void _updateGameState(GameState gs) {
    // 쓸 감지
    final prevSweep =
        state.gameUiState.gameState.sweepCount[gs.currentPlayer - 1 < 0 ? 1 : 0];
    final curSweep = gs.sweepCount.isNotEmpty ? gs.sweepCount[0] : 0;
    final isSweep = curSweep > prevSweep;

    if (gs.phase == GamePhase.end) {
      final result = GameResult.fromState(gs);
      state = state.copyWith(
        gameUiState: state.gameUiState.copyWith(
          gameState: gs,
          result: result,
          message: _endMessage(gs),
          event: isSweep ? GameEvent.sweep : GameEvent.none,
        ),
      );
      return;
    }

    if (gs.phase == GamePhase.goStop &&
        gs.currentPlayer == state.myPlayerIndex) {
      final score = Scoring.totalScore(gs.capturedCards[state.myPlayerIndex]);
      state = state.copyWith(
        gameUiState: state.gameUiState.copyWith(
          gameState: gs,
          message: '${score}점! 고 하시겠습니까?',
          event: isSweep ? GameEvent.sweep : GameEvent.none,
        ),
      );
      return;
    }

    state = state.copyWith(
      gameUiState: state.gameUiState.copyWith(
        gameState: gs,
        message: gs.currentPlayer == state.myPlayerIndex
            ? null
            : '상대 턴...',
        event: isSweep ? GameEvent.sweep : GameEvent.none,
      ),
    );
  }

  // === 플레이어 액션 (로컬 → 네트워크 전송) ===

  /// 카드 플레이
  void playCard(HwatooCard card) {
    final gs = state.gameUiState.gameState;
    if (gs.currentPlayer != state.myPlayerIndex) return;
    if (gs.phase != GamePhase.play) return;

    final table = gs.tableCards;
    final matches = table.findMatches(card);

    if (matches.length == 2) {
      // 2장 매칭 — 선택 대기
      state = state.copyWith(
        gameUiState: state.gameUiState.copyWith(
          pendingMatchChoices: matches,
          message: '가져갈 카드를 선택하세요',
        ),
      );
      _pendingPlayCard = card;
      return;
    }

    _executePlayAndSend(card,
        chosenMatch: matches.length == 1 ? matches.first : null);
  }

  HwatooCard? _pendingPlayCard;

  /// 2장 매칭 선택 완료
  void selectMatch(HwatooCard chosen) {
    if (_pendingPlayCard == null) return;
    final card = _pendingPlayCard!;
    _pendingPlayCard = null;
    state = state.copyWith(
      gameUiState: state.gameUiState.copyWith(pendingMatchChoices: []),
    );
    _executePlayAndSend(card, chosenMatch: chosen);
  }

  void _executePlayAndSend(HwatooCard card, {HwatooCard? chosenMatch}) {
    _turnCounter++;

    // 네트워크 메시지 전송
    final msg = GameMessage.playCard(
      turn: _turnCounter,
      player: state.myPlayerIndex,
      cardName: CardSerializer.toName(card),
      chosenMatchName:
          chosenMatch != null ? CardSerializer.toName(chosenMatch) : null,
    );
    _sendMessage(msg);

    // 로컬 상태 업데이트
    var gs = state.gameUiState.gameState.playCard(card, chosenMatch: chosenMatch);

    // 캡처
    final drawn = gs.drawnCard;
    if (drawn != null) {
      final captureMatches = gs.tableCards.findMatches(drawn);
      if (captureMatches.length == 2) {
        state = state.copyWith(
          gameUiState: state.gameUiState.copyWith(
            gameState: gs,
            pendingCaptureChoices: captureMatches,
            message: '뒤집힌 카드(${drawn.name})로 가져갈 카드를 선택하세요',
          ),
        );
        return;
      }
    }

    gs = gs.resolveCapture();
    _updateGameState(gs);
  }

  /// 캡처 2장 매칭 선택
  void selectCaptureMatch(HwatooCard chosen) {
    final msg = GameMessage.selectCaptureMatch(
      turn: _turnCounter,
      player: state.myPlayerIndex,
      chosenCardName: CardSerializer.toName(chosen),
    );
    _sendMessage(msg);

    var gs = state.gameUiState.gameState.resolveCapture(chosenMatch: chosen);
    state = state.copyWith(
      gameUiState: state.gameUiState.copyWith(pendingCaptureChoices: []),
    );
    _updateGameState(gs);
  }

  /// 고 선택
  void chooseGo() {
    final gs = state.gameUiState.gameState;
    if (gs.phase != GamePhase.goStop) return;
    if (gs.currentPlayer != state.myPlayerIndex) return;

    _sendMessage(GameMessage.chooseGo(
      turn: _turnCounter,
      player: state.myPlayerIndex,
    ));

    var newGs = gs.chooseGo();
    final goCount = gs.goCount[state.myPlayerIndex] + 1;

    state = state.copyWith(
      gameUiState: state.gameUiState.copyWith(
        gameState: newGs,
        message: '${goCount}고!',
        event: GameEvent.goChosen,
        lastGoCount: goCount,
      ),
    );
  }

  /// 스톱 선택
  void chooseStop() {
    final gs = state.gameUiState.gameState;
    if (gs.phase != GamePhase.goStop) return;
    if (gs.currentPlayer != state.myPlayerIndex) return;

    _sendMessage(GameMessage.chooseStop(
      turn: _turnCounter,
      player: state.myPlayerIndex,
    ));

    var newGs = gs.chooseStop();
    final result = GameResult.fromState(newGs);
    state = state.copyWith(
      gameUiState: state.gameUiState.copyWith(
        gameState: newGs,
        result: result,
        message: _endMessage(newGs),
        event: GameEvent.stopChosen,
      ),
    );
  }

  // === 유틸리티 ===

  void _sendMessage(GameMessage msg) {
    _webrtc?.sendMessage(msg.toJsonString());
  }

  String _endMessage(GameState gs) {
    if (gs.winner == null) return '무승부!';
    if (gs.winner == state.myPlayerIndex) return '승리!';
    return '패배...';
  }

  void _startReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 30), () {
      if (state.onlineState == OnlineState.opponentDisconnected) {
        disconnect();
      }
    });
  }

  /// 연결 종료
  void disconnect() {
    _cleanup();
    state = state.copyWith(onlineState: OnlineState.disconnected);
  }

  void _cleanup() {
    _reconnectTimer?.cancel();
    _signalSub?.cancel();
    _messageSub?.cancel();
    _stateSub?.cancel();
    _webrtc?.dispose();
    _signaling?.dispose();
    _signalSub = null;
    _messageSub = null;
    _stateSub = null;
    _webrtc = null;
    _signaling = null;
  }
}

/// Riverpod Provider
final onlineGameProvider =
    NotifierProvider<OnlineGameNotifier, OnlineGameUiState>(
  OnlineGameNotifier.new,
);
