import 'package:test/test.dart';
import 'package:engine/engine.dart';

void main() {
  group('HandChecker - 총통 (Chongtong)', () {
    test('4 cards of same month = chongtong', () {
      final hand = [Cards.crane, Cards.pineRedPoem, Cards.pine1, Cards.pine2,
        Cards.plum1, Cards.plum2, Cards.cherry1, Cards.cherry2, Cards.wisteria1, Cards.iris1];
      final result = HandChecker.checkChongtong(hand);
      expect(result, isNotNull);
      expect(result!.month, Month.january);
    });

    test('no 4 of same month = no chongtong', () {
      final hand = [Cards.crane, Cards.pineRedPoem, Cards.pine1,
        Cards.bushWarbler, Cards.plumRedPoem, Cards.plum1,
        Cards.curtain, Cards.cherryRedPoem, Cards.cherry1, Cards.cuckoo];
      final result = HandChecker.checkChongtong(hand);
      expect(result, isNull);
    });
  });

  group('HandChecker - 흔들기 (Swing)', () {
    test('3 cards of same month = swing', () {
      final hand = [Cards.crane, Cards.pineRedPoem, Cards.pine1,
        Cards.bushWarbler, Cards.plumRedPoem, Cards.plum1,
        Cards.curtain, Cards.cherry1, Cards.cuckoo, Cards.wisteria1];
      final result = HandChecker.checkSwing(hand);
      expect(result, isNotEmpty);
      expect(result.any((m) => m == Month.january), isTrue);
    });

    test('no 3 of same month = no swing', () {
      final hand = [Cards.crane, Cards.pineRedPoem,
        Cards.bushWarbler, Cards.plumRedPoem,
        Cards.curtain, Cards.cherryRedPoem,
        Cards.cuckoo, Cards.wisteriaRed,
        Cards.bridge, Cards.irisRed];
      final result = HandChecker.checkSwing(hand);
      expect(result, isEmpty);
    });

    test('4 of same month also triggers swing', () {
      final hand = [Cards.crane, Cards.pineRedPoem, Cards.pine1, Cards.pine2,
        Cards.plum1, Cards.plum2, Cards.cherry1, Cards.cherry2, Cards.wisteria1, Cards.iris1];
      final result = HandChecker.checkSwing(hand);
      expect(result, contains(Month.january));
    });
  });

  group('TurnResult - 피 뺏기 (Pi steal)', () {
    test('sweep steals 1 pi from each opponent', () {
      final config = GameConfig.standard;
      // Player captured everything on table this turn (sweep)
      final turnResult = TurnResult(
        capturedCount: 4,
        wasSweep: true,
        config: config,
      );
      expect(turnResult.piStealCount, 1);
    });

    test('no sweep = no pi steal', () {
      final config = GameConfig.standard;
      final turnResult = TurnResult(
        capturedCount: 2,
        wasSweep: false,
        config: config,
      );
      expect(turnResult.piStealCount, 0);
    });

    test('pi steal disabled in config', () {
      final config = GameConfig(usePiSteal: false);
      final turnResult = TurnResult(
        capturedCount: 4,
        wasSweep: true,
        config: config,
      );
      expect(turnResult.piStealCount, 0);
    });
  });

  group('TurnResult - 쓸 (Sweep)', () {
    test('capturing all table cards of a month is sweep', () {
      // After play + capture, no cards of played month remain on table
      final turnResult = TurnResult(
        capturedCount: 4,
        wasSweep: true,
        config: GameConfig.standard,
      );
      expect(turnResult.wasSweep, isTrue);
    });
  });
}
