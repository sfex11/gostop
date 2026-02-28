import 'package:engine/engine.dart';
import 'package:flutter/material.dart';

import 'card_widget.dart';

/// 족보 진행 상황 데이터
class _ComboProgress {
  final String name;
  final int current;
  final int total;
  final Color color;
  final bool completed;

  const _ComboProgress({
    required this.name,
    required this.current,
    required this.total,
    required this.color,
    required this.completed,
  });
}

/// 획득한 카드의 족보 진행률 계산
List<_ComboProgress> _calculateComboProgress(List<HwatooCard> cards) {
  final results = <_ComboProgress>[];
  final brights = cards.where((c) => c.type == CardType.bright).toList();
  final animals = cards.where((c) => c.type == CardType.animal).toList();
  final ribbons = cards.where((c) => c.type == CardType.ribbon).toList();

  // 광 (3광/4광/5광)
  if (brights.isNotEmpty && brights.length < 5) {
    results.add(_ComboProgress(
      name: brights.length >= 3 ? '${brights.length}광' : '삼광',
      current: brights.length,
      total: brights.length >= 3 ? 5 : 3,
      color: const Color(0xFFFFD600),
      completed: brights.length >= 3,
    ));
  } else if (brights.length == 5) {
    results.add(const _ComboProgress(
      name: '오광',
      current: 5,
      total: 5,
      color: Color(0xFFFFD600),
      completed: true,
    ));
  }

  // 고도리 (꾀꼬리 + 두견새 + 기러기)
  final hasWarbler = animals.contains(Cards.bushWarbler);
  final hasCuckoo = animals.contains(Cards.cuckoo);
  final hasGeese = animals.contains(Cards.geese);
  final godoriCount =
      (hasWarbler ? 1 : 0) + (hasCuckoo ? 1 : 0) + (hasGeese ? 1 : 0);
  if (godoriCount > 0) {
    results.add(_ComboProgress(
      name: '고도리',
      current: godoriCount,
      total: 3,
      color: const Color(0xFF4CAF50),
      completed: godoriCount == 3,
    ));
  }

  // 홍단 (1,2,3월 빨간 글씨 띠)
  final hasRedPoem1 = ribbons.contains(Cards.pineRedPoem);
  final hasRedPoem2 = ribbons.contains(Cards.plumRedPoem);
  final hasRedPoem3 = ribbons.contains(Cards.cherryRedPoem);
  final redPoemCount =
      (hasRedPoem1 ? 1 : 0) + (hasRedPoem2 ? 1 : 0) + (hasRedPoem3 ? 1 : 0);
  if (redPoemCount > 0) {
    results.add(_ComboProgress(
      name: '홍단',
      current: redPoemCount,
      total: 3,
      color: const Color(0xFFFF5252),
      completed: redPoemCount == 3,
    ));
  }

  // 청단 (6,9,10월 파란 글씨 띠)
  final hasBluePoem1 = ribbons.contains(Cards.peonyBluePoem);
  final hasBluePoem2 = ribbons.contains(Cards.chrysanthemumBluePoem);
  final hasBluePoem3 = ribbons.contains(Cards.mapleBluePoem);
  final bluePoemCount = (hasBluePoem1 ? 1 : 0) +
      (hasBluePoem2 ? 1 : 0) +
      (hasBluePoem3 ? 1 : 0);
  if (bluePoemCount > 0) {
    results.add(_ComboProgress(
      name: '청단',
      current: bluePoemCount,
      total: 3,
      color: const Color(0xFF448AFF),
      completed: bluePoemCount == 3,
    ));
  }

  // 초단 (4,5,7월 빨간 무지 띠)
  final hasPlainRed1 = ribbons.contains(Cards.wisteriaRed);
  final hasPlainRed2 = ribbons.contains(Cards.irisRed);
  final hasPlainRed3 = ribbons.contains(Cards.bushCloverRed);
  final plainRedCount = (hasPlainRed1 ? 1 : 0) +
      (hasPlainRed2 ? 1 : 0) +
      (hasPlainRed3 ? 1 : 0);
  if (plainRedCount > 0) {
    results.add(_ComboProgress(
      name: '초단',
      current: plainRedCount,
      total: 3,
      color: const Color(0xFFFF8A65),
      completed: plainRedCount == 3,
    ));
  }

  // 피 진행 (10피 필요)
  final junkCount = cards.where((c) => c.type == CardType.junk).length;
  final doubleJunkCount =
      cards.where((c) => c.type == CardType.doubleJunk).length;
  final totalPi = junkCount + doubleJunkCount * 2;
  if (totalPi > 0 && totalPi < 10) {
    results.add(_ComboProgress(
      name: '피',
      current: totalPi,
      total: 10,
      color: const Color(0xFF9E9E9E),
      completed: false,
    ));
  }

  return results;
}

/// 획득한 카드 영역 (광/동물/띠/피 타입별 그룹 분리 표시 + 족보 진행률)
class CapturedArea extends StatelessWidget {
  final List<HwatooCard> cards;
  final String label;

