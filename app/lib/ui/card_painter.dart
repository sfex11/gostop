import 'dart:math' as math;

import 'package:engine/engine.dart';
import 'package:flutter/material.dart';

/// 월별 테마 색상 & 심볼
class _MonthTheme {
  final Color primary;
  final Color secondary;
  final String symbol;
  final String label;

  const _MonthTheme(this.primary, this.secondary, this.symbol, this.label);
}

const _monthThemes = <Month, _MonthTheme>{
  Month.january: _MonthTheme(Color(0xFF2E7D32), Color(0xFF1B5E20), '松', '소나무'),
  Month.february: _MonthTheme(Color(0xFFE91E63), Color(0xFFC2185B), '梅', '매화'),
  Month.march: _MonthTheme(Color(0xFFF48FB1), Color(0xFFEC407A), '桜', '벚꽃'),
  Month.april: _MonthTheme(Color(0xFF7B1FA2), Color(0xFF6A1B9A), '藤', '등나무'),
  Month.may: _MonthTheme(Color(0xFF5C6BC0), Color(0xFF3949AB), '蘭', '난초'),
  Month.june: _MonthTheme(Color(0xFFD32F2F), Color(0xFFB71C1C), '牡', '모란'),
  Month.july: _MonthTheme(Color(0xFFFF8F00), Color(0xFFE65100), '萩', '싸리'),
  Month.august: _MonthTheme(Color(0xFF546E7A), Color(0xFF37474F), '芒', '억새'),
  Month.september: _MonthTheme(Color(0xFFFFB300), Color(0xFFF57F17), '菊', '국화'),
  Month.october: _MonthTheme(Color(0xFFE65100), Color(0xFFBF360C), '楓', '단풍'),
  Month.november: _MonthTheme(Color(0xFF4E342E), Color(0xFF3E2723), '桐', '오동'),
  Month.december: _MonthTheme(Color(0xFF455A64), Color(0xFF263238), '柳', '버들'),
};

/// 카드 유형별 뱃지 색상
Color cardTypeBadgeColor(CardType type) {
  return switch (type) {
    CardType.bright => const Color(0xFFFFD600),
    CardType.animal => const Color(0xFF00C853),
    CardType.ribbon => const Color(0xFFFF1744),
    CardType.junk => const Color(0xFF78909C),
    CardType.doubleJunk => const Color(0xFF90A4AE),
  };
}

/// 카드 유형 한자 라벨
String cardTypeKanji(CardType type) {
  return switch (type) {
    CardType.bright => '光',
    CardType.animal => '獣',
    CardType.ribbon => '帯',
    CardType.junk => '皮',
    CardType.doubleJunk => '双',
  };
}

/// 화투 카드를 그리는 CustomPainter
class HwatooCardPainter extends CustomPainter {
  final HwatooCard card;

