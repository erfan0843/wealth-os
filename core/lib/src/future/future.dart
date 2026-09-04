/// ماژول «آینده» — تقویمِ تکرار و پیش‌بینی جریان نقدی (فاز ۱۲).
/// - CalendarEntry: ورودی ورود/خروج نقدی با تکرار (یک‌بار/روزانه/هفتگی/ماهانه/سالانه).
/// - محاسبهٔ رخداد بعدی و رخدادهای بین یک بازه.
/// - CashFlowForecast: پیش‌بینی درآمد/هزینه/تراز برای N دوره از پایهٔ نقدی.
/// هستهٔ خالص؛ قابل تست. تاریخ‌ها با DateTime (تبدیل شمسی در لایهٔ نمایش).
library;

import '../money/money.dart';

/// جهت جریان نقدی.
enum CashDirection { inflow, outflow }

/// تکرار یک ورودی تقویم.
enum SeriesFrequency { once, daily, weekly, monthly, yearly }

/// یک ورودی تقویم (ورودی/خروجی دوره‌ای).
class CalendarEntry {
  final String id;
  final String title;
  final int amountMinor;
  final Currency currency;
  final CashDirection direction;
  final SeriesFrequency frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final int? interval; // برای weekly/monthly: هر چند واحد (پیش‌فرض ۱).

  const CalendarEntry({
    required this.id,
    required this.title,
    required this.amountMinor,
    required this.currency,
    required this.direction,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.interval,
  });

  bool get isExpired => endDate != null && endDate!.isBefore(DateTime.now());
}

/// دورهٔ پیش‌بینی.
enum ForecastPeriod {
  weekly(7),
  biweekly(14),
  monthly(30),
  quarterly(91),
  yearly(365);

  final int days;
  const ForecastPeriod(this.days);
}

/// تقویم آینده — محاسبهٔ رخدادها (تکرار درست).
class FutureCalendar {
  const FutureCalendar();

  /// اولین رخداد پس از `after` (شامل if دقیقاً بعدی).
  DateTime? nextOccurrence(CalendarEntry e, DateTime after) {
    final occ = _occurrenceAfter(e, after);
    if (occ == null) return null;
    if (e.endDate != null && occ.isAfter(e.endDate!)) return null;
    return occ;
  }

  /// همهٔ رخدادها در بازهٔ [from, to).
  List<DateTime> occurrencesBetween(
      CalendarEntry e, DateTime from, DateTime to) {
    final out = <DateTime>[];
    DateTime? d = e.startDate;
    if (!d.isAfter(from)) {
      d = _occurrenceAfter(e, from);
    }
    if (d == null) return out;
    while (d != null && d.isBefore(to)) {
      if (e.endDate != null && d.isAfter(e.endDate!)) break;
      out.add(d);
      d = _stepNext(e, d);
    }
    return out;
  }

  DateTime? _occurrenceAfter(CalendarEntry e, DateTime after) {
    if (e.frequency == SeriesFrequency.once) {
      return e.startDate.isAfter(after) ? e.startDate : null;
    }
    DateTime? d = e.startDate;
    // جلو رفتن تا اولین رخداد پس از after.
    while (d != null && !d.isAfter(after)) {
      d = _stepNext(e, d);
    }
    return d;
  }

  DateTime? _stepNext(CalendarEntry e, DateTime d) {
    final n = e.interval ?? 1;
    switch (e.frequency) {
      case SeriesFrequency.once:
        return null;
      case SeriesFrequency.daily:
        return d.add(Duration(days: n));
      case SeriesFrequency.weekly:
        return d.add(Duration(days: 7 * n));
      case SeriesFrequency.monthly:
        return _addMonths(d, n);
      case SeriesFrequency.yearly:
        return DateTime.utc(d.year + n, d.month, d.day);
    }
  }

  /// افزودن چند ماه با رعایت روز (clamp به آخرین روز ماهِ کوتاه).
  DateTime _addMonths(DateTime d, int months) {
    var y = d.year;
    var m = d.month + months;
    while (m > 12) {
      m -= 12;
      y += 1;
    }
    final lastDay = DateTime.utc(y, m + 1, 0).day;
    final day = d.day > lastDay ? lastDay : d.day;
    return DateTime.utc(y, m, day);
  }
}

/// حاصل یک دورهٔ پیش‌بینی.
class ForecastPeriodResult {
  final DateTime start;
  final DateTime end;
  final int inflowMinor;
  final int outflowMinor;
  final int netMinor;
  final int balanceMinor;

  const ForecastPeriodResult({
    required this.start,
    required this.end,
    required this.inflowMinor,
    required this.outflowMinor,
    required this.netMinor,
    required this.balanceMinor,
  });

  bool get negativeBalance => balanceMinor < 0;
}

/// پیش‌بینی جریان نقدی.
class CashFlowForecast {
  final List<CalendarEntry> _entries;
  final FutureCalendar _cal;
  const CashFlowForecast(this._entries, [this._cal = const FutureCalendar()]);

  /// پیش‌بینی برای `count` دوره از `startDate` با پایهٔ نقدی `baseMinor`.
  List<ForecastPeriodResult> project({
    required int baseMinor,
    required DateTime startDate,
    required ForecastPeriod period,
    required int count,
    String currencyCode = 'IRT',
  }) {
    final out = <ForecastPeriodResult>[];
    var balance = baseMinor;
    for (var i = 0; i < count; i++) {
      final pStart = startDate.add(Duration(days: period.days * i));
      final pEnd = pStart.add(Duration(days: period.days));
      var inflow = 0;
      var outflow = 0;
      for (final e in _entries) {
        if (e.currency.code != currencyCode) continue;
        final occ = _cal.nextOccurrence(e, pStart.subtract(const Duration(days: 1)));
        if (occ != null && !occ.isBefore(pStart) && occ.isBefore(pEnd)) {
          if (e.direction == CashDirection.inflow) {
            inflow += e.amountMinor;
          } else {
            outflow += e.amountMinor;
          }
        }
      }
      final net = inflow - outflow;
      balance += net;
      out.add(ForecastPeriodResult(
        start: pStart,
        end: pEnd,
        inflowMinor: inflow,
        outflowMinor: outflow,
        netMinor: net,
        balanceMinor: balance,
      ));
    }
    return out;
  }

  /// حداقل تراز پیش‌بینی‌شده (برای هشدار ریسک نقدینگی).
  int minBalanceMinor(List<ForecastPeriodResult> periods) => periods.fold<int>(
      0, (m, p) => p.balanceMinor < m ? p.balanceMinor : m);

  /// آیا دوره‌ای تراز منفی دارد؟ (کمبود نقدینگی)
  bool hasDeficit(List<ForecastPeriodResult> periods) =>
      periods.any((p) => p.negativeBalance);
}
