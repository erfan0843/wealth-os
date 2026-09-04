import 'package:test/test.dart';
import 'package:wealth_core/wealth_core.dart';

void main() {
  const engine = AssetEngine();

  group('AssetEngine — Cost Basis', () {
    test('متوسط میانگین چند خرید (بند ۲۳) — Average', () {
      // خرید ۱: ۱۰۰ گرم @ ۲۰۰۰ → هزینه ۲۰۰٬۰۰۰
      final lot1 = AssetLot(id: 'l1', assetId: 'silver', quantity: 100, unitPrice: 2000,
          costBasisTotal: 200000, openedAt: DateTime.utc(2026, 1, 1));
      // خرید ۲: ۵۰ گرم @ ۲۲۰۰ → هزینه ۱۱۰٬۰۰۰
      final lot2 = AssetLot(id: 'l2', assetId: 'silver', quantity: 50, unitPrice: 2200,
          costBasisTotal: 110000, openedAt: DateTime.utc(2026, 2, 1));
      final state = AssetState([lot1, lot2]);
      expect(state.openQuantity, 150);
      // میانگین = (200000+110000)/150 = 2066.67
      expect(state.avgCostPerUnit, closeTo(2066.666, 0.1));
      expect(state.totalCost, 310000);
    });

    test('FIFO — اولین Lot ابتدا مصرف می‌شود', () {
      final lot1 = AssetLot(id: 'l1', assetId: 's', quantity: 100, unitPrice: 2000,
          costBasisTotal: 200000, openedAt: DateTime.utc(2026, 1, 1));
      final lot2 = AssetLot(id: 'l2', assetId: 's', quantity: 50, unitPrice: 2200,
          costBasisTotal: 110000, openedAt: DateTime.utc(2026, 2, 1));
      // فروش ۱۲۰ گرم در FIFO → ۱۰۰ از Lot1 + ۲۰ از Lot2
      final r = const CostBasisCalculator().fifo([lot1, lot2], 120);
      expect(r.costOfSold, closeTo(100 * 2000 + 20 * 2200, 0.1)); // 244000
      expect(r.consumed.length, 2);
      expect(r.consumed.first.lotId, 'l1');
      expect(r.consumed.first.quantity, 100);
      expect(r.consumed.last.quantity, 20);
    });

    test('فروش تمام موجودی — Cost Basis کامل', () {
      final lot1 = AssetLot(id: 'l1', assetId: 's', quantity: 100, unitPrice: 2000,
          costBasisTotal: 200000, openedAt: DateTime.utc(2026, 1, 1));
      final r = const CostBasisCalculator().fifo([lot1], 100);
      expect(r.costOfSold, 200000);
    });
  });

  group('AssetEngine — خرید/فروش/P&L', () {
    const asset = Asset(id: 'silver', assetTypeCode: 'SILVER', name: 'نقره', unit: 'gram');

    test('خرید: Lot ایجاد و میانگین به‌روزرسانی (با کارمزد)', () {
      final res = engine.buy(
        asset: asset, existingLots: const [], qty: 100, unitPrice: 2000,
        feePercent: 1, newLotId: 'new', occurredAt: DateTime.utc(2026, 9, 1),
        sourceEventId: 'ev1',
      );
      expect(res.lot.quantity, 100);
      // هزینهٔ کل با کارمزد ۱٪ = 200000*1.01 = 202000 → میانگین 2020
      expect(res.lot.costBasisTotal, closeTo(202000, 0.1));
      expect(res.newAvgCostPerUnit, closeTo(2020, 0.1));
      expect(res.newQuantity, 100);
    });

    test('فروش: Realized P&L = درآمد − Cost Basis − کارمزد (بند ۲۶)', () {
      //خرید: ۵۰ گرم @ 3000، میانگین 3000
      final lot = AssetLot(id: 'l', assetId: 'silver', quantity: 50, unitPrice: 3000,
          costBasisTotal: 150000, openedAt: DateTime.utc(2026, 1, 1));
      // فروش ۲۰ گرم @ 4000 با کارمزد ۱٪
      final r = engine.sell(
          asset: asset, existingLots: [lot], qty: 20, unitPrice: 4000,
          feePercent: 1, occurredAt: DateTime.utc(2026, 9, 1));
      expect(r.costOfSold, closeTo(20 * 3000, 0.1)); // 60000
      // درآمد = 20*4000 = 80000 - کارمزد 1% = 79200
      final proceeds = 20 * 4000 * 0.99;
      expect(r.realizedProfit, closeTo(proceeds - 60000, 0.1));
      expect(r.costBasisBefore, 150000);
      expect(r.costBasisRemaining, closeTo(90000, 0.1));
    });

    test('فروش بیش از موجودی را رد می‌کند (بند ۷۵)', () {
      final lot = AssetLot(id: 'l', assetId: 'silver', quantity: 30, unitPrice: 3000,
          costBasisTotal: 90000, openedAt: DateTime.utc(2026, 1, 1));
      final res = engine.validateSaleQuantity(asset, AssetState([lot]), 50);
      expect(res.isErr, isTrue);
      expect(res.error!.code, 'insufficient_quantity');
    });

    test('فروش دقیقاً به اندازهٔ موجودی مجاز است', () {
      final lot = AssetLot(id: 'l', assetId: 'silver', quantity: 30, unitPrice: 3000,
          costBasisTotal: 90000, openedAt: DateTime.utc(2026, 1, 1));
      expect(engine.validateSaleQuantity(asset, AssetState([lot]), 30).isOk, isTrue);
    });

    test('P&L تحقق‌نیافته: ارزش فعلی − هزینهٔ فعلی + درصد', () {
      final lot = AssetLot(id: 'l', assetId: 'silver', quantity: 100, unitPrice: 2000,
          costBasisTotal: 200000, openedAt: DateTime.utc(2026, 1, 1));
      final state = AssetState([lot]);
      final pnl = engine.unrealized(state, 2400);
      expect(pnl.currentValue, 240000);
      expect(pnl.unrealizedMinor, 40000);
      expect(pnl.unrealizedPercent, closeTo(20, 0.1));
    });
  });
}
