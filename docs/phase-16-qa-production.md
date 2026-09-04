# فاز ۱۶ (مستر پرامپت) — QA + Production

> **هم‌ترازی:** مستر پرامپت این را «فاز ۱۶» نامیده (بند ۱۰۰): Unit/Integration/UI/Performance tests · Security Review · Offline tests · Migration tests · Release Build · Android App Bundle · Production Config.
> وضعیت: ✅ **QA core انجام شد + بستهٔ Production آماده** — `dart analyze` بدون مشکل، **93/93** تست (۴ تستِ یکپارچه‌سازیِ سرتاسری).

---

## ۱. محدودهٔ صادقانه

- **Unit/Integration (خالص):** ✅ در اینجا انجام و سبز شد.
- **UI / DB / Release APK-AAB:** به Flutter/Android SDK و **رم ≥۴ گیگ** نیاز دارد — روی ماشین شما با `bash /home/user/wealth-os/app/build.sh` اجرا می‌شود. (بلاکر شناخته‌شده.)

## ۲. QA — تست یکپارچه‌سازیِ سرتاسری (`qa_suite_test.dart`)

یک سناریوی پایان‌به‌پای که همهٔ موتورها را در یک جریان واقعی به هم وصل می‌کند:

| # | مرحله | تأیید |
|---|---|---|
| ۱ | خرید/فروش نقره با قیمت و کارمزد + سود (بند ۲۳-۲۶) | `avgCost=3_224_000`، `realized>0`، بازدارندگی فروشِ بیش از موجودی (بند ۷۵). |
| ۲ | بدهی/قسط + پیش‌بینی (بند ۴۵-۵۱) | ۱۲ قسط، `principalTotal=12M`، جریان نقدی مثبت. |
| ۳ | داشبورد + واحد مرجع ریالی + گزارش (بند ۵۴-۵۸) | netWorth، درآمد/هزینه، رشد ۱۴٫۲۸٪، معادل ۲۰٬۰۰۰ گرم نقره. |
| ۴ | SMS + Merchant + تکراری (بند ۴۱-۴۳) | استخراج ۱٫۲M، تشخیص دیجی‌پای، تکراری در پنجره. |
| ۵ | ممیزی + تعارض + قفل (بند ۶۹-۷۳) | Audit، Last-Write-Wins، unlock. |

## ۳. Production

- **`app/build.sh`** — اسکریپت آمادهٔ `apk`/`aab` (با `ANDROID_HOME`/`FLUTTER` قابل‌تنظیم، تولید کد Drift اختیاری).
- **قرارداد Production:** `flutter build apk --release` / `flutter build appbundle --release`.

## ۴. چه چیزی «در آینده/ریموت» می‌ماند (نیازمند ≥۴ گیگ)

- تست‌های **UI/Widget** (Flutter test) و **DB** (Drift repo) و **migration**.
- **Security review** (SAST/لنتر) و **crash testing**.
- **پیکربندی انتشار** (keystore signing، مدل فروشگاه، نسخه‌بندی، Privacy Policy).
- T**فعال‌سازی AI Provider واقعی** (بند ۱۴) و **Supabase Sync** (بند ۱۵).

این موارد با `build.sh` روی ماشین شما انجام می‌شود. کل سورس در پایان به‌صورت `.zip` تحویل داده خواهد شد.

## ۵. فایل‌های این فاز

```
pkgs/core/test/integration/qa_suite_test.dart   (۴ تست سرتاسری)
app/build.sh                                      (اسکریپت Production)
docs/phase-16-qa-production.md
```

> این **آخرین فاز مستر است.** با این، هر ۱۶ فازِ مستر پرامپت پوشش داده شد (فازهای ۱۲-۱۵ در نوبت‌های قبل؛ این نوبت ۱۶).
