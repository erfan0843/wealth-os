library;

import 'package:wealth_core/wealth_core.dart';

/// هماهنگ‌سازی قالب‌بندی فارسی (اعداد + جداکنندهٔ ٬) در سراسر UI.
/// تمام اعداد نمایشی کاربر باید از این توابع بگذرند تا ارقام فارسی باشند.
/// (بند: ارقام فارسی، جداساز هزارگان ـ تصمیم i18n)

/// نمایش یک عدد صحیح با ارقام فارسی.
String faInt(int n) => toFaNumber(n);

/// نمایش یک عدد صحیح با جداکنندهٔ ٬ (تبدیل به رشته سپس گروه‌بندی فارسی).
String faGroup(int n) => groupThousands(n.toString());

/// نمایش مبلغ + واحد پول (تومان) — فارسی.
String faMoney(int minor, Currency c) => formatMoneyFa(minor, c);

/// نمایش یک درصد با ارقام فارسی (بدون علامت).
String faPercent(double p) => toFaNumber(p.round());

/// نمایش یک درصد با یک رقم اعشار فارسی.
String faPercentDec(double p) => faDecimal(p, 1);

/// نمایش یک عدد اعشاری با ارقام فارسی و «٠» نقص.
String faDecimal(double value, int fractionDigits) {
  final fixed = value.toStringAsFixed(fractionDigits);
  final parts = fixed.split('.');
  final intPart = toFaNumber(double.parse(parts[0]));
  if (parts.length < 2) return intPart;
  final frac = parts[1].split('').map(toFaDigit).join();
  return '$intPart٫$frac';
}

/// نمایش عدد همراه با واحد «میلیون/هزار» فارسی.
String faCompact(int v) {
  if (v >= 1000000) return '${faGroup(v ~/ 1000000)} میلیون';
  if (v >= 1000) return '${faGroup(v ~/ 1000)} هزار';
  return faGroup(v);
}
