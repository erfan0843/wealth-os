# گزارش ممیزی کامل — «ما ساخته‌ایم» ⇄ «مستر پرامپت»

> این سند حاصل بررسی **نسخهٔ کاملِ** `MASTER PROMPT.md` (۲۵۷۹ خط) علیه تمام کد/اسنادِ ۱۳ فازِ ساخته‌شده است.
> تاریخ: ۲۰۲۶/۰۹/۰۳ · مسئول: معماری ارشد پروژه.
> نتیجهٔ تست نهایی: ✅ `dart analyze` بدون مشکل · ✅ **64/64** تست موفق.

---

## ۰. مهم‌ترین یافته: شماره‌گذاری فازهای من با مستر پرامپت یکی نیست!

مستر پرامپت (بند ۱۰۰) فازها را این‌طور تعریف می‌کند، ولی من دامنه‌ها را با شمارهٔ متفاوت برچسب زدم:

| مستر پرامپت | محتوا | برچسب من | وضعیت |
|---|---|---|---|
| PHASE 11 | **Liabilities + Future** (Debts, Receivables, Loans, Installments, BNPL, Checks, Recurring, Calendar, Forecast) | «فاز ۱۱» + «فاز ۱۲» | ✅ کامل |
| PHASE 12 | **Dashboard + Reports** (Dashboard, Net Worth, Cash Flow, Spending, Allocation, P&L, Fee Reports, Wealth Growth, Reference Asset) | «فاز ۱۳» | ⚠️ **ناقص** — Reports/RefAsset ✅ ، اما **Dashboard هنوز به‌داده وصل نیست** |
| PHASE 13 | **SMS + Local Intelligence** (Permission, Parser, Duplicate, Merchant, Rules, Category) | — | ❌ **ساخته نشده** |

**نتیجهٔ مهم:** من «۱۳ فاز» دارم اما در واقع به حدود **پایانِ فاز ۱۱ مستر** و **نصفِ فاز ۱۲ مستر** رسیده‌ام. فاز ۱۳ مستر (SMS) شروع نشده.

---

## ۱. نقشهٔ پوشش بندبه‌بند

### ✅ کاملاً پوشش‌داده‌شده
| بند | عنوان | کجا |
|---|---|---|
| ۱-۲ | فلسفهٔ محصول، Local-First | `docs/phase-01`، معماری و جریان آفلاین |
| ۳ | معماری Flutter + SQLite + Local-first | `docs/phase-02` |
| ۱۴-۱۶ | Event Model + Central Ledger + اصل دوطرفه | `ledger/event.dart`, `ledger_service` |
| ۱۷ | Net Worth = کل دارایی − کل بدهی | `ledger/networth.dart` |
| ۱۸ | Liquidity (Cash/Bank/Liquid/Non-liquid) | `networth.dart` (`LiquidityClass`) |
| ۱۹-۲۲ | Generic Asset Engine + Unit + Metadata + Lots | `assets/asset.dart` |
| ۲۳-۲۶ | Cost Basis (avg/FIFO/specific)، خرید/فروش، Realized/Unrealized P&L | `assets/{cost_basis,asset_engine}` |
| ۲۷-۳۱ | Pricing Engine + Provider + History + Cache آفلاین + `isStale` | `pricing/*` |
| ۳۵ | اولویتِ کارمزد (۶-سطّی) | 🔧 `fees/fee_rule.dart` (در این ممیزی کامل شد) |
| ۴۴ | Recurring Transactions | `future/future.dart` |
| ۴۵-۴۸ | Debts / Receivables / Loans / BNPL | `liabilities/liability.dart` |
| ۴۹ | Checks (Status) | `liabilities/liability.dart` (🔧 وضعیت «لغو» اضافه شد) |
| ۵۰-۵۱ | Future Calendar + Cash Flow Forecast | `future/future.dart` |
| ۵۵ | «پولم کجا رفت؟» | `reports.dart` (SpendAggregator) |
| ۵۶-۵۷ | Reference Asset + Historical (As-of) با **قیمت ریالی** | `reference/ref_asset.dart` (🔧 واحد «تومان» اضافه شد) |
| ۵۸ | Wealth Growth | 🔧 `reports.dart` (`WealthGrowthSeries`) |
| ۷۵ | Financial Integrity (بازدارندگی فروشِ بیش از موجودی) | `asset_engine.validateSaleQuantity` |

