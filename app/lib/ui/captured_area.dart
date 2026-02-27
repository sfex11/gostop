import 'package:engine/engine.dart';
import 'package:flutter/material.dart';

import 'card_widget.dart';

/// 획득한 카드 영역 (광/동물/띠/피 타입별 그룹 분리 표시)
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
        .where((c) => c.type == CardType.junk || c.type == CardType.doubleJunk)
        .toList()
      ..sort((a, b) => a.month.index.compareTo(b.month.index));

    final totalScore = Scoring.totalScore(cards);

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
