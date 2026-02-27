import 'package:engine/engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_notifier.dart';
import '../network/online_game_notifier.dart';
import 'animated_card.dart';
import 'card_widget.dart';
import 'captured_area.dart';
import 'result_dialog.dart';
import 'score_panel.dart';

/// 온라인 대전 게임 화면
class OnlineGamePage extends ConsumerStatefulWidget {
  const OnlineGamePage({super.key});

  @override
  ConsumerState<OnlineGamePage> createState() => _OnlineGamePageState();
}

class _OnlineGamePageState extends ConsumerState<OnlineGamePage> {
  bool _resultShown = false;
  GameEvent? _activeEvent;

  @override
  Widget build(BuildContext context) {
    final onlineState = ref.watch(onlineGameProvider);
    final uiState = onlineState.gameUiState;
    final gs = uiState.gameState;
    final notifier = ref.read(onlineGameProvider.notifier);
    final myIndex = onlineState.myPlayerIndex;
    final opponentIndex = myIndex == 0 ? 1 : 0;

    // 이벤트 애니메이션 트리거
    if (uiState.event != GameEvent.none && _activeEvent != uiState.event) {
      _activeEvent = uiState.event;
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) setState(() => _activeEvent = null);
      });
    }

    // 게임 종료 시 결과 다이얼로그
    if (uiState.isGameOver && !_resultShown && uiState.result != null) {
      _resultShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showResult(context, uiState.result!, notifier);
      });
    }

    // 상대 연결 끊김 오버레이
    if (onlineState.onlineState == OnlineState.opponentDisconnected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showDisconnectedDialog(context);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1B3A1B),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('P2P 대전'),
            const SizedBox(width: 8),
            // 연결 상태 인디케이터
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: onlineState.onlineState == OnlineState.playing
                    ? Colors.greenAccent
                    : Colors.red,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // 내 턴 표시
          if (onlineState.isMyTurn)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Center(
                child: Text(
                  '내 턴',
                  style: TextStyle(
                    color: Colors.amber,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // === 상대 손패 (뒷면) ===
                _sectionLabel('상대 손패'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: CardRow(
                    cards: gs.playerHands.length > opponentIndex
                        ? gs.playerHands[opponentIndex]
                        : [],
                    faceDown: true,
                    overlap: 0.7,
                    cardWidth: 42,
                    cardHeight: 58,
                  ),
                ),

                const SizedBox(height: 4),

                // === 상대 획득 카드 ===
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: CapturedArea(
                    cards: gs.capturedCards.length > opponentIndex
                        ? gs.capturedCards[opponentIndex]
                        : [],
                    label: '상대 획득',
                  ),
                ),

                const SizedBox(height: 6),

                // === 점수판 ===
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: ScorePanel(
                    playerCaptured: gs.capturedCards[myIndex],
                    aiCaptured: gs.capturedCards.length > opponentIndex
                        ? gs.capturedCards[opponentIndex]
                        : [],
                    playerGoCount: gs.goCount[myIndex],
                    aiGoCount: gs.goCount.length > opponentIndex
                        ? gs.goCount[opponentIndex]
                        : 0,
                    deckSize: gs.deckSize,
                    currentPlayer: gs.currentPlayer,
                  ),
                ),

                const SizedBox(height: 6),

                // === 바닥 카드 ===
                _sectionLabel('바닥'),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _TableArea(
                      tableCards: gs.tableCards.cards,
                      highlightedCards: {
                        ...uiState.pendingMatchChoices,
                        ...uiState.pendingCaptureChoices,
                      },
                      onCardTap: uiState.pendingMatchChoices.isNotEmpty
                          ? (card) => notifier.selectMatch(card)
                          : uiState.pendingCaptureChoices.isNotEmpty
                              ? (card) => notifier.selectCaptureMatch(card)
                              : null,
                      selectableCards: {
                        ...uiState.pendingMatchChoices,
                        ...uiState.pendingCaptureChoices,
                      },
                    ),
                  ),
                ),

                // === 메시지 바 ===
                if (uiState.message != null)
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    color: Colors.black54,
                    child: Text(
                      uiState.message!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber,
                      ),
                    ),
                  ),

                // === 고/스톱 버튼 ===
                if (onlineState.isMyGoStopChoice)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () => notifier.chooseGo(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade800,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 12),
                          ),
                          child: const Text(
                            '고',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 24),
                        ElevatedButton(
                          onPressed: () => notifier.chooseStop(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade800,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 12),
                          ),
                          child: const Text(
                            '스톱',
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 4),

                // === 내 획득 카드 ===
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: CapturedArea(
                    cards: gs.capturedCards[myIndex],
                    label: '내 획득',
                  ),
                ),

                const SizedBox(height: 4),

                // === 내 손패 ===
                _sectionLabel('내 손패'),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: CardRow(
                    cards: gs.playerHands[myIndex],
                    overlap: 0.5,
                    cardWidth: 52,
                    cardHeight: 72,
                    onCardTap:
                        onlineState.isMyTurn && gs.phase == GamePhase.play
                            ? (card) => notifier.playCard(card)
                            : null,
                  ),
                ),

                const SizedBox(height: 8),
              ],
            ),

            // === 이벤트 애니메이션 오버레이 ===
            if (_activeEvent == GameEvent.sweep)
              Positioned.fill(
                child: Center(
                  child: SweepEffectOverlay(
                    onComplete: () {
                      if (mounted) setState(() => _activeEvent = null);
                    },
                  ),
                ),
              ),
            if (_activeEvent == GameEvent.goChosen)
              Positioned.fill(
                child: Center(
                  child: GoStopBanner(
                    isGo: true,
                    goCount: uiState.lastGoCount,
                    onComplete: () {
                      if (mounted) setState(() => _activeEvent = null);
                    },
                  ),
                ),
              ),
            if (_activeEvent == GameEvent.stopChosen)
              Positioned.fill(
                child: Center(
                  child: GoStopBanner(
                    isGo: false,
                    onComplete: () {
                      if (mounted) setState(() => _activeEvent = null);
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.white38,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _showResult(BuildContext context, GameResult result,
      OnlineGameNotifier notifier) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ResultDialog(
        result: result,
        onNewGame: () {
          Navigator.of(context).pop(); // 다이얼로그 닫기
          // 온라인은 재매칭 필요
          notifier.disconnect();
          Navigator.of(context).pop(); // 로비로 돌아감
        },
        onBackToLobby: () {
          Navigator.of(context).pop();
          notifier.disconnect();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showDisconnectedDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('연결 끊김'),
        content: const Text('상대방과의 연결이 끊어졌습니다.\n30초 후 자동으로 종료됩니다.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // dialog
              ref.read(onlineGameProvider.notifier).disconnect();
              Navigator.of(context).pop(); // 로비로
            },
            child: const Text('나가기'),
          ),
        ],
      ),
    );
  }
}

/// 바닥 카드 영역 (Wrap 레이아웃) — GamePage와 동일한 구조
class _TableArea extends StatelessWidget {
  final List<HwatooCard> tableCards;
  final Set<HwatooCard> highlightedCards;
  final Set<HwatooCard> selectableCards;
  final ValueChanged<HwatooCard>? onCardTap;

  const _TableArea({
    required this.tableCards,
    this.highlightedCards = const {},
    this.selectableCards = const {},
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [
            for (final card in tableCards)
              HwatooCardWidget(
                card: card,
                width: 48,
                height: 66,
                highlighted: highlightedCards.contains(card),
                onTap: selectableCards.contains(card) && onCardTap != null
                    ? () => onCardTap!(card)
                    : null,
              ),
          ],
        ),
      ),
    );
  }
}
