import 'package:test/test.dart';
import 'package:engine/engine.dart';

void main() {
  group('Multiplier', () {
    test('no multipliers = 1x', () {
      final result = Multiplier.calculate(
        winnerCaptured: [Cards.crane, Cards.curtain, Cards.moon],
        loserCaptured: [Cards.rain, Cards.pine1, Cards.plum1, Cards.cherry1,
          Cards.wisteria1, Cards.iris1, Cards.peony1], // 1 bright + 6 junk
        winnerGoCount: 0,
        loserGoCount: 0,
        winnerHadSwing: false,
      );
      expect(result.multiplier, 1);
      expect(result.reasons, isEmpty);
    });

    test('pi-bak: loser has 0 junk = 2x', () {
      final result = Multiplier.calculate(
        winnerCaptured: [Cards.crane, Cards.curtain, Cards.moon],
        loserCaptured: [], // no junk at all
        winnerGoCount: 0,
        loserGoCount: 0,
        winnerHadSwing: false,
      );
      expect(result.reasons, contains(MultiplierType.piBak));
    });

    test('pi-bak: loser has 5 junk or fewer = 2x', () {
      final result = Multiplier.calculate(
        winnerCaptured: [Cards.crane, Cards.curtain, Cards.moon],
        loserCaptured: [Cards.pine1, Cards.plum1, Cards.cherry1,
          Cards.wisteria1, Cards.iris1], // 5 junk
        winnerGoCount: 0,
        loserGoCount: 0,
        winnerHadSwing: false,
      );
      expect(result.reasons, contains(MultiplierType.piBak));
    });

    test('pi-bak: loser has 6 junk = no pi-bak', () {
      final result = Multiplier.calculate(
        winnerCaptured: [Cards.crane, Cards.curtain, Cards.moon],
        loserCaptured: [Cards.pine1, Cards.plum1, Cards.cherry1,
          Cards.wisteria1, Cards.iris1, Cards.peony1], // 6 junk
        winnerGoCount: 0,
        loserGoCount: 0,
        winnerHadSwing: false,
      );
      expect(result.reasons, isNot(contains(MultiplierType.piBak)));
    });

    test('gwang-bak: loser has 0 brights = 2x', () {
      final result = Multiplier.calculate(
        winnerCaptured: [Cards.crane, Cards.curtain, Cards.moon],
        loserCaptured: [Cards.pine1, Cards.plum1, Cards.cherry1,
          Cards.wisteria1, Cards.iris1, Cards.peony1],
        winnerGoCount: 0,
        loserGoCount: 0,
        winnerHadSwing: false,
      );
      expect(result.reasons, contains(MultiplierType.gwangBak));
    });

    test('gwang-bak: loser has 1 bright = no gwang-bak', () {
      final result = Multiplier.calculate(
        winnerCaptured: [Cards.crane, Cards.curtain, Cards.moon],
        loserCaptured: [Cards.rain, Cards.pine1, Cards.plum1,
          Cards.cherry1, Cards.wisteria1, Cards.iris1, Cards.peony1],
        winnerGoCount: 0,
        loserGoCount: 0,
        winnerHadSwing: false,
      );
      expect(result.reasons, isNot(contains(MultiplierType.gwangBak)));
    });

    test('go-bak: loser called Go at least once = 2x', () {
      final result = Multiplier.calculate(
        winnerCaptured: [Cards.crane, Cards.curtain, Cards.moon],
        loserCaptured: [Cards.pine1, Cards.plum1, Cards.cherry1,
          Cards.wisteria1, Cards.iris1, Cards.peony1],
        winnerGoCount: 0,
        loserGoCount: 1,
        winnerHadSwing: false,
      );
      expect(result.reasons, contains(MultiplierType.goBak));
    });

    test('go-bak: loser never called Go = no go-bak', () {
      final result = Multiplier.calculate(
        winnerCaptured: [Cards.crane, Cards.curtain, Cards.moon],
        loserCaptured: [Cards.pine1, Cards.plum1, Cards.cherry1,
          Cards.wisteria1, Cards.iris1, Cards.peony1],
        winnerGoCount: 0,
        loserGoCount: 0,
        winnerHadSwing: false,
      );
      expect(result.reasons, isNot(contains(MultiplierType.goBak)));
    });

    test('swing: winner had swing = 2x', () {
      final result = Multiplier.calculate(
        winnerCaptured: [Cards.crane, Cards.curtain, Cards.moon],
        loserCaptured: [Cards.pine1, Cards.plum1, Cards.cherry1,
          Cards.wisteria1, Cards.iris1, Cards.peony1],
        winnerGoCount: 0,
        loserGoCount: 0,
        winnerHadSwing: true,
      );
      expect(result.reasons, contains(MultiplierType.swing));
    });

    test('mung-tung: winner has 7+ animals = 2x', () {
      final result = Multiplier.calculate(
        winnerCaptured: [
          Cards.bushWarbler, Cards.cuckoo, Cards.bridge, Cards.butterfly,
          Cards.boar, Cards.geese, Cards.deer,
        ],
        loserCaptured: [Cards.pine1, Cards.plum1, Cards.cherry1,
          Cards.wisteria1, Cards.iris1, Cards.peony1],
        winnerGoCount: 0,
        loserGoCount: 0,
        winnerHadSwing: false,
      );
      expect(result.reasons, contains(MultiplierType.mungTung));
    });

    test('multiple multipliers stack', () {
      // pi-bak (loser 0 junk) + gwang-bak (loser 0 bright) + go-bak
      final result = Multiplier.calculate(
        winnerCaptured: [Cards.crane, Cards.curtain, Cards.moon],
        loserCaptured: [], // no cards at all
        winnerGoCount: 0,
        loserGoCount: 1,
        winnerHadSwing: false,
      );
      // piBak + gwangBak + goBak = 3 multipliers = 2^3 = 8x
      expect(result.multiplier, 8);
    });

    test('go bonus: go count adds to score', () {
      expect(Multiplier.goBonus(0), 0);
      expect(Multiplier.goBonus(1), 1);
      expect(Multiplier.goBonus(2), 2);
      expect(Multiplier.goBonus(3), 3);
    });
  });
}
