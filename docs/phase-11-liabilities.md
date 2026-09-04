# فاز ۱۱ — بدهی‌ها، طلب‌ها و تعهدات (Liabilities & Commitments)

> ماژول: `liabilities` (ترتیب دامنه‌ها در نقشهٔ ماژولِ فاز ۲: بعد از `fees`، قبل از `future`/`budget`).
> وضعیت: ✅ تحویل و سبز — `dart analyze` بدون مشکل، **45/45** تست موفق.

---

## ۱. چرا این ماژول؟

در نقاط مختلف پروژه به «بدهی/طلب/قسط/چک/تعهد دورهای» اشاره شده بود:
- داشبورد: «قسط دیجی‌پای»، «چک دریافتی»، «۹ روز مانده».
- بندهای هزینه: اعتبار، بدهی، وام، خرید اقساطی (BNPL)، چک.
- ارزش خالص (فاز ۸): بدهیها کسر و طلبها در دارایی‌ها لحاظ می‌شوند.

این فاز منطق خالص این حوزه را یکجا و تست‌پذیر پیاده می‌کند.

---

## ۲. مدل‌ها (`liability.dart`)

- `LiabilityKind { debt, loan, bnpl, installment }`.
- `RepaymentFrequency { weekly, biweekly, monthly, quarterly, yearly }`.
- `Liability { id, name, kind, principalMinor, currency, interestRatePercent, startDate, frequency, installmentsCount, creditor? }`.
- `Installment { index, dueDate, principalMinor, interestMinor, status(pending/paid/overdue), paidDate? }` — با `totalMinor` و `amountMinor`.
- `CheckKind { payable, receivable }`، `CheckStatus { pending, cleared, bounced }`.
- `Check { id, kind, number, party, amountMinor, currency, issueDate, dueDate, status, clearedDate? }` — `isOverdue`.
- `RecurringCommitment { id, name, amountMinor, currency, frequency, nextDue, enabled }`.

---

## ۳. موتور (`liability_engine.dart`)

| متد | توضیح |
|---|---|
| `schedule(liability)` | ساخت برنامهٔ بازپرداخت **Amortization** (قسط مساوی): `M = P·r / (1−(1+r)^−n)`؛ رند به واحد جزئی؛ قسط آخر مانده را دقیقاً خالص می‌کند. |
| `outstandingPrincipalMinor(installments)` | اصل مانده = مجموع اصلِ قسط‌های پرداخت‌نشده. |
| `totalInterestMinor(liability)` | بهرهٔ کل برنامه. |
| `netPositionMinor(debts, receivables)` | **بدهی − طلب** (خالص بدهکار/طلبکار). |
| `overdueInstallments(all, {now})` | قسط‌های سررسیدشده. |
| `overdueChecks(checks)` | چک‌های معوق. |
| `recurringTotalMinor(commitments, currency)` | مجموع تعهدات دورهای فعال+فقط با ارز مشخص. |
| `nextCommitment(commitments)` | نزدیک‌ترین سررسید فعال. |

---

## ۴. تصمیم‌های کلیدی

1. **قسط مساوی (Amortization)** — نه «اصل ثابت»، چون بیشتر بدهیهای ایرانی (وام/BNPL) قسط مساوی دارند؛ نرخ % سالانه به دوره‌ای تبدیل می‌شود.
2. **بهره = اختیاری** — با `interestRatePercent = 0` خالصِ اصل است (بدون بهره).
3. **واحد جزئی (Minor)** — همهٔ مبالغ ∈ واحد جزئی (تومن/سنت) برای سازگاری با تصمیم C2 (بدون اعشار).
4. **طلب در ارزش خالص:** بدهی منهای طلب → در فاز ۸/NetWorth درست لحاظ شود (طلب قبلاً فقط نقدینگی نبود؛ اینجا خالصِ بدهی/طلب مشخص است).
5. **تعهد دورهای** با `enabled` — غیرفعال در جمع/نزدیک‌ترین حذف می‌شود.

---

## ۵. باگ واقعی یافت‌شده و اصلاح‌شده

در ساخت برنامهٔ بازپرداخت، قسط آخر **بعد از** تفریق، اصلش با باقی‌ماندهٔ (قبلاً‌کاهش‌یافته) بازنویسی می‌شد → قسط آخر ≈ ۰ و جمع اصل کسری می‌شد (در تست: ۱۱٬۰۰۰٬۰۰۰ به‌جای ۱۲٬۰۰۰٬۰۰۰ و اختلاف ۱٬۱۱۲٬۴۶۳ بین قسط اول/آخر).
**اصلاح:** تنظیمِ قسط آخر **قبل از** تفریق مانده انجام شد → قسط آخر باقی‌مانده را دقیقاً خالص می‌کند؛ جمع اصل = ۱۲٬۰۰۰٬۰۰۰ و تفاوت قسطها فقط از گردکردن واحد جزئی (<۱۰ تومن).

---

## ۶. تست‌ها (8 تست فاز ۱۱ — مجموع 45/45)

| تست | نتیجه |
|---|---|
| بدون بهره — قسط مساوی و جمع اصل کامل | ✅ |
| با بهره — قسط مساوی، اصل+بهره، مانده صفر | ✅ |
| اصل مانده — فقط قسط‌های پرداخت‌نشده | ✅ |
| وام خالص — بدهی منهای طلب | ✅ |
| تشخیص قسط سررسیدشده | ✅ |
| چک معوق | ✅ |
| تعهد دورهای — نزدیک‌ترین سررسید فعال | ✅ |
| تعهد دورهای غیرفعال در جمع حذف | ✅ |

---

## ۷. فایل‌های این فاز

```
pkgs/core/lib/src/liabilities/liability.dart
pkgs/core/lib/src/liabilities/liability_engine.dart
pkgs/core/lib/wealth_core.dart                  (export های جدید)
pkgs/core/test/liabilities/liability_engine_test.dart   (8)
docs/phase-11-liabilities.md
artifacts/app-preview-phase11.html
```

> **بلاکر شناخته‌شده (بدون تغییر):** تولید کد Drift و بسته‌بندی APK به رم ≥۴ گیگ نیاز دارند؛ در سندباکس (≈۱٫۱ گیگ آزاد) می‌سوزد — روی ماشین شما با `bash /home/user/wealth-os/app/build.sh`. در پایان، کل سورس Flutter به‌صورت `.zip` تحویل داده می‌شود.
