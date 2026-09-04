/// SMS + Local Intelligence (فاز ۱۳ مستر).
/// - SmsParser: استخراج Bank/Amount/Type/Date/Reference/Account با Regex (بند ۴۱-۴۲).
/// - SmsDuplicateDetector: تشخیص پیامک تکراری (بند ۴۳/۹۵).
/// - MerchantRecognizer + LocalCategoryRule: merchant → دسته (بند ۴۳).
/// - CategorySuggester: پیشنهاد دسته.
/// همه روی دستگاه (بند ۴۲/۸۰)؛ بدون AI/سرویس (بند ۴/۵). هستهٔ خالص؛ قابل تست.
library;

import '../date/jalali.dart';
import '../errors/result.dart';

final Map<String, int> _faDigit = {
  '۰': 0, '۱': 1, '۲': 2, '۳': 3, '۴': 4, '۵': 5, '۶': 6, '۷': 7, '۸': 8, '۹': 9,
  '٠': 0, '١': 1, '٢': 2, '٣': 3, '٤': 4, '٥': 5, '٦': 6, '٧': 7, '٨': 8, '٩': 9,
};

/// تبدیل ارقام فارسی/عربی به لاتین (برای parsing).
String normalizeDigits(String s) {
  final buf = StringBuffer();
  for (final ch in s.split('')) {
    final v = _faDigit[ch];
    if (v != null) {
      buf.write(v);
    } else {
      buf.write(ch);
    }
  }
  return buf.toString();
}

/// یک پیامکِ بانکی استخراج‌شده.
class BankSms {
  final String bank;
  final int amountMinor;
  final String txType; // واریز / برداشت / ...
  final String reference;
  final String fromAccount;
  final DateTime? occurredAt;
  final String merchantHint;
  final String raw;

  const BankSms({
    required this.bank,
    required this.amountMinor,
    required this.txType,
    required this.reference,
    required this.fromAccount,
    required this.merchantHint,
    required this.raw,
    this.occurredAt,
  });
}

/// تشخیص بانک با کلمات کلیدی.
String detectBank(String text) {
  final t = text.toLowerCase();
  const banks = [
    ('ملت', 'ملت'), ('ملی', 'ملی'), ('سامان', 'سامان'),
    ('پاسارگاد', 'پاسارگاد'), ('تجارت', 'تجارت'), ('صادرات', 'صادرات'),
    ('رفاه', 'رفاه'), ('پارسیان', 'پارسیان'), ('سپه', 'سپه'), ('آینده', 'آینده'),
  ];
  for (final b in banks) {
    if (t.contains(b.$1)) return b.$2;
  }
  return 'نامشخص';
}

/// تشخیص جهت: واریز/دریافت (ورودی) یا برداشت/خرید/پرداخت (خروجی).
String detectTxType(String text) {
  final t = normalizeDigits(text);
  if (RegExp(r'واریز|دریافت').hasMatch(t)) return 'واریز';
  if (RegExp(r'برداشت|خرید|پرداخت|شاپرک').hasMatch(t)) return 'برداشت';
  return 'نامشخص';
}

class SmsParser {
  const SmsParser();

  int? _extractAmount(String text) {
    final t = normalizeDigits(text).replaceAll(RegExp(r'[٬,]'), '');
    final m = RegExp(r'(?:به مبلغ|مبلغ[: ]|مبلغ ی|مبلغ)[^0-9]{0,4}([0-9]+)')
        .firstMatch(t);
    if (m != null) return int.tryParse(m.group(1)!);
    return null;
  }

  String? _extract(String text, RegExp re) {
    final m = re.firstMatch(normalizeDigits(text));
    return m?.group(1)?.trim();
  }

  DateTime? _extractDate(String text) {
    final m = RegExp(r'(\d{4})[/-](\d{1,2})[/-](\d{1,2})')
        .firstMatch(normalizeDigits(text));
    if (m != null) {
      final y = int.tryParse(m.group(1)!);
      final mo = int.tryParse(m.group(2)!);
      final d = int.tryParse(m.group(3)!);
      if (y != null && mo != null && d != null) {
        try {
          return jalaliToGregorian(JalaliDate(y, mo, d));
        } catch (_) {
          return null;
        }
      }
    }
    return null;
  }

