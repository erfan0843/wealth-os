import 'package:test/test.dart';
import 'package:wealth_core/wealth_core.dart';

void main() {
  const cal = FutureCalendar();

  CalendarEntry monthlyOut({String id = 'rent', int amount = 2000000, DateTime? start}) =>
      CalendarEntry(
        id: id,
        title: 'اجاره',
        amountMinor: amount,
        currency: Currency.irt,
        direction: CashDirection.outflow,
        frequency: SeriesFrequency.monthly,
        startDate: start ?? DateTime.utc(2025, 5, 1),
      );

  group('FutureCalendar — تقویم تکرار (فاز ۱۲)', () {
    test('ماهانه — رخداد بعدی پس از تاریخ', () {
      final next = cal.nextOccurrence(monthlyOut(), DateTime.utc(2025, 6, 15));
      expect(next, DateTime.utc(2025, 7, 1));
    });

    test('ماهانه — clamp روز آخری ماه کوتاه', () {
      final e = CalendarEntry(
        id: 'sal',
        title: 'حقوق',
        amountMinor: 100,
        currency: Currency.irt,
        direction: CashDirection.inflow,
        frequency: SeriesFrequency.monthly,
        startDate: DateTime.utc(2025, 1, 31),
      );
      // از ۳۱ بهمن ۲۰۲۵ → ۲۸ فوریه.
      final next = cal.nextOccurrence(e, DateTime.utc(2025, 1, 31));
      expect(next, DateTime.utc(2025, 2, 28));
      // از ۲۸ فوریه → ۳۱ مارس.
      final n2 = cal.nextOccurrence(e, DateTime.utc(2025, 2, 28));
      expect(n2, DateTime.utc(2025, 3, 31));
    });

    test('هفتگی — همان روز هفته', () {
      final e = CalendarEntry(
        id: 'gym',
        title: 'اشتراک',
        amountMinor: 500,
        currency: Currency.irt,
        direction: CashDirection.outflow,
        frequency: SeriesFrequency.weekly,
        startDate: DateTime.utc(2025, 6, 2), // دوشنبه.
      );
      final next = cal.nextOccurrence(e, DateTime.utc(2025, 6, 3));
      expect(next, DateTime.utc(2025, 6, 9));
    });

    test('رخدادهای بازه — تعداد درست', () {
      final occ = cal.occurrencesBetween(
          monthlyOut(start: DateTime.utc(2025, 5, 1)),
          DateTime.utc(2025, 5, 1),
          DateTime.utc(2025, 8, 1));
      expect(occ, hasLength(3)); // ۱/۵، ۱/۶، ۱/۷.
    });
  });

  group('CashFlowForecast — پیش‌بینی جریان نقدی (فاز ۱۲)', () {
    test('تراز چرخشی — ورود حقوق منهای اجاره', () {
      final entries = [
        CalendarEntry(
          id: 'sal',
          title: 'حقوق',
          amountMinor: 10000000,
          currency: Currency.irt,
          direction: CashDirection.inflow,
          frequency: SeriesFrequency.monthly,
          startDate: DateTime.utc(2025, 5, 1),
        ),
        monthlyOut(start: DateTime.utc(2025, 5, 5)),
      ];
      final fc = CashFlowForecast(entries);
      final periods = fc.project(
        baseMinor: 5000000,
        startDate: DateTime.utc(2025, 5, 1),
        period: ForecastPeriod.monthly,
        count: 3,
      );
      expect(periods, hasLength(3));
      expect(periods[0].inflowMinor, 10000000);
      expect(periods[0].outflowMinor, 2000000);
      expect(periods[0].netMinor, 8000000);
      expect(periods[0].balanceMinor, 13000000); // ۵M + ۸M.
      expect(periods[2].balanceMinor, 29000000); // ۱۳M + ۸M + ۸M.
    });

    test('هشدار کمبود نقدینگی', () {
      final entries = [monthlyOut(amount: 5000000, start: DateTime.utc(2025, 5, 5))];
      final fc = CashFlowForecast(entries);
      final periods = fc.project(
        baseMinor: 3000000,
        startDate: DateTime.utc(2025, 5, 1),
        period: ForecastPeriod.monthly,
        count: 2,
      );
      expect(fc.hasDeficit(periods), true);
      // دورهٔ ۱: ۳M − ۵M = −۲M؛ دورهٔ ۲: −۲M − ۵M = −۷M.
      expect(periods[0].balanceMinor, -2000000);
      expect(fc.minBalanceMinor(periods), -7000000);
    });

    test('فقط ورودی‌های با ارز مشخص شمرده می‌شوند', () {
      final entries = [
        CalendarEntry(
          id: 'usd',
          title: 'درآمد دلاری',
          amountMinor: 1000,
          currency: Currency.usd,
          direction: CashDirection.inflow,
          frequency: SeriesFrequency.monthly,
          startDate: DateTime.utc(2025, 5, 1),
        ),
        monthlyOut(amount: 2000000, start: DateTime.utc(2025, 5, 5)),
      ];
      final fc = CashFlowForecast(entries);
      final periods = fc.project(
        baseMinor: 1000000,
        startDate: DateTime.utc(2025, 5, 1),
        period: ForecastPeriod.monthly,
        count: 1,
      );
      // ورودی دلاری نادیده گرفته می‌شود؛ فقط خروجی تومن.
      expect(periods[0].inflowMinor, 0);
      expect(periods[0].outflowMinor, 2000000);
    });
  });
}
