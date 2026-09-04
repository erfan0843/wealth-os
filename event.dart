/// مدل کامل رویداد مالی و سند دوبادگانه (بند ۱۴-۱۶).
/// ورودی‌های خالص؛ قابل تست با `dart test`.
library;

import '../money/money.dart';

/// انواع رویداد (بند ۱۴).
enum EventKind {
  income, expense, transfer, assetBuy, assetSale, assetAdjust, fee, tax,
  debtCreate, debtPay, receivableCreate, receivableCollect, loan, installment,
  checkIssued, checkReceived, checkCleared, checkReturned, refund, discount,
  interest, penalty, investment, divestment, other,
}

/// وضعیت رویداد — ACTIVE یا REVERSED (بند ۷۴: Reversal، نه Hard Delete).
enum EventStatus { active, reversed }

/// موضوعِ سند: حساب / دارایی / تعهد (بدهی، طلب، وام، چک).
enum SubjectType { account, asset, liability }

/// جهت سند.
enum Side { debit, credit }

/// یک سند (خط) در دفتر کل.
class LedgerEntry {
  final Side side;
  final SubjectType subjectType;
  final String subjectId;
  final Money amount; // برای ورودی‌های پولی
  final double? quantity; // برای ورودی‌های مقداری (گرم/سهم/...)
  final String? unit;

  const LedgerEntry({
    required this.side,
    required this.subjectType,
    required this.subjectId,
    required this.amount,
    this.quantity,
    this.unit,
  });

  LedgerEntry copyWith({Side? side, Money? amount, double? quantity, String? unit}) =>
      LedgerEntry(
        side: side ?? this.side,
        subjectType: subjectType,
        subjectId: subjectId,
        amount: amount ?? this.amount,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
      );
}

/// یک رویداد مالی کامل.
class FinancialEvent {
  final String id;
  final String userId;
  final EventKind kind;
  final DateTime occurredAt;
  final Currency currency;
  final EventStatus status;
  final String? referenceEventId; // برای Reversal
  final String? note;
  final List<LedgerEntry> entries;

  const FinancialEvent({
    required this.id,
    required this.userId,
    required this.kind,
    required this.occurredAt,
    required this.currency,
    this.status = EventStatus.active,
    this.referenceEventId,
    this.note,
    this.entries = const [],
  });

  /// جمع کل مبلغ.
  int get totalMinor {
    var t = 0;
    for (final e in entries) {
      t += e.amount.amountMinor;
    }
    return t;
  }

  bool get isReversed => status == EventStatus.reversed;
}
