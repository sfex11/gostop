import 'dart:math';

import 'card.dart';
import 'deck.dart';
import 'game_config.dart';
import 'matching.dart';
import 'scoring.dart';

/// 게임 진행 단계
enum GamePhase {
  /// 손패에서 카드 선택
  play,

  /// 덱에서 뒤집은 카드 처리
  capture,

  /// Go 또는 Stop 선택
  goStop,

  /// 게임 종료
  end,
}

/// 게임 상태 (불변)
class GameState {
  final int playerCount;
  final int currentPlayer;
  final GamePhase phase;
  final List<List<HwatooCard>> playerHands;
  final List<List<HwatooCard>> capturedCards;
  final TableCards tableCards;
  final List<int> goCount;
  final int? winner;
  final GameConfig config;

  /// 각 플레이어의 쓸 횟수 (피 뺏기용)
  final List<int> sweepCount;

  // 내부 상태
  final Deck _deck;
  final HwatooCard? _drawnCard;
  final HwatooCard? _playedCard;
  final List<HwatooCard> _playMatchedCards;

  int get deckSize => _deck.length;
  HwatooCard? get drawnCard => _drawnCard;

  GameState._({
    required this.playerCount,
    required this.currentPlayer,
    required this.phase,
    required this.playerHands,
    required this.capturedCards,
    required this.tableCards,
    required this.goCount,
    required this.config,
    required Deck deck,
    List<int>? sweepCount,
    this.winner,
    HwatooCard? drawnCard,
    HwatooCard? playedCard,
    List<HwatooCard>? playMatchedCards,
  })  : _deck = deck,
        sweepCount = sweepCount ?? List.filled(playerCount, 0),
        _drawnCard = drawnCard,
        _playedCard = playedCard,
        _playMatchedCards = playMatchedCards ?? const [];

  /// 새 게임 생성 및 카드 배분
  factory GameState.newGame({
    required int playerCount,
    Random? random,
    GameConfig config = GameConfig.standard,
  }) {
    assert(playerCount == 2 || playerCount == 3);
    final deck = Deck(random: random)..shuffle();

    final int cardsPerPlayer;
    final int cardsOnTable;
    if (playerCount == 2) {
      cardsPerPlayer = 10;
      cardsOnTable = 8;
    } else {
      cardsPerPlayer = 7;
      cardsOnTable = 6;
    }

    final hands = <List<HwatooCard>>[];
    for (var p = 0; p < playerCount; p++) {
      hands.add(deck.drawMany(cardsPerPlayer));
    }

    final tableCardList = deck.drawMany(cardsOnTable);

    return GameState._(
      playerCount: playerCount,
      currentPlayer: 0,
      phase: GamePhase.play,
      playerHands: hands,
      capturedCards: List.generate(playerCount, (_) => <HwatooCard>[]),
      tableCards: TableCards(tableCardList),
      goCount: List.filled(playerCount, 0),
      config: config,
      deck: deck,
    );
  }

  /// 상태 복사 (변경할 필드만 지정)
  GameState copyWith({
    int? currentPlayer,
    GamePhase? phase,
    List<List<HwatooCard>>? playerHands,
    List<List<HwatooCard>>? capturedCards,
    TableCards? tableCards,
    List<int>? goCount,
    List<int>? sweepCount,
    Deck? deck,
    int? winner,
    HwatooCard? drawnCard,
    HwatooCard? playedCard,
    List<HwatooCard>? playMatchedCards,
  }) {
    return GameState._(
      playerCount: playerCount,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      phase: phase ?? this.phase,
      playerHands: playerHands ?? this.playerHands,
      capturedCards: capturedCards ?? this.capturedCards,
      tableCards: tableCards ?? this.tableCards,
      goCount: goCount ?? this.goCount,
      sweepCount: sweepCount ?? this.sweepCount,
      config: config,
      deck: deck ?? _deck,
      winner: winner ?? this.winner,
      drawnCard: drawnCard ?? _drawnCard,
      playedCard: playedCard ?? _playedCard,
      playMatchedCards: playMatchedCards ?? _playMatchedCards,
    );
  }

  // === Play Phase ===

  /// 손패에서 카드를 냄 → Capture Phase로 전환
  GameState playCard(HwatooCard card, {HwatooCard? chosenMatch}) {
    assert(phase == GamePhase.play);

    // 손패에서 카드 제거
    final newHands = _copyHands();
    newHands[currentPlayer].remove(card);

    // 테이블 매칭
    final newTable = tableCards.copy();
    final matchResult = MatchResult.from(card, newTable);

    final List<HwatooCard> matchedCards;
    switch (matchResult.type) {
      case MatchType.noMatch:
        newTable.add(card);
        matchedCards = const [];
      case MatchType.singleMatch:
        final matched = matchResult.candidates.first;
        newTable.remove(matched);
        matchedCards = [matched];
      case MatchType.doubleMatch:
        final matched = chosenMatch ?? matchResult.candidates.first;
        newTable.remove(matched);
        matchedCards = [matched];
      case MatchType.tripleMatch:
        // 3장 전부 테이블에서 제거 (뻑)
        for (final c in matchResult.candidates) {
          newTable.remove(c);
        }
        matchedCards = List<HwatooCard>.from(matchResult.candidates);
    }

    // 덱에서 카드 뽑기
    final drawn = _deck.draw();

    return copyWith(
      phase: GamePhase.capture,
      playerHands: newHands,
      tableCards: newTable,
      drawnCard: drawn,
      playedCard: card,
      playMatchedCards: matchedCards,
    );
  }

