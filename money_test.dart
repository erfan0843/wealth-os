import 'package:test/test.dart';
import 'package:wealth_core/wealth_core.dart';

void main() {
  group('Money', () {
    test('add and subtract', () {
      const a = Money(1000, Currency.irt);
      const b = Money(350, Currency.irt);
      expect(a.plus(b), const Money(1350, Currency.irt));
      expect(a.minus(b), const Money(650, Currency.irt));
    });

    test('equality over identical field values', () {
      expect(const Money(100, Currency.irt), const Money(100, Currency.irt));
      expect(const Money(100, Currency.usd), isNot(const Money(100, Currency.irt)));
    });

    test('negative detection', () {
      expect(const Money(-5, Currency.irt).isNegative, isTrue);
      expect(const Money(5, Currency.irt).isNegative, isFalse);
      expect(const Money(0, Currency.irt).isZero, isTrue);
    });
  });

  group('number formatting (Persian)', () {
    test('groups thousands and converts to Persian digits', () {
      expect(formatMoneyFa(350000, Currency.irt), '۳۵۰٬۰۰۰ تومان');
      expect(formatMoneyFa(920000000, Currency.irt), '۹۲۰٬۰۰۰٬۰۰۰ تومان');
    });

    test('toFaNumber', () {
      expect(toFaNumber(2026), '۲۰۲۶');
      expect(toFaNumber(0), '۰');
    });
  });
}
