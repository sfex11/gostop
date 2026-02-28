import 'dart:math';

import 'card.dart';
import 'game_state.dart';
import 'matching.dart';
import 'scoring.dart';

/// Go/Stop 선택
enum GoStopDecision { go, stop }

/// 카드 선택 액션
class PlayAction {
  final HwatooCard card;
  final HwatooCard? chosenMatch;

  const PlayAction({required this.card, this.chosenMatch});
}

/// AI 에이전트 인터페이스
abstract class Agent {
  /// 손패에서 낼 카드 + 매칭 선택
  PlayAction chooseCard(GameState state);

  /// 덱에서 뒤집은 카드의 매칭 선택 (2장 매칭 시)
  HwatooCard? chooseCapture(GameState state);

  /// Go / Stop 선택
  GoStopDecision chooseGoStop(GameState state);
}

/// 랜덤 가중치 AI (Phase 1 기본)
class RandomAgent extends Agent {
  final Random _random;

  RandomAgent({Random? random}) : _random = random ?? Random();

  @override
  PlayAction chooseCard(GameState state) {
    final hand = state.playerHands[state.currentPlayer];
    final table = state.tableCards;

    // 매칭 가능한 카드 우선 선택 (가중치)
    final withMatches = <PlayAction>[];
    final withoutMatches = <PlayAction>[];

    for (final card in hand) {
      final matches = table.findMatches(card);
      if (matches.isEmpty) {
        withoutMatches.add(PlayAction(card: card));
      } else if (matches.length == 1) {
        withMatches.add(PlayAction(card: card, chosenMatch: matches.first));
      } else if (matches.length == 2) {
        // 2장 매칭: 랜덤 선택
        final chosen = matches[_random.nextInt(matches.length)];
        withMatches.add(PlayAction(card: card, chosenMatch: chosen));
      } else {
        // 3장 매칭 (뻑): 첫 번째 카드로 전부 획득
        withMatches.add(PlayAction(card: card, chosenMatch: matches.first));
      }
    }

    // 70% 확률로 매칭 있는 카드 선택, 30% 랜덤
    if (withMatches.isNotEmpty && (_random.nextDouble() < 0.7 || withoutMatches.isEmpty)) {
      return withMatches[_random.nextInt(withMatches.length)];
    }
    if (withoutMatches.isNotEmpty) {
      return withoutMatches[_random.nextInt(withoutMatches.length)];
    }
    // fallback
    return withMatches[_random.nextInt(withMatches.length)];
  }

  @override
  HwatooCard? chooseCapture(GameState state) {
    if (state.drawnCard == null) return null;
    final matches = state.tableCards.findMatches(state.drawnCard!);
    if (matches.length <= 1) return matches.isEmpty ? null : matches.first;
    // 2장 이상: 랜덤 선택
    return matches[_random.nextInt(matches.length)];
  }

  @override
  GoStopDecision chooseGoStop(GameState state) {
    // 간단한 전략: 점수 낮으면 Go, 높으면 Stop
    final captured = state.capturedCards[state.currentPlayer];
    final score = _quickScore(captured);
    final goCount = state.goCount[state.currentPlayer];

    // 덱이 거의 비었으면 Stop
    if (state.deckSize <= 2) return GoStopDecision.stop;

    // 이미 2번 Go 했으면 Stop 확률 높임
    if (goCount >= 2) {
      return _random.nextDouble() < 0.8
          ? GoStopDecision.stop
          : GoStopDecision.go;
    }

    // 점수가 낮으면 Go, 높으면 Stop
    if (score <= 5) {
      return _random.nextDouble() < 0.6
          ? GoStopDecision.go
          : GoStopDecision.stop;
    }

    return GoStopDecision.stop;
  }

  int _quickScore(List<HwatooCard> captured) {
    var score = 0;
    final brights = captured.where((c) => c.type == CardType.bright).length;
    final animals = captured.where((c) => c.type == CardType.animal).length;
    final ribbons = captured.where((c) => c.type == CardType.ribbon).length;
    if (brights >= 3) score += brights;
    if (animals >= 5) score += animals - 4;
    if (ribbons >= 5) score += ribbons - 4;
    return score;
  }
}

/// AI 난이도 레벨
enum AiDifficulty { easy, normal, hard }

/// 전략 기반 AI (Phase 2)
///
/// 전략:
/// - 광 우선 수집 (삼광/사광 추적)
/// - 띠 조합 인식 (홍단/청단/초단 추적)
/// - 고도리 기회 감지
/// - 정확한 피 카운팅
/// - 남은 덱/상대 점수 기반 고/스톱 판단
class HeuristicAgent extends Agent {
  final AiDifficulty difficulty;
  final Random _random;

