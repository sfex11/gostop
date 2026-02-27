import 'card.dart';
import 'game_config.dart';

/// 점수 계산 결과 1건
class ScoringResult {
  final String name;
  final int points;

  const ScoringResult(this.name, this.points);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScoringResult && name == other.name && points == other.points;

  @override
  int get hashCode => Object.hash(name, points);

  @override
  String toString() => 'ScoringResult($name, $points)';
}

/// 고스톱 점수 계산 엔진
abstract final class Scoring {
  /// 광 점수 계산
  static ScoringResult? calculateBrights(List<HwatooCard> cards) {
    final brights = cards.where((c) => c.type == CardType.bright).toList();
    final hasRain = brights.contains(Cards.rain);
    final count = brights.length;

    if (count == 5) return const ScoringResult('오광', 15);
    if (count == 4) return const ScoringResult('사광', 4);
    if (count == 3) {
      if (hasRain) return const ScoringResult('비삼광', 2);
      return const ScoringResult('삼광', 3);
    }
    return null;
  }

  /// 동물 장수 점수 계산 (5장 이상: 장수-4)
  static ScoringResult? calculateAnimals(List<HwatooCard> cards) {
    final count = cards.where((c) => c.type == CardType.animal).length;
    if (count >= 5) return ScoringResult('${count}동물', count - 4);
    return null;
  }

  /// 고도리 (꾀꼬리 + 두견새 + 기러기)
  static ScoringResult? calculateGodori(List<HwatooCard> cards) {
    final animals = cards.where((c) => c.type == CardType.animal).toList();
    final hasAll = animals.contains(Cards.bushWarbler) &&
        animals.contains(Cards.cuckoo) &&
        animals.contains(Cards.geese);
    if (hasAll) return const ScoringResult('고도리', 5);
    return null;
  }

  /// 띠 장수 점수 계산 (5장 이상: 장수-4)
  static ScoringResult? calculateRibbons(List<HwatooCard> cards) {
    final count = cards.where((c) => c.type == CardType.ribbon).length;
    if (count >= 5) return ScoringResult('${count}띠', count - 4);
    return null;
  }

  /// 홍단 (1,2,3월 빨간 시 글씨 띠)
  static ScoringResult? calculateRedPoem(List<HwatooCard> cards) {
    final ribbons = cards.where((c) => c.type == CardType.ribbon).toList();
    final hasAll = ribbons.contains(Cards.pineRedPoem) &&
        ribbons.contains(Cards.plumRedPoem) &&
        ribbons.contains(Cards.cherryRedPoem);
    if (hasAll) return const ScoringResult('홍단', 3);
    return null;
  }

  /// 청단 (6,9,10월 파란 시 글씨 띠)
  static ScoringResult? calculateBluePoem(List<HwatooCard> cards) {
    final ribbons = cards.where((c) => c.type == CardType.ribbon).toList();
    final hasAll = ribbons.contains(Cards.peonyBluePoem) &&
        ribbons.contains(Cards.chrysanthemumBluePoem) &&
        ribbons.contains(Cards.mapleBluePoem);
    if (hasAll) return const ScoringResult('청단', 3);
    return null;
  }

  /// 초단 (4,5,7월 빨간 무지 띠)
  static ScoringResult? calculatePlainRed(List<HwatooCard> cards) {
    final ribbons = cards.where((c) => c.type == CardType.ribbon).toList();
    final hasAll = ribbons.contains(Cards.wisteriaRed) &&
        ribbons.contains(Cards.irisRed) &&
        ribbons.contains(Cards.bushCloverRed);
    if (hasAll) return const ScoringResult('초단', 3);
    return null;
  }

  /// 피 점수 계산 (10피 이상: 피수-9, 쌍피는 2로 계산)
  /// 국진(CUP)은 동물이지만 피가 10장 이상이면 쌍피(2)로 전환
  static ScoringResult? calculateJunk(List<HwatooCard> cards) {
    final junkCount = cards.where((c) => c.type == CardType.junk).length;
    final doubleJunkCount = cards.where((c) => c.type == CardType.doubleJunk).length;
    final hasCup = cards.contains(Cards.cup);
    var totalJunk = junkCount + doubleJunkCount * 2;

    // 국진 전환: 피 + 국진(2) ≥ 10이면 쌍피로 전환
    if (hasCup && totalJunk + 2 >= 10) {
      totalJunk += 2; // CUP counts as 2 junk
    }

    if (totalJunk >= 10) {
      final cardCount = junkCount + doubleJunkCount + (hasCup && totalJunk >= 10 ? 1 : 0);
      return ScoringResult('${cardCount}피', totalJunk - 9);
    }
    return null;
  }

  /// 모든 족보를 계산하여 결과 목록 반환
  static List<ScoringResult> calculate(List<HwatooCard> cards, {GameConfig? config}) {
    final results = <ScoringResult>[];
    final cfg = config ?? GameConfig.standard;

    final bright = calculateBrights(cards);
    if (bright != null) results.add(bright);

    final animal = calculateAnimals(cards);
    if (animal != null) results.add(animal);

    if (cfg.useGodori) {
      final godori = calculateGodori(cards);
      if (godori != null) results.add(godori);
    }

    final ribbon = calculateRibbons(cards);
    if (ribbon != null) results.add(ribbon);

    final redPoem = calculateRedPoem(cards);
    if (redPoem != null) results.add(redPoem);

    final bluePoem = calculateBluePoem(cards);
    if (bluePoem != null) results.add(bluePoem);

    final plainRed = calculatePlainRed(cards);
    if (plainRed != null) results.add(plainRed);

    final junk = calculateJunk(cards);
    if (junk != null) results.add(junk);

    return results;
  }

  /// 총점 합산
  static int totalScore(List<HwatooCard> cards, {GameConfig? config}) {
    return calculate(cards, config: config).fold(0, (sum, r) => sum + r.points);
  }
}