  /// Parse کردن یک پیامکِ بانکی.
  Result<BankSms> parse(String raw) {
    if (raw.trim().length < 8) {
      return const Err(AppError('sms_short', 'پیامکِ نامعتبر/کوتاه'));
    }
    final normalized = normalizeDigits(raw);
    final amount = _extractAmount(raw);
    if (amount == null || amount <= 0) {
      return const Err(AppError('sms_no_amount', 'مبلغ از پیامک استخراج نشد'));
    }
    return Ok(BankSms(
      bank: detectBank(raw),
      amountMinor: amount,
      txType: detectTxType(raw),
      reference: _extract(
              normalized,
              RegExp(r'(?:پیگیری|شماره[ ]*پیگیری|ref\.?[: ])\s*([0-9]+)')) ??
          '',
      fromAccount: _extract(
              normalized,
              RegExp(r'(?:عضو|کارت|از حساب)\s*[: ]?([0-9]{9,16})')) ??
          '',
      merchantHint: _extract(normalized, RegExp(r'(?:فروشگاه|پذیرنده)\s*[: ]?\s*([^\s،;\n]{2,30})')) ?? '',
      occurredAt: _extractDate(raw),
      raw: raw,
    ));
  }
}

/// یک قانون محلّی: merchant → دسته‌بندی (بند ۴۳/۸۰).
class LocalCategoryRule {
  final String merchant;
  final String categoryId;
  final String categoryLabelFa;
  final int timesUsed;

  const LocalCategoryRule({
    required this.merchant,
    required this.categoryId,
    required this.categoryLabelFa,
    this.timesUsed = 1,
  });

  LocalCategoryRule bump() => LocalCategoryRule(
        merchant: merchant,
        categoryId: categoryId,
        categoryLabelFa: categoryLabelFa,
        timesUsed: timesUsed + 1,
      );
}

/// تشخیصِ فروشنده/مرکچنت (بند ۴۳، Merchant Recognition) — محلی.
class MerchantRecognizer {
  final List<LocalCategoryRule> _rules;
  const MerchantRecognizer([this._rules = const []]);

  String? detect(String text) {
    final t = normalizeDigits(text);
    // اول قوانین کاربر (بند ۴۳) — اولویت بالا.
    for (final r in _rules) {
      if (t.contains(r.merchant)) return r.merchant;
    }
    const known = <String, String>{
      'دیجی‌پای': 'دیجی‌پای', 'دیجی‌پی': 'دیجی‌پای', 'اسنپ فود': 'اسنپ‌فود',
      'اسنپ': 'اسنپ', 'تاپسی': 'تاپسی', 'شپرفود': 'شپرفود', 'جاروب': 'جاروب',
      'فروشگاه': 'فروشگاه', 'کافه': 'کافه', 'بنگاه': 'بنگاه', 'مک‌دونالد': 'مک‌دونالد',
    };
    for (final e in known.entries) {
      if (t.contains(e.key)) return e.value;
    }
    return null;
  }
}

/// پیشنهاد دسته از روی merchant (بند ۴۳/۸۰).
class CategorySuggester {
  final List<LocalCategoryRule> _rules;
  const CategorySuggester([this._rules = const []]);

  String? suggest(String? merchant) {
    if (merchant == null) return null;
    for (final r in _rules) {
      if (r.merchant == merchant) return r.categoryId;
    }
    return null;
  }
}

/// تشخیص پیامک تکراری (بند ۴۳/۹۵) — پنجرهٔ زمانی.
class SmsDuplicateDetector {
  const SmsDuplicateDetector();

  /// کلید یکتا: بانک + مبلغ + نوع.
  String fingerprint(BankSms s) => '${s.bank}|${s.amountMinor}|${s.txType}';

  bool isDuplicate(BankSms s, Map<String, DateTime> seen, {int windowMinutes = 5}) {
    final key = fingerprint(s);
    final last = seen[key];
    if (last == null) return false;
    if (s.occurredAt != null) {
      return s.occurredAt!.difference(last).inMinutes.abs() < windowMinutes;
    }
    return true; // بدون زمان → در پنجرهٔ غیرطبیعی دوباره دیده شده.
  }

  /// ثبت یک پیامک برای مقایسهٔ بعدی.
  void record(BankSms s, Map<String, DateTime> seen) {
    seen[fingerprint(s)] = s.occurredAt ?? DateTime.now();
  }
}
