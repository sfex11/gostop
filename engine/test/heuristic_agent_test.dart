import 'dart:math';

import 'package:test/test.dart';
import 'package:engine/engine.dart';

void main() {
  group('HeuristicAgent', () {
    test('returns valid card from hand', () {
      final state = GameState.newGame(playerCount: 2, random: Random(42));
      final agent = HeuristicAgent(random: Random(99));
      final action = agent.chooseCard(state);
      expect(state.playerHands[state.currentPlayer], contains(action.card));
    });

    test('chosen match is valid when present', () {
      final state = GameState.newGame(playerCount: 2, random: Random(42));
      final agent = HeuristicAgent(random: Random(99));
      final action = agent.chooseCard(state);
      if (action.chosenMatch != null) {
        final matches = state.tableCards.findMatches(action.card);
        expect(matches, contains(action.chosenMatch));
      }
    });

    test('Go/Stop decision is valid', () {
      final state = GameState.newGame(playerCount: 2, random: Random(42))
          .copyWith(phase: GamePhase.goStop);
      final agent = HeuristicAgent(random: Random(99));
      final decision = agent.chooseGoStop(state);
      expect(
        decision == GoStopDecision.go || decision == GoStopDecision.stop,
        isTrue,
      );
    });

    for (final difficulty in AiDifficulty.values) {
      test('$difficulty difficulty completes full game (10 seeds)', () {
        for (var seed = 0; seed < 10; seed++) {
          var state = GameState.newGame(playerCount: 2, random: Random(seed));
          final agents = [
            HeuristicAgent(difficulty: difficulty, random: Random(seed + 100)),
            HeuristicAgent(difficulty: difficulty, random: Random(seed + 200)),
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

          expect(state.phase, GamePhase.end,
              reason: '$difficulty seed=$seed should end');
        }
      });
    }

    test('HeuristicAgent vs RandomAgent mixed games', () {
      for (var seed = 0; seed < 10; seed++) {
        var state = GameState.newGame(playerCount: 2, random: Random(seed));
        final agents = <Agent>[
          HeuristicAgent(difficulty: AiDifficulty.hard, random: Random(seed + 100)),
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

        expect(state.phase, GamePhase.end,
            reason: 'Mixed game seed=$seed should end');
      }
    });
  });
}
