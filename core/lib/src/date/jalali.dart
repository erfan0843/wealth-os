/// تقویم جلالی (شمسی) — تبدیل دوطرفهٔ میلادی ↔ شمسی.
/// اجراییِ معتبر و متقارن (Jalaali-js) تا round-trip دقیق بماند.
/// هستهٔ خالص؛ قابل تست با `dart test`.
///
/// ذخیره‌سازی اپ UTC/ISO است؛ این ماژول فقط لایهٔ نمایش/ورودی/محاسبهٔ شمسی است.
/// هفتهٔ ایرانی از شنبه (Saturday) شروع می‌شود.
library;

class JalaliDate {
  final int year;
  final int month; // ۱ تا ۱۲
  final int day; // ۱ تا ۳۱

  const JalaliDate(this.year, this.month, this.day);

  @override
  String toString() => '$year/$month/$day';

  bool operator ==(Object other) =>
      other is JalaliDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  static const monthNamesFa = [
    'فروردین', 'اردیبهشت', 'خرداد', 'تیر', 'مرداد', 'شهریور', 'مهر',
    'آبان', 'آذر', 'دی', 'بهمن', 'اسفند',
  ];

  String get monthNameFa => monthNamesFa[month - 1];
  String get shortFa => '$day $monthNameFa $year';

  String get numericFa {
    const z = '۰';
    final m = (month < 10 ? z : '') + JalaliDate.toFa(month);
    final d = (day < 10 ? z : '') + JalaliDate.toFa(day);
    return '${JalaliDate.toFa(year)}/$m/$d';
  }

  static String toFa(int n) {
    const fa = ['۰', '۱', '۲', '۳', '۴', '۵', '۶', '۷', '۸', '۹'];
    return n.toString().split('').map((c) => fa[int.parse(c)]).join();
  }
}

// ---- Jalaali-js utility ----
const List<int> _breaks = [
  -61, 9, 38, 199, 426, 686, 756, 818, 1111, 1181, 1210, 1635, 2060, 2097,
  2192, 2262, 2324, 2394, 2456, 3178,
];

// Jalaali-js uses truncation-toward-zero division (like `~~(a/b)` in JS).
int _div(int a, int b) => a < 0 ? -((-a) ~/ b) : a ~/ b;
int _mod(int a, int b) => a - _div(a, b) * b;

// شمارهٔ سال کبیسه، سال میلادیِ هم‌آغاز و روزِ آغاز فروردین.
class _JalCal {
  final int leap;
  final int gy;
  final int march;
  const _JalCal(this.leap, this.gy, this.march);
}

_JalCal _jalCal(int jy) {
  final bl = _breaks.length;
  final gy = jy + 621;
  var leapJ = -14;
  var jp = _breaks[0];
  var jump = 0;
  for (var i = 1; i < bl; i++) {
    final jm = _breaks[i];
    jump = jm - jp;
    if (jy < jm) break;
    leapJ += _div(jump, 33) * 8 + _div(_mod(jump, 33), 4);
    jp = jm;
  }
  var n = jy - jp;
  leapJ += _div(n, 33) * 8 + _div(_mod(n, 33) + 3, 4);
  if (_mod(jump, 33) == 4 && jump - n == 4) leapJ += 1;
  final leapG = _div(gy, 4) - _div((_div(gy, 100) + 1) * 3, 4) - 150;
  final march = 20 + leapJ - leapG;
  if (jump - n < 6) n = n - jump + _div(jump + 4, 33) * 33;
  var leap = _mod(_mod(n + 1, 33) - 1, 4);
  if (leap == -1) leap = 4;
  return _JalCal(leap, gy, march);
}

int _j2d(int jy, int jm, int jd) {
  final r = _jalCal(jy);
  return _g2d(r.gy, 3, r.march) + (jm - 1) * 31 - _div(jm, 7) * (jm - 7) +
      jd - 1;
}

JalaliDate _d2j(int jdn) {
  final gy = _d2g(jdn).year;
  var jy = gy - 621;
  final r = _jalCal(jy);
  final jdn1f = _g2d(gy, 3, r.march);
  var k = jdn - jdn1f;
  int jm, jd;
  if (k >= 0) {
    if (k <= 185) {
      jm = 1 + _div(k, 31);
      jd = _mod(k, 31) + 1;
      return JalaliDate(jy, jm, jd);
    }
    k -= 186;
  } else {
    jy -= 1;
    k += 179;
    if (r.leap == 1) k += 1;
  }
  jm = 7 + _div(k, 30);
  jd = _mod(k, 30) + 1;
  return JalaliDate(jy, jm, jd);
}

int _g2d(int gy, int gm, int gd) {
  var d = _div((gy + _div(gm - 8, 6) + 100100) * 1461, 4) +
      _div((153 * _mod(gm + 9, 12) + 2), 5) + gd - 34840408;
  d = d - _div(_div(gy + 100100 + _div(gm - 8, 6), 100) * 3, 4) + 752;
  return d;
}

JalaliDate _d2g(int jdn) {
  int j = 4 * jdn + 139361631;
  j = j + _div(_div(4 * jdn + 183187720, 146097) * 3, 4) * 4 - 3908;
  final i = _div(_mod(j, 1461), 4) * 5 + 308;
  final gd = _div(_mod(i, 153), 5) + 1;
  final gm = _mod(_div(i, 153), 12) + 1;
  final gy = _div(j, 1461) - 100100 + _div(8 - gm, 6);
  return JalaliDate(gy, gm, gd);
}

/// تبدیل شمسی → میلادی (UTC).
DateTime jalaliToGregorian(JalaliDate j) {
  final g = _d2g(_j2d(j.year, j.month, j.day));
  return DateTime.utc(g.year, g.month, g.day);
}

/// تبدیل میلادی → شمسی.
JalaliDate gregorianToJalali(DateTime g) =>
    _d2j(_g2d(g.year, g.month, g.day));

/// روز هفتهٔ ایرانی: شنبه=0 ... جمعه=6.
int jalaliWeekday(DateTime dt) => (dt.weekday + 1) % 7;
