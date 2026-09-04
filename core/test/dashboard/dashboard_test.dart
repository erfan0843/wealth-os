import 'package:test/test.dart';
import 'package:wealth_core/wealth_core.dart';

void main() {
  const builder = DashboardBuilder();

  test('Dashboard — ترکیب ثروت + درآمد/هزینه + تخصیص + واحد مرجع', () {
    final input = DashboardInput(
      wealthItems: [
        // نقد و بانک.
        const WealthItem(id: 'cash', name: 'نقد', valueMinor: 50000000, currency: Currency.irt, liquidity: LiquidityClass.liquid),
        // طلا (نیمه‌نقدشونده).
        const WealthItem(id: 'gold', name: 'طلا', valueMinor: 30000000, currency: Currency.irt, liquidity: LiquidityClass.semiLiquid),
        // ملک (غیرنقد).
        const WealthItem(id: 'prop', name: 'ملک', valueMinor: 40000000, currency: Currency.irt, liquidity: LiquidityClass.nonLiquid),
        // طلب.
        const WealthItem(id: 'recv', name: 'طلب از دوست', valueMinor: 5000000, currency: Currency.irt, isReceivable: true),
        // بدهی.
        const WealthItem(id: 'debt', name: 'بدهی', valueMinor: 8000000, currency: Currency.irt, isLiability: true),
      ],
      transactions: [
        Transaction(id: 't1', userId: 'u', type: TxType.income, amountMinor: 10000000, currency: Currency.irt, occurredAt: DateTime.utc(2026, 9, 1)),
        Transaction(id: 't2', userId: 'u', type: TxType.expense, amountMinor: 2000000, currency: Currency.irt, occurredAt: DateTime.utc(2026, 9, 2), categoryId: 'food', categoryLabelFa: 'خوراک'),
        Transaction(id: 't3', userId: 'u', type: TxType.expense, amountMinor: 500000, currency: Currency.irt, occurredAt: DateTime.utc(2026, 9, 3), categoryId: 'food', categoryLabelFa: 'خوراک'),
      ],
      prevNetWorthMinor: 100000000,
      currency: Currency.irt,
      refPrice: RefAssetPrice(unit: RefUnit.silverGram, priceRialPerUnit: 40000, asOf: DateTime.utc(2026, 9, 2)),
    );
    final s = builder.build(input);

    // دارایی خالص = کل دارایی − کل بدهی.
    expect(s.totalAssetsMinor, 125000000); // ۵۰+۳۰+۴۰+۵.
    expect(s.totalLiabilitiesMinor, 8000000);
    expect(s.netWorthMinor, 117000000);
    // نقدینگی (نقد+نیمه‌نقد) — طلب در نقدینگی نه.
    expect(s.cashMinor, 50000000);
    expect(s.liquidAssetsMinor, 80000000); // نقد + طلا.
    expect(s.receivablesMinor, 5000000);
    // درآمد/هزینه.
    expect(s.incomeMinor, 10000000);
    expect(s.expenseMinor, 2500000);
    expect(s.netMinor, 7500000);
    // رشد از ۱۰۰M به ۱۱۷M → ۱۷٪.
    expect(s.growth.percent, closeTo(17.0, 0.001));
    // تخصیص — نقد/نیمه/غیرنقد.
    expect(s.allocation, hasLength(3));
    // واحد مرجع: ۱۱۷M تومان → ×۱۰ ریال ÷ ۴۰٬۰۰۰ = ۲۹۲۵۰ گرم نقره.
    expect(s.refValue, isNotNull);
    expect(s.refValue!.quantity, 29250);
  });

  test('Dashboard — بدون واحد مرجع → refValue صفر', () {
    final input = DashboardInput(
      wealthItems: const [
        WealthItem(id: 'cash', name: 'نقد', valueMinor: 5000000, currency: Currency.irt, liquidity: LiquidityClass.liquid),
      ],
      transactions: const [],
      prevNetWorthMinor: 5000000,
      currency: Currency.irt,
    );
    final s = builder.build(input);
    expect(s.refValue, isNull);
    expect(s.netWorthMinor, 5000000);
    expect(s.growth.percent, 0);
  });
}
