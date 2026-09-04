# PHASE 9 — Asset Engine
## سیستم مدیریت مالی، دارایی و ثروت شخصی
**وضعیت:** ✅ منطق خالص کامل + تست ۲۷/۲۷ سبز؛ لایهٔ DB در pH7 آماده است.
**تاریخ:** ۲۰۲۶-۰۹-۰۳
**شاخه:** `docs/phase-09-assets.md` | `pkgs/core/lib/src/assets/`

---

## ۰. چرا مهم
دارایی‌های ژنریک (بند ۱۹). نقره فقط یک نوع است؛ همین Engine برای طلا/ارز/سهم/کریپتو/ملک/خودرو هم کار می‌کند. و مهم‌ترین: «خرید دارایی ≠ هزینه»، «فروش ≠ درآمد» (بند ۱۰۳) و **Cost Basis + P&L** (بند ۲۳، ۲۶).

## ۱. چه چیزی ساخته شد

### ۱.۱ مدل `asset.dart` (بند ۱۹-۲۲)
- **`AssetType`** — کد (GOLD/SILVER/.../CUSTOM)، نام، واحد پیش‌فرض، نقدشوندگی، `supportsShort` (بند ۷۵)، دقت اعشار، Metadata Schema (بند ۲۱).
- **`Asset`** — دارایی مشخص + `supportsShort` + روش Cost Basis + Metadata.
- **`CostMethod`** — `average` (Default) / `fifo` / `specific` (بند ۲۳).
- **`AssetLot`** — تاریخچهٔ هر نوبت خرید (بند ۲۲): مقدار، قیمت واحد، هزینهٔ کل، تاریخ، باز/بسته.

### ۱.۲ Cost Basis `cost_basis.dart` (بند ۲۳)
- `average` (میانگین)، `fifo` (اولین Lot)، `specific` (Lot های مشخص‌شده).
- `CostBasisResult` + `LotConsumption` (کدام Lots مصرف شد).

### ۱.۳ موتور `asset_engine.dart` (بند ۲۴-۲۶)
- **`buy`** (بند ۲۴): Lot ایجاد، Cost Basis با کارمزد، میانگین جدید.
- **`sell`** (بند ۲۵): مقدار کاهش، Cost Basis مصرف‌شده، **Realized P&L = درآمد − Cost Basis − کارمزد** (بند ۲۶).
- **`validateSaleQuantity`** (بند ۷۵): رد فروش بیش از موجودی مگر `supportsShort` (تأیید صریح).
- **`unrealized`** (بند ۲۶): ارزش فعلی − هزینهٔ فعلی + درصد.

## ۲. فایل‌ها
`pkgs/core/lib/src/assets/{asset,cost_basis,asset_engine}.dart` + `test/assets/asset_engine_test.dart`.

## ۳. Schema
از جدول‌های `asset_types`, `assets`, `asset_lots`, `asset_aggregates` (فاز ۷) استفاده می‌شود.

## ۴. تصمیمات معماری
Default Average برای Cost Basis؛ معماری آمادهٔ FIFO/Specific؛ اعتبارسنجی Short-position؛ P&L خالص در Domain (بند ۹۳، ۲۶).

## ۵. تست‌ها — ۲۷/۲۷ سبز ✅
میانگین، FIFO، فروش کل، خرید با کارمزد، Realized P&L، رد فروش بیش از موجودی، فروش دقیقاً به اندازهٔ موجودی، P&L تحقق‌نیافته.

## ۶. مشکلات
Codegen/Build در این sandbox به‌دلیل RAM ممکن نیست (روی ماشین ≥۴GB).

## ۷. باقی‌مانده
فاز ۱۰ (Pricing + Fee Engine).

## ۸. ناسازگاری
هیچ؛ سازگار با بند ۱۹-۲۶، ۷۵، ۱۰۳ و C1/C11.

---

✅ **فاز ۹ تکمیل شد.** (Build/Codegen نیازمند ≥۴GB RAM.)
