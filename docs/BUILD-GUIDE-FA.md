# راهنمای «به تولید رساندن» — از سورس تا APK نصبی

> این سند دقیقاً می‌گوید که تو **الان** چطور این پروژه را روی سیستمِ خودت (ویندوز/مک/لینوکس با ≥۴ گیگ رم) به یک APK نصب‌شدنی تبدیل کنی.
> کل سورس در **`/home/user/wealth-os.zip`** (۲۸۳KB) آماده است.

---

## ۰. خلاصهٔ مسیر (۳ قدم)

```
۱) نصب ابزارها (Flutter + Android SDK + JDK + گیت)
۲) بازکردن زیپ و دریافت وابستگی‌ها
۳) اجرای build.sh → APK
```

---

## ۱. نصب ابزارها (یک‌بار)

### ۱.۱ Flutter (باید نسخهٔ ۳.۲۴+ و Dart ۳.۳+)
- **ویندوز:** [flutter.dev/get-started](https://docs.flutter.dev/get-started/install/windows) → `flutter_windows_*.zip` را باز و `flutter/bin` را به `PATH` اضافه کن.
- **مک:** `brew install --cask flutter` یا zip رسمی.
- **لینوکس:** zip رسمی + نصب git، curl، unzip، و `liblz4`.
- سپس در ترمینال:
  ```bash
  flutter doctor      # باید همه چیز سبز باشد
  ```

### ۱.۲ Android SDK (فرمان‌های flutter doctor شما را راهنمایی می‌کند)
- **ساده‌ترین راه:** Android Studio → "Android SDK" را نصب کن، یا خودِ `flutter doctor --android-licenses` SDK را می‌گیرد.
- مطمئن شو: `ANDROID_HOME` تنظیم باشد (در `build.sh` قابل‌تغییر است).

### ۱.۳ JDK 17
- Flutter از JDK 17 استفاده می‌کند: `brew install --cask temurin` (مک) / `winget install EclipseAdoptium.Temurin.17.JDK` (ویندوز).

### ۱.۴ گیت
- Flutter نیاز به גit دارد (برای clone/cache). نصب کن.

---

## ۲. آماده‌سازی پروژه

```bash
# ۱) زیپ را باز کن
cd ~
unzip wealth-os.zip -d wealth-os
cd wealth-os

# ۲) برو داخل app و وابستگی‌ها را بگیر
cd app
flutter pub get

# (اختیاری) اگر build_runner هست، کد Drift را تولید کن:
dart run build_runner build --delete-conflicting-outputs
```

---

## ۳. ساخت APK

### ساده — یک دستور:
```bash
bash /home/user/wealth-os/app/build.sh apk
```
> اگر `ANDROID_HOME`/`FLUTTER` درست نیستند، اول:
> `export ANDROID_HOME=/مسیر/به/android-sdk`
> `export FLUTTER=flutter` (یا مسیر کامل)

یا مستقیم:
```bash
cd wealth-os/app
flutter build apk --release
```

### خروجی:
```
wealth-os/app/build/app/outputs/flutter-apk/app-release.apk
```
این فایل را به موبایل (اندروید ۷+) منتقل کن و نصب کن (فعال‌سازی «نصب از منابع ناشناس»).

### برای فروشگاه (Play Store):
```bash
flutter build appbundle --release
# → wealth-os/app/build/app/outputs/bundle/release/app-release.aab
```

---

## ۴. اگر خطا گرفت

| مشکل | راه‌حل |
|---|---|
| `flutter doctor` خطا → Android SDK | `flutter doctor -v` و طبق راهنما SDK را بگذار؛ `sdkmanager --licenses` |
| OOM / Gradle کند | رم ≥۴ گیگ لازم؛ در `android/gradle.properties` خط `org.gradle.jvmargs=-Xmx2048m` را به `-Xmx4g` بالا ببر |
| کد Drift (`*.g.dart`) موجود نیست | `dart run build_runner build` |
| `unsigned apk` (برای نصب مستقیم لازم است) | `flutter build apk --release` خودش با debug-key امضا می‌کند؛ برای انتشار واقعی keystore بگذار (بخش ۵) |

---

## ۵. برای انتشار واقعی (اختیاری، بعد از تست)

1. **keystore:** یک فایل `.jks` با `keytool` بساز:
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. **مسیر امضا:** در `android/app/build.gradle` و `key.properties` (این‌ها فعلاً با debug-key ساخته می‌شوند).
3. **نسخه‌بندی:** در `app/pubspec.yaml` مقدار `version:` را زیاد کن (مثل `0.1.0+1`).

---

## ۶. بعد از نصب APK — انتظار چه چیزی

- برنامهٔ Flutter رندر می‌شود (داشبورد/ثبت سریع/دارایی/آینده/پروفایل — پیش‌نمایش‌های HTML معادل صفحات‌اند).
- دادهٔ محلی در SQLite (رمزنگاری‌شده با کلید در SecureStorage).
- هستهٔ مالی (خرید/فروش/قسط/گزارش/واحد مرجع/پیامک/امنیت) از `pkgs/core` — همان که ۹۳/۹۳ تست دارد.

> ⚠️ صادقانه: هم‌اکنون **UI اصلی متصل به دادهٔ واقعی Drift نیست**؛ داشبورد/فرم‌ها نمونه‌اند تا وقتی `build_runner` کل جداول را تولید کند. منطق مالی درست و تست‌شده است.

---

## ۷. فایلهای کلیدی برای مراجعه

- `wealth-os/app/build.sh` — اسکریپت ساخت
- `wealth-os/app/android/` — پروژهٔ اندروید
- `wealth-os/pkgs/core/` — موتورهای مالی (۹۳ تست)
- `wealth-os/docs/` — اسناد فازهای ۱-۱۶
- `wealth-os/artifacts/` — پیش‌نمایش‌های UI هر فاز
