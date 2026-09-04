/// مدل تراکنش (بندهای ۴۳، ۶۲-۶۴).
/// یک رویداد کاربرمحور: نوع، دسته، برچسب، مبلغ، تاریخ.
/// برچسب‌ها/دسته‌بندی‌ها برای گزارش Spending/Search/Filters (بند ۵۵، ۶۲-۶۴).
/// هستهٔ خالص؛ قابل تست.
library;

import '../money/money.dart';

/// نوع تراکنش (بند ۱۴ خلاصه برای برنامهٔ سادهٔ کاربر).
enum TxType { income, expense, transfer, buyAsset, sellAsset, debtPay, other }

/// یک تراکنش کاربرمحور.
class Transaction {
  final String id;
  final String userId;
  final TxType type;
  final int amountMinor;
  final Currency currency;
  final DateTime occurredAt;
  final String? categoryId; // دسته‌بندی.
  final String? categoryLabelFa;
  final String? merchant; // بند ۴۳: Merchant Recognition.
  final String? source; // MANUAL/SMS/...
  final String? note;
  final List<String> tags; // بند ۶۴.

  const Transaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.amountMinor,
    required this.currency,
    required this.occurredAt,
    this.categoryId,
    this.categoryLabelFa,
    this.merchant,
    this.source,
    this.note,
    this.tags = const [],
  });
}
