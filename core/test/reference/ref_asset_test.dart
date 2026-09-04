import 'package:test/test.dart';
import 'package:wealth_core/wealth_core.dart';

void main() {
  const eng = RefAssetEngine();

  // ۱ گرم نقره = ۴۰٬۰۰۰ ریال (یعنی ۴٬۰۰۰ تومان) — نمونه.
  final silverPrice = RefAssetPrice(
    unit: RefUnit.silverGram,
    priceRialPerUnit: 40000,
    asOf: DateTime.utc(2026, 9, 2), // کمتر از ۱ روز تا امروز → کهنه نیست.
  );

  group('RefAssetEngine — واحد مرجع (بند ۵۷، الزام ریال)', () {
    test('تومان به گرم نقره — با قیمت ریالی', () {
      // ۹۲۰٬۰۰۰٬۰۰۰ تومان (مثال پرامپت) → ریال = ÷... 
      final v = eng.calculate(
        amountMinor: 920000000,
        currency: Currency.irt,
        refPrice: silverPrice,
      );
      // ریال = ۹۲۰٬۰۰۰٬۰۰۰ × ۱۰ = ۹٬۲۰۰٬۰۰۰٬۰۰۰ ریال.
      // گرم نقره = ۹٬۲۰۰٬۰۰۰٬۰۰۰ / ۴۰٬۰۰۰ = ۲۳۰٬۰۰۰ گرم.
      expect(v.quantity, 230000);
      expect(v.unit, RefUnit.silverGram);
      expect(v.priceRialPerUnit, 40000);
    });

    test('مبلغ ریال مستقیم — تبدیل عین', () {
      final v = eng.calculate(
        amountMinor: 12000000, // ریال.
        currency: Currency.rial,
        refPrice: silverPrice,
      );
      expect(v.quantity, 300); // ۱۲M ریال / ۴۰٬۰۰۰ = ۳۰۰ گرم.
    });

    test('برعکس — از گرم نقره به تومان', () {
      final toman = eng.fromQuantity(
        quantity: 100,
        currency: Currency.irt,
        refPrice: silverPrice,
      );
      // ۱۰۰ گرم × ۴۰٬۰۰۰ ریال = ۴٬۰۰۰٬۰۰۰ ریال → ÷۱۰ = ۴۰۰٬۰۰۰ تومان.
      expect(toman, 400000);
    });

    test('labels و کارکرد تبدیل', () {
      final v = eng.calculate(
        amountMinor: 4800000, // تومان.
        currency: Currency.irt,
        refPrice: silverPrice,
      );
      // ۴٬۸۰۰٬۰۰۰ ×۱۰ = ۴۸٬۰۰۰٬۰۰۰ ریال / ۴۰٬۰۰۰ = ۱٬۲۰۰ گرم.
      expect(v.quantity, 1200);
      expect(v.labelFa(), 'معادل ۱٬۲۰۰ گرم نقره');
    });

    test('کهنگی قیمت (بیش از ۱ روز)', () {
      final old = RefAssetPrice(
        unit: RefUnit.goldGram,
        priceRialPerUnit: 500000,
        asOf: DateTime.utc(2020, 1, 1),
      );
      expect(old.isStale, true);
      expect(silverPrice.isStale, false);
    });
  });
}
