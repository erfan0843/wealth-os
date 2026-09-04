# فاز ۱۳ — گزارش‌ها و واحد مرجع (Reports & RefValue)

> ماژول: `reports` (+ بخش RefValue/Reference Asset در `reference/`) — ترتیب دامنهها در نقشهٔ ماژولِ فاز ۲: بعد از `future`.
> وضعیت: ✅ تحویل و سبز — `dart analyze` بدون مشکل، **59/59** تست موفق.

---

## ۱. اصلاحِ الزام «واحد مرجع = ریال» (به‌درخواست کاربر)

در پرامپت، **Reference Asset (واحد مرجع / بند ۵۷)** یک تمایزدهٔ کلیدی است: «ثروت به معادلِ طلا/نقره/دلار، با قیمتِ *همان زمان*، نه فقط تومان».
**الزام صریح شما:** قیمتِ هر واحد مرجع (مثلاً هر گرم نقره) باید به **ریال** بیان شود.

پیادهسازی:
- `Currency.rial` + تبدیل `Currency.toRial()` / `fromRial()` با ثابت `tomanToRial = 10` (۱ تومان = ۱۰ ریال).
- موتور `RefAssetEngine`:
  - `calculate(amountMinor, currency, refPrice)` → مبلغ ورودی به **ریال** تبدیل (تومان ×۱۰) سپس ÷ قیمتِ هر گرم (ریال) → تعداد گرم.
  - `fromQuantity(...)` → برعکس.
  - `RefAssetPrice { unit, priceRialPerUnit, asOf }` — قیمت هر واحد به ریال + «زمان همان» (بند ۵۷) + `isStale` (>۱ روز).
  - `RefUnit { silverGram, goldGram, usd, eur }` با برچسب فارسی.
  - `RefValue.labelFa()` → «معادل ۱٬۱۲۵ گرم نقره» (با ارقام ٬ فارسی).

### تست نمونه (از پرامپت):
- ۹۲۰٬۰۰۰٬۰۰۰ تومان → ریال = ۹٬۲۰۰٬۰۰۰٬۰۰۰ → ÷ ۴۰٬۰۰۰ ← **۲۳۰٬۰۰۰ گرم نقره** ✅
- ۱۰۰ گرم نقره × ۴۰٬۰۰۰ ریال = ۴٬۰۰۰٬۰۰۰ ریال → ÷۱۰ ← **۴۰۰٬۰۰۰ تومان** ✅

---

## ۲. گزارش‌های هستهٔ خالص (`reports.dart`)

| ابزار | توضیح |
|---|---|
| `SpendAggregator` | تجمیع هزینهٔ دستهبندیها → `CategorySpend` مرتب نزولی. |
| `AllocationCalculator` | سهم هر کلاس دارایی از کل → `AllocationSlice.share`. |
| `Growth` | رشد دارایی خالص: `deltaMinor`، `percent` (منفی = افت)، `isUp`. |
| `FeesTotals` | جمع/تفکیک کارمزد بر اساس Rule. |

---

## ۳. تصمیمهای کلیدی

1. **قیمت واحد مرجع ∈ ریال** — همانطور که خواستید؛ برخلاف پول/حسابها که توماناند. این مفروضه در `RefAssetPrice` و تبدیل `Currency` صریح است.
2. **As-of** — هرگز قیمت امروز برای مبلغِ گذشته (بند ۵۷؛ ریسک R3 «نبود قیمت تاریخی» با `asOf` + قیمت تاریخدار `price_coordinator.asOf`).
3. **هستهٔ خالص** — تمام اینها بدون Flutter/DB، تستپذیر با `dart test`.
4. **ارقام فارسی** — همهٔ خروجیها با `groupThousands`/توافق i18n.

---

## ۴. تست‌ها (9 جدید — مجموع 59/59)

| گروه | تعداد | نمونه |
|---|---|---|
| واحد مرجع/ریال | 5 | تومان→گرم، ریال→گرم، گرم→تومان، برچسب، کهنگی |
| Reports | 4 | تجمیع هزینه، Allocation، Growth صعود/نزول/صفر، FeesTotals |

---

## ۵. فایل‌ها

```
pkgs/core/lib/src/money/money.dart              (+ Currency.rial / toRial / fromRial)
pkgs/core/lib/src/reference/ref_asset.dart      (واحد مرجع — ریال)
pkgs/core/lib/src/reports/reports.dart          (گزارش‌ها)
pkgs/core/lib/wealth_core.dart                  (export جدید)
pkgs/core/test/reference/ref_asset_test.dart    (5)
pkgs/core/test/reports/reports_test.dart        (4)
docs/phase-13-reports.md
artifacts/app-preview-phase13.html
```

> **بلاکر شناخته‌شده (بدون تغییر):** تولید کد Drift و بسته‌بندی APK به رم ≥۴ گیگ نیاز دارند؛ روی ماشین شما با `bash /home/user/wealth-os/app/build.sh`. در پایان کل سورس Flutter به‌صورت `.zip`.
