/// لایهٔ UseCase برای Dashboard (بند ۵۲-۵۸، تکمیلِ فاز ۱۲ مستر).
/// ترکیبِ موتورهای NetWorth / Spending / Fees / Reference / P&L در یک Snapshot واحد.
/// خروجی‌ها همگی از مدل‌های خالص و قابل‌تست‌اند؛ UI فقط این را رندر می‌کند (بند ۹۲).
/// هستهٔ خالص؛ قابل تست.
library;

import '../ledger/networth.dart';
import '../money/money.dart';
import '../reference/ref_asset.dart';
import '../reports/reports.dart';
import '../transaction/transaction.dart';

/// ورودی Dashboard — همهٔ دادهٔ لازم.
class DashboardInput {
  final List<WealthItem> wealthItems;
  final List<Transaction> transactions;
  final int prevNetWorthMinor; // دارایی خالص ابتدای دورهٔ قبل (برای رشد).
  final RefAssetPrice? refPrice; // واحد مرجع (قیمت ریالِ همان زمان).
  final Currency currency;

  const DashboardInput({
    required this.wealthItems,
    required this.transactions,
    required this.prevNetWorthMinor,
    required this.currency,
    this.refPrice,
  });
}

/// یک کلاسِ دسته‌بندی برای Allocation (از WealthItem نام کلاس).
class _Cls {
  final String name;
  int value;
  _Cls(this.name, this.value);
}

/// Snapshot کامل Dashboard.
class DashboardSnapshot {
  final int netWorthMinor;
  final int totalAssetsMinor;
  final int totalLiabilitiesMinor;
  final int cashMinor; // نقد+بانک.
  final int liquidAssetsMinor;
  final int investmentsMinor; // نقدشوندهٔ غیرنقد به‌اضافهٔ نیمه‌نقدشوندهٔ سرمایه‌ای.
  final int receivablesMinor;
  final int incomeMinor; // درآمد این دوره.
  final int expenseMinor; // هزینه این دوره.
  final int netMinor; // درآمد − هزینه.
  final int feeMinor;
  final Growth growth; // رشد دارایی خالص.
  final List<CategorySpend> spending; // پولم کجا رفت.
  final List<AllocationSlice> allocation; // سهم کلاس‌ها.
  final RefValue? refValue; // معادل واحد مرجع (گرم نقره).

  const DashboardSnapshot({
    required this.netWorthMinor,
    required this.totalAssetsMinor,
    required this.totalLiabilitiesMinor,
    required this.cashMinor,
    required this.liquidAssetsMinor,
    required this.investmentsMinor,
    required this.receivablesMinor,
    required this.incomeMinor,
    required this.expenseMinor,
    required this.netMinor,
    required this.feeMinor,
    required this.growth,
    required this.spending,
    required this.allocation,
    this.refValue,
  });

  int get cashFlowMinor => netMinor;
  bool get isGrowing => growth.isUp;
}

/// انبوه‌سازِ Dashboard.
class DashboardBuilder {
  const DashboardBuilder();

  /// ترکیبِ همه‌چیز از ورودی.
  DashboardSnapshot build(DashboardInput input) {
    // ۱) دارایی خالص و نقدینگی — تفکیک دارایی/بدهی.
    final assets = <WealthItem>[];
    final liabilities = <WealthItem>[];
    for (final w in input.wealthItems) {
      if (w.isLiability) {
        liabilities.add(w);
      } else {
        assets.add(w);
      }
    }
    final nw = NetWorthCalculator().calculate(
      assets: assets,
      liabilities: liabilities,
      currency: input.currency,
    );

    // ۲) درآمد/هزینه این دوره (تراکنش‌های فعال؟ همه ورودی است).
    var income = 0, expense = 0, fee = 0;
    final spend = SpendAggregator();
    for (final t in input.transactions) {
      switch (t.type) {
        case TxType.income:
          income += t.amountMinor;
        case TxType.expense:
          expense += t.amountMinor;
          spend.add(
            categoryId: t.categoryId ?? 'other',
            labelFa: t.categoryLabelFa ?? 'سایر',
            amountMinor: t.amountMinor,
          );
        default:
          break;
      }
    }

    // ۳) تخصیص بر اساس نام/کلاسِ آیتم‌ها (غیراز طلب/بدهی).
    final classes = <String, _Cls>{};
    var totalAlloc = 0;
    for (final w in input.wealthItems) {
      if (w.isReceivable) continue;
      final key = _poolFor(w);
      classes.putIfAbsent(key, () => _Cls(key, 0)).value += w.valueMinor;
      totalAlloc += w.valueMinor;
    }
    final slices = classes.values
        .map((c) => AllocationSlice(c.name, c.value, totalAlloc))
        .toList()
      ..sort((a, b) => b.valueMinor.compareTo(a.valueMinor));

    // ۴) سرمایه‌گذاری = نیمه‌نقدشونده + غیرنقدشونده (کل − نقد − طلب).
    final investments = nw.totalAssetsMinor - nw.cashMinor - nw.receivablesMinor;

    // ۵) رشد.
    final growth = Growth(input.prevNetWorthMinor, nw.netWorthMinor);

    // ۶) واحد مرجع (فقط اگر قیمت ریالی دادیم).
    final RefValue? ref = input.refPrice == null
        ? null
        : const RefAssetEngine().calculate(
            amountMinor: nw.netWorthMinor,
            currency: input.currency,
            refPrice: input.refPrice!,
          );

    return DashboardSnapshot(
      netWorthMinor: nw.netWorthMinor,
      totalAssetsMinor: nw.totalAssetsMinor,
      totalLiabilitiesMinor: nw.totalLiabilitiesMinor,
      cashMinor: nw.cashMinor,
      liquidAssetsMinor: nw.liquidAssetsMinor,
      investmentsMinor: investments,
      receivablesMinor: nw.receivablesMinor,
      incomeMinor: income,
      expenseMinor: expense,
      netMinor: income - expense,
      feeMinor: fee,
      growth: growth,
      spending: spend.result(),
      allocation: slices,
      refValue: ref,
    );
  }

  String _poolFor(WealthItem w) {
    switch (w.liquidity) {
      case LiquidityClass.liquid:
        return 'نقد و بانک';
      case LiquidityClass.semiLiquid:
        return 'نیمه‌نقدشونده (طلا/نقره/ارز)';
      case LiquidityClass.nonLiquid:
        return 'غیرنقدشونده (ملک/خودرو/...)';
    }
  }
}
