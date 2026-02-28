import 'package:engine/engine.dart';
import 'package:flutter/material.dart';

/// 월별 테마 색상 & 심볼
class MonthTheme {
  final Color primary;
  final Color secondary;
  final String symbol;
  final String label;

  const MonthTheme(this.primary, this.secondary, this.symbol, this.label);
}

const monthThemes = <Month, MonthTheme>{
  Month.january: MonthTheme(Color(0xFF2E7D32), Color(0xFF1B5E20), '松', '소나무'),
  Month.february: MonthTheme(Color(0xFFE91E63), Color(0xFFC2185B), '梅', '매화'),
  Month.march: MonthTheme(Color(0xFFF48FB1), Color(0xFFEC407A), '桜', '벚꽃'),
  Month.april: MonthTheme(Color(0xFF7B1FA2), Color(0xFF6A1B9A), '藤', '등나무'),
  Month.may: MonthTheme(Color(0xFF5C6BC0), Color(0xFF3949AB), '蘭', '난초'),
  Month.june: MonthTheme(Color(0xFFD32F2F), Color(0xFFB71C1C), '牡', '모란'),
  Month.july: MonthTheme(Color(0xFFFF8F00), Color(0xFFE65100), '萩', '싸리'),
  Month.august: MonthTheme(Color(0xFF546E7A), Color(0xFF37474F), '芒', '억새'),
  Month.september: MonthTheme(Color(0xFFFFB300), Color(0xFFF57F17), '菊', '국화'),
  Month.october: MonthTheme(Color(0xFFE65100), Color(0xFFBF360C), '楓', '단풍'),
  Month.november: MonthTheme(Color(0xFF4E342E), Color(0xFF3E2723), '桐', '오동'),
  Month.december: MonthTheme(Color(0xFF455A64), Color(0xFF263238), '柳', '버들'),
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

/// 카드 유형 한글 라벨
String cardTypeLabel(CardType type) {
  return switch (type) {
    CardType.bright => '광',
    CardType.animal => '동물',
    CardType.ribbon => '띠',
    CardType.junk => '피',
    CardType.doubleJunk => '쌍피',
  };
}

/// 화투 카드 앞면 위젯 (Widget 기반 — 웹 호환)
class HwatooCardFace extends StatelessWidget {
  final HwatooCard card;
  final double width;
  final double height;

  const HwatooCardFace({
    super.key,
    required this.card,
    this.width = 52,
    this.height = 72,
  });

  @override
  Widget build(BuildContext context) {
    final theme = monthThemes[card.month]!;
    final badgeColor = cardTypeBadgeColor(card.type);
    final isBright = card.type == CardType.bright;
    final monthNum = card.month.index + 1;
    final fs = width * 0.15; // base font scale

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFDE7), Color(0xFFFFF8E1), Color(0xFFFFF3E0)],
        ),
        border: Border.all(color: const Color(0xFFBCAAA4), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Stack(
          children: [
            // 상단 색 띠
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: height * 0.33,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [theme.primary, theme.secondary],
                  ),
                ),
                child: Stack(
                  children: [
                    // 월 번호 (좌상단)
                    Positioned(
                      left: 3,
                      top: 1,
                      child: Text(
                        '$monthNum',
                        style: TextStyle(
                          fontSize: fs * 1.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1,
                        ),
                      ),
                    ),
                    // 한자 심볼 (중앙)
                    Center(
                      child: Text(
                        theme.symbol,
                        style: TextStyle(
                          fontSize: fs * 2.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white.withValues(alpha: 0.85),
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 광 카드 코너 장식
            if (isBright) ...[
              Positioned(
                top: 0,
                left: 0,
                child: CustomPaint(
                  size: Size(width * 0.2, height * 0.1),
                  painter: _TrianglePainter(
                    color: const Color(0xFFFFD600).withValues(alpha: 0.6),
                    isTopLeft: true,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: CustomPaint(
                  size: Size(width * 0.2, height * 0.1),
                  painter: _TrianglePainter(
                    color: const Color(0xFFFFD600).withValues(alpha: 0.6),
                    isTopLeft: false,
                  ),
                ),
              ),
            ],

            // 유형 뱃지 (중앙)
            Positioned(
              top: height * 0.43,
              left: width * 0.12,
              right: width * 0.12,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: height * 0.03),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(height * 0.06),
                  border: Border.all(color: badgeColor, width: 1.2),
                ),
                child: Center(
                  child: Text(
                    cardTypeLabel(card.type),
                    style: TextStyle(
                      fontSize: fs * 1.25,
                      fontWeight: FontWeight.w700,
                      color: badgeColor,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),

            // 카드 이름 (하단)
            Positioned(
              bottom: height * 0.12,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  card.name,
                  style: TextStyle(
                    fontSize: fs * 1.05,
                    fontWeight: FontWeight.w600,
                    color: Colors.brown.shade700,
                    height: 1,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // 월 이름 (최하단)
            Positioned(
              bottom: height * 0.02,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  theme.label,
                  style: TextStyle(
                    fontSize: fs * 0.9,
                    fontWeight: FontWeight.normal,
                    color: Colors.brown.shade400,
                    height: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 카드 뒷면 위젯 (Widget 기반 — 웹 호환)
class HwatooCardBack extends StatelessWidget {
  final double width;
  final double height;

  const HwatooCardBack({
    super.key,
    this.width = 52,
    this.height = 72,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF1B5E20)],
        ),
        border: Border.all(color: const Color(0xFF388E3C), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Stack(
          children: [
            // 다이아몬드 패턴 (간소화된 위젯 버전)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 중앙 원 + 花 텍스트
                  Container(
                    width: width * 0.45,
                    height: width * 0.45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFD600).withValues(alpha: 0.7),
                      border: Border.all(
                        color: const Color(0xFF43A047),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '花',
                        style: TextStyle(
                          fontSize: width * 0.2,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1B5E20),
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 코너 장식
            for (final align in [
              Alignment.topLeft,
              Alignment.topRight,
              Alignment.bottomLeft,
              Alignment.bottomRight,
            ])
              Align(
                alignment: align,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Container(
                    width: width * 0.08,
                    height: width * 0.08,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF43A047).withValues(alpha: 0.5),
                    ),
                  ),
                ),
              ),

            // 테두리 장식 라인
            Positioned(
              top: height * 0.08,
              left: width * 0.08,
              right: width * 0.08,
              bottom: height * 0.08,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: const Color(0xFF43A047).withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 광 코너 삼각형 (이것만 CustomPaint — 단순 도형이라 웹 OK)
class _TrianglePainter extends CustomPainter {
  final Color color;
  final bool isTopLeft;

  _TrianglePainter({required this.color, required this.isTopLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (isTopLeft) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.lineTo(size.width, 0);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _TrianglePainter old) =>
      color != old.color || isTopLeft != old.isTopLeft;
}
