import 'dart:math';

import 'card.dart';
import 'deck.dart';
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

  // 내부 상태
  final Deck _deck;
  final HwatooCard? _drawnCard;
  final HwatooCard? _playedCard;
  final HwatooCard? _matchedTableCard;

  int get deckSize => _deck.length;
  HwatooCard? get drawnCard => _drawnCard;

  /// 점수 기준 (이 점수 이상이면 Go/Stop 선택)
  static const int scoreThreshold = 3;

  GameState._({
    required this.playerCount,
    required this.currentPlayer,
    required this.phase,
    required this.playerHands,
    required this.capturedCards,
    required this.tableCards,
    required this.goCount,
    required Deck deck,
    this.winner,
    HwatooCard? drawnCard,
    HwatooCard? playedCard,
    HwatooCard? matchedTableCard,
  })  : _deck = deck,
        _drawnCard = drawnCard,
        _playedCard = playedCard,
        _matchedTableCard = matchedTableCard;

  /// 새 게임 생성 및 카드 배분
  factory GameState.newGame({
    required int playerCount,
    Random? random,
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
    Deck? deck,
    int? winner,
    HwatooCard? drawnCard,
    HwatooCard? playedCard,
    HwatooCard? matchedTableCard,
  }) {
    return GameState._(
      playerCount: playerCount,
      currentPlayer: currentPlayer ?? this.currentPlayer,
      phase: phase ?? this.phase,
      playerHands: playerHands ?? this.playerHands,
      capturedCards: capturedCards ?? this.capturedCards,
      tableCards: tableCards ?? this.tableCards,
      goCount: goCount ?? this.goCount,
      deck: deck ?? _deck,
      winner: winner ?? this.winner,
      drawnCard: drawnCard ?? _drawnCard,
      playedCard: playedCard ?? _playedCard,
      matchedTableCard: matchedTableCard ?? _matchedTableCard,
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

    HwatooCard? matchedCard;
    switch (matchResult.type) {
      case MatchType.noMatch:
        newTable.add(card);
      case MatchType.singleMatch:
        matchedCard = matchResult.candidates.first;
        newTable.remove(matchedCard);
      case MatchType.doubleMatch:
        matchedCard = chosenMatch ?? matchResult.candidates.first;
        newTable.remove(matchedCard);
      case MatchType.tripleMatch:
        // 3장 전부 테이블에서 제거 (뻑)
        matchedCard = matchResult.candidates.first;
        for (final c in matchResult.candidates) {
          newTable.remove(c);
        }
    }

    // 덱에서 카드 뽑기
    final drawn = _deck.draw();

    return copyWith(
      phase: GamePhase.capture,
      playerHands: newHands,
      tableCards: newTable,
      drawnCard: drawn,
      playedCard: card,
      matchedTableCard: matchedCard,
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
    if (_matchedTableCard != null) {
      newCaptured[currentPlayer].add(_playedCard!);
      newCaptured[currentPlayer].add(_matchedTableCard!);
      // tripleMatch인 경우 나머지 카드도 추가
      if (_playedCard != null) {
        final originalMatch = MatchResult.from(_playedCard!, tableCards);
        if (originalMatch.type == MatchType.tripleMatch) {
          for (final c in originalMatch.candidates.skip(1)) {
            if (c != _matchedTableCard) {
              newCaptured[currentPlayer].add(c);
            }
          }
        }
      }
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

    // 점수 체크
    final score = Scoring.totalScore(newCaptured[currentPlayer]);
    if (score >= scoreThreshold) {
      return copyWith(
        phase: GamePhase.goStop,
        capturedCards: newCaptured,
        tableCards: newTable,
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
      );
    }

    return copyWith(
      phase: GamePhase.play,
      currentPlayer: nextPlayer,
      capturedCards: newCaptured,
      tableCards: newTable,
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
