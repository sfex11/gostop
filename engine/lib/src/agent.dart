import 'dart:math';

import 'card.dart';
import 'game_state.dart';
import 'matching.dart';

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
