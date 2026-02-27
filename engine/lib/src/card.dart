/// 화투 카드의 월 (1~12월)
enum Month {
  january,
  february,
  march,
  april,
  may,
  june,
  july,
  august,
  september,
  october,
  november,
  december,
}

/// 화투 카드 유형
enum CardType {
  /// 광 (Bright) — 5장
  bright,

  /// 동물/십 (Animal) — 9장
  animal,

  /// 띠/오 (Ribbon) — 10장
  ribbon,

  /// 피 (Junk) — 21장, 1피로 계산
  junk,

  /// 쌍피 (Double Junk) — 3장, 2피로 계산
  doubleJunk,
}

/// 화투 카드 1장
class HwatooCard {
  final String name;
  final Month month;
  final CardType type;

  const HwatooCard({
    required this.name,
    required this.month,
    required this.type,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HwatooCard && month == other.month && type == other.type && name == other.name;

  @override
  int get hashCode => Object.hash(name, month, type);

  @override
  String toString() => 'HwatooCard($name, $month, $type)';
}

/// 48장 화투 카드 상수 정의
abstract final class Cards {
  // === 1월 소나무 (Pine) ===
  static const crane = HwatooCard(name: '학', month: Month.january, type: CardType.bright);
  static const pineRedPoem = HwatooCard(name: '송학홍단', month: Month.january, type: CardType.ribbon);
  static const pine1 = HwatooCard(name: '솔피1', month: Month.january, type: CardType.junk);
  static const pine2 = HwatooCard(name: '솔피2', month: Month.january, type: CardType.junk);

  // === 2월 매화 (Plum) ===
  static const bushWarbler = HwatooCard(name: '꾀꼬리', month: Month.february, type: CardType.animal);
  static const plumRedPoem = HwatooCard(name: '매화홍단', month: Month.february, type: CardType.ribbon);
  static const plum1 = HwatooCard(name: '매피1', month: Month.february, type: CardType.junk);
  static const plum2 = HwatooCard(name: '매피2', month: Month.february, type: CardType.junk);

  // === 3월 벚꽃 (Cherry) ===
  static const curtain = HwatooCard(name: '막', month: Month.march, type: CardType.bright);
  static const cherryRedPoem = HwatooCard(name: '벚꽃홍단', month: Month.march, type: CardType.ribbon);
  static const cherry1 = HwatooCard(name: '벚피1', month: Month.march, type: CardType.junk);
  static const cherry2 = HwatooCard(name: '벚피2', month: Month.march, type: CardType.junk);

  // === 4월 등나무 (Wisteria) ===
  static const cuckoo = HwatooCard(name: '두견새', month: Month.april, type: CardType.animal);
  static const wisteriaRed = HwatooCard(name: '등초단', month: Month.april, type: CardType.ribbon);
  static const wisteria1 = HwatooCard(name: '등피1', month: Month.april, type: CardType.junk);
  static const wisteria2 = HwatooCard(name: '등피2', month: Month.april, type: CardType.junk);

  // === 5월 난초 (Iris) ===
  static const bridge = HwatooCard(name: '다리', month: Month.may, type: CardType.animal);
  static const irisRed = HwatooCard(name: '난초단', month: Month.may, type: CardType.ribbon);
  static const iris1 = HwatooCard(name: '난피1', month: Month.may, type: CardType.junk);
  static const iris2 = HwatooCard(name: '난피2', month: Month.may, type: CardType.junk);

  // === 6월 모란 (Peony) ===
  static const butterfly = HwatooCard(name: '나비', month: Month.june, type: CardType.animal);
  static const peonyBluePoem = HwatooCard(name: '모란청단', month: Month.june, type: CardType.ribbon);
  static const peony1 = HwatooCard(name: '모피1', month: Month.june, type: CardType.junk);
  static const peony2 = HwatooCard(name: '모피2', month: Month.june, type: CardType.junk);

  // === 7월 싸리 (Bush Clover) ===
  static const boar = HwatooCard(name: '멧돼지', month: Month.july, type: CardType.animal);
  static const bushCloverRed = HwatooCard(name: '싸리초단', month: Month.july, type: CardType.ribbon);
  static const bushClover1 = HwatooCard(name: '싸리피1', month: Month.july, type: CardType.junk);
  static const bushClover2 = HwatooCard(name: '싸리피2', month: Month.july, type: CardType.junk);

  // === 8월 억새 (Pampas Grass) ===
  static const moon = HwatooCard(name: '달', month: Month.august, type: CardType.bright);
  static const geese = HwatooCard(name: '기러기', month: Month.august, type: CardType.animal);
  static const pampas1 = HwatooCard(name: '억새피1', month: Month.august, type: CardType.junk);
  static const pampas2 = HwatooCard(name: '억새피2', month: Month.august, type: CardType.junk);

  // === 9월 국화 (Chrysanthemum) ===
  /// 국진(Cup): 동물이지만, 피 10장 이상이면 쌍피로 전환 가능
  static const cup = HwatooCard(name: '국진', month: Month.september, type: CardType.animal);
  static const chrysanthemumBluePoem = HwatooCard(name: '국화청단', month: Month.september, type: CardType.ribbon);
  static const chrysanthemum1 = HwatooCard(name: '국피1', month: Month.september, type: CardType.junk);
  static const chrysanthemum2 = HwatooCard(name: '국피2', month: Month.september, type: CardType.junk);

  // === 10월 단풍 (Maple) ===
  static const deer = HwatooCard(name: '사슴', month: Month.october, type: CardType.animal);
  static const mapleBluePoem = HwatooCard(name: '단풍청단', month: Month.october, type: CardType.ribbon);
  static const maple1 = HwatooCard(name: '단풍피1', month: Month.october, type: CardType.junk);
  static const maple2 = HwatooCard(name: '단풍피2', month: Month.october, type: CardType.junk);

  // === 11월 오동 (Paulownia) ===
  static const phoenix = HwatooCard(name: '봉황', month: Month.november, type: CardType.bright);
  static const paulownia2 = HwatooCard(name: '오동쌍피', month: Month.november, type: CardType.doubleJunk);
  static const paulownia1 = HwatooCard(name: '오동피1', month: Month.november, type: CardType.junk);
  static const paulownia3 = HwatooCard(name: '오동피2', month: Month.november, type: CardType.junk);

  // === 12월 버들 (Willow) ===
  static const rain = HwatooCard(name: '비', month: Month.december, type: CardType.bright);
  static const swallow = HwatooCard(name: '제비', month: Month.december, type: CardType.animal);
  static const willowRed = HwatooCard(name: '버들띠', month: Month.december, type: CardType.ribbon);
  static const willow2 = HwatooCard(name: '버들쌍피', month: Month.december, type: CardType.doubleJunk);

  /// 48장 전체 덱
  static const all = <HwatooCard>[
    crane, pineRedPoem, pine1, pine2,
    bushWarbler, plumRedPoem, plum1, plum2,
    curtain, cherryRedPoem, cherry1, cherry2,
    cuckoo, wisteriaRed, wisteria1, wisteria2,
    bridge, irisRed, iris1, iris2,
    butterfly, peonyBluePoem, peony1, peony2,
    boar, bushCloverRed, bushClover1, bushClover2,
    moon, geese, pampas1, pampas2,
    cup, chrysanthemumBluePoem, chrysanthemum1, chrysanthemum2,
    deer, mapleBluePoem, maple1, maple2,
    phoenix, paulownia2, paulownia1, paulownia3,
    rain, swallow, willowRed, willow2,
  ];
}
