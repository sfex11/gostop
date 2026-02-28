import 'package:engine/engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/game_notifier.dart';
import 'animated_card.dart';
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
  GameEvent? _activeEvent;

  @override
  Widget build(BuildContext context) {
    final uiState = ref.watch(gameProvider);
    final gs = uiState.gameState;
    final notifier = ref.read(gameProvider.notifier);

    // 이벤트 애니메이션 트리거
    if (uiState.event != GameEvent.none && _activeEvent != uiState.event) {
      _activeEvent = uiState.event;
      // 일정 시간 후 리셋
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

    // --- 손패 월별 정렬 ---
    final sortedHand = List<HwatooCard>.from(gs.playerHands[0])
      ..sort((a, b) {
        final monthCmp = a.month.index.compareTo(b.month.index);
        if (monthCmp != 0) return monthCmp;
        return a.type.index.compareTo(b.type.index);
      });

    // --- 바닥과 매칭되는 손패 카드 계산 ---
    final tableMonths = <Month>{};
    for (final c in gs.tableCards.cards) {
      tableMonths.add(c.month);
    }
    final matchableCards = <HwatooCard>{};
    if (uiState.isPlayerTurn && gs.phase == GamePhase.play) {
      for (final c in sortedHand) {
        if (tableMonths.contains(c.month)) {
          matchableCards.add(c);
        }
      }
    }

    // --- 바닥 카드 월별 정렬 ---
    final sortedTable = List<HwatooCard>.from(gs.tableCards.cards)
      ..sort((a, b) {
        final monthCmp = a.month.index.compareTo(b.month.index);
        if (monthCmp != 0) return monthCmp;
        return a.type.index.compareTo(b.type.index);
      });

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
        child: Stack(
          children: [
            Column(
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
            _sectionLabel('바닥 (${sortedTable.length}장)'),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _TableArea(
                  tableCards: sortedTable,
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
            _sectionLabel(
              '내 손패 (${sortedHand.length}장)',
              isActive: uiState.isPlayerTurn && gs.phase == GamePhase.play,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: CardRow(
                cards: sortedHand,
                overlap: 0.5,
                cardWidth: 52,
                cardHeight: 72,
                matchableCards: matchableCards,
                enableDimming:
                    uiState.isPlayerTurn && gs.phase == GamePhase.play,
                showMonthBadge: true,
                enableLongPressZoom: true,
                onCardTap: uiState.isPlayerTurn &&
                        gs.phase == GamePhase.play
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
            if (_activeEvent == GameEvent.tripleMatch)
              Positioned.fill(
                child: Center(
                  child: SpecialMoveBanner(
                    text: '뻑!',
                    color: Colors.purple.shade800,
                    onComplete: () {
                      if (mounted) setState(() => _activeEvent = null);
                    },
                  ),
                ),
              ),
            if (_activeEvent == GameEvent.bomb)
              Positioned.fill(
                child: Center(
                  child: SpecialMoveBanner(
                    text: '폭탄!',
                    color: Colors.red.shade900,
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

  Widget _sectionLabel(String text, {bool isActive = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, bottom: 2),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: 10,
                color: isActive ? Colors.greenAccent : Colors.white38,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isActive) ...[
              const SizedBox(width: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Text(
                  '내 턴',
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
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

/// 바닥 카드 영역 — 월별 그룹 표시
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
    // 월별 그룹핑 (이미 정렬된 상태)
    final groups = <Month, List<HwatooCard>>{};
    for (final card in tableCards) {
      groups.putIfAbsent(card.month, () => []).add(card);
    }

    return Center(
      child: SingleChildScrollView(
        child: Wrap(
          spacing: 2,
          runSpacing: 6,
          alignment: WrapAlignment.center,
          children: [
            for (final entry in groups.entries)
              _MonthGroup(
                cards: entry.value,
                highlightedCards: highlightedCards,
                selectableCards: selectableCards,
                onCardTap: onCardTap,
              ),
          ],
        ),
      ),
    );
  }
}

/// 같은 월 카드를 묶어 표시하는 위젯
class _MonthGroup extends StatelessWidget {
  final List<HwatooCard> cards;
  final Set<HwatooCard> highlightedCards;
  final Set<HwatooCard> selectableCards;
  final ValueChanged<HwatooCard>? onCardTap;

  const _MonthGroup({
    required this.cards,
    required this.highlightedCards,
    required this.selectableCards,
    this.onCardTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasMultiple = cards.length > 1;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.all(2),
      decoration: hasMultiple
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 1,
              ),
              color: Colors.white.withValues(alpha: 0.04),
            )
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            if (i > 0) const SizedBox(width: 2),
            HwatooCardWidget(
              card: cards[i],
              width: 48,
              height: 66,
              highlighted: highlightedCards.contains(cards[i]),
              showMonthBadge: true,
              onTap: selectableCards.contains(cards[i]) && onCardTap != null
                  ? () => onCardTap!(cards[i])
                  : null,
              onLongPress: () => showCardZoomDialog(context, cards[i]),
            ),
          ],
        ],
      ),
    );
  }
}
