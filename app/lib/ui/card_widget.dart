import 'package:engine/engine.dart';
import 'package:flutter/material.dart';

import 'card_image_service.dart';
import 'card_painter.dart';

/// 화투 카드 위젯 — 이미지 에셋 또는 Widget 기반 렌더링
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
    final svc = CardImageService.instance;

    Widget cardChild;
    if (faceDown) {
      final backPath = svc.backImagePath();
      cardChild = backPath != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(backPath, width: width, height: height, fit: BoxFit.cover),
            )
          : HwatooCardBack(width: width, height: height);
    } else {
      final imgPath = svc.imagePath(card);
      cardChild = imgPath != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.asset(imgPath, width: width, height: height, fit: BoxFit.cover),
            )
          : HwatooCardFace(card: card, width: width, height: height);
    }

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
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: highlighted
                ? const Color(0xFFFF9800)
                : selected
                    ? const Color(0xFF2196F3)
                    : Colors.transparent,
            width: highlighted || selected ? 2.5 : 0,
          ),
          boxShadow: [
            if (selected)
              BoxShadow(
                color: Colors.blue.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            else if (highlighted)
              BoxShadow(
                color: Colors.orange.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            else
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 3,
                offset: const Offset(1, 2),
              ),
          ],
        ),
        child: cardChild,
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

    final effectiveWidth =
        cardWidth + (cards.length - 1) * cardWidth * (1 - overlap);

    return SizedBox(
      height: cardHeight + 8,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: effectiveWidth,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < cards.length; i++)
                Positioned(
                  left: i * cardWidth * (1 - overlap),
                  child: HwatooCardWidget(
                    card: cards[i],
                    faceDown: faceDown,
                    selected: cards[i] == selectedCard,
                    highlighted: highlightedCards.contains(cards[i]),
                    onTap:
                        onCardTap != null ? () => onCardTap!(cards[i]) : null,
                    width: cardWidth,
                    height: cardHeight,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
