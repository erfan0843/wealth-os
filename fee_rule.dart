/// قوانین کارمزد (بند ۳۲-۳۶).
/// - انواع کارمزد: Buy / Sell / Transfer / Commission / Tax (بند ۳۲).
/// - نوع نرخ: Percent / Fixed / Percent+Fixed، با حداقل/حداکثر (بند ۳۶).
/// - اولویت ۶-سطّی (بند ۳۵): Transaction‎‏ > Asset > AssetType > User > Global > Default.
/// - قوانین زمانی/روز-هفته/مقداری/مبلغی/تاریخی (بند ۳۳-۳۴).
/// - Snapshot در لحظه (بند ۳۷) و Manual Override (بند ۳۸).
/// هستهٔ خالص؛ قابل تست.
library;

/// کاربرد کارمزد (بند ۳۲).
enum FeeKind { buy, sell, transfer, commission, tax }

/// ترتیب اولویت (بند ۳۵) — عدد بالاتر = اولویت بیشتر.
enum FeePriority {
  /// Transaction-specific override (بالاترین).
  transactionSpecific(6),
  asset(5),
  assetType(4),
  user(3),
  global(2),
  fallback(1);

  final int rank;
  const FeePriority(this.rank);
}

/// نوع نرخ (بند ۳۶).
enum FeeRateType { percent, fixed, percentPlusFixed }

/// ساختار نرخ + حداقل/حداکثر (بند ۳۶).
class FeeRate {
  final FeeRateType type;
  final num percent; // درصد (برای percent / percentPlusFixed).
  final num fixed; // مبلغ ثابت (برای fixed / percentPlusFixed).
  final num? minimum; // کِفِ کارمزد.
  final num? maximum; // سقف کارمزد.

  const FeeRate({
    this.type = FeeRateType.percent,
    this.percent = 0,
    this.fixed = 0,
    this.minimum,
    this.maximum,
  });

  const FeeRate.fixedAmount(num f) : this(type: FeeRateType.fixed, fixed: f);
  const FeeRate.percentOnly(num p) : this(type: FeeRateType.percent, percent: p);

  /// محاسبهٔ کارمزد از مبلغ ناخالص.
  num compute(num gross) {
    var fee = switch (type) {
      FeeRateType.percent => gross * percent / 100,
      FeeRateType.fixed => fixed,
      FeeRateType.percentPlusFixed => gross * percent / 100 + fixed,
    };
    if (minimum != null && fee < minimum!) fee = minimum!;
    if (maximum != null && fee > maximum!) fee = maximum!;
    return fee;
  }
}

/// شرایط اجرای قانون (بند ۳۳-۳۴).
class FeeConditions {
  final TimeWindow? timeWindow; // بند ۳۳: ساعت واقعی تراکنش.
  final Set<int>? dayOfWeek; // بند ۳۴ (دوشنبه=1 ... شنبه=6).
  final num? minQuantity; // حداقل مقدار.
  final num? maxQuantity;
  final num? minAmount;
  final num? maxAmount;
  final bool isBuy; // فقط خرید.
  final bool isSell; // فقط فروش.
  final DateTime? effectiveFrom; // start date.
  final DateTime? effectiveTo; // end date.

  const FeeConditions({
    this.timeWindow,
    this.dayOfWeek,
    this.minQuantity,
    this.maxQuantity,
    this.minAmount,
    this.maxAmount,
    this.isBuy = false,
    this.isSell = false,
    this.effectiveFrom,
    this.effectiveTo,
  });

  bool matches(FeeContext c) {
    if (timeWindow != null && !timeWindow!.contains(c.timeOfDay)) return false;
    if (dayOfWeek != null && !dayOfWeek!.contains(c.dayOfWeek)) return false;
    if (minQuantity != null && c.quantity != null && c.quantity! < minQuantity!) return false;
    if (maxQuantity != null && c.quantity != null && c.quantity! > maxQuantity!) return false;
    if (minAmount != null && c.amount < minAmount!) return false;
    if (maxAmount != null && c.amount > maxAmount!) return false;
    if (isBuy && c.kind != FeeKind.buy) return false;
    if (isSell && c.kind != FeeKind.sell) return false;
    if (effectiveFrom != null && c.at.isBefore(effectiveFrom!)) return false;
    if (effectiveTo != null && c.at.isAfter(effectiveTo!)) return false;
    return true;
  }
}

/// بازهٔ زمانی روز (بند ۳۳). اگر start > end یعنی شب (عبور از نیمه‌شب).
class TimeWindow {
  final int startMinute; // دقیقه از ۰۰:۰۰.
  final int endMinute;

  const TimeWindow(this.startMinute, this.endMinute);

  bool contains(int minute) {
    if (startMinute <= endMinute) {
      return minute >= startMinute && minute <= endMinute;
    }
    return minute >= startMinute || minute <= endMinute; // شب عبوری.
  }
}

/// یک قانون کارمزد.
class FeeRule {
  final String id;
  final FeeKind kind;
  final FeePriority priority;
  final FeeRate rate;
  final String? assetId; // asset-specific.
  final String? assetTypeId; // asset-type-specific.
  final String? userId; // user-specific.
  final FeeConditions conditions;

  const FeeRule({
    required this.id,
    required this.kind,
    required this.priority,
    required this.rate,
    this.assetId,
    this.assetTypeId,
    this.userId,
    this.conditions = const FeeConditions(),
  });
}

/// زمینهٔ مبلغ، مقدار و زمانِ یک معامله.
class FeeContext {
  final FeeKind kind;
  final num amount; // مبلغ ناخالص.
  final num? quantity; // مقدار (برای دارایی).
  final DateTime at;
  final String? assetId;
  final String? assetTypeId;
  final String? userId;

  const FeeContext({
    required this.kind,
    required this.amount,
    required this.at,
    this.quantity,
    this.assetId,
    this.assetTypeId,
    this.userId,
  });

  int get dayOfWeek => at.weekday; // دوشنبه=1 ... شنبه=6 (ISO).
  int get timeOfDay => at.hour * 60 + at.minute;
}

/// اسنیپ‌شات قانون (بند ۳۷): پس از ثبت Transaction ثابت می‌ماند.
class FeeRuleSnapshot {
  final String ruleId;
  final FeeRate rate;
  final FeeKind kind;
  final DateTime capturedAt;

  const FeeRuleSnapshot({
    required this.ruleId,
    required this.rate,
    required this.kind,
    required this.capturedAt,
  });
}

/// Manual Override (بند ۳۸).
class FeeOverride {
  final String ruleId;
  final num? overrideRate;
  final num? overridePercent;
  final DateTime at;
  final String? reason;

  const FeeOverride({
    required this.ruleId,
    this.overrideRate,
    this.overridePercent,
    required this.at,
    this.reason,
  });
}
