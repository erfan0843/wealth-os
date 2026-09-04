# فاز ۱۲ (مستر پرامپت) — Dashboard + Reports

> **هم‌ترازی شماره‌گذاری:** مستر پرامپت این را «فاز ۱۲» نامیده (بند ۱۰۰). قبلاً من به‌اشتباه Reports را «فاز ۱۳» برچسب زدم. این سند هم‌تراز با مستر است.
> وضعیت: ✅ تحویل و سبز — لایهٔ UseCase خالص + یکپارچه‌سازی. `dart analyze` بدون مشکل، **66/66** تست در این فاز.

---

## ۱. تکمیلِ «فاز ۱۲ مستر»

مستر پرامپت فاز ۱۲ را این‌طور تعریف می‌کند:
- Dashboard · Net Worth · Cash Flow · Spending · Asset Allocation · P&L · Fee Reports · Wealth Growth · **Reference Asset**

قبل از این، من فقط نصفِ آن (Reports/RefAsset در `reports.dart`/`ref_asset.dart`) را داشتم. این فاز **لایهٔ یکپارچه‌سازی (UseCase)** را اضافه کرد که همهٔ موتورها را به یک **DashboardSnapshot** قابل‌تست ترکیب می‌کند — دقیقاً مطابق بند ۹۲ (UI → Service → Domain) و بند ۹۳ (منطق مالی بیرون از UI).

## ۲. مدل‌های جدید

### `transaction.dart` (بند ۱۴/۶۲-۶۴)
- `Transaction { id, userId, type, amountMinor, currency, occurredAt, categoryId?, categoryLabelFa?, merchant?, source?, note?, tags }`.
- `TxType { income, expense, transfer, buyAsset, sellAsset, debtPay, other }`.

### `dashboard/dashboard.dart` (بند ۵۲-۵۸)
- `DashboardInput { wealthItems, transactions, prevNetWorthMinor, currency, refPrice? }`.
- `DashboardSnapshot { netWorth, totalAssets, totalLiabilities, cash, liquidAssets, investments, receivables, income, expense, net, fee, growth, spending, allocation, refValue? }`.
- `DashboardBuilder.build(input)`:
  1. `NetWorthCalculator` → ثروت و نقدینگی (بند ۱۷/۱۸).
  2. تجمیع درآمد/هزینه + `SpendAggregator` (بند ۵۵).
  3. `AllocationCalculator` — سهم کلاس‌ها (بند ۵۴).
  4. `Growth(prevNetWorth, netWorth)` — رشد (بند ۵۸).
  5. `RefAssetEngine` — معادلِ واحد مرجع با قیمت ریالیِ همان زمان (بند ۵۶/۵۷).

## ۳. اصلاحِ `WealthItem` — فلگ `isLiability`
برای تفکیک صحیح دارایی/بدهی در محاسبهٔ ثروت (بند ۱۷)، `isLiability` به `WealthItem` اضافه شد (قبلاً با `LiquidityClass` استنتاج می‌شد که کموبیش غلط بود).

## ۴. تست‌ها (۲ تست یکپارچه‌سازی — مجموع 66)

| تست | نتیجه |
|---|---|
| ترکیب ثروت+درآمد/هزینه+تخصیص+واحد مرجع (با طلب/بدهی جدا) | ✅ |
| بدون واحد مرجع → `refValue` صفر | ✅ |

```dart
// نمونهٔ تأییدشده در تست:
// totalAssets=125M, totalLiab=8M → netWorth=117M
// cash=50M, liquidAssets=80M (نقد+طلا), طلب=5M
// income=10M, expense=2.5M → net=7.5M
// رشد از 100M → 117M = 17%
// refValue: 117M تومان ×10 ÷ 40000 ریال = 29250 گرم نقره
```

## ۵. فایل‌ها

```
pkgs/core/lib/src/transaction/transaction.dart     (مدل تراکنش)
pkgs/core/lib/src/dashboard/dashboard.dart         (Dashboard UseCase)
pkgs/core/lib/src/ledger/networth.dart             (+ isLiability)
pkgs/core/lib/wealth_core.dart                     (export)
pkgs/core/test/dashboard/dashboard_test.dart       (2)
docs/phase-12-dashboard-reports.md
artifacts/app-preview-phase12.html
```

> **بلاکر بدون تغییر:** Drift repo و Flutter real به رم ≥۴ گیگ نیاز دارند؛ روی ماشین شما `bash /home/user/wealth-os/app/build.sh`. موتورها/UseCase خالص با `dart test` اینجا سبزند.
