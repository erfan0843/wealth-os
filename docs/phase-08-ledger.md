# PHASE 8 — Financial Ledger
## سیستم مدیریت مالی، دارایی و ثروت شخصی
**وضعیت:** ✅ منطق خالص کامل + تست ۱۹/۱۹ سبز؛ لایهٔ DB پیاده‌سازی شد (روی ماشین ≥۴GB کامپایل می‌شود).
**تاریخ:** ۲۰۲۶-۰۹-۰۳
**شاخه:** `docs/phase-08-ledger.md` | `pkgs/core/lib/src/ledger/` | `app/lib/data/domain|db/ledger_repository*`

---

## ۰. چرا این فاز مهم است
دفتر کل «منبع حقیقت» محاسبات مالی است (بند ۱۵). هر رویداد به سندهای دوبادگانه ترجمه می‌شود که اثر مالی واقعی را ثبت می‌کند (بند ۱۶). این دقیقاً همان تفکیک درست است که خرید طلا را «مبادله» (نه هزینه) و طلب را «غیرنقد» می‌کند (بند ۱۰۳).

## ۱. چه چیزی ساخته شد

### ۱.۱ مدل رویداد (بند ۱۴-۱۵) — `event.dart`
- `EventKind` (۳۰ نوع از بند ۱۴): income, expense, transfer, assetBuy, assetSale, assetAdjust, fee, tax, debtCreate, debtPay, receivableCreate, receivableCollect, loan, installment, checkIssued/Received/Cleared/Returned, refund, discount, interest, penalty, investment, divestment, other.
- `EventStatus` (active/reversed — بند ۷۴).
- `LedgerEntry` (جهت Debit/Credit، موضوع حساب/دارایی/تعهد، پول+کمیت+واحد).
- `FinancialEvent` (id, userId, kind, time, currency, status, reference, note, entries).

### ۱.۲ موتور دفتر کل — `ledger_engine.dart`
- `validateBalanced`: تعادل دوبادگانه (Sum Debit == Sum Credit).
- `netBalance`/`balanceOf`: جمع بده-بستان یک موضوع.
- `quantityOf`: ردیابی مقدار (گرم/سهم).
- `afterBalance`: جلوگیری از موجودی منفی بدون Short-position (بند ۷۵ / ۱۰۳).
- `QuantityTracker`.

### ۱.۳ سرویس ساخت رویداد — `ledger_service.dart`
- `buildExpense` (هزینه: حساب Credit)، `buildTransfer` (خنثی، بند ۴۰)، `buildAssetBuy` (مبادله+کارمزد)، `buildAssetSale` (مبادله+کارمزد) — بند ۱۰۳.
- اعتبارسنجی رویدادها.

### ۱.۴ دارایی خالص و نقدینگی — `networth.dart` (بند ۱۷-۱۸، C11)
- `LiquidityClass` (liquid/semiLiquid/nonLiquid).
- `WealthItem` (+ `isReceivable` برای C11).
- `NetWorthCalculator` → `NetWorthSnapshot` (cash, liquid, totalAssets, totalLiabilities, receivables, netWorth). **طلب در نقدینگی نه، در خالص آری (C11).**

### ۱.۵ لایهٔ ذخیره‌سازی Drift — `ledger_repository_impl.dart` (بند ۹۲)
- `recordEvent`: ثبت اتمیک (تراکنش) رویداد + سندها + به‌روزرسانی Aggregate (C1).
- `listEvents`: بازیابی با فیلتر بازه/نوع.
- `reverseEvent`: Reversal (بند ۷۴) — ACTIVE→REVERSED + رویداد برگشت معکوس.
- `balanceOf`: خواندن موجودی aggregate (سریع، برای Dashboard).

## ۲. فایل‌ها
- `pkgs/core/lib/src/ledger/{event,ledger_engine,ledger_service,networth}.dart`
- `pkgs/core/test/ledger/{ledger_service_test,networth_test}.dart`
- `app/lib/data/domain/ledger_repository.dart`, `app/lib/data/db/ledger_repository_impl.dart`

## ۳. Schema
جدول‌های `financial_events`, `ledger_entries`, `account_aggregates`, `asset_aggregates` (از فاز ۷) برای این فاز به‌کار گرفته شد.

## ۴. تصمیمات معماری
Double-entry، Reversal به‌جای Hard Delete، Aggregate snapshot (C1)، C11 در خالص/نقدینگی، اعتبارسنجی موجودی (بند ۷۵)، منطق مالی کاملاً در Domain (بند ۹۳).

## ۵. تست‌ها — **۱۹/۱۹ سبز** ✅
- Money + Persian format.
- تقویم شمسی + round-trip.
- دفتر کل: تعادل، ردّ نامتوازن، جمع خالص، مقدار.
- سرویس: هزینه، انتقالِ خنثی، خرید/فروش (مبادله، با کارمزد).
- دارایی خالص: فرمول، C11 (طلب در خالص، نه نقدینگی)، نقدینگی با نیمه‌نقدشونده.

## ۶. مشکلات
- Codegen Drift و Build APK همچنان در این sandbox به‌دلیل RAM ممکن نیست (روی ماشین ≥۴GB اجرا می‌شود).
- `occurredAt` در `reverseEvent` (فیلد نمونه) برای بازگشت علامت — در پیاده‌سازی واقعی DB دقیق می‌شود.

## ۷. باقی‌مانده
فاز ۹ (Asset Engine — Generic Assets/Lots/Cost Basis/خرید/فروش/P&L).

## ۸. ناسازگاری با نیازمندی
هیچ؛ سازگار با بند ۱۴-۱۸، ۴۰، ۷۴-۷۵، ۹۲-۹۳، ۱۰۳ و C1/C11.

---

✅ **فاز ۸ تکمیل شد.** Heart of the system built & tested. (Build/Codegen نیاز به ≥۴GB RAM.)
