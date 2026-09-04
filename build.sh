#!/usr/bin/env bash
#
# ساخت APK / AAB (فاز ۱۶ مستر — Production).
# روی ماشینی با ≥۴ گیگ رم و Flutter + Android SDK نصب‌شده اجرا شود.
#
#   bash /home/user/wealth-os/app/build.sh [apk|aab]
#
# خروجی‌ها:
#   APK : app/build/app/outputs/flutter-apk/app-release.apk
#   AAB : app/build/app/outputs/bundle/release/app-release.aab
#
set -euo pipefail

# ۱) مسیرهای ابزار (در صورت نصب) — می‌خواهی دستی تنظیم کن:
FLUTTER="${FLUTTER:-flutter}"
export ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$(dirname "$(dirname "$(readlink -f "$(command -v flutter)" 2>/dev/null)")")}}"

cd "$(dirname "$0")"

echo "==> Flutter: $(command -v "$FLUTTER" || echo 'یافت نشد — flutter را نصب کن')"
echo "==> ANDROID_HOME=$ANDROID_HOME"
if [ ! -f android/local.properties ]; then
  echo "sdk.dir=$ANDROID_HOME" > android/local.properties
fi

echo "==> پایگاه دادهٔ تولید کد (Drift) — نیازمند رَم"
# تولید کد Drift (در صورت وجود build_runner). روی ماشین ≥۴ گیگ اجرا می‌شود.
if command -v "$FLUTTER" >/dev/null 2>&1; then
  "$FLUTTER" pub get
  # اگر build_runner نصب است، فایل‌های .g را تولید کن:
  # "$FLUTTER" pub run build_runner build --delete-conflicting-outputs || echo "(build_runner در دسترس نیست — نادیده گرفته شد)"
fi

TARGET="${1:-apk}"
case "$TARGET" in
  apk) "$FLUTTER" build apk --release;;
  aab) "$FLUTTER" build appbundle --release;;
  *) echo "خروجی نامعتبر: $TARGET (انتخاب: apk | aab)"; exit 1;;
esac

echo ""
echo "✅ ساخت کامل شد."
echo "   APK: $(pwd)/build/app/outputs/flutter-apk/app-release.apk"
echo "   AAB: $(pwd)/build/app/outputs/bundle/release/app-release.aab"
