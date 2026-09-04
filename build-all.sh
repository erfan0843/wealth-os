#!/usr/bin/env bash
# ============================================================================
#  Wealth OS — بیلدِ خودکفا  (روی هر سیستم با ≥4GB رم + اینترنت)
#  هدف: نصب هر ابزار لازم ( اگر نبود ) و سپس تولید APK نصب‌شدنی.
#
#  استفاده:
#      bash build-all.sh            # ساخت APK (release)
#      bash build-all.sh aab        # ساخت Android App Bundle (فروشگاه)
#
#  خروجی:
#      app/build/app/outputs/flutter-apk/app-release.apk
# ============================================================================
set -euo pipefail

TARGET="${1:-apk}"
ROOT="$(cd "$(dirname "$0")" && pwd)"
WORK="${HOME}/.wealthos-tools"
mkdir -p "$WORK"

echo "═══════════════════════════════════════════════"
echo "  Wealth OS — Build (خودکفا)   هدف: ${TARGET}"
echo "═══════════════════════════════════════════════"

# ---------- ابزارهای پایه ----------
echo ""
echo "▸ بررسی ابزارهای پایه (git, curl, unzip) ..."
for t in git curl unzip tar; do
  if ! command -v "$t" >/dev/null 2>&1; then
    echo "   ✗ $t نصب نیست. لطفاً نصب کن:  sudo apt install $t   (یا معادل مک/windows)"
    exit 1
  fi
done
echo "   ✓ ابزارهای پایه موجودند."

# ---------- JDK 17 ----------
echo ""
echo "▸ بررسی JDK 17 ..."
JAVA_HOME_TARGET=""
if [ -d "${WORK}/jdk17" ]; then
  JAVA_HOME_TARGET="${WORK}/jdk17"
elif command -v javac >/dev/null 2>&1 && java -version 2>&1 | grep -q '17'; then
  JAVA_HOME_TARGET="$(dirname "$(dirname "$(readlink -f "$(command -v javac)")")")"
else
  echo "   ⏳ در حال دانلود JDK 17 (Adoptium)..."
  # ساده‌تر: از apt (لینوکس) یا آرشیو رسمی
  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get install -y openjdk-17-jdk || true
  fi
  if ! java -version 2>&1 | grep -q '17'; then
    echo "   ⏳ دانلود JDK 17 tar.gz ..."
    ARCH=$(uname -m)
    case "$ARCH" in x86_64) A=x64;; aarch64) A=aarch64;; esac
    URL="https://api.adoptium.net/v3/binary/latest/17/ga/linux/${A}/hotspot/normal/eclipse"
    curl -sL -o "$WORK/jdk17.tar.gz" "$URL"
    mkdir -p "$WORK/jdk17"
    tar -xzf "$WORK/jdk17.tar.gz" -C "$WORK/jdk17" --strip-components=1
    JAVA_HOME_TARGET="${WORK}/jdk17"
  else
    JAVA_HOME_TARGET="$(dirname "$(dirname "$(readlink -f "$(command -v javac)")")")"
  fi
fi
export JAVA_HOME="$JAVA_HOME_TARGET"
export PATH="$JAVA_HOME/bin:$PATH"
echo "   ✓ JDK: $("$JAVA_HOME/bin/java" -version 2>&1 | head -1)"

# ---------- Flutter ----------
echo ""
echo "▸ بررسی Flutter ..."
FLUTTER_BIN=""
if command -v flutter >/dev/null 2>&1; then
  FLUTTER_BIN="$(command -v flutter)"
elif [ -x "${WORK}/flutter/bin/flutter" ]; then
  FLUTTER_BIN="${WORK}/flutter/bin/flutter"
else
  echo "   ⏳ دانلود Flutter (stable) ..."
  mkdir -p "$WORK/flutter"
  curl -sL -o "$WORK/flutter.tar.xz" \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.5-stable.tar.xz"
  tar -xf "$WORK/flutter.tar.xz" -C "$WORK"
  FLUTTER_BIN="${WORK}/flutter/bin/flutter"
fi
chmod +x "$(dirname "$FLUTTER_BIN")"/flutter "$(dirname "$FLUTTER_BIN")"/dart
export PATH="$(dirname "$FLUTTER_BIN"):$PATH"
echo "   ✓ Flutter: $("$FLUTTER_BIN" --version 2>&1 | head -1)"

# ---------- Android SDK ----------
echo ""
echo "▸ بررسی Android SDK ..."
export ANDROID_HOME="${ANDROID_HOME:-${WORK}/android-sdk}"
if [ ! -d "${ANDROID_HOME}/cmdline-tools/latest/bin" ]; then
  echo "   ⏳ دانلود Android cmdline-tools + SDK ..."
  mkdir -p "$ANDROID_HOME"
  curl -sL -o "$WORK/clt.zip" \
    "https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
  unzip -q "$WORK/clt.zip" -d "$ANDROID_HOME/cmdline-tools"
  mv "$ANDROID_HOME/cmdline-tools/cmdline-tools" "$ANDROID_HOME/cmdline-tools/latest" 2>/dev/null || true
fi
SDKMANAGER="${ANDROID_HOME}/cmdline-tools/latest/bin/sdkmanager"
if [ -x "$SDKMANAGER" ]; then
  echo "   ⏳ نصب license + build-tools + platform (ممکن است چند دقیقه طول بکشد) ..."
  yes | "$SDKMANAGER" --sdk_root="$ANDROID_HOME" \
    "build-tools;34.0.0" "platform-tools" "platforms;android-34" >/dev/null 2>&1 || true
  yes | "$SDKMANAGER" --sdk_root="$ANDROID_HOME" --licenses >/dev/null 2>&1 || true
fi
echo "   ✓ Android SDK: $ANDROID_HOME"

# ---------- پروژه ----------
cd "$ROOT/app"
echo ""
echo "▸ flutter pub get ..."
"$FLUTTER_BIN" pub get

echo "▸ (اختیاری) تولید کد Drift ..."
if command -v dart >/dev/null 2>&1; then
  dart pub global activate build_runner >/dev/null 2>&1 || true
  echo "   (build_runner نادیده گرفته شد — در صورت نیاز بعداً اجرا کن)"
fi

echo "▸ ساخت ..."
echo "   sdk.dir=$ANDROID_HOME" > android/local.properties
case "$TARGET" in
  apk) "$FLUTTER_BIN" build apk --release;;
  aab) "$FLUTTER_BIN" build appbundle --release;;
  *) echo "خروجی نامعتبر"; exit 1;;
esac

echo ""
echo "═══════════════════════════════════════════════"
echo "  ✅ تمام شد!"
echo "  APK: ${ROOT}/app/build/app/outputs/flutter-apk/app-release.apk"
echo "  AAB: ${ROOT}/app/build/app/outputs/bundle/release/app-release.aab"
echo "═══════════════════════════════════════════════"
