# فاز ۱۲ — آینده (تقویمِ تکرار و پیشبینی جریان نقدی)

> ماژول: `future` (ترتیب دامنهها در نقشهٔ ماژولِ فاز ۲: بعد از `liabilities`، قبل از `reports`).
> وضعیت: ✅ تحویل و سبز — `dart analyze` بدون مشکل، **50/50** تست موفق.

---

## ۱. چرا این ماژول؟

پس از موتورهای Ledger / Assets / Pricing / Fees / Liabilities، اکنون نوبت **تصمیمگیری آیندهنگر** است:
- تقویمِ تکرار (ورود/خروج دورهٔیِ حقوق، اجاره، قسط، اشتراک، ...).
- پیشبینی **جریان نقدی** برای N دوره آینده از پایهٔ نقدی — برای تشخیص کسری/ریسک نقدینگی.

---

## ۲. مدلها (`future.dart`)

- `CashDirection { inflow, outflow }`.
- `SeriesFrequency { once, daily, weekly, monthly, yearly }`.
- `ForecastPeriod { weekly, biweekly, monthly, quarterly, yearly }` — با `days`.
- `CalendarEntry { id, title, amountMinor, currency, direction, frequency, startDate, endDate?, interval? }` — `isExpired`.
- `ForecastPeriodResult { start, end, inflowMinor, outflowMinor, netMinor, balanceMinor }` — `negativeBalance`.

---

## ۳. تقویم تکرار (`FutureCalendar`)

| متد | توضیح |
|---|---|
| `nextOccurrence(entry, after)` | اولین رخداد بعد از تاریخ؛ بازنشانی آخرینِ `endDate`. |
| `occurrencesBetween(entry, from, to)` | همهٔ رخدادها در بازه. |

تکرارها:
- `monthly`: جلو بردن ماه با **clamp روز** به آخرین روزِ ماهِ کوتاه (۳۱ بهمن → ۲۸ فوریه؛ برگشت به ۳۱ اسفند).
- `weekly`: همان روز هفته (بازه ۷×interval).
- `yearly` / `daily`: جلو بردن سال/روز.
- `interval`: برای «هر ۲ ماه» و امثال آن.

---

## ۴. پیشبینی جریان نقدی (`CashFlowForecast`)

| متد | توضیح |
|---|---|
| `project(baseMinor, startDate, period, count, {currencyCode})` | خروجیِ `count` دوره با تراز چرخشی: `balance += inflow − outflow`. |
| `minBalanceMinor(periods)` | حداقل تراز برای هشدار ریسک. |
| `hasDeficit(periods)` | آیا دورهای تراز منفی دارد؟ |

- **فقط ارز مشخص** (`IRT`) شمرده میشود (ورودی دلاری در پیشبینی تومن نادیده گرفته میشود).
- تاریخها با `DateTime`؛ نمایش شمسی در لایهٔ UI (تبدیل با `jalali.dart`).

---

## ۵. تصمیمهای کلیدی

1. **تکرارِ درستِ ماهانه** با clamp روز-آخر — یک باگِ ظریف رایج. در تست پوشش داده شد (۳۱ بهمن ↔ ۲۸ فوریه ↔ ۳۱ اسفند).
2. **پیشبینی صرفاً نقدی، نه سرمایهگذاری** — ورود/خروج نقدی برای ریسک نقدینگی؛ پورتفوی در ماژول Assets است.
3. **همهٔ مبالغ ∈ واحد جزئی (Minor)** — سازگار با تصمیم C2.
4. **شکل تفکیک**: هستهٔ `future` فقط محاسبه؛ اتصال به جدولهای Drift/Transaction در فاز پایانی.

---

## ۶. تستها (5 تست فاز ۱۲ — مجموع 50/50)

| تست | نتیجه |
|---|---|
| ماهانه — رخداد بعدی | ✅ |
| ماهانه — clamp روز آخری ماه | ✅ |
| هفتگی — همان روز هفته | ✅ |
| رخدادهای بازه — تعداد درست | ✅ |
| تراز چرخشی (حقوق − اجاره) | ✅ |
| هشدار کمبود نقدینگی | ✅ |
| فقط ارز مشخص | ✅ |

---

## ۷. فایلهای این فاز

```
pkgs/core/lib/src/future/future.dart
pkgs/core/lib/wealth_core.dart                  (export جدید)
pkgs/core/test/future/future_test.dart          (5)
docs/phase-12-future.md
artifacts/app-preview-phase12.html
```

> **بلاکر شناختهشده (بدون تغییر):** تولید کد Drift و بستهبندی APK به رم ≥۴ گیگ نیاز دارند؛ در سندباکس (≈۱٫۱ گیگ آزاد) میسوزد — روی ماشین شما با `bash /home/user/wealth-os/app/build.sh`. در پایان، کل سورس Flutter بهصورت `.zip` تحویل داده میشود.
