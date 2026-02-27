import 'dart:math';

import 'package:test/test.dart';
import 'package:engine/engine.dart';

void main() {
  group('Agent interface', () {
    test('RandomAgent returns a valid card from hand', () {
      final state = GameState.newGame(playerCount: 2, random: Random(42));
      final agent = RandomAgent(random: Random(99));
      final action = agent.chooseCard(state);
      expect(state.playerHands[state.currentPlayer], contains(action.card));
    });

    test('RandomAgent chooses match when available', () {
      final state = GameState.newGame(playerCount: 2, random: Random(42));
      final agent = RandomAgent(random: Random(99));
      final action = agent.chooseCard(state);
      // If the card has matches, chosenMatch should be one of them (or null if no match)
      if (action.chosenMatch != null) {
        final matches = state.tableCards.findMatches(action.card);
        expect(matches, contains(action.chosenMatch));
      }
    });

    test('RandomAgent chooses Go or Stop', () {
      final state = GameState.newGame(playerCount: 2, random: Random(42))
          .copyWith(phase: GamePhase.goStop);
      final agent = RandomAgent(random: Random(99));
      final decision = agent.chooseGoStop(state);
      expect(decision == GoStopDecision.go || decision == GoStopDecision.stop, isTrue);
    });
  });

  group('RandomAgent plays full game', () {
    test('two RandomAgents can complete a full game', () {
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
            final decision = agent.chooseGoStop(state);
            if (decision == GoStopDecision.go) {
              state = state.chooseGo();
            } else {
              state = state.chooseStop();
            }

          case GamePhase.end:
            break;
        }
      }

      expect(state.phase, GamePhase.end);
      // Game should end within reasonable turns
      expect(turns, lessThan(200));
    });

    test('multiple games with different seeds all complete', () {
      for (var seed = 0; seed < 10; seed++) {
        var state = GameState.newGame(playerCount: 2, random: Random(seed));
        final agents = [
          RandomAgent(random: Random(seed + 100)),
          RandomAgent(random: Random(seed + 200)),
        ];

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
              final decision = agent.chooseGoStop(state);
              state = decision == GoStopDecision.go
                  ? state.chooseGo()
                  : state.chooseStop();
            case GamePhase.end:
              break;
          }
        }

        expect(state.phase, GamePhase.end, reason: 'Game seed=$seed should end');
      }
    });
  });
}
