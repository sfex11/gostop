import 'package:test/test.dart';
import 'package:engine/engine.dart';

void main() {
  group('Scoring - Brights (광)', () {
    test('5 brights = 15 points', () {
      final cards = [Cards.crane, Cards.curtain, Cards.moon, Cards.phoenix, Cards.rain];
      final result = Scoring.calculateBrights(cards);
      expect(result, equals(const ScoringResult('오광', 15)));
    });

    test('4 brights = 4 points', () {
      final cards = [Cards.crane, Cards.curtain, Cards.moon, Cards.phoenix];
      final result = Scoring.calculateBrights(cards);
      expect(result, equals(const ScoringResult('사광', 4)));
    });

    test('3 brights without rain = 3 points', () {
      final cards = [Cards.crane, Cards.curtain, Cards.moon];
      final result = Scoring.calculateBrights(cards);
      expect(result, equals(const ScoringResult('삼광', 3)));
    });

    test('3 brights with rain = 2 points', () {
      final cards = [Cards.crane, Cards.curtain, Cards.rain];
      final result = Scoring.calculateBrights(cards);
      expect(result, equals(const ScoringResult('비삼광', 2)));
    });

    test('2 brights = no score', () {
      final cards = [Cards.crane, Cards.curtain];
      final result = Scoring.calculateBrights(cards);
      expect(result, isNull);
    });

    test('4 brights with rain still counts as 4 brights', () {
      final cards = [Cards.crane, Cards.curtain, Cards.moon, Cards.rain];
      final result = Scoring.calculateBrights(cards);
      expect(result, equals(const ScoringResult('사광', 4)));
    });
  });

  group('Scoring - Animals (동물/십)', () {
    test('5 animals = 1 point', () {
      final cards = [
        Cards.bushWarbler, Cards.cuckoo, Cards.bridge,
        Cards.butterfly, Cards.boar,
      ];
      final result = Scoring.calculateAnimals(cards);
      expect(result!.points, 1);
    });

    test('7 animals = 3 points', () {
      final cards = [
        Cards.bushWarbler, Cards.cuckoo, Cards.bridge,
        Cards.butterfly, Cards.boar, Cards.geese, Cards.deer,
      ];
      final result = Scoring.calculateAnimals(cards);
      expect(result!.points, 3);
    });

    test('4 animals = no score', () {
      final cards = [
        Cards.bushWarbler, Cards.cuckoo, Cards.bridge, Cards.butterfly,
      ];
      final result = Scoring.calculateAnimals(cards);
      expect(result, isNull);
    });
  });

  group('Scoring - Godori (고도리)', () {
    test('bush warbler + cuckoo + geese = 5 points', () {
      final cards = [Cards.bushWarbler, Cards.cuckoo, Cards.geese];
      final result = Scoring.calculateGodori(cards);
      expect(result, equals(const ScoringResult('고도리', 5)));
    });

    test('missing one bird = no godori', () {
      final cards = [Cards.bushWarbler, Cards.cuckoo];
      final result = Scoring.calculateGodori(cards);
      expect(result, isNull);
    });
  });

  group('Scoring - Ribbons (띠/오)', () {
    test('5 ribbons = 1 point', () {
      final cards = [
        Cards.pineRedPoem, Cards.plumRedPoem, Cards.cherryRedPoem,
        Cards.wisteriaRed, Cards.irisRed,
      ];
      final result = Scoring.calculateRibbons(cards);
      expect(result!.points, 1);
    });

    test('7 ribbons = 3 points', () {
      final cards = [
        Cards.pineRedPoem, Cards.plumRedPoem, Cards.cherryRedPoem,
        Cards.wisteriaRed, Cards.irisRed, Cards.bushCloverRed,
        Cards.peonyBluePoem,
      ];
      final result = Scoring.calculateRibbons(cards);
      expect(result!.points, 3);
    });

    test('4 ribbons = no score', () {
      final cards = [
        Cards.pineRedPoem, Cards.plumRedPoem, Cards.cherryRedPoem,
        Cards.wisteriaRed,
      ];
      final result = Scoring.calculateRibbons(cards);
      expect(result, isNull);
    });
  });

  group('Scoring - Red Poem Ribbons (홍단)', () {
    test('3 red poem ribbons = 3 points', () {
      final cards = [Cards.pineRedPoem, Cards.plumRedPoem, Cards.cherryRedPoem];
      final result = Scoring.calculateRedPoem(cards);
      expect(result, equals(const ScoringResult('홍단', 3)));
    });

    test('missing one = no score', () {
      final cards = [Cards.pineRedPoem, Cards.plumRedPoem];
      final result = Scoring.calculateRedPoem(cards);
      expect(result, isNull);
    });
  });

  group('Scoring - Blue Poem Ribbons (청단)', () {
    test('3 blue poem ribbons = 3 points', () {
      final cards = [
        Cards.peonyBluePoem, Cards.chrysanthemumBluePoem, Cards.mapleBluePoem,
      ];
      final result = Scoring.calculateBluePoem(cards);
      expect(result, equals(const ScoringResult('청단', 3)));
    });

    test('missing one = no score', () {
      final cards = [Cards.peonyBluePoem, Cards.chrysanthemumBluePoem];
      final result = Scoring.calculateBluePoem(cards);
      expect(result, isNull);
    });
  });

  group('Scoring - Plain Red Ribbons (초단)', () {
    test('3 plain red ribbons = 3 points', () {
      final cards = [Cards.wisteriaRed, Cards.irisRed, Cards.bushCloverRed];
      final result = Scoring.calculatePlainRed(cards);
      expect(result, equals(const ScoringResult('초단', 3)));
    });

    test('missing one = no score', () {
      final cards = [Cards.wisteriaRed, Cards.irisRed];
      final result = Scoring.calculatePlainRed(cards);
      expect(result, isNull);
    });
  });

  group('Scoring - Junk (피)', () {
    test('10 junk = 1 point', () {
      final cards = <HwatooCard>[
        ...Cards.all.where((c) => c.type == CardType.junk).take(10),
      ];
      final result = Scoring.calculateJunk(cards);
      expect(result!.points, 1);
    });

    test('12 junk = 3 points', () {
      final cards = <HwatooCard>[
        ...Cards.all.where((c) => c.type == CardType.junk).take(12),
      ];
      final result = Scoring.calculateJunk(cards);
      expect(result!.points, 3);
    });

    test('9 junk = no score', () {
      final cards = <HwatooCard>[
        ...Cards.all.where((c) => c.type == CardType.junk).take(9),
      ];
      final result = Scoring.calculateJunk(cards);
      expect(result, isNull);
    });

    test('doubleJunk counts as 2', () {
      // 8 regular junk + 1 doubleJunk(paulownia2) = 10 junk points
      final cards = <HwatooCard>[
        ...Cards.all.where((c) => c.type == CardType.junk).take(8),
        Cards.paulownia2,
      ];
      final result = Scoring.calculateJunk(cards);
      expect(result!.points, 1);
    });

    test('both doubleJunk cards count double', () {
      // 8 regular junk + 2 doubleJunk (4) = 12 junk points = 3 points
      final cards = <HwatooCard>[
        ...Cards.all.where((c) => c.type == CardType.junk).take(8),
        Cards.paulownia2, Cards.willow2,
      ];
      final result = Scoring.calculateJunk(cards);
      expect(result!.points, 3);
    });

    test('cup converts to doubleJunk when junk >= 10', () {
      // 9 regular junk + cup (as animal, but converts to 2 junk) = 11 junk
      final cards = <HwatooCard>[
        ...Cards.all.where((c) => c.type == CardType.junk).take(9),
        Cards.cup,
      ];
      final result = Scoring.calculateJunk(cards);
      // 9 junk alone < 10, but with cup conversion: 9 + 2 = 11 -> 2 points
      expect(result!.points, 2);
    });
  });

  group('Scoring - Total score', () {
    test('5 brights gives 15 points total', () {
      final cards = [Cards.crane, Cards.curtain, Cards.moon, Cards.phoenix, Cards.rain];
      final total = Scoring.totalScore(cards);
      expect(total, 15);
    });

    test('godori birds + other animals combined', () {
      // 3 godori birds (5 pts godori + 0 animal count) + 2 more animals (= 5 animals = 1pt)
      final cards = [
        Cards.bushWarbler, Cards.cuckoo, Cards.geese,
        Cards.bridge, Cards.butterfly,
      ];
      final total = Scoring.totalScore(cards);
      expect(total, 6); // godori 5 + animals(5-4)=1
    });

    test('hongdan + chodan + cheongdan combined', () {
      final cards = [
        Cards.pineRedPoem, Cards.plumRedPoem, Cards.cherryRedPoem, // 홍단 3
        Cards.wisteriaRed, Cards.irisRed, Cards.bushCloverRed,     // 초단 3
        Cards.peonyBluePoem, Cards.chrysanthemumBluePoem, Cards.mapleBluePoem, // 청단 3
        // 9 ribbons total = ribbon(9-4)=5
        Cards.willowRed, // 10th ribbon = ribbon(10-4)=6
      ];
      final total = Scoring.totalScore(cards);
      // ribbons: 10-4=6, hongdan:3, chodan:3, cheongdan:3 = 15
      expect(total, 15);
    });

    test('empty cards = 0 points', () {
      final total = Scoring.totalScore([]);
      expect(total, 0);
    });
  });
}
