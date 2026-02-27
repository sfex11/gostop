import 'package:engine/engine.dart';
import 'package:flutter/material.dart';

/// 월 이름 (한글)
const _monthNames = [
  '1월', '2월', '3월', '4월', '5월', '6월',
  '7월', '8월', '9월', '10월', '11월', '12월',
];

/// 카드 유형별 색상
Color _cardTypeColor(CardType type) {
  return switch (type) {
    CardType.bright => const Color(0xFFFFD600),
    CardType.animal => const Color(0xFF4CAF50),
    CardType.ribbon => const Color(0xFFE53935),
    CardType.junk => const Color(0xFF9E9E9E),
    CardType.doubleJunk => const Color(0xFFB0BEC5),
  };
}

/// 카드 유형 라벨
String _cardTypeLabel(CardType type) {
  return switch (type) {
    CardType.bright => '광',
    CardType.animal => '동물',
    CardType.ribbon => '띠',
    CardType.junk => '피',
    CardType.doubleJunk => '쌍피',
  };
}

/// 화투 카드 위젯 (텍스트 플레이스홀더)
class HwatooCardWidget extends StatelessWidget {
  final HwatooCard card;
  final bool faceDown;
  final bool selected;
  final bool highlighted;
  final VoidCallback? onTap;
  final double width;
  final double height;

  const HwatooCardWidget({
    super.key,
    required this.card,
    this.faceDown = false,
    this.selected = false,
    this.highlighted = false,
    this.onTap,
    this.width = 52,
    this.height = 72,
  });

  @override
  Widget build(BuildContext context) {
    if (faceDown) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF1B5E20),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: const Color(0xFF388E3C), width: 1.5),
          ),
          child: const Center(
            child: Text('🎴', style: TextStyle(fontSize: 20)),
          ),
        ),
      );
    }

    final monthIndex = card.month.index;
    final monthLabel = _monthNames[monthIndex];
    final typeColor = _cardTypeColor(card.type);
    final typeLabel = _cardTypeLabel(card.type);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width,
        height: height,
        transform: selected
            ? (Matrix4.identity()..translate(0.0, -8.0))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: highlighted
                ? const Color(0xFFFF9800)
                : selected
                    ? const Color(0xFF2196F3)
                    : const Color(0xFFBCAAA4),
            width: highlighted || selected ? 2.5 : 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              monthLabel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.brown.shade800,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                typeLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: typeColor.withValues(alpha: 1.0),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              card.name,
              style: TextStyle(
                fontSize: 8,
                color: Colors.brown.shade600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// 카드 리스트를 가로로 나열 (겹침 가능)
class CardRow extends StatelessWidget {
  final List<HwatooCard> cards;
  final bool faceDown;
  final HwatooCard? selectedCard;
  final Set<HwatooCard> highlightedCards;
  final ValueChanged<HwatooCard>? onCardTap;
  final double overlap;
  final double cardWidth;
  final double cardHeight;

  const CardRow({
    super.key,
    required this.cards,
    this.faceDown = false,
    this.selectedCard,
    this.highlightedCards = const {},
    this.onCardTap,
    this.overlap = 0.6,
    this.cardWidth = 52,
    this.cardHeight = 72,
  });

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) {
      return SizedBox(height: cardHeight);
    }

    return SizedBox(
      height: cardHeight + 8, // 선택 시 위로 올라가는 여유
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < cards.length; i++)
              Padding(
                padding: EdgeInsets.only(
                  left: i == 0 ? 0 : cardWidth * (1 - overlap),
                ),
                child: HwatooCardWidget(
                  card: cards[i],
                  faceDown: faceDown,
                  selected: cards[i] == selectedCard,
                  highlighted: highlightedCards.contains(cards[i]),
                  onTap: onCardTap != null ? () => onCardTap!(cards[i]) : null,
                  width: cardWidth,
                  height: cardHeight,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