  HeuristicAgent({
    this.difficulty = AiDifficulty.normal,
    Random? random,
  }) : _random = random ?? Random();

  @override
  PlayAction chooseCard(GameState state) {
    final hand = state.playerHands[state.currentPlayer];
    final table = state.tableCards;
    final captured = state.capturedCards[state.currentPlayer];

    // 매칭 가능한 플레이 목록과 점수 매기기
    final scored = <({PlayAction action, double score})>[];

    for (final card in hand) {
      final matches = table.findMatches(card);
      if (matches.isEmpty) {
        // 매칭 없음 — 가치 낮은 카드를 버리는 게 유리
        scored.add((
          action: PlayAction(card: card),
          score: _dumpScore(card, captured),
        ));
      } else if (matches.length == 1) {
        scored.add((
          action: PlayAction(card: card, chosenMatch: matches.first),
          score: _captureScore(card, matches.first, captured),
        ));
      } else if (matches.length == 2) {
        // 두 후보 중 가치 높은 카드 선택
        final best = _pickBestCapture(card, matches, captured);
        scored.add((
          action: PlayAction(card: card, chosenMatch: best),
          score: _captureScore(card, best, captured),
        ));
      } else {
        // 트리플매치: 전부 획득 — 높은 점수
        scored.add((
          action: PlayAction(card: card, chosenMatch: matches.first),
          score: _captureScore(card, matches.first, captured) + 10,
        ));
      }
    }

    scored.sort((a, b) => b.score.compareTo(a.score));

    // 난이도에 따라 최선/차선 선택 확률 조정
    switch (difficulty) {
      case AiDifficulty.easy:
        // 50% 최선, 50% 랜덤
        if (scored.length > 1 && _random.nextDouble() < 0.5) {
          return scored[_random.nextInt(scored.length)].action;
        }
      case AiDifficulty.normal:
        // 80% 최선, 20% 차선
        if (scored.length > 1 && _random.nextDouble() < 0.2) {
          return scored[min(1, scored.length - 1)].action;
        }
      case AiDifficulty.hard:
        break; // 항상 최선
    }

    return scored.first.action;
  }

  @override
  HwatooCard? chooseCapture(GameState state) {
    if (state.drawnCard == null) return null;
    final matches = state.tableCards.findMatches(state.drawnCard!);
    if (matches.length <= 1) return matches.isEmpty ? null : matches.first;
    final captured = state.capturedCards[state.currentPlayer];
    return _pickBestCapture(state.drawnCard!, matches, captured);
  }

  @override
  GoStopDecision chooseGoStop(GameState state) {
    final me = state.currentPlayer;
    final captured = state.capturedCards[me];
    final myScore = Scoring.totalScore(captured);
    final goCount = state.goCount[me];
    final deckRemain = state.deckSize;

    // 상대 점수 추정
    final opponentIdx = me == 0 ? 1 : 0;
    final opponentScore = Scoring.totalScore(state.capturedCards[opponentIdx]);

    // 덱이 거의 비었으면 Stop
    if (deckRemain <= 2) return GoStopDecision.stop;

    // 난이도별 고/스톱 공격성
    final goAggressiveness = switch (difficulty) {
      AiDifficulty.easy => 0.3,
      AiDifficulty.normal => 0.5,
      AiDifficulty.hard => 0.7,
    };

    // 상대 점수가 높으면 Stop (역전 위험)
    if (opponentScore >= state.config.scoreThreshold - 2) {
      return GoStopDecision.stop;
    }

    // Go 보너스 한도 체크: 3번 이상이면 거의 Stop
    if (goCount >= 3) return GoStopDecision.stop;

    // 고도리/띠 세트 근접 시 Go
    if (_hasNearbyBonus(captured) && goCount < 2) {
      if (_random.nextDouble() < goAggressiveness + 0.2) {
        return GoStopDecision.go;
      }
    }

    // 점수가 임계값 근처이면 Stop, 여유 있으면 Go
    if (myScore <= state.config.scoreThreshold + 1 && goCount < 2) {
      if (_random.nextDouble() < goAggressiveness) {
        return GoStopDecision.go;
      }
    }

    return GoStopDecision.stop;
  }

  // --- 내부 점수 평가 메서드 ---

  /// 카드 획득 시 전략적 가치 평가
  double _captureScore(
    HwatooCard playedCard,
    HwatooCard tableCard,
    List<HwatooCard> captured,
  ) {
    var score = 0.0;

    for (final card in [playedCard, tableCard]) {
      score += _cardValue(card, captured);
    }

    return score;
  }

