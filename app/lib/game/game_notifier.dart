import 'dart:math';

import 'package:engine/engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 게임 UI 상태
class GameUiState {
  final GameState gameState;

  /// AI가 턴을 진행 중인지
  final bool aiThinking;

  /// 2장 매칭 시 선택 대기 중인 후보 카드들
  final List<HwatooCard> pendingMatchChoices;

  /// 캡처 페이즈에서 2장 매칭 선택 대기
  final List<HwatooCard> pendingCaptureChoices;

  /// 마지막 이벤트 메시지 (UI 표시용)
  final String? message;

  /// 게임 결과 (종료 시)
  final GameResult? result;

  /// AI 난이도
  final AiDifficulty difficulty;

  const GameUiState({
    required this.gameState,
    this.aiThinking = false,
    this.pendingMatchChoices = const [],
    this.pendingCaptureChoices = const [],
    this.message,
    this.result,
    this.difficulty = AiDifficulty.normal,
  });

  GameUiState copyWith({
    GameState? gameState,
    bool? aiThinking,
    List<HwatooCard>? pendingMatchChoices,
    List<HwatooCard>? pendingCaptureChoices,
    String? message,
    GameResult? result,
    AiDifficulty? difficulty,
  }) {
    return GameUiState(
      gameState: gameState ?? this.gameState,
      aiThinking: aiThinking ?? this.aiThinking,
      pendingMatchChoices: pendingMatchChoices ?? this.pendingMatchChoices,
      pendingCaptureChoices:
          pendingCaptureChoices ?? this.pendingCaptureChoices,
      message: message,
      result: result,
      difficulty: difficulty ?? this.difficulty,
    );
  }

  /// 플레이어(인간)의 턴인지
  bool get isPlayerTurn => gameState.currentPlayer == 0 && !aiThinking;

  /// 게임이 끝났는지
  bool get isGameOver => gameState.phase == GamePhase.end;

  /// 고/스톱 선택 대기 중인지 (플레이어)
  bool get isGoStopChoice =>
      gameState.phase == GamePhase.goStop && gameState.currentPlayer == 0;
}

/// 게임 컨트롤러 (Riverpod Notifier)
class GameNotifier extends Notifier<GameUiState> {
  Agent _ai = HeuristicAgent();

  @override
  GameUiState build() {
    return GameUiState(
      gameState: GameState.newGame(playerCount: 2),
    );
  }

  /// AI 난이도 변경
  void setDifficulty(AiDifficulty difficulty) {
    _ai = HeuristicAgent(difficulty: difficulty);
    state = state.copyWith(difficulty: difficulty);
  }

  /// 새 게임 시작
  void newGame() {
    state = GameUiState(
      gameState: GameState.newGame(
        playerCount: 2,
        random: Random(),
      ),
      difficulty: state.difficulty,
    );
    // 난이도 유지
    _ai = HeuristicAgent(difficulty: state.difficulty);
  }

  /// 플레이어가 손패에서 카드를 냄
  void playCard(HwatooCard card) {
    if (!state.isPlayerTurn) return;
    if (state.gameState.phase != GamePhase.play) return;

    final table = state.gameState.tableCards;
    final matches = table.findMatches(card);

    if (matches.length == 2) {
      // 2장 매칭 — 플레이어가 선택해야 함
      state = state.copyWith(
        pendingMatchChoices: matches,
        message: '가져갈 카드를 선택하세요',
      );
      // 선택한 뒤 _executePlay가 호출됨
      _pendingPlayCard = card;
      return;
    }

    _executePlay(card, chosenMatch: matches.length == 1 ? matches.first : null);
  }

  HwatooCard? _pendingPlayCard;

  /// 2장 매칭 중 선택 완료
  void selectMatch(HwatooCard chosen) {
    if (_pendingPlayCard == null) return;
    final card = _pendingPlayCard!;
    _pendingPlayCard = null;
    state = state.copyWith(pendingMatchChoices: []);
    _executePlay(card, chosenMatch: chosen);
  }

