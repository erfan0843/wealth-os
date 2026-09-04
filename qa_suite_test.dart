/// تستِ یکپارچه‌سازیِ سرتاسری (فاز ۱۶ مستر — QA).
/// یک سناریوی کامل چندمرحله‌ای که همهٔ موتورها را در یک جریان واقعی به هم وصل می‌کند:
///   حساب → خرید/فروش دارایی (قیمت+کارمزد+CotBasis) → بدهی/قسط → گزارش/داشبورد →
///   واحد مرجع (ریال) → SMS → ممیزی.
/// هستهٔ خالص؛ قابل تست با `dart test`.
import 'package:test/test.dart';
import 'package:wealth_core/wealth_core.dart';

void main() {
  group('QA — سناریوی پایان‌به‌پای (فاز ۱۶)', () {
    test('ثبت خرید/فروش نقره با قیمت و کارمزد + سود', () {
      const engine = AssetEngine();
      // دارایی نقره (قابل فروش به مقدار موجود — بدون Short).
      const silver = Asset(
          id: 'silver', assetTypeCode: 'SILVER', name: 'نقره', unit: 'gram');

      // خرید ۱۰۰ گرم @ ۲۰٬۰۰۰ با کارمزد ۴٪.
      final b1 = engine.buy(
        asset: silver,
        existingLots: const [],
        qty: 100,
        unitPrice: 20000,
        feePercent: 4,
        newLotId: 'l1',
        occurredAt: DateTime.utc(2026, 9, 1),
        sourceEventId: 'e1',
      );
      // خرید ۵۰ گرم @ ۲۲٬۰۰۰ با کارمزد ۴٪.
      final b2 = engine.buy(
        asset: silver,
        existingLots: [b1.lot],
        qty: 50,
        unitPrice: 22000,
        feePercent: 4,
        newLotId: 'l2',
        occurredAt: DateTime.utc(2026, 9, 5),
        sourceEventId: 'e2',
      );

      // Cost Basis میانگین:
      //  lot1 = 100×20000 = 2_000_000 ; fee 4% = 80_000 → 2_080_000.
      //  lot2 = 50×22000 = 1_100_000 ; fee 4% = 44_000 → 1_144_000.
      //  totalCost = 3_224_000 ; qty = 150 → avg ≈ 21_493.33.
      final state = AssetState([b1.lot, b2.lot]);
      expect(state.openQuantity, 150);
      expect(state.totalCost, closeTo(3224000, 0.01));

      // فروش ۶۰ گرم @ ۲۵٬۰۰۰ با کارمزد ۴٪.
      final sale = engine.sell(
        asset: silver,
        existingLots: [b1.lot, b2.lot],
        qty: 60,
        unitPrice: 25000,
        feePercent: 4,
        occurredAt: DateTime.utc(2026, 9, 10),
      );
      // saleProceeds = 60×25000 − 4% = 1_500_000 − 60_000 = 1_440_000.
      // costOfSold (avg) = 60 × 21493.33 = 1_289_600.
      // realized = 1_440_000 − 1_289_600 ≈ 150_400 (>0).
      expect(sale.realizedProfit, greaterThan(0));

      // بازدارندگی فروشِ بیش از موجودی (بند ۷۵) — نقره Short ندارد.
      final over = engine.validateSaleQuantity(silver, state, 999);
      expect(over.isErr, true);
    });

    test('بدهی/قسط + پیش‌بینی + گزارش + وحداکثر نقدینگی', () {
      // وام ۱۲ میلیون، ۱۲ قسط بدون بهره.
      final loan = Liability(
          id: 'l1', name: 'وام', kind: LiabilityKind.loan,
          principalMinor: 12000000, currency: Currency.irt,
          startDate: DateTime.utc(2025, 1, 1), installmentsCount: 12);
      final sched = const LiabilitiesEngine().schedule(loan);
      expect(sched.installments, hasLength(12));
      expect(sched.principalTotalMinor, 12000000);

      // پیش‌بینی با ورود/خروج.
      final entries = [
        CalendarEntry(
            id: 'sal', title: 'حقوق', amountMinor: 10000000, currency: Currency.irt,
            direction: CashDirection.inflow, frequency: SeriesFrequency.monthly,
            startDate: DateTime.utc(2025, 1, 1)),
        CalendarEntry(
            id: 'rent', title: 'اجاره', amountMinor: 4000000, currency: Currency.irt,
            direction: CashDirection.outflow, frequency: SeriesFrequency.monthly,
            startDate: DateTime.utc(2025, 1, 5)),
      ];
      final fc = CashFlowForecast(entries);
      final periods = fc.project(
          baseMinor: 5000000, startDate: DateTime.utc(2025, 1, 1),
          period: ForecastPeriod.monthly, count: 3);
      expect(periods[0].netMinor, 6000000); // ورود ۱۰M − خروج ۴M.
      expect(periods[2].balanceMinor, 23000000);
      expect(fc.hasDeficit(periods), false);
    });

    test('داشبورد + واحد مرجع (ریال) + گزارش', () {
      const builder = DashboardBuilder();
      final snap = builder.build(DashboardInput(
        wealthItems: [
          const WealthItem(id: 'cash', name: 'نقد', valueMinor: 50000000, currency: Currency.irt, liquidity: LiquidityClass.liquid),
          const WealthItem(id: 'gold', name: 'طلا', valueMinor: 30000000, currency: Currency.irt, liquidity: LiquidityClass.semiLiquid),
        ],
        transactions: [
          Transaction(id: 't1', userId: 'u', type: TxType.income, amountMinor: 10000000, currency: Currency.irt, occurredAt: DateTime.utc(2026, 9, 1)),
          Transaction(id: 't2', userId: 'u', type: TxType.expense, amountMinor: 2500000, currency: Currency.irt, occurredAt: DateTime.utc(2026, 9, 2), categoryId: 'food', categoryLabelFa: 'خوراک'),
        ],
        prevNetWorthMinor: 70000000,
        currency: Currency.irt,
        refPrice: RefAssetPrice(unit: RefUnit.silverGram, priceRialPerUnit: 40000, asOf: DateTime.utc(2026, 9, 2)),
      ));
      expect(snap.netWorthMinor, 80000000);
      expect(snap.incomeMinor, 10000000);
      expect(snap.expenseMinor, 2500000);
      expect(snap.growth.percent, closeTo(14.2857, 0.01));
      // ۸۰M تومان → ×۱۰ ریال ÷ ۴۰٬۰۰۰ = ۲۰٬۰۰۰ گرم نقره.
      expect(snap.refValue!.quantity, 20000);
      expect(snap.allocation, isNotEmpty);
    });

    test('SMS + Merchant + تکراری در کنار هم', () {
      const parser = SmsParser();
      final sms = parser.parse('بانک ملی: پرداخت موفق به مبلغ ۱٬۲۰۰٬۰۰۰ ریال، فروشگاه دیجی‌پای، تاریخ 1405/06/12');
      expect(sms.isOk, true);
      expect(sms.value!.amountMinor, 1200000);
      expect(sms.value!.bank, 'ملی');

      const rec = MerchantRecognizer();
      expect(rec.detect('فروشگاه دیجی‌پای'), 'دیجی‌پای');

      const det = SmsDuplicateDetector();
      final seen = <String, DateTime>{};
      final a = BankSms(bank: 'ملی', amountMinor: 1200000, txType: 'برداشت', reference: 'r', fromAccount: '', merchantHint: '', raw: 'a', occurredAt: DateTime.utc(2026, 9, 3, 10, 0));
      final b = BankSms(bank: 'ملی', amountMinor: 1200000, txType: 'برداشت', reference: 'r', fromAccount: '', merchantHint: '', raw: 'b', occurredAt: DateTime.utc(2026, 9, 3, 10, 1));
      det.record(a, seen);
      expect(det.isDuplicate(b, seen), true);
    });

    test('ممیزی امنیتی + حل تعارض', () {
      final trail = AuditTrail();
      trail.record(userId: 'u', type: AuditEventType.transactionEdit, subjectId: 't', beforeJson: '{}', afterJson: '{}');
      trail.record(userId: 'u', type: AuditEventType.feeRuleChange, subjectId: 'f');
      expect(trail.length, 2);

      const r = ConflictResolver();
      final res = r.resolve(
          SyncRecord('a', DateTime.utc(2026, 9, 2), '1'),
          SyncRecord('a', DateTime.utc(2026, 9, 3), '1'));
      expect(res.appliedLocalChange, false); // remote نویتر.

      // قفل برنامه.
      final lock = AppLock(const AppLockPolicy(enabled: true, maxAttempts: 3));
      lock.verify('0000', correct: false);
      expect(lock.verify('1234', correct: true).unlocked, true);
    });
  });
}
