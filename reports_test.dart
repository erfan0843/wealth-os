import 'package:test/test.dart';
import 'package:wealth_core/wealth_core.dart';

void main() {
  group('Reports — Spending / Allocation / Growth / Fees (فاز ۱۳)', () {
    test('تجمیع هزینه بر اساس دسته — مرتب نزولی', () {
      final agg = SpendAggregator()
        ..add(categoryId: 'food', labelFa: 'خوراک', amountMinor: 7000000)
        ..add(categoryId: 'transport', labelFa: 'حمل‌ونقل', amountMinor: 1800000)
        ..add(categoryId: 'food', labelFa: 'خوراک', amountMinor: 2500000)
        ..add(categoryId: 'shopping', labelFa: 'خرید', amountMinor: 2600000);
      final r = agg.result();
      expect(r, hasLength(3));
      expect(r.first.categoryId, 'food'); // ۹٬۵۰۰٬۰۰۰.
      expect(r.first.totalMinor, 9500000);
      expect(r[1].categoryId, 'shopping'); // ۲٬۶۰۰٬۰۰۰.
      expect(r[2].categoryId, 'transport'); // ۱٬۸۰۰٬۰۰۰.
    });

    test('Allocation — سهم هر کلاس دارایی', () {
      const calc = AllocationCalculator();
      final slices = calc.compute([
        ('نقد', 5000000),
        ('طلا', 3000000),
        ('سهام', 2000000),
      ]);
      expect(slices, hasLength(3));
      expect(slices.first.share, closeTo(0.5, 0.0001));
      // مجموع سهم‌ها = ۱.
      final sum = slices.fold<double>(0, (s, x) => s + x.share);
      expect(sum, closeTo(1.0, 0.0001));
      // بیشترین اول.
      expect(slices.first.assetClassName, 'نقد');
    });

    test('Growth — رشد و افت دارایی خالص', () {
      const up = Growth(80000000, 92000000);
      expect(up.percent, closeTo(15.0, 0.0001));
      expect(up.isUp, true);

      const down = Growth(92000000, 86000000);
      expect(down.percent, closeTo(-6.5217, 0.01));
      expect(down.isUp, false);

      const zero = Growth(0, 5000000);
      expect(zero.percent, 0); // تقسیم بر صفر → 0.
    });

    test('FeesTotals — جمع و تفکیک کارمزد', () {
      final f = FeesTotals()
        ..add(ruleId: 'ex', feeMinor: 40000)
        ..add(ruleId: 'ex', feeMinor: 20000)
        ..add(ruleId: 'bank', feeMinor: 15000);
      expect(f.total, 75000);
      expect(f.byRule['ex'], 60000);
      expect(f.byRule['bank'], 15000);
    });

    test('PnLReport — سود/زیان تحقق‌یافته و تحقق‌نیافته + درصد', () {
      final p = PnLReport(
        realizedMinor: 6000000,
        unrealizedMinor: 3000000,
        realizedCostMinor: 40000000, // فروش ۵۰M با هزینه ۴۰M → ۲۵٪.
        unrealizedCostMinor: 50000000,
        realizedFeesMinor: 200000,
        feesMinor: 300000,
      );
      expect(p.totalMinor, 9000000);
      expect(p.realizedPercent, closeTo(15.0, 0.001));
      expect(p.unrealizedPercent, closeTo(6.0, 0.001));
    });

    test('CashFlowReport — خالص جریان نقدی (بند ۵۴/۵۱)', () {
      const r = CashFlowReport(inflowMinor: 12000000, outflowMinor: 7500000);
      expect(r.netMinor, 4500000);
    });

    test('NetWorthReport — دارایی خالص (بند ۵۴/۱۷)', () {
      final r = NetWorthReport(
        totalAssetsMinor: 1250000000,
        totalLiabilitiesMinor: 48000000,
        liquidMinor: 360000000,
        investmentsMinor: 890000000,
      );
      expect(r.netWorthMinor, 1202000000);
    });

    test('WealthGrowthSeries — سری رشد چند دوره (بند ۵۸)', () {
      final s = WealthGrowthSeries(
        granularity: GrowthGranularity.monthly,
        unit: GrowthUnit.silverGram,
        points: [
          GrowthPoint(DateTime.utc(2026, 6, 30), 300000),
          GrowthPoint(DateTime.utc(2026, 7, 31), 380000),
          GrowthPoint(DateTime.utc(2026, 8, 31), 410000),
        ],
      );
      expect(s.points, hasLength(3));
      expect(s.isUp, true);
      expect(s.change, 110000);
    });
  });
}