  /// 개별 카드의 전략적 가치
  double _cardValue(HwatooCard card, List<HwatooCard> captured) {
    switch (card.type) {
      case CardType.bright:
        // 광은 항상 고가치
        final brightCount = captured.where((c) => c.type == CardType.bright).length;
        if (brightCount >= 2) return 15.0; // 삼광 달성 가능
        return 8.0;

      case CardType.animal:
        var value = 2.0;
        // 고도리 새 체크
        if (_isGodoriBird(card)) {
          final godoriBirds = captured.where((c) => _isGodoriBird(c)).length;
          if (godoriBirds >= 1) value += 5.0; // 고도리 근접
          if (godoriBirds >= 2) value += 10.0; // 고도리 달성!
        }
        // 동물 개수 보너스
        final animalCount = captured.where((c) => c.type == CardType.animal).length;
        if (animalCount >= 4) value += 2.0;
        return value;

      case CardType.ribbon:
        var value = 1.5;
        // 홍단/청단/초단 세트 추적
        value += _ribbonSetBonus(card, captured);
        // 띠 총 개수
        final ribbonCount = captured.where((c) => c.type == CardType.ribbon).length;
        if (ribbonCount >= 4) value += 1.5;
        return value;

      case CardType.junk:
        // 피 카운팅
        final junkTotal = _totalJunkValue(captured);
        if (junkTotal >= 8) return 3.0; // 피 점수 근접
        return 1.0;

      case CardType.doubleJunk:
        final junkTotal = _totalJunkValue(captured);
        if (junkTotal >= 7) return 5.0; // 쌍피로 점수 도달 가능
        return 2.0;
    }
  }

  /// 카드를 버릴 때 점수 (낮을수록 좋은 버림 — 음수가 좋음)
  double _dumpScore(HwatooCard card, List<HwatooCard> captured) {
    // 매칭 없는 카드는 테이블에 놓아야 함 → 가치 낮은 카드가 유리
    return -_cardValue(card, captured);
  }

  /// 2장 매칭 중 가치 높은 카드 선택
  HwatooCard _pickBestCapture(
    HwatooCard playedCard,
    List<HwatooCard> candidates,
    List<HwatooCard> captured,
  ) {
    HwatooCard best = candidates.first;
    double bestVal = _cardValue(candidates.first, captured);
    for (var i = 1; i < candidates.length; i++) {
      final val = _cardValue(candidates[i], captured);
      if (val > bestVal) {
        bestVal = val;
        best = candidates[i];
      }
    }
    return best;
  }

  /// 고도리 새인지 확인
  bool _isGodoriBird(HwatooCard card) {
    return card == Cards.bushWarbler ||
        card == Cards.cuckoo ||
        card == Cards.geese;
  }

  /// 띠 세트 보너스 점수
  double _ribbonSetBonus(HwatooCard card, List<HwatooCard> captured) {
    final ribbons = captured.where((c) => c.type == CardType.ribbon).toList();

    // 홍단: 1,2,3월
    const hongdan = [Cards.pineRedPoem, Cards.plumRedPoem, Cards.cherryRedPoem];
    // 청단: 6,9,10월
    const cheongdan = [Cards.peonyBluePoem, Cards.chrysanthemumBluePoem, Cards.mapleBluePoem];
    // 초단: 4,5,7월
    const chodan = [Cards.wisteriaRed, Cards.irisRed, Cards.bushCloverRed];

    double bonus = 0.0;
    for (final set in [hongdan, cheongdan, chodan]) {
      if (!set.contains(card)) continue;
      final owned = set.where((c) => ribbons.contains(c)).length;
      if (owned >= 1) bonus += 2.0; // 세트 2/3
      if (owned >= 2) bonus += 5.0; // 세트 완성!
    }
    return bonus;
  }

  /// 현재 피 총량 (junk + doubleJunk*2)
  int _totalJunkValue(List<HwatooCard> captured) {
    final junk = captured.where((c) => c.type == CardType.junk).length;
    final doubleJunk = captured.where((c) => c.type == CardType.doubleJunk).length;
    return junk + doubleJunk * 2;
  }

  /// 고도리/띠세트 보너스에 근접한지
  bool _hasNearbyBonus(List<HwatooCard> captured) {
    // 고도리 2/3
    final godoriCount = captured.where((c) => _isGodoriBird(c)).length;
    if (godoriCount >= 2) return true;

    // 띠 세트 2/3
    final ribbons = captured.where((c) => c.type == CardType.ribbon).toList();
    const sets = [
      [Cards.pineRedPoem, Cards.plumRedPoem, Cards.cherryRedPoem],
      [Cards.peonyBluePoem, Cards.chrysanthemumBluePoem, Cards.mapleBluePoem],
      [Cards.wisteriaRed, Cards.irisRed, Cards.bushCloverRed],
    ];
    for (final set in sets) {
      final owned = set.where((c) => ribbons.contains(c)).length;
      if (owned >= 2) return true;
    }

    return false;
  }
}
