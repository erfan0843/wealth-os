import 'package:test/test.dart';
import 'package:wealth_core/wealth_core.dart';

void main() {
  const parser = SmsParser();

  group('SmsParser — بانک/مبلغ/نوع/مرجع (بند ۴۱-۴۲)', () {
    test('واریز با رقم فارسی و تاریخ شمسی', () {
      final res = parser.parse(
        'بانک ملت: مبلغ ۱٬۵۰۰٬۰۰۰ ریال واریز از حساب ۶۱۰۴ به کارت ۶۲۴۴ در تاریخ 1405/06/12 — شماره پیگیری 123456789');
      expect(res.isOk, true);
      final s = res.value!;
      expect(s.bank, 'ملت');
      expect(s.amountMinor, 1500000);
      expect(s.txType, 'واریز');
      expect(s.reference, '123456789');
      // تاریخ شمسی 1405/06/12 ≈ ۲۰۲۶/۰۹/۰۳.
      expect(s.occurredAt, isNotNull);
      expect(s.occurredAt!.year, 2026);
    });

    test('برداشت/خرید فروشگاهی', () {
      final res = parser.parse(
        'پرداخت موفق به مبلغ ۲۵۰٬۰۰۰ ریال، کارت ۶۳۵۴، فروشگاه دیجی‌پای، تاریخ 1405/06/10');
      expect(res.isOk, true);
      final s = res.value!;
      expect(s.txType, 'برداشت');
      expect(s.amountMinor, 250000);
      expect(s.merchantHint, 'دیجی‌پای');
    });

    test('پیامک بدون مبلغ → خطا', () {
      final res = parser.parse('پیامک خوش‌آمد بانک');
      expect(res.isErr, true);
      expect(res.error!.code, 'sms_no_amount');
    });

    test('پیامک کوتاه → خطا', () {
      expect(parser.parse('hi').isErr, true);
    });
  });

  group('MerchantRecognizer / CategorySuggester — Local Rules (بند ۴۳)', () {
    test('تشخیص فروشگاه از کلید معروف', () {
      const rec = MerchantRecognizer();
      expect(rec.detect('پرداخت اسنپ فود'), 'اسنپ‌فود');
      expect(rec.detect('پرداخت دیجی‌پای'), 'دیجی‌پای');
      expect(rec.detect('پرداخت تاکسی'), isNull);
    });

    test('قانون کاربر بر کلید معروف اولویت دارد', () {
      final rec = MerchantRecognizer([
        const LocalCategoryRule(
            merchant: 'کافه', categoryId: 'coffee', categoryLabelFa: 'قهوه'),
      ]);
      expect(rec.detect('پرداخت کافه ری'), 'کافه');
    });

    test('پیشنهاد دسته از قانون', () {
      const sug = CategorySuggester([
        LocalCategoryRule(
            merchant: 'دیجی‌پای', categoryId: 'bnpl', categoryLabelFa: 'خرید اقساطی'),
      ]);
      expect(sug.suggest('دیجی‌پای'), 'bnpl');
      expect(sug.suggest('نامشخص'), isNull);
    });

    test('افزایش شمارهٔ استفاده (بند ۴۳)', () {
      final r = const LocalCategoryRule(
          merchant: 'x', categoryId: 'food', categoryLabelFa: 'خوراک');
      expect(r.timesUsed, 1);
      expect(r.bump().timesUsed, 2);
    });
  });

  group('SmsDuplicateDetector — تکراری (بند ۴۳/۹۵)', () {
    test('دو پیامک یکسان در پنجره → تکراری', () {
      const det = SmsDuplicateDetector();
      final seen = <String, DateTime>{};
      final a = BankSms(bank: 'ملت', amountMinor: 100000, txType: 'برداشت',
          reference: 'r1', fromAccount: '', merchantHint: '', raw: 'a',
          occurredAt: DateTime.utc(2026, 9, 3, 10, 0));
      final b = BankSms(bank: 'ملت', amountMinor: 100000, txType: 'برداشت',
          reference: 'r2', fromAccount: '', merchantHint: '', raw: 'b',
          occurredAt: DateTime.utc(2026, 9, 3, 10, 2));
      det.record(a, seen);
      expect(det.isDuplicate(b, seen), true);
      // مبلغ متفاوت → تکراری نیست.
      final c = BankSms(bank: 'ملت', amountMinor: 100001, txType: 'برداشت',
          reference: 'r3', fromAccount: '', merchantHint: '', raw: 'c',
          occurredAt: DateTime.utc(2026, 9, 3, 10, 2));
      expect(det.isDuplicate(c, seen), false);
    });
  });
}
