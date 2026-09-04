import 'package:test/test.dart';
import 'package:wealth_core/wealth_core.dart';

void main() {
  group('NetWorthCalculator', () {
    const calc = NetWorthCalculator();

    test('دارایی خالص = کل دارایی - کل بدهی', () {
      final snap = calc.calculate(
        assets: const [
          WealthItem(id: 'bank', name: 'بانک', valueMinor: 1000000000, currency: Currency.irt, liquidity: LiquidityClass.liquid),
          WealthItem(id: 'silver', name: 'نقره', valueMinor: 200000000, currency: Currency.irt, liquidity: LiquidityClass.semiLiquid),
        ],
        liabilities: const [
          WealthItem(id: 'debt', name: 'بدهی', valueMinor: 80000000, currency: Currency.irt),
        ],
        currency: Currency.irt,
      );
      expect(snap.totalAssetsMinor, 1200000000);
      expect(snap.totalLiabilitiesMinor, 80000000);
      expect(snap.netWorthMinor, 1120000000);
    });

    test('C11: نقدینگی فقط نقد+نقدشونده؛ طلب در نقدینگی لحاظ نمی‌شود', () {
      final snap = calc.calculate(
        assets: const [
          WealthItem(id: 'cash', name: 'نقد', valueMinor: 50000000, currency: Currency.irt, liquidity: LiquidityClass.liquid),
          WealthItem(id: 'receivable', name: 'طلب از دوست', valueMinor: 30000000, currency: Currency.irt, isReceivable: true),
        ],
        liabilities: const [],
        currency: Currency.irt,
      );
      // نقدینگی فقط ۵۰ میلیون (نقد)، نه ۸۰؛ طلب در دارایی کل و دارایی خالص هست.
      expect(snap.cashMinor, 50000000);
      expect(snap.liquidAssetsMinor, 50000000);
      expect(snap.totalAssetsMinor, 80000000);
      expect(snap.netWorthMinor, 80000000);
    });

    test('نقدینگی شامل نیمه‌نقدشونده (طلا/نقره/ارز) می‌شود', () {
      final snap = calc.calculate(
        assets: const [
          WealthItem(id: 'cash', name: 'نقد', valueMinor: 50000000, currency: Currency.irt, liquidity: LiquidityClass.liquid),
          WealthItem(id: 'silver', name: 'نقره', valueMinor: 120000000, currency: Currency.irt, liquidity: LiquidityClass.semiLiquid),
          WealthItem(id: 'house', name: 'ملک', valueMinor: 700000000, currency: Currency.irt, liquidity: LiquidityClass.nonLiquid),
        ],
        liabilities: const [],
        currency: Currency.irt,
      );
      // نقدینگی = ۵۰ + ۱۲۰ (ملک؟ نه).
      expect(snap.liquidAssetsMinor, 170000000);
      expect(snap.totalAssetsMinor, 870000000);
    });
  });
}