### 🔧 در همین ممیزی از «ناقص» به «کامل» رسید
| بند | قبل | بعد |
|---|---|---|
| ۳۲ | فقط percent/fixed/tiered | 🔧 `FeeKind` شامل **Buy/Sell/Transfer/Commission/Tax** |
| ۳۳ | قوانین زمانی نبود | 🔧 `TimeWindow` + انتخاب Rule با ساعت واقعی تراکنش |
| ۳۴ | فقط مقدار | 🔧 day-of-week / min-max quantity / min-max amount / buy-sell / start-end date |
| ۳۵ | اولویت ۴-سطّی | 🔧 اولویت **۶-سطّی** (Transaction→Asset→AssetType→User→Global→Default) |
| 36 | درصد/ثابت | 🔧 فرمول **percent+fixed** + **کف/سقف** (min/max) |
| ۴۹ | وضعیت چک بدون «لغو» | 🔧 `cancelled` اضافه شد |
| ۵۴/۵۸ | فقط Spending/Allocation/Growth تک‌نقطه | 🔧 **PnLReport, CashFlowReport, NetWorthReport, WealthGrowthSeries** |

---

## ۲. شکاف‌های باقی‌مانده (مطابق مستر پرامپت)

### A. فازهای مستر که هنوز هستند
1. **PHASE 12 — Dashboard**: فقط یک داشبوردِ استاتیک/نمونه‌ای (`app/lib/presentation`) وجود دارد؛ **به موتورها و داده متصل نیست** (Drift repo ننوشته به‌خاطر OOM). باید کامل شود.
2. **PHASE 13 — SMS + Local Intelligence**: **کاملاً ساخته نشده**. نیازمند: Permission، Parser محلی، Duplicate Detection، Merchant Recognition، Local Rules، Category Suggestions.
3. **PHASE 14 — AI Layer** (اختیاری)، **PHASE 15 — Security/Backup/Sync/Конфликт**، **PHASE 16 — QA/Production**.

### B. الزاماتِ خاص که در هیچ فازی «مستقیم» نیامده‌اند (باید دربارهٔ جانمایی تصمیم بگیریم)
| بند | قابلیت | وضعیت |
|---|---|---|
| ۵۹ | Goals | ❌ پیاده نشده — در فازهای مستر به‌صراحت نیست؛ پیشنهاد: در Dashboard+Reports یا یک فازِ Goals/Budget |
| ۶۰ | Budget | ❌ همین‌طور |
| ۶۱ | Alerts | ❌ (ماژول notifications؛ پیشنهاد در فاز ۱۵/۱۶) |
| ۶۲-۶۴ | Search / Filters / Tags | ❌ (پیشنهاد: فاز تراکنش‌ها یا SMS) |
| ۶۵-۶۶ | Attachments / OCR | ❌ (اختیاری؛ پیشنهاد فاز ۱۴/۱۵) |
| ۶۷-۶۹ | Export / Import / Backup / Sync | در فاز ۱۵/۱۶ مستر |
| ۷۶ | Reconciliation | طراحی‌شده به‌عنوان آینده؛ در فازهای پایانی |

### C. محدودیت‌های صادقانه (که از مستر عقب هستند)
- **§۱۱۰ Definition of Done** می‌گوید هر فاز باید **Database Migration + UI کامل + Validation + Error Handling + Offline** داشته باشد. فازهای ۸-۱۳ من **هستهٔ خالصِ** هستند: **Migration/Drift repo** به‌خاطر OOM سندباکس نوشته نشده، و **UI به‌صورت preview HTML** است نه Flutter واقعیِ متصل به داده. این مهم‌ترین ناسازگاری با DoD است.
- **§۹۴/۹۵ تست‌ها**: Unit تست‌ها خوب است؛ **Database / Sync / Parser / UI** تست‌ها هنوز نیست.

---

## ۳. تغییراتِ اعمال‌شده در این ممیزی (تست‌زده)

- `fees/fee_rule.dart` + `fees/fee_engine.dart` — بازسازی پرسپکتیو بند ۳۲-۳۶ (انواع، زمان، اولویت ۶-سطّی، درصد+ثابت، کف/سقف، Override).
- `fees/fee_engine_test.dart` — بازنویسی با ۱۰ سناریو (شامل ساعت، مقدار، خرید/فروش، کف/سقف، اولویت).
- `liabilities/liability.dart` — وضعیت چک `cancelled`.
- `reference/ref_asset.dart` — واحد مرجع `toman`.
- `reports/reports.dart` — `PnLReport`, `CashFlowReport`, `NetWorthReport`, `WealthGrowthSeries`.
- `reports/reports_test.dart` — ۵ سناریوی جدید.

