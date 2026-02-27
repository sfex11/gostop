import 'package:test/test.dart';
import 'package:engine/engine.dart';

void main() {
  group('GameConfig', () {
    test('standard config has default values', () {
      const config = GameConfig.standard;
      expect(config.scoreThreshold, 3);
      expect(config.useSsangpi, isTrue);
      expect(config.useBomb, isTrue);
      expect(config.useSwing, isTrue);
      expect(config.useChongtong, isTrue);
      expect(config.usePiSteal, isTrue);
      expect(config.useSweep, isTrue);
      expect(config.useGwangBak, isTrue);
      expect(config.usePiBak, isTrue);
      expect(config.useGoBak, isTrue);
      expect(config.useMungTung, isTrue);
      expect(config.useGodori, isTrue);
    });

    test('fast config disables some rules', () {
      const config = GameConfig.fast;
      expect(config.scoreThreshold, 7);
      expect(config.useSwing, isFalse);
      expect(config.useChongtong, isFalse);
      expect(config.useMungTung, isFalse);
      // Other rules still enabled
      expect(config.useBomb, isTrue);
      expect(config.usePiSteal, isTrue);
    });

    test('custom config', () {
      const config = GameConfig(
        scoreThreshold: 5,
        useGodori: false,
        useSweep: false,
      );
      expect(config.scoreThreshold, 5);
      expect(config.useGodori, isFalse);
      expect(config.useSweep, isFalse);
      expect(config.useBomb, isTrue); // default
    });
  });
}
