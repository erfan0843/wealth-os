# PHASE 6 — Project Foundation
## سیستم مدیریت مالی، دارایی و ثروت شخصی
**وضعیت:** ✅ تکمیل‌شده (کد) — کد تحلیل/تست‌شده؛ Build APK در این محیط به‌دلیل حد RAM ممکن نیست.
**تاریخ:** ۲۰۲۶-۰۹-۰۳
**شاخه:** `docs/phase-06-foundation.md` | `app/` | `pkgs/core/`

---

## ۰. خلاصهٔ خروجی

**نخستین فاز واقعی کد.** پایهٔ تمام‌عیار پروژه Flutter ساخته شد؛ هستهٔ مالی خالص (پول، تقویم شمسی، دفتر کل) به‌صورت پکیج مستقل `wealth_core` با **۱۶ تست سبز**؛ و اپ Flutter با **رنگ‌های نظام طراحی فاز ۴**، **RTL و فارسی**، **روتر**، **نوار پایین** و چند اسکرین اولیه با **`flutter analyze` بدون خطا** و **تست ویجت سبز**.

---

## ۱. چه چیزی ساخته شد

### ساختار پروژه
```
wealth-os/
├── pkgs/core/         ← هستهٔ خالص Dart (بدون Flutter) → تست‌پذیر با dart test
│   ├── lib/src/date/jalali.dart      (تقویم شمسی — تبدیل متقارن/راندتریک دقیق)
│   ├── lib/src/money/money.dart      (پول Integer + Minor Unit + قالب فارسی)
│   ├── lib/src/errors/result.dart    (Result/Either + AppError)
│   ├── lib/src/ledger/ledger.dart    (دفتر کل دوبادگانه + اعتبارسنجی موجودی)
│   ├── lib/wealth_core.dart          (export عمومی)
│   └── test/ …                        (۱۶ تست)
└── app/               ← اپ Flutter (هسته به‌صورت path دپند)
    ├── lib/main.dart
    ├── lib/app/app_root.dart          (MaterialApp + RTL + فارسی + تم)
    ├── lib/core/theme/app_colors.dart (توکن‌های فاز ۴: روشن/تیره)
    ├── lib/core/theme/app_theme.dart  (ThemeData هر دو حالت)
    ├── lib/core/utils/…               (logger، config، app_strings)
    ├── lib/presentation/router/app_router.dart  (go_router، Shell)
    ├── lib/presentation/screens/app_shell.dart  (نوار پایین + FAB مرکزی)
    ├── lib/presentation/screens/{dashboard,transactions,assets,future,profile}
    ├── lib/presentation/widgets/{wealth_networth_card,wealth_metric_card}
    ├── assets/fonts/Vazirmatn-*.ttf   (فونت واقعی دانلودشد)
    └── test/widget_test.dart
```

### تصمیم‌های معماری پیاده‌شده
- **معماری لایه‌ای + Path Dep برای core** — هستهٔ مالی جدا و قابل تست (بند ۹۴).
- **RTL + فارسی** از طریق `MaterialApp` + `localizationsDelegates` (بند ۹۰).
- **ThemeMode Provider** (Riverpod)؛ آمادهٔ شخصی‌سازی از تنظیمات (بند ۸).
- **go_router Shell** با ۵ تب + FAB مرکزی (بند ۱۲).
- **توکن‌های رنگ فاز ۴** بازتاب مستقیم در ThemeData.
- **Logger با قاعدهٔ «بدون دادهٔ مالی»** (بند ۹۸).
- **AppConfig Feature-Flags**: AI/SMS/Cloud فعلاً خاموش (بند ۷۹، ۴۱، ۳).

### هستهٔ مالی تأییدشده (۱۶ تست سبز)
- `Money` جمع/تفریق/مساوی/منفی + قالب فارسی با جداکنندهٔ ٬ (۳۵۰٬۰۰۰ تومان).
- تقویم: تبدیل شمسی↔میلادی، **round-trip دقیق برای همهٔ ۳۶۶ روز ۱۴۰۵**، شنبه=۰، ماه‌های شمسی.
- دفتر کل: تعادل دوبادگانه، ردّ سند نامتوازن، جمع خالص (Credit-Debit)، مبادلهٔ خنثیِ انتقال، ردیابی مقدار (گرم).

---

## ۲. فایل‌های ایجاد/تغییر
- `app/pubspec.yaml`، `android/gradle.properties`
- `app/lib/…` (بالا)
- `pkgs/core/pubspec.yaml`، `pkgs/core/lib/…`، `pkgs/core/test/…`
- `assets/fonts/`
- `docs/phase-06-foundation.md`
- `artifacts/app-preview-phase6.html` ← پیش‌نمایش UI

## ۳. Schema دیتابیس
هیچ (فاز ۷ — Local DB — اسکیما و مایگریشن Drift را می‌سازد).

## ۴. تصمیمات معماری
Path-dep برای core، RTL/Persian، Riverpod ThemeMode، feature-flags، تم دوتایی فاز ۴، فونت Vazirmatn واقعی.

## ۵. تست‌های نوشته/اجرا شده
- `pkgs/core`: **۱۶/۱۶** `dart test` ✅ (+Ledger، Money، Jalali)
- `app`: `flutter analyze` = **No issues found** ✅
- `app`: `flutter test` (widget) = **All tests passed** ✅

## ۶. مشکلات (صادقانه)
**Build APK در این محیط ممکن نیست.** دلیل: این sandbox فقط **~۲ گیگابایت RAM** (و ~۱ گیگ آزاد) دارد. Gradle (پشت‌صحنهٔ Kotlin/AAPT) در آخرین مرحلهٔ کامپایل داemon اش OOM می‌شود. این **مشکل کد نیست** (تحلیل+تست سبز است)؛ محدودیت سخت‌افزاری است. تمام ابزارها (Dart، Flutter، JDK17، Android SDK 34، build-tools) نصب شد و فقط گامِ آخرِ بسته‌بندی به‌دلیل RAM شکست.

## ۷. باقی‌مانده / پیشنهاد
- **Build نهایی:** روی دستگاه/سرویس با ≥۴GB RAM: `cd app && flutter build apk --debug` (ابزارها آماده‌اند؛ «android/gradle.properties» به‌صورت محافظه‌کارانه تنظیم شده).
- فاز ۷ — Local DB (Drift + مایگریشن + Encryption).

## ۸. ناسازگاری با نیازمندی
هیچ؛ سازگار با بند ۹۲/۹۳/۹۴/۹۸ و فاز ۴.

---

✅ **فاز ۶ کامل شد.** `flutter analyze` و `flutter test` هر دو سبز. (Build APK در این sandbox به‌دلیل RAM ممکن نیست.)
