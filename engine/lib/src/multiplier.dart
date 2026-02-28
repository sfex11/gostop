import 'card.dart';
import 'game_config.dart';

/// 배수 종류
enum MultiplierType {
  /// 피박: 진 쪽 피 ≤ 5장
  piBak,

  /// 광박: 진 쪽 광 0장
  gwangBak,

  /// 고박: 진 쪽이 '고' 선언한 적 있음
  goBak,

  /// 흔들기: 이긴 쪽 손패에 같은 월 3장
  swing,

  /// 멍따: 이긴 쪽 동물 ≥ 7장
  mungTung,
}

/// 배수 계산 결과
class MultiplierResult {
  final List<MultiplierType> reasons;

  /// 총 배수 (각 2배씩 중첩)
  int get multiplier => reasons.isEmpty ? 1 : 1 << reasons.length;

  const MultiplierResult(this.reasons);
}

/// 배수 계산 엔진
abstract final class Multiplier {
  /// 배수 계산
  static MultiplierResult calculate({
    required List<HwatooCard> winnerCaptured,
    required List<HwatooCard> loserCaptured,
    required int winnerGoCount,
    required int loserGoCount,
    required bool winnerHadSwing,
    GameConfig? config,
  }) {
    final reasons = <MultiplierType>[];
    final cfg = config ?? GameConfig.standard;

    // 피박: 진 쪽 피 ≤ 5장 (junk + doubleJunk*2)
    if (cfg.usePiBak) {
      final loserJunk = loserCaptured.where((c) => c.type == CardType.junk).length;
      final loserDoubleJunk =
          loserCaptured.where((c) => c.type == CardType.doubleJunk).length;
      final loserTotalJunk = loserJunk + loserDoubleJunk * 2;
      if (loserTotalJunk <= 5) {
        reasons.add(MultiplierType.piBak);
      }
    }

    // 광박: 진 쪽 광 0장
    if (cfg.useGwangBak) {
      final loserBrights =
          loserCaptured.where((c) => c.type == CardType.bright).length;
      if (loserBrights == 0) {
        reasons.add(MultiplierType.gwangBak);
      }
    }

    // 고박: 진 쪽이 고 선언한 적 있음
    if (cfg.useGoBak && loserGoCount > 0) {
      reasons.add(MultiplierType.goBak);
    }

    // 흔들기
    if (cfg.useSwing && winnerHadSwing) {
      reasons.add(MultiplierType.swing);
    }

    // 멍따: 이긴 쪽 동물 ≥ 7장
    if (cfg.useMungTung) {
      final winnerAnimals =
          winnerCaptured.where((c) => c.type == CardType.animal).length;
      if (winnerAnimals >= 7) {
        reasons.add(MultiplierType.mungTung);
      }
    }

    return MultiplierResult(reasons);
  }

  /// 고(Go) 보너스 점수
  static int goBonus(int goCount) => goCount;
}
