import 'package:test/test.dart';
import 'package:engine/engine.dart';

void main() {
  group('TableCards', () {
    test('findMatches returns cards of same month', () {
      final table = TableCards([
        Cards.pine1, Cards.plum1, Cards.cherry1, Cards.crane,
      ]);
      final matches = table.findMatches(Cards.pine2);
      expect(matches, containsAll([Cards.pine1, Cards.crane]));
      expect(matches.length, 2);
    });

    test('findMatches returns empty list when no match', () {
      final table = TableCards([Cards.pine1, Cards.plum1]);
      final matches = table.findMatches(Cards.cherry1);
      expect(matches, isEmpty);
    });

    test('findMatches with 1 match', () {
      final table = TableCards([Cards.pine1, Cards.plum1]);
      final matches = table.findMatches(Cards.pine2);
      expect(matches.length, 1);
      expect(matches.first, Cards.pine1);
    });

    test('findMatches with 3 matches (all remaining of month)', () {
      final table = TableCards([Cards.crane, Cards.pineRedPoem, Cards.pine1]);
      final matches = table.findMatches(Cards.pine2);
      expect(matches.length, 3);
    });

    test('add puts card on table', () {
      final table = TableCards([]);
      table.add(Cards.pine1);
      expect(table.cards.length, 1);
      expect(table.cards.first, Cards.pine1);
    });

    test('remove takes card from table', () {
      final table = TableCards([Cards.pine1, Cards.plum1]);
      table.remove(Cards.pine1);
      expect(table.cards.length, 1);
      expect(table.cards.first, Cards.plum1);
    });
  });

  group('MatchResult', () {
    test('no match: card goes to table', () {
      final table = TableCards([Cards.plum1, Cards.cherry1]);
      final result = MatchResult.from(Cards.pine1, table);
      expect(result.type, MatchType.noMatch);
      expect(result.candidates, isEmpty);
    });

    test('single match: auto-capture', () {
      final table = TableCards([Cards.pine1, Cards.plum1]);
      final result = MatchResult.from(Cards.pine2, table);
      expect(result.type, MatchType.singleMatch);
      expect(result.candidates.length, 1);
    });

    test('double match: player must choose', () {
      final table = TableCards([Cards.pine1, Cards.pineRedPoem, Cards.plum1]);
      final result = MatchResult.from(Cards.pine2, table);
      expect(result.type, MatchType.doubleMatch);
      expect(result.candidates.length, 2);
    });

    test('triple match: capture all (ppuk/bomb)', () {
      final table = TableCards([Cards.crane, Cards.pineRedPoem, Cards.pine1]);
      final result = MatchResult.from(Cards.pine2, table);
      expect(result.type, MatchType.tripleMatch);
      expect(result.candidates.length, 3);
    });
  });
}