  void _executePlay(HwatooCard card, {HwatooCard? chosenMatch}) {
    var gs = state.gameState.playCard(card, chosenMatch: chosenMatch);

    // 캡처 페이즈: 덱에서 뒤집은 카드 처리
    final drawn = gs.drawnCard;
    if (drawn != null) {
      final captureMatches = gs.tableCards.findMatches(drawn);
      if (captureMatches.length == 2) {
        // 캡처에서도 2장 매칭 — 선택 대기
        state = state.copyWith(
          gameState: gs,
          pendingCaptureChoices: captureMatches,
          message: '뒤집힌 카드(${_cardLabel(drawn)})로 가져갈 카드를 선택하세요',
        );
        return;
      }
    }

    // 자동 캡처 해결
    gs = gs.resolveCapture();
    _afterCapture(gs);
  }

  /// 캡처 2장 매칭 선택 완료
  void selectCaptureMatch(HwatooCard chosen) {
    var gs = state.gameState.resolveCapture(chosenMatch: chosen);
    state = state.copyWith(pendingCaptureChoices: []);
    _afterCapture(gs);
  }

  void _afterCapture(GameState gs) {
    if (gs.phase == GamePhase.goStop && gs.currentPlayer == 0) {
      // 플레이어가 고/스톱 선택
      final score = Scoring.totalScore(gs.capturedCards[0]);
      state = state.copyWith(
        gameState: gs,
        message: '${score}점! 고 하시겠습니까?',
      );
      return;
    }

    if (gs.phase == GamePhase.end) {
      final result = GameResult.fromState(gs);
      state = state.copyWith(
        gameState: gs,
        result: result,
        message: _endMessage(gs),
      );
      return;
    }

    // AI 턴인 경우
    if (gs.currentPlayer != 0) {
      state = state.copyWith(gameState: gs, aiThinking: true, message: 'AI 생각 중...');
      _runAiTurn(gs);
      return;
    }

    state = state.copyWith(gameState: gs, message: null);
  }

  /// Go 선택
  void chooseGo() {
    if (state.gameState.phase != GamePhase.goStop) return;
    var gs = state.gameState.chooseGo();
    final goCount = state.gameState.goCount[state.gameState.currentPlayer] + 1;

    if (gs.currentPlayer != 0) {
      state = state.copyWith(
        gameState: gs,
        aiThinking: true,
        message: '${goCount}고! AI 턴...',
      );
      _runAiTurn(gs);
    } else {
      state = state.copyWith(gameState: gs, message: '${goCount}고!');
    }
  }

  /// Stop 선택
  void chooseStop() {
    if (state.gameState.phase != GamePhase.goStop) return;
    var gs = state.gameState.chooseStop();
    final result = GameResult.fromState(gs);
    state = state.copyWith(
      gameState: gs,
      result: result,
      message: _endMessage(gs),
    );
  }

  /// AI 턴 실행 (비동기로 딜레이 후)
  Future<void> _runAiTurn(GameState gs) async {
    await Future.delayed(const Duration(milliseconds: 700));

    while (gs.currentPlayer != 0 && gs.phase != GamePhase.end) {
      if (gs.phase == GamePhase.play) {
        final action = _ai.chooseCard(gs);
        gs = gs.playCard(action.card, chosenMatch: action.chosenMatch);
        // 캡처
        final captureChoice = _ai.chooseCapture(gs);
        gs = gs.resolveCapture(chosenMatch: captureChoice);
      } else if (gs.phase == GamePhase.goStop) {
        final decision = _ai.chooseGoStop(gs);
        if (decision == GoStopDecision.go) {
          gs = gs.chooseGo();
        } else {
          gs = gs.chooseStop();
        }
      } else {
        break;
      }
    }

    if (gs.phase == GamePhase.end) {
      final result = GameResult.fromState(gs);
      state = state.copyWith(
        gameState: gs,
        aiThinking: false,
        result: result,
        message: _endMessage(gs),
      );
    } else {
      state = state.copyWith(
        gameState: gs,
        aiThinking: false,
        message: null,
      );
    }
  }

  String _endMessage(GameState gs) {
    if (gs.winner == null) return '무승부!';
    if (gs.winner == 0) return '승리!';
    return '패배...';
  }

  String _cardLabel(HwatooCard card) => card.name;
}

/// Riverpod Provider
final gameProvider = NotifierProvider<GameNotifier, GameUiState>(
  GameNotifier.new,
);
