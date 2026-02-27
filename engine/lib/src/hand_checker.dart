import 'card.dart';

/// 총통 결과
class ChongtongResult {
  final Month month;
  const ChongtongResult(this.month);
}

/// 손패 검사 (배분 직후 특수 규칙)
abstract final class HandChecker {
  /// 총통 검사: 같은 월 4장이 있으면 해당 월 반환
  static ChongtongResult? checkChongtong(List<HwatooCard> hand) {
    final monthCount = <Month, int>{};
    for (final card in hand) {
      monthCount[card.month] = (monthCount[card.month] ?? 0) + 1;
    }
    for (final entry in monthCount.entries) {
      if (entry.value >= 4) {
        return ChongtongResult(entry.key);
      }
    }
    return null;
  }

  /// 흔들기 검사: 같은 월 3장 이상인 월 목록 반환
  static List<Month> checkSwing(List<HwatooCard> hand) {
    final monthCount = <Month, int>{};
    for (final card in hand) {
      monthCount[card.month] = (monthCount[card.month] ?? 0) + 1;
    }
    return monthCount.entries
        .where((e) => e.value >= 3)
        .map((e) => e.key)
        .toList();
  }
}
