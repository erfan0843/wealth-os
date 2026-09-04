/// پول — تصمیم C2: مبالغ به‌صورت Integer (Minor Unit) ذخیره می‌شوند؛ بدون اعشار/خطا.
/// تومان = خودِ عدد صحیح (بدون جزء). ارزهای دارای جزء (USD/EUR) = Minor Unit (سنت).
/// نسبت تبدیل استاندارد ایران: ۱ تومان = ۱۰ ریال (بند واحد مرجع).
library;

/// نرخ تبدیل استاندارد: ۱ تومان = ۱۰ ریال.
const int tomanToRial = 10;

enum Currency {
  irt('IRT', 'تومان', 0), // تومان — بدون جزء
  rial('IRR', 'ریال', 0), // ریال — بدون جزء (واحد قیمتِ مرجعِ نقره/طلا)
  usd('USD', 'دلار', 2), // سنت
  eur('EUR', 'یورو', 2); // سنت

  final String code;
  final String labelFa;
  final int minorUnit;

  const Currency(this.code, this.labelFa, this.minorUnit);

  /// تبدیل مبلغ به ریال (اگر همین ریال باشد عین؛ اگر تومان ×۱۰).
  int toRial(int amountMinor) {
    switch (this) {
      case Currency.rial:
        return amountMinor;
      case Currency.irt:
        return amountMinor * tomanToRial;
      default:
        throw UnsupportedError('تبدیل ${code} به ریال پشتیبانی نمی‌شود');
    }
  }

  /// تبدیل مبلغ ریال به این واحد (تومان = ÷۱۰).
  int fromRial(int rialMinor) {
    switch (this) {
      case Currency.irt:
        return rialMinor ~/ tomanToRial;
      case Currency.rial:
        return rialMinor;
      default:
        throw UnsupportedError('تبدیل ریال به ${code} پشتیبانی نمی‌شود');
    }
  }
}

class Money {
  final int amountMinor;
  final Currency currency;

  const Money(this.amountMinor, this.currency);

  Money plus(Money other) {
    assert(other.currency == currency);
    return Money(amountMinor + other.amountMinor, currency);
  }

  Money minus(Money other) {
    assert(other.currency == currency);
    return Money(amountMinor - other.amountMinor, currency);
  }

  bool get isNegative => amountMinor < 0;
  bool get isZero => amountMinor == 0;

  @override
  bool operator ==(Object other) =>
      other is Money &&
      other.amountMinor == amountMinor &&
      other.currency == currency;

  @override
  int get hashCode => Object.hash(amountMinor, currency);

  @override
  String toString() => formatMoneyFa(amountMinor, currency);
}

String formatMoneyFa(int amountMinor, Currency currency) {
  return '${groupThousands(amountMinor.toString())} ${currency.labelFa}';
}

String groupThousands(String digits) {
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write('٬');
    buf.write(toFaDigit(digits[i]));
  }
  return buf.toString();
}

String toFaDigit(String d) {
  const fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
  final i = int.tryParse(d);
  return i == null ? d : fa[i];
}

String toFaNumber(num n) {
  final s = n.toInt().toString();
  return s.split('').map(toFaDigit).join();
}
