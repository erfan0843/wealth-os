/// موتور دفتر کل — رکورد/محاسبه (بند ۱۵-۱۸).
/// خالص و قابل تست. همهٔ محاسبات در Domain (بند ۹۳)، هرگز در UI.
library;

import '../errors/result.dart';
import 'event.dart';

/// نتیجهٔ اعتبارسنجی درستی دفتر کل.
class LedgerValidation {
  final bool valid;
  final AppError? error;
  const LedgerValidation(this.valid, [this.error]);
}

/// موتور خالص دفتر کل.
class LedgerEngine {
  const LedgerEngine();

  /// اعتبارسنجی دبادگانه: مجموع Debit == مجموع Credit (برای رویدادهای متوازن).
  LedgerValidation validateBalanced(Iterable<LedgerEntry> entries) {
    var debit = 0, credit = 0;
    for (final e in entries) {
      if (e.side == Side.debit) {
        debit += e.amount.amountMinor;
      } else {
        credit += e.amount.amountMinor;
      }
    }
    if (debit != credit) {
      return const LedgerValidation(
          false, AppError('unbalanced_ledger', 'دفتر کل متوازن نیست'));
    }
    return const LedgerValidation(true);
  }

  /// جمع خالص برای یک موضوع (Credit مثبت، Debit منفی).
  /// برای حساب: Credit=افزایش، Debit=کاهش.
  int netBalance(Iterable<LedgerEntry> entries) {
    var total = 0;
    for (final e in entries) {
      total += e.side == Side.credit ? e.amount.amountMinor : -e.amount.amountMinor;
    }
    return total;
  }

  /// موجودی یک حساب از روی جمع ورودی‌ها.
  int balanceOf(Iterable<LedgerEntry> entries) => netBalance(entries);

  /// مجموع کمیت (مقدار) برای یک دارایی — مثل گرم باقی‌مانده.
  double quantityOf(Iterable<LedgerEntry> entries, String subjectId) {
    var q = 0.0;
    for (final e in entries) {
      if (e.subjectType == SubjectType.asset && e.subjectId == subjectId &&
          e.quantity != null) {
        q += e.side == Side.debit ? e.quantity! : -e.quantity!;
      }
    }
    return q;
  }

  /// `(اینکه آیا هر رویداد باعث موجودی منفی حساب می‌شود)` — بند ۷۵.
  /// در صورت Short-ot برای دارایی‌ها، از این گذرگاه متفاوت استفاده می‌شود.
  /// اگر `currentBalance + net < 0` → خطای موجودی ناکافی.
  Result<int> afterBalance(List<LedgerEntry> existing, LedgerEntry newEntry,
      {int? priorBalance}) {
    final base = priorBalance ?? netBalance(existing);
    final delta =
        newEntry.side == Side.debit ? -newEntry.amount.amountMinor : newEntry.amount.amountMinor;
    final result = base + delta;
    if (result < 0) {
      return Err(AppError.insufficientFunds);
    }
    return Ok(result);
  }
}

/// ردیابی مقدار (گرم/سهم) در چند رویداد.
class QuantityTracker {
  final Map<String, double> _byId = {};

  void apply(String subjectId, double delta) {
    _byId[subjectId] = (_byId[subjectId] ?? 0) + delta;
  }

  double quantityOf(String subjectId) => _byId[subjectId] ?? 0;
}
