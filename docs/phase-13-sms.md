# فاز ۱۳ (مستر پرامپت) — SMS + Local Intelligence

> **هم‌ترازی شماره‌گذاری:** مستر پرامپت این را «فاز ۱۳» نامیده (بند ۱۰۰) = SMS Permission + Parser + Duplicate + Merchant + Rules + Category. قبلاً من Reports را «فاز ۱۳» برچسب زده بودم؛ حالا با مستر هم‌تراز شد (Reports → فاز ۱۲).
> وضعیت: ✅ تحویل و سبز — `dart analyze` بدون مشکل، **75/75** تست (۹ جدید در این فاز).

---

## ۱. چرا SMS؟

بند ۴۱/۴۲: در Android و با Permission کاربر، پیامکِ بانکی پردازش شود؛ **تا حد امکان Local** (بند ۴۲/۸۰)، بدون AI (بند ۴/۵).
بند ۴۳: تراکنش ناشناخته ← «این بابت چه چیزی بود؟» ← بعد از چند بار، **Rule محلی** ساخته شود.

## ۲. `sms.dart` — هستهٔ خالص

### `SmsParser` (بند ۴۱-۴۲)
استخراج با Regex/کلمات کلیدی:
- **Bank** (`detectBank`): ملت/ملی/سامان/پاسارگاد/تجارت/صادرات/رفاه/پارسیان/سپه/آینده.
- **Amount**: عدد (با ارقام فارسی/عربی → `normalizeDigits`) پسِ «مبلغ/به مبلغ».
- **Type** (`detectTxType`): واریز/برداشت/خرید/شاپرک.
- **Reference** پیگیری، **Account** کارت، **Date** (شمسی → `jalaliToGregorian`)، **MerchantHint**.
- خطاها: پیامکِ کوتاه (`sms_short`)، بدون مبلغ (`sms_no_amount`).

### `MerchantRecognizer` (بند ۴۳)
- قوانین کاربرِ `LocalCategoryRule` اول، سپس کلیدهای معروف (دیجیپای/اسنپفود/تاپسی/شپرفود/جاروب/کافه/...) محلی.

### `CategorySuggester` (بند ۴۳/۸۰)
- پیشنهاد دسته از روی merchant (از قوانین محلی).

### `SmsDuplicateDetector` (بند ۴۳/۹۵)
- Fingerprint = بانک + مبلغ + نوع؛ تکراری اگر در پنجرهٔ ۵ دقیقه (با تاریخ) یا بیتاریخ باشد.

### `LocalCategoryRule`
- `merchant → category` با `timesUsed` (بعد از چند بار → `bump()`).

## ۳. تست‌ها (۹ تست)

| گروه | تعداد | نمونه |
|---|---|---|
| Parser | 4 | واریز+شمس، برداشت+فروشگاه، بدون مبلغ، کوتاه |
| Merchant/Suggester | 4 | تشخیص معروف، اولویت قانون کاربر، پیشنهاد دسته، `bump` |
| Duplicate | 1 | تکراری در پنجره / مبلغ متفاوت نه |

## ۴. فایل‌ها

```
pkgs/core/lib/src/sms/sms.dart                 (SMS + Local Intelligence)
pkgs/core/lib/wealth_core.dart                 (export)
pkgs/core/test/sms/sms_test.dart               (9)
docs/phase-13-sms.md
artifacts/app-preview-phase13.html
```

> **بلاکر بدون تغییر:** Permission/خواندن واقعی SMS و UI متصل به Drift به رم ≥۴ گیگ نیاز دارند؛ روی ماشین شما. Parser/Rules/Detect خالص با `dart test` اینجا سبزند.
