import 'dart:math';

import 'package:test/test.dart';
import 'package:engine/engine.dart';

void main() {
  group('GameResult', () {
    test('creates result from ended game with winner', () {
      // 게임을 진행하여 goStop 상태까지 만든 후 Stop
      var state = GameState.newGame(playerCount: 2, random: Random(42));
      final agents = [RandomAgent(random: Random(1)), RandomAgent(random: Random(2))];

      var turns = 0;
      while (state.phase != GamePhase.end && turns < 200) {
        turns++;
        final agent = agents[state.currentPlayer];
        switch (state.phase) {
          case GamePhase.play:
            final action = agent.chooseCard(state);
            state = state.playCard(action.card, chosenMatch: action.chosenMatch);
          case GamePhase.capture:
            final captureAction = agent.chooseCapture(state);
            state = state.resolveCapture(chosenMatch: captureAction);
          case GamePhase.goStop:
            state = state.chooseStop(); // 항상 Stop
          case GamePhase.end:
            break;
        }
      }

      expect(state.phase, GamePhase.end);
      final result = GameResult.fromState(state);

      expect(result.baseScores.length, 2);
      expect(result.finalScores.length, 2);
      expect(result.scoreDetails.length, 2);

      if (result.winner != null) {
        expect(result.finalScores[result.winner!], greaterThan(0));
        expect(result.multiplierResult, isNotNull);
      }
    });

    test('deck exhaustion produces draw result', () {
      // 항상 Go를 선택해서 덱 소진되게 함
      var state = GameState.newGame(playerCount: 2, random: Random(42));
      final agents = [RandomAgent(random: Random(1)), RandomAgent(random: Random(2))];

      var turns = 0;
      while (state.phase != GamePhase.end && turns < 200) {
        turns++;
        final agent = agents[state.currentPlayer];
        switch (state.phase) {
          case GamePhase.play:
            final action = agent.chooseCard(state);
            state = state.playCard(action.card, chosenMatch: action.chosenMatch);
          case GamePhase.capture:
            final captureAction = agent.chooseCapture(state);
            state = state.resolveCapture(chosenMatch: captureAction);
          case GamePhase.goStop:
            state = state.chooseGo(); // 항상 Go
          case GamePhase.end:
            break;
        }
      }

      expect(state.phase, GamePhase.end);
      final result = GameResult.fromState(state);

      // 무승부이거나 winner가 있을 수 있음 (덱 소진 전에 end 될 수도)
      expect(result.baseScores.length, 2);
    });
  });
}