  HwatooCardPainter({required this.card});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final theme = _monthThemes[card.month]!;
    final rect = Rect.fromLTWH(0, 0, w, h);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));

    // 1) 배경 그라디언트
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFFFFDE7),
          const Color(0xFFFFF8E1),
          const Color(0xFFFFF3E0),
        ],
      ).createShader(rect);
    canvas.drawRRect(rrect, bgPaint);

    // 2) 상단 색 띠 (월 테마)
    final bandRect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, w, h * 0.32),
      topLeft: const Radius.circular(6),
      topRight: const Radius.circular(6),
    );
    final bandPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [theme.primary, theme.secondary],
      ).createShader(Rect.fromLTWH(0, 0, w, h * 0.32));
    canvas.drawRRect(bandRect, bandPaint);

    // 3) 한자 심볼 (큰 글씨, 중앙)
    _drawText(
      canvas,
      theme.symbol,
      Offset(w / 2, h * 0.17),
      fontSize: w * 0.38,
      color: Colors.white.withValues(alpha: 0.85),
      fontWeight: FontWeight.w900,
    );

    // 4) 월 번호 (좌상단)
    final monthNum = '${card.month.index + 1}';
    _drawText(
      canvas,
      monthNum,
      Offset(w * 0.18, h * 0.10),
      fontSize: w * 0.22,
      color: Colors.white,
      fontWeight: FontWeight.bold,
    );

    // 5) 카드 유형 뱃지 (중앙 하단)
    final badgeColor = cardTypeBadgeColor(card.type);
    final badgeCenterY = h * 0.55;
    final badgeW = w * 0.65;
    final badgeH = h * 0.16;
    final badgeRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w / 2, badgeCenterY), width: badgeW, height: badgeH),
      Radius.circular(badgeH / 2),
    );
    canvas.drawRRect(badgeRect, Paint()..color = badgeColor.withValues(alpha: 0.2));
    canvas.drawRRect(
      badgeRect,
      Paint()
        ..color = badgeColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // 유형 텍스트
    final typeLabel = _cardTypeLabel(card.type);
    _drawText(
      canvas,
      typeLabel,
      Offset(w / 2, badgeCenterY),
      fontSize: w * 0.2,
      color: badgeColor,
      fontWeight: FontWeight.w700,
    );

    // 6) 카드 이름 (하단)
    _drawText(
      canvas,
      card.name,
      Offset(w / 2, h * 0.78),
      fontSize: w * 0.16,
      color: Colors.brown.shade700,
      fontWeight: FontWeight.w600,
    );

    // 7) 월 이름 (최하단)
    _drawText(
      canvas,
      theme.label,
      Offset(w / 2, h * 0.90),
      fontSize: w * 0.14,
      color: Colors.brown.shade400,
      fontWeight: FontWeight.normal,
    );

    // 8) 광 카드는 특별 장식 — 코너에 빛 효과
    if (card.type == CardType.bright) {
      _drawBrightCorners(canvas, w, h);
    }

    // 9) 테두리
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFFBCAAA4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawBrightCorners(Canvas canvas, double w, double h) {
    final paint = Paint()..color = const Color(0xFFFFD600).withValues(alpha: 0.6);
    // 좌상단 삼각
    final path1 = Path()
      ..moveTo(0, 0)
      ..lineTo(w * 0.15, 0)
      ..lineTo(0, h * 0.08)
      ..close();
    canvas.drawPath(path1, paint);
    // 우하단 삼각
    final path2 = Path()
      ..moveTo(w, h)
      ..lineTo(w * 0.85, h)
      ..lineTo(w, h * 0.92)
      ..close();
    canvas.drawPath(path2, paint);
  }

  String _cardTypeLabel(CardType type) {
    return switch (type) {
      CardType.bright => '광',
      CardType.animal => '동물',
      CardType.ribbon => '띠',
      CardType.junk => '피',
      CardType.doubleJunk => '쌍피',
    };
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset center, {
    required double fontSize,
    required Color color,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant HwatooCardPainter oldDelegate) {
    return card != oldDelegate.card;
  }
}

/// 카드 뒷면 패턴 Painter
class CardBackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rect = Rect.fromLTWH(0, 0, w, h);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));

    // 배경
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF1B5E20)],
      ).createShader(rect);
    canvas.drawRRect(rrect, bgPaint);

    // 중앙 다이아몬드 패턴
    final centerX = w / 2;
    final centerY = h / 2;
    final diamondSize = w * 0.28;

    final diamondPaint = Paint()
      ..color = const Color(0xFF43A047)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (var i = 0; i < 3; i++) {
      final s = diamondSize * (1 + i * 0.5);
      final path = Path()
        ..moveTo(centerX, centerY - s)
        ..lineTo(centerX + s * 0.6, centerY)
        ..lineTo(centerX, centerY + s)
        ..lineTo(centerX - s * 0.6, centerY)
        ..close();
      canvas.drawPath(path, diamondPaint);
    }

    // 중앙 원
    canvas.drawCircle(
      Offset(centerX, centerY),
      w * 0.12,
      Paint()..color = const Color(0xFFFFD600).withValues(alpha: 0.7),
    );

    // 花 텍스트
    _drawText(
      canvas,
      '花',
      Offset(centerX, centerY),
      fontSize: w * 0.18,
      color: const Color(0xFF1B5E20),
      fontWeight: FontWeight.bold,
    );

    // 코너 장식
    final cornerPaint = Paint()..color = const Color(0xFF43A047).withValues(alpha: 0.5);
    final dotR = w * 0.03;
    for (final pos in [
      Offset(w * 0.15, h * 0.08),
      Offset(w * 0.85, h * 0.08),
      Offset(w * 0.15, h * 0.92),
      Offset(w * 0.85, h * 0.92),
    ]) {
      canvas.drawCircle(pos, dotR, cornerPaint);
    }

    // 테두리
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = const Color(0xFF388E3C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset center, {
    required double fontSize,
    required Color color,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant CardBackPainter oldDelegate) => false;
}