  // === Capture Phase ===

  /// 덱에서 뽑은 카드로 테이블 매칭 해결
  GameState resolveCapture({HwatooCard? chosenMatch}) {
    assert(phase == GamePhase.capture);
    assert(_drawnCard != null);

    final newTable = tableCards.copy();
    final newCaptured = _copyCaptured();
    final drawnMatchResult = MatchResult.from(_drawnCard!, newTable);

    // 이전 Play Phase에서 매칭된 카드 획득
    if (_playMatchedCards.isNotEmpty) {
      newCaptured[currentPlayer].add(_playedCard!);
      newCaptured[currentPlayer].addAll(_playMatchedCards);
    }

    // 덱 카드 매칭 처리
    switch (drawnMatchResult.type) {
      case MatchType.noMatch:
        newTable.add(_drawnCard!);
      case MatchType.singleMatch:
        final matched = drawnMatchResult.candidates.first;
        newTable.remove(matched);
        newCaptured[currentPlayer].add(_drawnCard!);
        newCaptured[currentPlayer].add(matched);
      case MatchType.doubleMatch:
        final matched = chosenMatch ?? drawnMatchResult.candidates.first;
        newTable.remove(matched);
        newCaptured[currentPlayer].add(_drawnCard!);
        newCaptured[currentPlayer].add(matched);
      case MatchType.tripleMatch:
        for (final c in drawnMatchResult.candidates) {
          newTable.remove(c);
        }
        newCaptured[currentPlayer].add(_drawnCard!);
        for (final c in drawnMatchResult.candidates) {
          newCaptured[currentPlayer].add(c);
        }
    }

    // 쓸(sweep) 감지: 카드를 획득했는데 테이블이 비었으면 쓸
    final newSweepCount = List<int>.from(sweepCount);
    final didCapture = _playMatchedCards.isNotEmpty ||
        drawnMatchResult.type != MatchType.noMatch;
    if (config.useSweep && didCapture && newTable.cards.isEmpty) {
      newSweepCount[currentPlayer]++;
      // 피 뺏기: 상대에게서 피 1장씩 빼앗음
      if (config.usePiSteal) {
        for (var p = 0; p < playerCount; p++) {
          if (p == currentPlayer) continue;
          final opponentJunkIdx = newCaptured[p].lastIndexWhere(
            (c) => c.type == CardType.junk || c.type == CardType.doubleJunk,
          );
          if (opponentJunkIdx >= 0) {
            final stolen = newCaptured[p].removeAt(opponentJunkIdx);
            newCaptured[currentPlayer].add(stolen);
          }
        }
      }
    }

    // 점수 체크
    final score = Scoring.totalScore(newCaptured[currentPlayer]);
    if (score >= config.scoreThreshold) {
      return copyWith(
        phase: GamePhase.goStop,
        capturedCards: newCaptured,
        tableCards: newTable,
        sweepCount: newSweepCount,
      );
    }

    // 다음 플레이어
    final nextPlayer = (currentPlayer + 1) % playerCount;

    // 덱이 비었으면 게임 종료
    if (_deck.isEmpty) {
      return copyWith(
        phase: GamePhase.end,
        capturedCards: newCaptured,
        tableCards: newTable,
        sweepCount: newSweepCount,
      );
    }

    return copyWith(
      phase: GamePhase.play,
      currentPlayer: nextPlayer,
      capturedCards: newCaptured,
      tableCards: newTable,
      sweepCount: newSweepCount,
    );
  }

  // === GoStop Phase ===

  /// Go 선택 — 게임 계속
  GameState chooseGo() {
    assert(phase == GamePhase.goStop);
    final newGoCount = List<int>.from(goCount);
    newGoCount[currentPlayer]++;

    final nextPlayer = (currentPlayer + 1) % playerCount;
    return copyWith(
      phase: GamePhase.play,
      currentPlayer: nextPlayer,
      goCount: newGoCount,
    );
  }

  /// Stop 선택 — 현재 플레이어 승리
  GameState chooseStop() {
    assert(phase == GamePhase.goStop);
    return copyWith(
      phase: GamePhase.end,
      winner: currentPlayer,
    );
  }

  // === Helpers ===

  List<List<HwatooCard>> _copyHands() {
    return playerHands.map((h) => List<HwatooCard>.from(h)).toList();
  }

  List<List<HwatooCard>> _copyCaptured() {
    return capturedCards.map((c) => List<HwatooCard>.from(c)).toList();
  }
}
