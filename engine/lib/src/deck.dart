import 'dart:math';

import 'card.dart';

/// 화투 48장 덱
class Deck {
  final List<HwatooCard> _cards;
  final Random _random;

  Deck({Random? random})
      : _cards = List<HwatooCard>.from(Cards.all),
        _random = random ?? Random();

  /// 현재 남은 카드 목록 (읽기 전용)
  List<HwatooCard> get cards => List.unmodifiable(_cards);

  /// 남은 카드 수
  int get length => _cards.length;

  /// 덱이 비었는지
  bool get isEmpty => _cards.isEmpty;

  /// Fisher-Yates 셔플
  void shuffle() {
    for (var i = _cards.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final temp = _cards[i];
      _cards[i] = _cards[j];
      _cards[j] = temp;
    }
  }

  /// 맨 위 카드 1장 뽑기
  HwatooCard draw() {
    if (_cards.isEmpty) {
      throw StateError('Deck is empty');
    }
    return _cards.removeLast();
  }

  /// 여러 장 뽑기
  List<HwatooCard> drawMany(int count) {
    if (count > _cards.length) {
      throw StateError('Not enough cards: requested $count, have ${_cards.length}');
    }
    final drawn = <HwatooCard>[];
    for (var i = 0; i < count; i++) {
      drawn.add(_cards.removeLast());
    }
    return drawn;
  }
}
