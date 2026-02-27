import 'dart:math';

import 'package:test/test.dart';
import 'package:engine/engine.dart';

void main() {
  group('GameState - Deal', () {
    test('2-player deal: 10 cards each, 8 on table, 20 in deck', () {
      final state = GameState.newGame(playerCount: 2, random: Random(42));
      expect(state.playerHands[0].length, 10);
      expect(state.playerHands[1].length, 10);
      expect(state.tableCards.cards.length, 8);
      expect(state.deckSize, 20); // 48 - (10×2 + 8) = 20
    });

    test('3-player deal: 7 cards each, 6 on table, 21 in deck', () {
      final state = GameState.newGame(playerCount: 3, random: Random(42));
      expect(state.playerHands[0].length, 7);
      expect(state.playerHands[1].length, 7);
      expect(state.playerHands[2].length, 7);
      expect(state.tableCards.cards.length, 6);
      expect(state.deckSize, 21);
    });

    test('total cards always 48', () {
      final state = GameState.newGame(playerCount: 2, random: Random(42));
      final total = state.playerHands[0].length +
          state.playerHands[1].length +
          state.tableCards.cards.length +
          state.deckSize;
      expect(total, 48);
    });

    test('starts as PlayPhase', () {
      final state = GameState.newGame(playerCount: 2, random: Random(42));
      expect(state.phase, GamePhase.play);
    });

    test('player 0 goes first', () {
      final state = GameState.newGame(playerCount: 2, random: Random(42));
      expect(state.currentPlayer, 0);
    });
  });

  group('GameState - Play Phase', () {
    test('playing card with no match puts it on table', () {
      final state = GameState.newGame(playerCount: 2, random: Random(42));
      final hand = state.playerHands[state.currentPlayer];

      // Find a card that doesn't match any table card
      HwatooCard? noMatchCard;
      for (final card in hand) {
        final matches = state.tableCards.findMatches(card);
        if (matches.isEmpty) {
          noMatchCard = card;
          break;
        }
      }

      if (noMatchCard != null) {
        final tableBefore = state.tableCards.cards.length;
        final handBefore = hand.length;
        final next = state.playCard(noMatchCard);
        expect(next.tableCards.cards.length, tableBefore + 1);
        expect(next.playerHands[state.currentPlayer].length, handBefore - 1);
        expect(next.phase, GamePhase.capture);
      }
    });

    test('playing card with single match moves to capture phase', () {
      final state = GameState.newGame(playerCount: 2, random: Random(42));
      final hand = state.playerHands[state.currentPlayer];

      HwatooCard? matchCard;
      for (final card in hand) {
        final matches = state.tableCards.findMatches(card);
        if (matches.length == 1) {
          matchCard = card;
          break;
        }
      }

      if (matchCard != null) {
        final next = state.playCard(matchCard);
        expect(next.phase, GamePhase.capture);
      }
    });
  });

  group('GameState - Capture Phase', () {
    test('after play, deck card is drawn for capture', () {
      final state = GameState.newGame(playerCount: 2, random: Random(42));
      final card = state.playerHands[state.currentPlayer].first;
      final deckBefore = state.deckSize;
      final next = state.playCard(card);
      expect(next.phase, GamePhase.capture);
      expect(next.deckSize, deckBefore - 1);
      expect(next.drawnCard, isNotNull);
    });
  });

  group('GameState - Go/Stop', () {
    test('stop ends the game with winner', () {
      // Create a GoStop state manually
      final state = GameState.newGame(playerCount: 2, random: Random(42));
      final goStopState = state.copyWith(
        phase: GamePhase.goStop,
      );
      final endState = goStopState.chooseStop();
      expect(endState.phase, GamePhase.end);
      expect(endState.winner, goStopState.currentPlayer);
    });

    test('go continues the game to next player', () {
      final state = GameState.newGame(playerCount: 2, random: Random(42));
      final goStopState = state.copyWith(
        phase: GamePhase.goStop,
      );
      final nextState = goStopState.chooseGo();
      expect(nextState.phase, GamePhase.play);
      expect(nextState.currentPlayer, 1);
      expect(nextState.goCount[0], 1);
    });
  });

  group('GameState - Turn flow', () {
    test('complete turn transitions: play -> capture -> next player', () {
      final state = GameState.newGame(playerCount: 2, random: Random(42));
      expect(state.phase, GamePhase.play);
      expect(state.currentPlayer, 0);

      // Play a card
      final card = state.playerHands[0].first;
      final afterPlay = state.playCard(card);
      expect(afterPlay.phase, GamePhase.capture);
      expect(afterPlay.currentPlayer, 0);

      // Resolve capture (no match on drawn card = card to table)
      final afterCapture = afterPlay.resolveCapture();
      // Should move to next player (or goStop if score threshold met)
      expect(
        afterCapture.phase == GamePhase.play ||
            afterCapture.phase == GamePhase.goStop,
        isTrue,
      );
      if (afterCapture.phase == GamePhase.play) {
        expect(afterCapture.currentPlayer, 1);
      }
    });
  });
}
