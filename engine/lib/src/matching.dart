import 'card.dart';

/// 매칭 결과 유형
enum MatchType {
  /// 매칭 없음 — 카드를 테이블에 놓음
  noMatch,

  /// 1장 매칭 — 자동 획득
  singleMatch,

  /// 2장 매칭 — 플레이어가 선택
  doubleMatch,

  /// 3장 매칭 — 전부 획득 (뻑/폭탄)
  tripleMatch,
}

/// 테이블 위의 카드들
class TableCards {
  final List<HwatooCard> _cards;

  TableCards(List<HwatooCard> cards) : _cards = List<HwatooCard>.from(cards);

  /// 현재 테이블 카드 (읽기 전용)
  List<HwatooCard> get cards => List.unmodifiable(_cards);

  /// 같은 월의 카드를 찾아 반환
  List<HwatooCard> findMatches(HwatooCard card) {
    return _cards.where((c) => c.month == card.month).toList();
  }

  /// 카드 추가
  void add(HwatooCard card) {
    _cards.add(card);
  }

  /// 카드 제거
  void remove(HwatooCard card) {
    _cards.remove(card);
  }

  /// 깊은 복사
  TableCards copy() => TableCards(List<HwatooCard>.from(_cards));
}

/// 매칭 결과
class MatchResult {
  final MatchType type;
  final HwatooCard playedCard;
  final List<HwatooCard> candidates;

  const MatchResult({
    required this.type,
    required this.playedCard,
    required this.candidates,
  });

  /// 테이블과 카드를 비교하여 매칭 결과 생성
  factory MatchResult.from(HwatooCard card, TableCards table) {
    final matches = table.findMatches(card);
    final MatchType type;

    switch (matches.length) {
      case 0:
        type = MatchType.noMatch;
      case 1:
        type = MatchType.singleMatch;
      case 2:
        type = MatchType.doubleMatch;
      default:
        type = MatchType.tripleMatch;
    }

    return MatchResult(
      type: type,
      playedCard: card,
      candidates: matches,
    );
  }
}
