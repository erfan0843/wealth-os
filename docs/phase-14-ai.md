# فاز ۱۴ (مستر پرامپت) — لایهٔ AI (کاملاً اختیاری)

> **هم‌ترازی:** مستر پرامپت این را «فاز ۱۴» (بعد از تکمیل Core) نامیده (بند ۱۰۰).
> وضعیت: ✅ تحویل و سبز — `dart analyze` بدون مشکل، **80/80** تست (۵ جدید در این فاز).

---

## ۱. اصول رعایت‌شده

- **بند ۵:** AI قابلیت Optional است؛ Core Feature به AI وابسته نیست.
- **بند ۶ (Privacy by Design):** پردازش روی دستگاه؛ بدون ارسال غیرضروری؛ API Key در اپ هاردکد نمی‌شود؛ دادهٔ ضروری با `AiSettings.privacy`.
- **بند ۷۸:** سیستِم **اول دادهٔ ساختاریافته را Local استخراج می‌کند** (درآمد/هزینه/تغییر دارایی/تغییر بدهی/P&L)؛ AI فقط **تحلیل زبانی** تولید می‌کند. **AI هرگز محاسبات مالی پایه را انجام نمی‌دهد.**
- **بند ۷۹:** اگر خاموش باشد، برنامه بدون AI **کاملاً** کار می‌کند.
- **بند ۱۰۲ (ضد Overengineering):** بدون دپندنسی/نیاز؛ فقط یک رابطِ کوچک.

## ۲. `ai/ai.dart` — هستهٔ خالص

| ابزار | توضیح |
|---|---|
| `AiSettings { enabled, privacy }` | روشن/خاموش + حالت حریم خصوصی (`AiPrivacyMode`). |
| `FinancialSummary` | حقایقِ ساختاریافته‌ی محاسبه‌شده در دستگاه؛ `netChangeMinor` و `buildAiSafeSummary()` (حقایق، بدون شناسهٔ شخصی). |
| `FinancialSummaryExtractor` | ساختِ `FinancialSummary` از اعداد — Local. |
| `AiProvider` (interface) | تزریق خارجی LLM (کلید/URL در لایهٔ App/`flutter_secure_storage`؛ نه اینجا). |
| `AiAssistant` | اگر `enabled` و Provider باشد → `ask(...)`؛ وگرنه `null`. |
| `LocalAnalytics` | تحلیل Local بدون AI (بند ۷۷): میانگین، رشد دسته، آنومالی با آستانه. |

### تست‌ها (۵)
- خاموش → `null` (برنامه کامل کار می‌کند).
- بدون Provider → `null`.
- فعال + Provider → پاسخ و فقط دادهٔ ساختاریافته.
- استخراج ساختاریافته — AI محاسبات پایه نمی‌کند (`netChangeMinor` و رشتهٔ امن).
- LocalAnalytics — میانگین/رشد/آنومالی.

## ۳. فایل‌ها

```
pkgs/core/lib/src/ai/ai.dart
pkgs/core/lib/wealth_core.dart                 (export)
pkgs/core/test/ai/ai_test.dart                 (5)
docs/phase-14-ai.md
artifacts/app-preview-phase14.html
```

> ⚠️ خودِ Provider واقعی (مثلاً یک LLM) با کلید کاربری در لایهٔ App/SecureStorage در فاز ۱۶/انتشار فعال می‌شود؛ اینجا فقط قرارداد اختیاری است. هیچ کد/کلید/URL در هسته نیست.
