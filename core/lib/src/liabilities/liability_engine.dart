/// موتور بدهی/طلب/تعهدات (فاز ۱۱).
/// - برنامهٔ بازپرداخت (Amortization) برای قسط مساوی/ثابت.
/// - اصل مانده، بهرهٔ کل، وام خالص (بدهی − طلب).
/// - تشخیص قسط/چک سررسیدشده (Overdue).
/// - تعهد دورهای و سررسید بعدی.
/// هستهٔ خالص؛ قابل تست.
library;

import '../money/money.dart';
import 'liability.dart';

/// نتیجهٔ ساخت برنامهٔ بازپرداخت.
class ScheduleResult {
  final List<Installment> installments;
  final int principalTotalMinor;
  final int interestTotalMinor;

  const ScheduleResult(this.installments, {
    required this.principalTotalMinor,
    required this.interestTotalMinor,
  });
}

/// موتور بدهی و تعهدات.
class LiabilitiesEngine {
  const LiabilitiesEngine();

  /// نرخ بهرهٔ دوره‌ای بر مبنای درصد سالانه.
  double _periodRate(Liability l) {
    if (!l.hasInterest) return 0;
    final perYear = switch (l.frequency) {
      RepaymentFrequency.weekly => 52.0,
      RepaymentFrequency.biweekly => 26.0,
      RepaymentFrequency.monthly => 12.0,
      RepaymentFrequency.quarterly => 4.0,
      RepaymentFrequency.yearly => 1.0,
    };
    return l.interestRatePercent / 100 / perYear;
  }

  /// قسط مساوی (ارزش فعلی) — M = P·r / (1 − (1+r)^−n).
  double _equalPayment(Liability l, double r, int n) {
    if (r == 0) return l.principalMinor / n;
    final pow = (1 + r);
    return l.principalMinor * r / (1 - 1 / _pow(pow, n));
  }

  double _pow(double base, int exp) {
    var r = 1.0;
    for (var i = 0; i < exp; i++) {
      r *= base;
    }
    return r;
  }

  /// ساخت برنامهٔ بازپرداخت (Amortization).
  ScheduleResult schedule(Liability l, {int? atInstallments}) {
    final n = atInstallments ?? l.installmentsCount;
    final r = _periodRate(l);
    final payment = _equalPayment(l, r, n);
    var remaining = l.principalMinor.toDouble();
    final result = <Installment>[];
    var totalInt = 0;
    final step = _stepDays(l.frequency);

    for (var i = 0; i < n; i++) {
      final due = l.startDate.add(Duration(days: step * (i + 1)));
      final interest = (remaining * r).round();
      var principal = (payment - interest).round();
      if (principal > remaining) principal = remaining.round();
      // قسط آخر: باقی‌مانده را دقیقاً خالص می‌کند (قبل از تفریق).
      if (i == n - 1) principal = remaining.round();
      remaining -= principal;
      totalInt += interest;
      result.add(Installment(
        index: i + 1,
        dueDate: due,
        principalMinor: principal,
        interestMinor: interest,
      ));
    }
    return ScheduleResult(
      result,
      principalTotalMinor: l.principalMinor,
      interestTotalMinor: totalInt,
    );
  }

  int _stepDays(RepaymentFrequency f) => switch (f) {
        RepaymentFrequency.weekly => 7,
        RepaymentFrequency.biweekly => 14,
        RepaymentFrequency.monthly => 30,
        RepaymentFrequency.quarterly => 91,
        RepaymentFrequency.yearly => 365,
      };

  /// اصل ماندهٔ باقی‌مانده بر اساس قسط‌های پرداخت‌شده.
  int outstandingPrincipalMinor(List<Installment> installments) {
    var outstanding = 0;
    for (final i in installments) {
      if (i.status == InstallmentStatus.paid) continue;
      outstanding += i.principalMinor;
    }
    return outstanding;
  }

  /// بهرهٔ کل یک بدهی.
  int totalInterestMinor(Liability l) => schedule(l).interestTotalMinor;

  /// وام خالص (بدهی‌ها − طلب‌ها). منفی یعنی خالص طلبکار.
  int netPositionMinor({
    required List<Liability> debts,
    required List<Check> receivables,
  }) {
    final debtTotal = debts.fold<int>(
        0, (s, d) => s + outstandingPrincipalMinor(schedule(d).installments));
    final recvTotal = receivables
        .where((c) => c.kind == CheckKind.receivable)
        .fold<int>(0, (s, c) => s + c.amountMinor);
    return debtTotal - recvTotal;
  }

  /// قسط‌های سررسیدشده (overdue) — برای هشدار.
  List<Installment> overdueInstallments(List<Installment> all,
      {DateTime? now}) {
    final n = now ?? DateTime.now();
    return all
        .where((i) =>
            i.status == InstallmentStatus.pending &&
            i.dueDate.isBefore(n))
        .toList();
  }

  /// چک‌های معوق.
  List<Check> overdueChecks(List<Check> checks) =>
      checks.where((c) => c.isOverdue).toList();

  /// مجموع تعهدات دورهای فعال.
  int recurringTotalMinor(List<RecurringCommitment> cs, Currency currency) =>
      cs.where((c) => c.currency == currency && c.enabled).fold<int>(
          0, (s, c) => s + c.amountMinor);

  /// نزدیک‌ترین سررسید تعهد دورهای.
  RecurringCommitment? nextCommitment(List<RecurringCommitment> cs) {
    if (cs.isEmpty) return null;
    var best = cs.first;
    for (final c in cs) {
      if (best.enabled && !c.enabled) continue;
      if (c.enabled && (!best.enabled || c.nextDue.isBefore(best.nextDue))) {
        best = c;
      }
    }
    return best.enabled ? best : null;
  }
}
