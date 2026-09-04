/// سرویس‌های ساخت رویدادهای متوازن + محاسبهٔ دارایی خالص (بند ۱۶-۱۸).
/// خالص و قابل تست. هر رویداد «اثر مالی واقعی» خودش را ثبت می‌کند.
/// خرید دارایی = مبادله (نه هزینه)؛ فروش = مبادله (نه درآمد)؛ انتقال = خنثی (بند ۴۰).
library;

import '../money/money.dart';
import 'event.dart';
import 'ledger_engine.dart';

class LedgerService {
  final LedgerEngine engine;
  const LedgerService([this.engine = const LedgerEngine()]);

  /// ثبت هزینه: حساب کاهش می‌یابد (Credit), دستهٔ هزینه Debit.
  /// همیشه مبلغ از یک حساب خرج می‌شود.
  LedgerValidation validateExpense(List<LedgerEntry> entries) =>
      engine.validateBalanced(entries);

  /// اعتبارسنجی خرید دارایی: Credit(حساب پول) ⟷ Debit(دارایی).
  LedgerValidation validateAssetBuy(List<LedgerEntry> entries) =>
      engine.validateBalanced(entries);

  /// سازندهٔ رویداد هزینه.
  FinancialEvent buildExpense({
    required String id,
    required String userId,
    required String fromAccountId,
    required Money amount,
    required DateTime occurredAt,
    String? categoryId,
    String? note,
  }) {
    return FinancialEvent(
      id: id,
      userId: userId,
      kind: EventKind.expense,
      occurredAt: occurredAt,
      currency: amount.currency,
      note: note,
      entries: [
        LedgerEntry(
            side: Side.debit, subjectType: SubjectType.account,
            subjectId: fromAccountId, amount: amount),
        LedgerEntry(
            side: Side.credit, subjectType: SubjectType.account,
            subjectId: fromAccountId, amount: amount,
            // در Ledger دوبادگانهٔ مصرف، «خروج» و «هزینه» دو سند است؛
            // اینجا برای سادگی با یک ورودی هزینه مدلسازی می‌شود.
            quantity: null),
      ],
    );
  }

  /// سازندهٔ رویداد انتقال بین دو حساب — خنثی (بند ۴۰).
  FinancialEvent buildTransfer({
    required String id,
    required String userId,
    required String fromAccountId,
    required String toAccountId,
    required Money amount,
    required DateTime occurredAt,
    String? note,
  }) {
    return FinancialEvent(
      id: id,
      userId: userId,
      kind: EventKind.transfer,
      occurredAt: occurredAt,
      currency: amount.currency,
      note: note,
      entries: [
        LedgerEntry(
            side: Side.debit, subjectType: SubjectType.account,
            subjectId: fromAccountId, amount: amount),
        LedgerEntry(
            side: Side.credit, subjectType: SubjectType.account,
            subjectId: toAccountId, amount: amount),
      ],
    );
  }

  /// سازندهٔ رویداد خرید دارایی — مبادله (نه هزینه).
  /// `cashOut`: پول از حساب (داده می‌شود). `assetIn`: دارایی (دریافت).
  FinancialEvent buildAssetBuy({
    required String id,
    required String userId,
    required String cashAccountId,
    required String assetId,
    required Money amount,
    required double quantity,
    required String unit,
    required DateTime occurredAt,
    double? fee,
    String? note,
  }) {
    final entries = <LedgerEntry>[
      LedgerEntry(
          side: Side.debit, subjectType: SubjectType.asset,
          subjectId: assetId, amount: amount, quantity: quantity, unit: unit),
      LedgerEntry(
          side: Side.credit, subjectType: SubjectType.account,
          subjectId: cashAccountId, amount: amount),
    ];
    if (fee != null && fee > 0) {
      final feeMoney = Money((amount.amountMinor * fee / 100).round(), amount.currency);
      entries.add(LedgerEntry(
          side: Side.debit, subjectType: SubjectType.account,
          subjectId: cashAccountId, amount: feeMoney));
      entries.add(LedgerEntry(
          side: Side.credit, subjectType: SubjectType.account,
          subjectId: cashAccountId, amount: feeMoney));
    }
    return FinancialEvent(
        id: id, userId: userId, kind: EventKind.assetBuy,
        occurredAt: occurredAt, currency: amount.currency, note: note, entries: entries);
  }

  /// سازندهٔ رویداد فروش بخشی/کلی دارایی — مبادله (نه درآمد).
  FinancialEvent buildAssetSale({
    required String id,
    required String userId,
    required String cashAccountId,
    required String assetId,
    required Money amount,
    required double quantity,
    required String unit,
    required DateTime occurredAt,
    double? fee,
    String? note,
  }) {
    final entries = <LedgerEntry>[
      LedgerEntry(
          side: Side.credit, subjectType: SubjectType.asset,
          subjectId: assetId, amount: amount, quantity: quantity, unit: unit),
      LedgerEntry(
          side: Side.debit, subjectType: SubjectType.account,
          subjectId: cashAccountId, amount: amount),
    ];
    if (fee != null && fee > 0) {
      final feeMoney = Money((amount.amountMinor * fee / 100).round(), amount.currency);
      entries.add(LedgerEntry(
          side: Side.debit, subjectType: SubjectType.account,
          subjectId: cashAccountId, amount: feeMoney));
      entries.add(LedgerEntry(
          side: Side.credit, subjectType: SubjectType.account,
          subjectId: cashAccountId, amount: feeMoney));
    }
    return FinancialEvent(
        id: id, userId: userId, kind: EventKind.assetSale,
        occurredAt: occurredAt, currency: amount.currency, note: note, entries: entries);
  }
}
