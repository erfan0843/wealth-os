import 'package:test/test.dart';
import 'package:wealth_core/wealth_core.dart';

void main() {
  group('Jalali conversion', () {
    test('known anchor 2026-09-03 -> 1405/06/12', () {
      final j = gregorianToJalali(DateTime.utc(2026, 9, 3));
      expect(j.year, 1405);
      expect(j.month, 6);
      expect(j.day, 12);
      expect(j.monthNameFa, 'شهریور');
    });

    test('Nowruz anchor 2026-03-21 -> 1405/01/01', () {
      final j = gregorianToJalali(DateTime.utc(2026, 3, 21));
      expect(j.month, 1);
      expect(j.day, 1);
    });

    test('round-trip gregorian -> jalali -> gregorian', () {
      for (var day = 0; day <= 365; day++) {
        final g = DateTime.utc(2026, 1, 1).add(Duration(days: day));
        final j = gregorianToJalali(g);
        final back = jalaliToGregorian(j);
        expect(back, g, reason: 'roundtrip failed for day=$day');
      }
    });

    test('Feb 28 2026 -> Esfand', () {
      final j = gregorianToJalali(DateTime.utc(2026, 2, 28));
      expect(j.month, 12);
      expect(j.day, 9);
    });

    test('weekday Saturday=0', () {
      expect(jalaliWeekday(DateTime.utc(2026, 9, 5)), 0); // Saturday
      expect(jalaliWeekday(DateTime.utc(2026, 9, 3)), 5); // Thursday (پنجشنبه)
      expect(jalaliWeekday(DateTime.utc(2026, 9, 6)), 1); // Sunday (یکشنبه)
    });

    test('Persian digit formatting in numericFa', () {
      final j = gregorianToJalali(DateTime.utc(2026, 9, 3));
      expect(j.numericFa, '۱۴۰۵/۰۶/۱۲');
    });
  });
}