  const CapturedArea({
    super.key,
    required this.cards,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final brights = cards.where((c) => c.type == CardType.bright).toList()
      ..sort((a, b) => a.month.index.compareTo(b.month.index));
    final animals = cards.where((c) => c.type == CardType.animal).toList()
      ..sort((a, b) => a.month.index.compareTo(b.month.index));
    final ribbons = cards.where((c) => c.type == CardType.ribbon).toList()
      ..sort((a, b) => a.month.index.compareTo(b.month.index));
    final junk = cards
        .where(
            (c) => c.type == CardType.junk || c.type == CardType.doubleJunk)
        .toList()
      ..sort((a, b) => a.month.index.compareTo(b.month.index));

    final totalScore = Scoring.totalScore(cards);
    final combos = _calculateComboProgress(cards);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 라벨 + 총점
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
              if (totalScore > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${totalScore}점',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 3),
          // 카테고리 칩
          Row(
            children: [
              _CategoryChip('광', brights.length, const Color(0xFFFFD600)),
              const SizedBox(width: 6),
              _CategoryChip('동물', animals.length, const Color(0xFF4CAF50)),
              const SizedBox(width: 6),
              _CategoryChip('띠', ribbons.length, const Color(0xFFE53935)),
              const SizedBox(width: 6),
              _CategoryChip('피', _junkCount(junk), const Color(0xFF9E9E9E)),
            ],
          ),
          // 족보 진행률
          if (combos.isNotEmpty) ...[
            const SizedBox(height: 3),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var i = 0; i < combos.length; i++) ...[
                    if (i > 0) const SizedBox(width: 4),
                    _ComboChip(combo: combos[i]),
                  ],
                ],
              ),
            ),
          ],
          // 타입별 그룹 분리 표시
          if (cards.isNotEmpty) ...[
            const SizedBox(height: 3),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (brights.isNotEmpty)
                    _TypeGroup(
                      cards: brights,
                      color: const Color(0xFFFFD600),
                    ),
                  if (brights.isNotEmpty &&
                      (animals.isNotEmpty ||
                          ribbons.isNotEmpty ||
                          junk.isNotEmpty))
                    _groupDivider(),
                  if (animals.isNotEmpty)
                    _TypeGroup(
                      cards: animals,
                      color: const Color(0xFF4CAF50),
                    ),
                  if (animals.isNotEmpty &&
                      (ribbons.isNotEmpty || junk.isNotEmpty))
                    _groupDivider(),
                  if (ribbons.isNotEmpty)
                    _TypeGroup(
                      cards: ribbons,
                      color: const Color(0xFFE53935),
                    ),
                  if (ribbons.isNotEmpty && junk.isNotEmpty) _groupDivider(),
                  if (junk.isNotEmpty)
                    _TypeGroup(
                      cards: junk,
                      color: const Color(0xFF9E9E9E),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _groupDivider() {
    return Container(
      width: 1,
      height: 40,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.white12,
    );
  }

  int _junkCount(List<HwatooCard> junk) {
    var count = 0;
    for (final c in junk) {
      count += c.type == CardType.doubleJunk ? 2 : 1;
    }
    return count;
  }
}

/// 족보 진행 칩
class _ComboChip extends StatelessWidget {
  final _ComboProgress combo;

  const _ComboChip({required this.combo});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: combo.completed
            ? combo.color.withValues(alpha: 0.3)
            : combo.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border:
            combo.completed ? Border.all(color: combo.color, width: 1) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            combo.name,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: combo.completed
                  ? combo.color
                  : combo.color.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(width: 3),
          // 진행 도트
          if (combo.total <= 5)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < combo.total; i++) ...[
                  if (i > 0) const SizedBox(width: 1),
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < combo.current
                          ? combo.color
                          : combo.color.withValues(alpha: 0.2),
                    ),
                  ),
                ],
              ],
            )
          else
            // 피처럼 10개인 경우 숫자로 표시
            Text(
              '${combo.current}/${combo.total}',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.bold,
                color: combo.color.withValues(alpha: 0.7),
              ),
            ),
        ],
      ),
    );
  }
}

/// 타입별 카드 그룹 (겹침 표시)
class _TypeGroup extends StatelessWidget {
  final List<HwatooCard> cards;
  final Color color;

  const _TypeGroup({required this.cards, required this.color});

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();

    const cardW = 34.0;
    const cardH = 48.0;
    const overlap = 0.72;

    final effectiveWidth = cardW + (cards.length - 1) * cardW * (1 - overlap);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: color.withValues(alpha: 0.4), width: 2),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 2),
      child: SizedBox(
        width: effectiveWidth,
        height: cardH,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (var i = 0; i < cards.length; i++)
              Positioned(
                left: i * cardW * (1 - overlap),
                child: HwatooCardWidget(
                  card: cards[i],
                  width: cardW,
                  height: cardH,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _CategoryChip(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label $count',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
