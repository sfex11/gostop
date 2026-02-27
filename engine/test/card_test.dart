import 'package:test/test.dart';
import 'package:engine/engine.dart';

void main() {
  group('Month enum', () {
    test('has 12 months', () {
      expect(Month.values.length, 12);
    });

    test('january is first, december is last', () {
      expect(Month.values.first, Month.january);
      expect(Month.values.last, Month.december);
    });
  });

  group('CardType enum', () {
    test('has 5 types', () {
      expect(CardType.values.length, 5);
    });

    test('contains bright, animal, ribbon, junk, doubleJunk', () {
      expect(CardType.values, containsAll([
        CardType.bright,
        CardType.animal,
        CardType.ribbon,
        CardType.junk,
        CardType.doubleJunk,
      ]));
    });
  });

  group('HwatooCard', () {
    test('has name, month, and type', () {
      final card = HwatooCard(
        name: '학',
        month: Month.january,
        type: CardType.bright,
      );
      expect(card.name, '학');
      expect(card.month, Month.january);
      expect(card.type, CardType.bright);
    });

    test('cards with same month and type are equal', () {
      final a = HwatooCard(name: '학', month: Month.january, type: CardType.bright);
      final b = HwatooCard(name: '학', month: Month.january, type: CardType.bright);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('cards with different month are not equal', () {
      final a = HwatooCard(name: '학', month: Month.january, type: CardType.bright);
      final b = HwatooCard(name: '막', month: Month.march, type: CardType.bright);
      expect(a, isNot(equals(b)));
    });

    test('cards with different type are not equal', () {
      final a = HwatooCard(name: '홍단', month: Month.january, type: CardType.ribbon);
      final b = HwatooCard(name: '피', month: Month.january, type: CardType.junk);
      expect(a, isNot(equals(b)));
    });
  });

  group('Cards constants', () {
    test('all 48 cards defined', () {
      expect(Cards.all.length, 48);
    });

    test('4 cards per month', () {
      for (final month in Month.values) {
        final count = Cards.all.where((c) => c.month == month).length;
        expect(count, 4, reason: '$month should have 4 cards');
      }
    });

    test('5 bright cards total', () {
      final brights = Cards.all.where((c) => c.type == CardType.bright);
      expect(brights.length, 5);
    });

    test('9 animal cards total', () {
      final animals = Cards.all.where((c) => c.type == CardType.animal);
      expect(animals.length, 9);
    });

    test('10 ribbon cards total', () {
      final ribbons = Cards.all.where((c) => c.type == CardType.ribbon);
      expect(ribbons.length, 10);
    });

    test('22 junk cards total', () {
      final junks = Cards.all.where((c) => c.type == CardType.junk);
      expect(junks.length, 22);
    });

    test('2 doubleJunk cards total (cup is animal)', () {
      final doubleJunks = Cards.all.where((c) => c.type == CardType.doubleJunk);
      expect(doubleJunks.length, 2);
    });

    test('specific bright cards exist', () {
      expect(Cards.crane.type, CardType.bright);
      expect(Cards.crane.month, Month.january);
      expect(Cards.curtain.type, CardType.bright);
      expect(Cards.curtain.month, Month.march);
      expect(Cards.moon.type, CardType.bright);
      expect(Cards.moon.month, Month.august);
      expect(Cards.phoenix.type, CardType.bright);
      expect(Cards.phoenix.month, Month.november);
      expect(Cards.rain.type, CardType.bright);
      expect(Cards.rain.month, Month.december);
    });

    test('godori birds are animal type', () {
      expect(Cards.bushWarbler.type, CardType.animal);
      expect(Cards.bushWarbler.month, Month.february);
      expect(Cards.cuckoo.type, CardType.animal);
      expect(Cards.cuckoo.month, Month.april);
      expect(Cards.geese.type, CardType.animal);
      expect(Cards.geese.month, Month.august);
    });

    test('red poem ribbons exist', () {
      expect(Cards.pineRedPoem.type, CardType.ribbon);
      expect(Cards.plumRedPoem.type, CardType.ribbon);
      expect(Cards.cherryRedPoem.type, CardType.ribbon);
    });

    test('blue poem ribbons exist', () {
      expect(Cards.peonyBluePoem.type, CardType.ribbon);
      expect(Cards.chrysanthemumBluePoem.type, CardType.ribbon);
      expect(Cards.mapleBluePoem.type, CardType.ribbon);
    });

    test('plain red ribbons exist', () {
      expect(Cards.wisteriaRed.type, CardType.ribbon);
      expect(Cards.irisRed.type, CardType.ribbon);
      expect(Cards.bushCloverRed.type, CardType.ribbon);
    });

    test('cup is animal type (can convert to doubleJunk in scoring)', () {
      expect(Cards.cup.type, CardType.animal);
      expect(Cards.cup.month, Month.september);
    });

    test('doubleJunk cards at correct months', () {
      expect(Cards.paulownia2.type, CardType.doubleJunk);
      expect(Cards.paulownia2.month, Month.november);
      expect(Cards.willow2.type, CardType.doubleJunk);
      expect(Cards.willow2.month, Month.december);
    });
  });

  group('Deck', () {
    test('new deck has 48 cards', () {
      final deck = Deck();
      expect(deck.length, 48);
    });

    test('shuffle changes card order', () {
      final deck1 = Deck();
      final deck2 = Deck()..shuffle();
      // 48! 순열이므로 같을 확률은 사실상 0
      // 하지만 확률적 테스트이므로 원본 순서와 비교
      final originalOrder = Deck().cards.toList();
      expect(deck2.cards, isNot(equals(originalOrder)));
    });

    test('shuffle preserves all 48 cards', () {
      final deck = Deck()..shuffle();
      expect(deck.length, 48);
      for (final month in Month.values) {
        final count = deck.cards.where((c) => c.month == month).length;
        expect(count, 4, reason: '$month should still have 4 cards');
      }
    });

    test('draw removes and returns top card', () {
      final deck = Deck();
      final top = deck.cards.last;
      final drawn = deck.draw();
      expect(drawn, equals(top));
      expect(deck.length, 47);
    });

    test('drawMany removes multiple cards', () {
      final deck = Deck();
      final drawn = deck.drawMany(10);
      expect(drawn.length, 10);
      expect(deck.length, 38);
    });
  });
}
