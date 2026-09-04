/// ماژول گزارش‌ها (فاز ۱۳) — بخشی از Reports که به هستهٔ خالص مربوط است.
/// - SpendingByCategory: تجمیع هزینهٔ دسته‌بندی‌ها.
/// - Allocation: سهم هر کلاس دارایی از کل.
/// - Growth: رشد دارایی خالص بین دو نقطه در زمان.
/// - FeesTotal: جمع کارمزدها.
/// RefValue (واحد مرجع) در `reference/ref_asset.dart` است (بند ۵۷).
/// هستهٔ خالص؛ قابل تست.
library;

import '../money/money.dart';

/// یک خطِ هزینه بر اساس دسته.
class CategorySpend {
  final String categoryId;
  final String categoryLabelFa;
  final int totalMinor;
  final Currency currency;

  const CategorySpend({
    required this.categoryId,
    required this.categoryLabelFa,
    required this.totalMinor,
    required this.currency,
  });
}

/// حساب هزینهٔ بابتِ Categories (از تراکنش‌ها).
class SpendAggregator {
  // categoryId → totalMinor (در IRT).
  final Map<String, int> _byId = {};
  final Map<String, String> _labels = {};

  void add({required String categoryId, required String labelFa, required int amountMinor}) {
    _byId[categoryId] = (_byId[categoryId] ?? 0) + amountMinor;
    _labels[categoryId] = labelFa;
  }

  /// مرتبشدهٔ نزولی.
  List<CategorySpend> result() {
    final list = _byId.entries
        .map((e) => CategorySpend(
              categoryId: e.key,
              categoryLabelFa: _labels[e.key] ?? e.key,
              totalMinor: e.value,
              currency: Currency.irt,
            ))
        .toList()
      ..sort((a, b) => b.totalMinor.compareTo(a.totalMinor));
    return list;
  }
}

/// سهم هر کلاس دارایی از کل (Allocation).
class AllocationSlice {
  final String assetClassName;
  final int valueMinor;
  final int totalMinor;

  const AllocationSlice(this.assetClassName, this.valueMinor, this.totalMinor);

  double get share => totalMinor == 0 ? 0 : valueMinor / totalMinor;
}

/// حساب Allocation از یک لیست از (کلاس، ارزش).
class AllocationCalculator {
  const AllocationCalculator();

  List<AllocationSlice> compute(List<(String, int)> values) {
    final total = values.fold<int>(0, (s, v) => s + v.$2);
    return values
        .map((v) => AllocationSlice(v.$1, v.$2, total))
        .toList()
      ..sort((a, b) => b.valueMinor.compareTo(a.valueMinor));
  }
}

/// رشد بین دو ارزش دارایی خالص.
class Growth {
  final int fromMinor;
  final int toMinor;

  const Growth(this.fromMinor, this.toMinor);

  int get deltaMinor => toMinor - fromMinor;

  /// درصد رشد (می‌تواند منفی = کاهش).
  double get percent =>
      fromMinor == 0 ? 0 : (toMinor - fromMinor) / fromMinor * 100;

  bool get isUp => toMinor > fromMinor;
}

/// جمع کارمزدها.
class FeesTotals {
  final Map<String, int> _byRule = {};

  void add({required String ruleId, required int feeMinor}) {
    _byRule[ruleId] = (_byRule[ruleId] ?? 0) + feeMinor;
  }

  int get total => _byRule.values.fold<int>(0, (s, v) => s + v);
  Map<String, int> get byRule => Map.unmodifiable(_byRule);
}

/// گزارش سود و زیان (بند ۵۴).
class PnLReport {
  final int realizedMinor; // سود تحقق‌یافته.
  final int unrealizedMinor; // سود تحقق‌نیافته.
  final int realizedCostMinor; // مجموع بهای تمام‌شدهٔ فروش.
  final int unrealizedCostMinor; // بهای تمام‌شدهٔ دارایی‌های باز.
  final int realizedFeesMinor;
  final int feesMinor;

  const PnLReport({
    required this.realizedMinor,
    required this.unrealizedMinor,
    required this.realizedCostMinor,
    required this.unrealizedCostMinor,
    required this.realizedFeesMinor,
    required this.feesMinor,
  });

  int get totalMinor => realizedMinor + unrealizedMinor;

  double get realizedPercent =>
      realizedCostMinor == 0 ? 0 : realizedMinor / realizedCostMinor * 100;
  double get unrealizedPercent => unrealizedCostMinor == 0
      ? 0
      : unrealizedMinor / unrealizedCostMinor * 100;
}

/// گزارش جریان نقدی (بند ۵۴/۵۱).
class CashFlowReport {
  final int inflowMinor;
  final int outflowMinor;
  final int netMinor;

  const CashFlowReport({
    required this.inflowMinor,
    required this.outflowMinor,
  }) : netMinor = inflowMinor - outflowMinor;
}

/// گزارش دارایی خالص (بند ۵۴/۱۷).
class NetWorthReport {
  final int totalAssetsMinor;
  final int totalLiabilitiesMinor;
  final int netWorthMinor;
  final int liquidMinor;
  final int investmentsMinor;

  const NetWorthReport({
    required this.totalAssetsMinor,
    required this.totalLiabilitiesMinor,
    required this.liquidMinor,
    required this.investmentsMinor,
  }) : netWorthMinor = totalAssetsMinor - totalLiabilitiesMinor;
}

/// دوره‌های رشد ثروت (بند ۵۸).
enum GrowthGranularity { daily, weekly, monthly, yearly }

/// واحد نمایش رشد (بند ۵۸).
enum GrowthUnit { toman, silverGram, goldGram, usd }

/// یک نقطه از سری رشد.
class GrowthPoint {
  final DateTime endOfPeriod;
  final int valueMinor; // ارزش (در ارز/واحد نمایش).

  const GrowthPoint(this.endOfPeriod, this.valueMinor);
}

/// سری رشد ثروت (بند ۵۸): بازه‌های زمانی × واحد.
class WealthGrowthSeries {
  final List<GrowthPoint> points;
  final GrowthGranularity granularity;
  final GrowthUnit unit;

  const WealthGrowthSeries({
    required this.points,
    required this.granularity,
    required this.unit,
  });

  bool get isUp => points.isNotEmpty &&
      points.last.valueMinor >= points.first.valueMinor;
  int get change => points.isNotEmpty
      ? points.last.valueMinor - points.first.valueMinor
      : 0;
}

