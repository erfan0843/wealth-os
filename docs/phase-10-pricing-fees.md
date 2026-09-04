# فاز ۱۰ — موتور قیمت‌گذاری و کارمزد (Pricing + Fee Engine)

> بندهای پوشش‌داده‌شده: ۲۷، ۲۸، ۲۹، ۳۰، ۳۱، ۳۲، ۳۵، ۳۶، ۳۷، ۳۸، ۸۲.
> وضعیت: ✅ تحویل و سبز — `dart analyze` بدون مشکل، `37/37` تست موفق.

---

## ۱. دو زیرموتور مستقل

| زیرموتور | مسیر | مسئولیت |
|---|---|---|
| **Pricing** | `pkgs/core/lib/src/pricing/` | Providerها، تاریخچه، کش آفلاین، رزولوشن قیمت، وضعیت منبع |
| **Fee** | `pkgs/core/lib/src/fees/` | قوانین کارمزد، اولویت (Priority)، تاریخ‌محور، اسنیپ‌شات و Override |

هر دو **خالص** (Pure Dart، بدون Flutter/DB) و مستقیماً با `dart test` تست شدند؛ لایهٔ DB در فازهای آخر (Drift) متصل می‌شود.

---

## ۲. موتور قیمت‌گذاری Pricing

### مدل‌ها (`price.dart`)
- `PriceSnapshot { assetTypeId, assetId?, price, currency, unit, sourceId, observedAt, status }` — عکس‌فوری قیمت در لحظه (بند ۳۰).
- `PriceStatus { live, stale, manual, unknown }` — وضعیت منبع/قیمت (بند ۸۲).
- `PriceSource { id, code(MANUAL/API/CSV/CHARISMA/CUSTOM), name, priority, enabled }` — منبع قیمت (بند ۲۸).
- `PriceHistoryEntry` — رکورد تاریخچهٔ قیمت (بند ۳۰).
- `OfflinePriceCacheEntry { lastPrice, lastObservedAt, status }` — کش آفلاین (بند ۳۱).

### Providerها (`price_provider.dart`)
- قرارداد `PriceProvider`: `supports()`, `fetchLive()`, `fetchAsOf()`.
- `ManualPriceProvider` — قیمت دستی (بند ۲۷).
- `ApiPriceProvider` — API عمومی؛ بدون هاردکد URI، فقط قرارداد (تزریق Provider رسمی مثل CHARISMA در مراحل بعد با Endpoint تأییدشده).

### هماهنگ‌کننده (`price_coordinator.dart`)
- `PriceCoordinator.resolve(request)`:
  1. تلاش روی همهٔ Providerها به ترتیب؛ اولین «LIVE» موفق برنده (بند ۲۷).
  2. استثنا/خطا → امتحان Provider بعدی (بند ۲۸).
  3. هیچ‌کدام → **افتادن به کش آفلاین** با `status = stale` و فلگ `fromCache/isStale` (بند ۸۲؛ هرگز قیمت قدیمی به‌عنوان لحظه‌ای گزارش نمی‌شود).
  4. بدون کش → خطا.
- `PriceResult { snapshot?, fromCache, isStale, error? }` — شفاف در مورد منبع و کهنگی.
- `asOf(request, date)` — قیمت تاریخ‌دار برای واحد مرجع (بند ۵۷).
- `PriceCachePort` interface — جداشدگی DB (در data/ پیاده می‌شود).

---

## ۳. موتور کارمزد Fees

### قوانین (`fee_rule.dart`)
- `FeePriority { bankAccount, exchange, assetType, amount }` — رتبهٔ اولویت (بند ۳۵).
- `FeeType { percent, fixed, tiered }` (بند ۳۳).
- `FeeRule { id, type, priority, rate, distribution }` — `distribution = post` (بند ۴۰: کارمزد بعد از مبلغ؛ برای fees همیشه Post).
- `FeeRuleSnapshot` — اسنیپ‌شات پس از هر ویرایش (بند ۳۷).
- `FeeOverride { ruleId, multiplier?, overrideRate?, at }` — اعمال/آخرین‌نوشتار (بند ۳۷).

