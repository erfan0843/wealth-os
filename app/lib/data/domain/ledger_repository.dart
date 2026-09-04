import 'package:wealth_core/wealth_core.dart';

/// قرارداد ثبت/بازیابی رویدادهای مالی و سندهای دوبادگانه — در domain (بند ۹۲).
/// پیاده‌سازی Drift در data/. UI مستقیم با DB کار نمی‌کند.
abstract interface class LedgerRepository {
  /// ثبت اتمیک یک رویداد + سندهایش + به‌روزرسانی Aggregate.
  Future<Result<FinancialEvent>> recordEvent(FinancialEvent event);

  /// صفِ رویدادهای یک بازه (برای گزارش/تاریخچه).
  Future<Result<List<FinancialEvent>>> listEvents(String userId,
      {DateTime? from, DateTime? to, EventKind? kind});

  /// Reversal (بند ۷۴): رویداد قبلی ACTIVE→REVERSED + رویداد برگشت جداگانه.
  Future<Result<FinancialEvent>> reverseEvent(String eventId, String userId);

  /// جمع بده-بستان یک حساب (موجودی/aggregate).
  Future<Result<int>> balanceOf(String accountId, Currency currency);
}
