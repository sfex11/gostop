import 'package:engine/engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_notifier.dart';
import 'card_widget.dart';
import 'captured_area.dart';
import 'result_dialog.dart';
import 'score_panel.dart';

/// 메인 게임 화면
class GamePage extends ConsumerStatefulWidget {
  const GamePage({super.key});

  @override
  ConsumerState<GamePage> createState() => _GamePageState();
}

class _GamePageState extends ConsumerState<GamePage> {
  bool _resultShown = false;

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(gameProvider);
    final gs = uiState.gameState;
    final notifier = ref.read(gameProvider.notifier);

    // 게임 종료 시 결과 다이얼로그
    if (uiState.isGameOver && !_resultShown && uiState.result != null) {
      _resultShown = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showResult(context, uiState.result!, notifier);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1B3A1B),
      appBar: AppBar(
        title: const Text('고스톱'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '새 게임',
            onPressed: () {
              _resultShown = false;
              notifier.newGame();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // === AI 손패 (뒷면) ===
            _sectionLabel('AI 손패'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: CardRow(
                cards: gs.playerHands.length > 1 ? gs.playerHands[1] : [],
                faceDown: true,
                overlap: 0.7,
                cardWidth: 42,
                cardHeight: 58,
              ),
            ),

            const SizedBox(height: 4),

            // === AI 획득 카드 ===
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: CapturedArea(
                cards: gs.capturedCards.length > 1 ? gs.capturedCards[1] : [],
                label: 'AI 획득',
              ),
            ),

            const SizedBox(height: 6),

            // === 점수판 ===
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: ScorePanel(
                playerCaptured: gs.capturedCards[0],
                aiCaptured:
                    gs.capturedCards.length > 1 ? gs.capturedCards[1] : [],
                playerGoCount: gs.goCount[0],
                aiGoCount: gs.goCount.length > 1 ? gs.goCount[1] : 0,
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
            if (uiState.isGoStopChoice)
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
                cards: gs.capturedCards[0],
                label: '내 획득',
              ),
            ),

            const SizedBox(height: 4),

            // === 내 손패 ===
            _sectionLabel('내 손패'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: CardRow(
                cards: gs.playerHands[0],
                overlap: 0.5,
                cardWidth: 52,
                cardHeight: 72,
                onCardTap: uiState.isPlayerTurn &&
                        gs.phase == GamePhase.play
                    ? (card) => notifier.playCard(card)
                    : null,
              ),
            ),

            const SizedBox(height: 8),
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

  void _showResult(
      BuildContext context, GameResult result, GameNotifier notifier) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ResultDialog(
        result: result,
        onNewGame: () {
          Navigator.of(context).pop();
          _resultShown = false;
          notifier.newGame();
        },
        onBackToLobby: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop(); // lobby로 돌아감
        },
      ),
    );
  }
}

/// 바닥 카드 영역 (Wrap 레이아웃)
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
