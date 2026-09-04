/// واحد مرجع (Reference Asset / RefValue — بند ۵۷).
/// ثروت/مبلغ را علاوه بر تومان، به معادلِ «گرم نقره / گرم طلا / دلار» نشان می‌دهد
/// با قیمتِ همان زمان (As-of). قیمتِ هر واحد مرجع به «ریال» بیان می‌شود (الزام کاربر).
/// هستهٔ خالص؛ قابل تست.
library;

import '../money/money.dart';

/// واحدهای مرجع معتبر.
enum RefUnit {
  toman('IRR_BASE', 'تومان', 'تومان'),
  silverGram('SILVER_G', 'گرم نقره', 'گرم'),
  goldGram('GOLD_G', 'گرم طلا', 'گرم'),
  usd('USD', 'دلار', 'دلار'),
  eur('EUR', 'یورو', 'یورو');

  /// کد هویتی (انگلیسی برای DB).
  final String code;
  final String labelFa;
  final String unitWording;

  const RefUnit(this.code, this.labelFa, this.unitWording);
}

/// قیمتِ یک واحد مرجع به ریال.
class RefAssetPrice {
  final RefUnit unit;
  final int priceRialPerUnit; // قیمت هر واحد (مثلاً هر گرم نقره) به ریال.
  final DateTime asOf; // زمانِ قیمت (همان زمان — بند ۵۷).

  const RefAssetPrice({
    required this.unit,
    required this.priceRialPerUnit,
    required this.asOf,
  });

  bool get isStale =>
      DateTime.now().difference(asOf).inDays > 1; // بیشتر از ۱ روز → کهنه.
}

/// نتیجهٔ معادل‌سازی یک مبلغ به واحد مرجع.
class RefValue {
  final int amountMinor; // مبلغ اصلی (در ارز ورودی).
  final Currency currency;
  final double quantity; // تعداد واحد مرجع.
  final RefUnit unit;
  final RefAssetPrice price;
  final int priceRialPerUnit;
  final DateTime asOf;

  const RefValue({
    required this.amountMinor,
    required this.currency,
    required this.quantity,
    required this.unit,
    required this.price,
    required this.priceRialPerUnit,
    required this.asOf,
  });

  /// نمایش «معادل ۴۸۰ گرم نقره».
  String labelFa() =>
      'معادل ${_faQty(quantity)} ${unit.labelFa}';
}

String _faQty(double q) {
  // تا ۳ رقم اعشار.
  final rounded = (q * 1000).round() / 1000;
  if (rounded == rounded.roundToDouble()) {
    return groupThousands(rounded.round().toString());
  }
  return groupThousands(rounded.toString());
}

/// موتور واحد مرجع.
class RefAssetEngine {
  const RefAssetEngine();

  /// معادل‌سازی مبلغ ورودی به یک واحد مرجع.
  /// - مبلغ ورودی به ریال تبدیل می‌شود (تومان ×۱۰).
  /// - سپس تقسیم بر قیمت هر واحد مرجع.
  RefValue calculate({
    required int amountMinor,
    required Currency currency,
    required RefAssetPrice refPrice,
  }) {
    final amountRial = currency.toRial(amountMinor);
    final qty = amountRial / refPrice.priceRialPerUnit;
    return RefValue(
      amountMinor: amountMinor,
      currency: currency,
      quantity: qty,
      unit: refPrice.unit,
      price: refPrice,
      priceRialPerUnit: refPrice.priceRialPerUnit,
      asOf: refPrice.asOf,
    );
  }

  /// برعکس: از تعداد واحد مرجع به مبلغ در ارز ورودی.
  int fromQuantity({
    required double quantity,
    required Currency currency,
    required RefAssetPrice refPrice,
  }) {
    final rial = (quantity * refPrice.priceRialPerUnit).round();
    return currency.fromRial(rial);
  }
}