### موتور (`fee_engine.dart`)
- `FeeEngine.resolve(target)` → **بالاترین Priority برنده**؛ در اولویتِ مساوی، **آخرین‌قانون/آخرین‌ویرایش غالب** (بند ۳۵، ۳۷).
- Override آخرین‌زمان → نرخ جایگزین یا ضرب در multiplier (بند ۳۷).
- `computeFor(target, gross)` → `FeeResult { rule?, fee, distribution, overridden }`.
- `percent`: `fee = gross × rate / 100`؛ `fixed`: `fee = rate`.
- `snapshot(rule)` → ثبت اسنیپ‌شات برای Audit بعد از ویرایش (بند ۳۷).

---

## ۴. تصمیم‌های کلیدی ثبت‌شده

1. **قیمت منبع ≠ قیمت لحظه‌ای**: API رسمی (CHARISMA) تا فاز تأیید Endpoint تزریق نمی‌شود؛ با قرارداد `ApiPriceProvider` باز بماند. Manual برای حال حاضر.
2. **کش آفلاین شفاف**: قیمت کش‌شده هرگز به‌عنوان LIVE گزارش نمی‌شود؛ فلگ `isStale` برای UI (نمایش «نامعتبر/قدیمی») (بند ۸۲).
3. **اولویت کارمزد**: با `rank` عددی، و قاعدهٔ «برندهٔ آخرینِ هم‌رتبه» برای پشتیبانی از ویرایش متوالی (بند ۳۵، ۳۷) — در تست `fee_engine_test` «برندهٔ هم‌رتبه» بار اول شکست خورد و با تقویت منطق رزولوشن اصلاح شد.
4. **ارقام فارسی در UI**: همهٔ اعداد از `format.dart` (بنا بر `toFaNumber`/`groupThousands`) — طبق دستور «عدد انگلیسی نگذار».

---

## ۵. خلاصهٔ تست‌ها (37/37)

| گروه | تعداد | توضیح |
|---|---|---|
| Money + فارسی/٬ | 5 | جمع/تفریق، برابری، منفی، گروه‌بندی و ارقام فارسی |
| Jalali + گردش | 6 | تبدیل و بازگشت، Nowruz، ایام هفته شنبه=۰، ارقام فارسی |
| LedgerService | 5 | هزینه/انتقال/خرید/فروش/کارمزد — متوازن |
| NetWorth | 3 | کل دارایی − کل بدهی، C11 نقدینگی، نیمه‌نقدشونده |
| AssetEngine (فاز ۹) | 8 | Cost Basis میانگین/FIFO، کارمزد، Realized/Unrealized P&L، بازدارندگی فروشِ بیش از موجودی |
| **PriceCoordinator (فاز ۱۰)** | 4 | Manual برنده، افتادن به کش کهنه، خطای بدون قیمت، امتحان Provider بعدی |
| **FeeEngine (فاز ۱۰)** | 6 | درصد/ثابت/هم‌رتبه، بالاترین اولویت، بدون قاعده صفر، Override آخرین‌نوشتار |

---

## ۶. فایل‌های این فاز

```
pkgs/core/lib/src/pricing/price.dart
pkgs/core/lib/src/pricing/price_provider.dart
pkgs/core/lib/src/pricing/price_coordinator.dart
pkgs/core/lib/src/fees/fee_rule.dart
pkgs/core/lib/src/fees/fee_engine.dart
pkgs/core/lib/wealth_core.dart          (export های جدید)
pkgs/core/test/pricing/price_coordinator_test.dart   (4)
pkgs/core/test/fees/fee_engine_test.dart             (6)
app/lib/core/utils/format.dart          (ابزار قالب‌بندی فارسی — مشترک)
docs/phase-10-pricing-fees.md
artifacts/app-preview-phase10.html
```

> **بلاکر شناخته‌شده**: `dart run build_runner` (تولید فایل‌های Drift) و `flutter build apk` در این سندباکس به‌خاطر کمبود RAM (≈۱٫۱ گیگ آزاد) شکست می‌خورند — نیازمند ماشین ≥۴ گیگ. کد تمیز است؛ ورودی `bash /home/user/wealth-os/app/build.sh`.
