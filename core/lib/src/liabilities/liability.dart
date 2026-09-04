/// مدلهای بدهی، طلب و تعهدات (بندهای مرتبط: قسط، چک، بدهی، اقساط، برنامهٔ بازپرداخت).
/// - LiabilityKind: بدهی(کلی) / وام / خرید اقساطی (BNPL) / قسط.
/// - RecurringCommitment: تعهد دورهای (قبض، اجاره، اشتراک...).
/// - Check: چک پرداختی/دریافتی.
/// هستهٔ خالص؛ قابل تست.
library;

import '../money/money.dart';

/// نوع بدهی.
enum LiabilityKind { debt, loan, bnpl, installment }

/// تکرار بازپرداخت/قسط.
enum RepaymentFrequency { weekly, biweekly, monthly, quarterly, yearly }

/// وضعیت قسط.
enum InstallmentStatus { pending, paid, overdue }

/// نوع چک.
enum CheckKind { payable, receivable }

/// وضعیت چک.
enum CheckStatus { pending, cleared, bounced, cancelled }

/// یک بدهی (منبع تعهد).
class Liability {
  final String id;
  final String name;
  final LiabilityKind kind;
  final int principalMinor; // اصل مبلغ (واحد جزئی).
  final Currency currency;
  final double interestRatePercent; // درصد سالانه (۰ = بدون بهره).
  final DateTime startDate;
  final RepaymentFrequency frequency;
  final int installmentsCount; // تعداد قسط (۰ = یکجا در پایان).
  final String? creditor; // طلبکار.

  const Liability({
    required this.id,
    required this.name,
    required this.kind,
    required this.principalMinor,
    required this.currency,
    required this.startDate,
    this.interestRatePercent = 0,
    this.frequency = RepaymentFrequency.monthly,
    this.installmentsCount = 1,
    this.creditor,
  });

  bool get hasInterest => interestRatePercent > 0;
}

/// یک قسط (← محاسبهٔ برنامهٔ بازپرداخت).
class Installment {
  final int index; // 1-based.
  final DateTime dueDate;
  final int principalMinor;
  final int interestMinor;
  final InstallmentStatus status;
  final DateTime? paidDate;

  const Installment({
    required this.index,
    required this.dueDate,
    required this.principalMinor,
    required this.interestMinor,
    this.status = InstallmentStatus.pending,
    this.paidDate,
  });

  int get totalMinor => principalMinor + interestMinor;
  int get amountMinor => totalMinor;
}

/// چک.
class Check {
  final String id;
  final CheckKind kind;
  final String number;
  final String party; // طرف مقابل.
  final int amountMinor;
  final Currency currency;
  final DateTime issueDate;
  final DateTime dueDate;
  final CheckStatus status;
  final DateTime? clearedDate;

  const Check({
    required this.id,
    required this.kind,
    required this.number,
    required this.party,
    required this.amountMinor,
    required this.currency,
    required this.issueDate,
    required this.dueDate,
    this.status = CheckStatus.pending,
    this.clearedDate,
  });

  bool get isOverdue =>
      status == CheckStatus.pending && dueDate.isBefore(DateTime.now());
}

/// تعهد دورهای (قبض، اجاره، اشتراک، ...).
class RecurringCommitment {
  final String id;
  final String name;
  final int amountMinor;
  final Currency currency;
  final RepaymentFrequency frequency;
  final DateTime nextDue;
  final bool enabled;

  const RecurringCommitment({
    required this.id,
    required this.name,
    required this.amountMinor,
    required this.currency,
    required this.nextDue,
    this.frequency = RepaymentFrequency.monthly,
    this.enabled = true,
  });
}