**نتیجه:** ۶۴/۶۴ تست، آنالایز بدون مشکل.

---

## ۴. توصیهٔ مسیر اصلاحی (با درخواست تأیید — طبق بند ۰/۱۱۲/۱۱۳)

طبق مستر پرامپت، ترتیب درستِ باقی‌مانده باید این باشد:

1. **تکمیل فاز ۱۲ مستر = Dashboard واقعی** (وصل کردن داشبورد به موتورها + توافق «چگونه بدون Drift repo و با UI فلتر/پیش‌نمایش با داکتای دادهٔ نمونه»).
   ⚠️ این نیازمند یک تصمیم بزرگ معماری است (چطور UI واقعی را بدون کد Drift (OOM) به داده وصل کنیم) — **قبل از نادیده‌گرفتن، از شما تأیید می‌گیرم.**
2. **فاز ۱۳ مستر = SMS + Local Intelligence** (Parser محلی با Regex، Duplicate، Merchant، Category Rules).
3. سپس فازهای ۱۴ (AI اختیاری)، ۱۵ (Security/Backup/Sync)، ۱۶ (QA/Production).

---

## ۴.۵ ⏫ به‌روزرسانی پس از تأیید «هرجور کامل‌تر» (این نوبت)

با تأیید شما، **گزینهٔ ۱ + نگاهِ «هر چه کامل‌تر»** اجرا شد و شماره‌گذاری با مستر هم‌تراز شد:

### ✅ فاز ۱۲ مستر (Dashboard + Reports) — تکمیل شد
- **`transaction.dart`** — مدل تراکنش (دسته/برچسب/مرکچنت؛ بند ۱۴/۶۲-۶۴).
- **`dashboard/dashboard.dart`** — `DashboardBuilder` (UseCase) موتورهای NetWorth/Spending/Allocation/Growth/RefAsset را در یک `DashboardSnapshot` قابل‌تست ترکیب می‌کند (بند ۹۲/۹۳).
- **`WealthItem`** + فلگ `isLiability` (بند ۱۷ — تفکیک صحیح).
- تست یکپارچه: ترکیبِ ثروت/درآمد/تخصیص/واحد مرجع. ✅

### ✅ فاز ۱۳ مستر (SMS + Local Intelligence) — ساخته شد
- **`sms.dart`** — `SmsParser` (بانک/مبلغ/نوع/مرجع/تاریخ شمسی)، `MerchantRecognizer`، `CategorySuggester`، `SmsDuplicateDetector`، `LocalCategoryRule` (بند ۴۱-۴۳، ۸۰، ۹۵). همه Local، بدون AI.
- ۹ تست جدید. ✅

### 🧪 وضعیت تست فعلی
- `dart analyze` → بدون مشکل
- `dart test` → **75/75** موفق

### 📌 مراحل بعدی مستر (باقی‌مانده)
1. **اتصال UI/DB واقعی** (Drift + repo + Flutter screens) — نیازمند ≥۴ گیگ رم.
2. **فاز ۱۴ مستر** (AI Layer، اختیاری) · **فاز ۱۵** (Security/Backup/Sync) · **فاز ۱۶** (QA/Production).
3. **بندهای ۵۹-۶۱** (Goals/Budget/Alerts) و **۶۲-۶۶** (Search/Filters/Tags/Attachments/OCR).

---

## ۵. تصمیمی که باید بگیرید (منتظر تأیید — پیش از تغییر بزرگ بعدی)

با توجه به اینکه شماره‌گذاری من با مستر اختلاف دارد و §۱۱۲/§۱۱۳ می‌گوید «قبل از تصمیم بزرگ منتظر تأیید بمان»، لطفاً جهت را مشخص کنید:

- **گزینه ۱:** نام‌گذاری فازهای خودم را با مستر هم‌تراز کنم (فاز ۱۲ = Dashboard+Reports، فاز ۱۳ = SMS) و از هم‌اکنون دقیقاً همان ترتیب بروم.
- **گزینه ۲:** چون هستهٔ فازهای ۸-۱۱ کامل است، اول **فاز ۱۳ مستر (SMS)** را بسازم (هستهٔ خالص با Regex/Rules) و Dashboardِ متصل را بعداً.
- **گزینه ۳:** اول **Goals/Budget/Alerts** (بند ۵۹-۶۱ که در هیچ فازی نیامده‌اند) را تعیین تکلیف و پیاده کنم.

(من گزینهٔ ۱ را توصیه می‌کنم چون دقیق‌ترین تطابق با مستر است و از اشتباه در شماره‌گذاری جلوگیری می‌کند.)
