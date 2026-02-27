import 'package:engine/engine.dart';
import 'package:flutter/material.dart';

import 'card_widget.dart';

/// 획득한 카드 영역 (광/띠/동물/피 분류 표시)
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
    final brights = cards.where((c) => c.type == CardType.bright).toList();
    final animals = cards.where((c) => c.type == CardType.animal).toList();
    final ribbons = cards.where((c) => c.type == CardType.ribbon).toList();
    final junk = cards
        .where((c) => c.type == CardType.junk || c.type == CardType.doubleJunk)
        .toList();

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
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 4),
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
          if (cards.isNotEmpty) ...[
            const SizedBox(height: 4),
            CardRow(
              cards: cards,
              overlap: 0.75,
              cardWidth: 36,
              cardHeight: 50,
            ),
          ],
        ],
      ),
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
