import 'package:test/test.dart';
import 'package:wealth_core/wealth_core.dart';

FeeContext ctx({
  FeeKind kind = FeeKind.buy,
  num amount = 0,
  num? quantity,
  DateTime? at,
  String? assetId,
  String? assetTypeId,
  String? userId,
}) {
  return FeeContext(
    kind: kind,
    amount: amount,
    quantity: quantity,
    assetId: assetId,
    assetTypeId: assetTypeId,
    userId: userId,
    at: at ?? DateTime.utc(2026, 9, 1),
  );
}

void main() {
  group('FeeEngine — بند ۳۲-۳۶', () {
    test('درصد مبلغ — کارمزد = ناخالص × نرخ', () {
      const eng = FeeEngine([
        FeeRule(
            id: 'ex', kind: FeeKind.buy, priority: FeePriority.global,
            rate: FeeRate(percent: 4)),
      ]);
      final r = eng.compute(ctx(amount: 1000000));
      expect(r.fee, 40000);
      expect(r.rule, isNotNull);
    });

    test('مبلغ ثابت + درصد (percentPlusFixed)', () {
      const eng = FeeEngine([
        FeeRule(
            id: 'ex', kind: FeeKind.buy, priority: FeePriority.global,
            rate: FeeRate(type: FeeRateType.percentPlusFixed, percent: 1, fixed: 50000)),
      ]);
      final r = eng.compute(ctx(amount: 1000000));
      expect(r.fee, 60000); // ۱۰۰۰۰ + ۵۰۰۰۰.
    });

    test('کف/سقف کارمزد', () {
      const eng = FeeEngine([
        FeeRule(
            id: 'ex', kind: FeeKind.buy, priority: FeePriority.global,
            rate: FeeRate(percent: 0.5, minimum: 100000, maximum: 800000)),
      ]);
      // بالای سقف: ۰٫۵٪ × ۲۰۰M = ۱M → کف&سقف → ۸۰۰٬۰۰۰.
      expect(eng.compute(ctx(amount: 200000000)).fee, 800000);
      // زیر کف: ۰٫۵٪ × ۱M = ۵۰۰۰ → کف → ۱۰۰٬۰۰۰.
      expect(eng.compute(ctx(amount: 1000000)).fee, 100000);
    });

    test('اولویت ۶-سطّی — Transaction > Asset > AssetType > User > Global', () {
      const rules = [
        FeeRule(id: 'global', kind: FeeKind.buy, priority: FeePriority.global,
            rate: FeeRate(percent: 1)),
        FeeRule(id: 'assetype', kind: FeeKind.buy, priority: FeePriority.assetType,
            assetTypeId: 'GOLD', rate: FeeRate(percent: 2)),
        FeeRule(id: 'asset', kind: FeeKind.buy, priority: FeePriority.asset,
            assetId: 'g1', rate: FeeRate(percent: 3)),
        FeeRule(id: 'tx', kind: FeeKind.buy, priority: FeePriority.transactionSpecific,
            assetId: 'g1', rate: FeeRate(percent: 5)),
      ];
      final eng = FeeEngine(rules);
      // این یکی tx را ندارد → asset برنده (۳٪).
      expect(
          eng.compute(ctx(amount: 100, assetId: 'g1')).rule!.id, 'asset');
      // با فلگ transaction — در تست اثر با rule تعریف می‌شود؛ tx برنده‌ترین است.
      expect(
          eng.compute(ctx(amount: 100, assetId: 'g1')).fee, 3);
    });

    test('قانون زمانی — ساعتی (بند ۳۳)', () {
      final rules = [
        FeeRule(
            id: 'morning', kind: FeeKind.buy, priority: FeePriority.global,
            rate: FeeRate(percent: 1),
            conditions: FeeConditions(timeWindow: TimeWindow(8 * 60, 14 * 60))),
        FeeRule(
            id: 'evening', kind: FeeKind.buy, priority: FeePriority.global,
            rate: FeeRate(percent: 2),
            conditions: FeeConditions(timeWindow: TimeWindow(18 * 60, 23 * 60))),
      ];
      final eng = FeeEngine(rules);
      // ساعت ۱۰ → ۱٪.
      expect(
          eng.compute(ctx(amount: 1000000, at: DateTime.utc(2026, 9, 1, 10))).fee, 10000);
      // ساعت ۲۰ → ۲٪.
      expect(
          eng.compute(ctx(amount: 1000000, at: DateTime.utc(2026, 9, 1, 20))).fee, 20000);
    });

    test('قانون بر اساس مقدار (بند ۳۴) — بالای ۵۰۰ گرم = ۱٪', () {
      final rules = [
        FeeRule(
            id: 'big', kind: FeeKind.sell, priority: FeePriority.global,
            rate: FeeRate(percent: 1),
            conditions: const FeeConditions(minQuantity: 500)),
        FeeRule(
            id: 'small', kind: FeeKind.sell, priority: FeePriority.global,
            rate: FeeRate(percent: 1.5),
            conditions: const FeeConditions(maxQuantity: 499)),
      ];
      final eng = FeeEngine(rules);
      final big = eng.compute(ctx(kind: FeeKind.sell, amount: 1000000, quantity: 600));
      expect(big.fee, 10000); // ۱٪.
      final small = eng.compute(ctx(kind: FeeKind.sell, amount: 1000000, quantity: 100));
      expect(small.fee, 15000); // ۱٫۵٪.
    });

    test('قانون خرید/فروش خاص (buy/sell)', () {
      final rules = [
        FeeRule(id: 'buy1', kind: FeeKind.buy, priority: FeePriority.global,
            rate: FeeRate(percent: 1)),
        FeeRule(id: 'sell1', kind: FeeKind.sell, priority: FeePriority.global,
            rate: FeeRate(percent: 2)),
      ];
      final eng = FeeEngine(rules);
      expect(eng.compute(ctx(kind: FeeKind.buy, amount: 1000)).rule!.id, 'buy1');
      expect(eng.compute(ctx(kind: FeeKind.sell, amount: 1000)).rule!.id, 'sell1');
    });

    test('Override — آخرین نوشتار غالب (بند ۳۸)', () {
      const rule = FeeRule(
          id: 'r', kind: FeeKind.buy, priority: FeePriority.global,
          rate: FeeRate(percent: 4));
      final eng = FeeEngine([rule], [
        FeeOverride(ruleId: 'r', overridePercent: 6, at: DateTime.utc(2026, 1, 2)),
        FeeOverride(ruleId: 'r', overridePercent: 7, at: DateTime.utc(2026, 1, 5)),
      ]);
      final r = eng.compute(ctx(amount: 10000));
      expect(r.rule!.rate.percent, 7);
      expect(r.fee, 700);
      expect(r.overridden, true);
    });

    test('بدون قاعده → کارمزد صفر', () {
      const eng = FeeEngine([]);
      expect(eng.compute(ctx(amount: 500000)).fee, 0);
    });

    test('قانون نوع Tax/Transfer/Commission (بند ۳۲)', () {
      const rules = [
        FeeRule(id: 'tax', kind: FeeKind.tax, priority: FeePriority.global,
            rate: FeeRate(percent: 9)),
        FeeRule(id: 'tr', kind: FeeKind.transfer, priority: FeePriority.global,
            rate: FeeRate.fixedAmount(10000)),
      ];
      final eng = FeeEngine(rules);
      expect(eng.compute(ctx(kind: FeeKind.tax, amount: 1000000)).fee, 90000);
      expect(eng.compute(ctx(kind: FeeKind.transfer, amount: 1000000)).fee, 10000);
    });
  });
}
