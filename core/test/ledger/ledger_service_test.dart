import 'package:test/test.dart';
import 'package:wealth_core/wealth_core.dart';

void main() {
  group('LedgerService — ساخت رویداد', () {
    const svc = LedgerService();

    test('هزینه: حساب کاهش (Credit) — متوازن', () {
      final ev = svc.buildExpense(
        id: 'e1', userId: 'u1', fromAccountId: 'bank',
        amount: const Money(350000, Currency.irt),
        occurredAt: DateTime.utc(2026, 9, 3),
      );
      expect(ev.kind, EventKind.expense);
      expect(ev.entries.length, 2);
      expect(svc.engine.validateBalanced(ev.entries).valid, isTrue);
    });

    test('انتقال بین دو حساب: خنثی — نه درآمد نه هزینه', () {
      final ev = svc.buildTransfer(
        id: 't1', userId: 'u1', fromAccountId: 'bankA', toAccountId: 'bankB',
        amount: const Money(500000, Currency.irt),
        occurredAt: DateTime.utc(2026, 9, 3),
      );
      expect(ev.kind, EventKind.transfer);
      // جمع خالص سراسری صفر است (مبادلهٔ خنثی).
      expect(svc.engine.netBalance(ev.entries), 0);
    });

    test('خرید دارایی = مبادله (نه هزینه)؛ مقدار دارایی Debit می‌شود', () {
      final ev = svc.buildAssetBuy(
        id: 'b1', userId: 'u1', cashAccountId: 'bank', assetId: 'silver',
        amount: const Money(1000000, Currency.irt),
        quantity: 20, unit: 'gram', occurredAt: DateTime.utc(2026, 9, 3),
      );
      expect(ev.kind, EventKind.assetBuy);
      expect(svc.engine.validateBalanced(ev.entries).valid, isTrue);
      // مقدار دارایی ۲۰ گرم.
      expect(svc.engine.quantityOf(ev.entries, 'silver'), 20);
    });

    test('فروش دارایی = مبادله (نه درآمد)؛ مقدار دارایی Credit می‌شود', () {
      final ev = svc.buildAssetSale(
        id: 's1', userId: 'u1', cashAccountId: 'bank', assetId: 'silver',
        amount: const Money(900000, Currency.irt),
        quantity: 10, unit: 'gram', occurredAt: DateTime.utc(2026, 9, 3),
      );
      expect(ev.kind, EventKind.assetSale);
      // مقدار دارایی منفی می‌شود (خروج).
      expect(svc.engine.quantityOf(ev.entries, 'silver'), -10);
    });

    test('کارمزد در خرید: دو سند متوازن اضافه می‌کند', () {
      final ev = svc.buildAssetBuy(
        id: 'b2', userId: 'u1', cashAccountId: 'bank', assetId: 'gold',
        amount: const Money(1000000, Currency.irt),
        quantity: 5, unit: 'gram', occurredAt: DateTime.utc(2026, 9, 3),
        fee: 1.0,
      );
      expect(ev.entries.length, 4); // 2 اصلی + 2 کارمزد
      expect(svc.engine.validateBalanced(ev.entries).valid, isTrue);
    });
  });
}
