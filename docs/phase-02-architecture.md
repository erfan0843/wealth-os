# PHASE 2 — System Architecture
## سیستم مدیریت مالی، دارایی و ثروت شخصی
**وضعیت:** ✅ تکمیل‌شده — در انتظار تأیید شما
**تاریخ:** ۲۰۲۶-۰۹-۰۳
**شاخه:** `docs/phase-02-architecture.md`

---

## ۱. نمای کلان معماری (Overview)

```
┌──────────────────────────────────────────────────────────────────┐
│                         Presentation (Flutter)                    │
│  Screens · Widgets · ViewModels · State (Riverpod) · Router      │
│  (Dashboard | Transactions | Assets | Future | Profile | Quick+) │
└──────────────────────────────┬───────────────────────────────────┘
                               │ (Dependency: only on Use Cases / VM)
┌──────────────────────────────▼───────────────────────────────────┐
│                        Domain Layer (Pure Dart)                   │
│  Entities · ValueObjects · Domain Services · Use Cases            │
│  Ledger · AssetEngine · Pricing · FeeEngine · P&L · Forecast ·    │
│  Budget · Reconciliation · Analytics                              │
│  (NO Flutter, NO IO — 100% unit-testable)                         │
└──────────────────────────────┬───────────────────────────────────┘
                               │ (Repository interfaces)
┌──────────────────────────────▼───────────────────────────────────┐
│                        Data Access Layer (Repositories)           │
│  Local DS (Drift/SQLite)  ·  Remote DS (Supabase, optional)       │
│  Mappers Entity↔DB · Cache · Outbox · Audit                       │
└──────────────┬───────────────────────────────┬───────────────────┘
               │                               │
┌──────────────▼───────────────┐   ┌───────────▼───────────────────┐
│  Local DB (Drift/SQLite)     │   │  Cloud (Supabase) — Optional  │
│  • Source of Truth (Offline) │   │  • Auth · Sync · Backup       │
│  • Encryption @Rest (SQLC)   │   │  • Never the source of truth  │
└──────────────────────────────┘   └───────────────────────────────┘
```

---

## ۲. لایه‌ها و قواعد Dependency

### ۲.۱ اصل وابستگی
```
Presentation ──▶ ViewModel ──▶ UseCase ──▶ Domain Service ──▶ Repository ──▶ DataSource
        (UI)   (Riverpod)  (App)      (domain)           (interface)      (Drift/Remote)
```

- وابستگی **فقط به سمت پایین** است؛ هیچ لایه‌ای به لایهٔ بالاتر ارجاع ندارد (Dependency Inversion).
- **Domain اجرای صفر Flutter/IO دارد** — به همین دلیل با `dart test` قابل‌تست است (بند ۹۴ و نکتهٔ R9).
- Repository ها در `domain` به‌صورت **interface**، و در `data` به‌صورت **پیاده‌سازی** تعریف می‌شوند (Dependency Injection).

### ۲.۲ تفکیک مسئولیت‌ها
| لایه | مسئول | ممنوع |
|---|---|---|
| Presentation | نمایش/ورودی/راهبری/state UI | محاسبهٔ مالی، دسترسی مستقیم DB |
| ViewModel | هماهنگی UI ↔ UseCase، نگهداری state صفحه، loading/error | منطق مالی |
| UseCase (App/Application) | orchestrating یک عمل کاربر (مثلاً «خرید دارایی») | — |
| Domain Service | منطق خالص مالی (P&L، Fee، Ledger، P&L) | IO، Flutter |
| Repository | دسترسی داده، نگاشت Entity↔DB، caching، outbox | منطق مالی |
| DataSource | SQL/HTTP خالص | — |

---

## ۳. نقشهٔ ماژول‌ها (Module Map)

```
wealth_os/
├── core/                     # Result, Either, AppError, Logger, DI, DateTime utils, Extensions
├── domain/                   # PURE — هستهٔ تست‌پذیر
│   ├── ledger/               # FinancialEvent, LedgerEntry, Account, Reversal, NetWorth, Balance
│   ├── assets/               # AssetType, Asset, AssetLot, CostBasis, Buy/Sell, P&L
│   ├── pricing/              # PriceProvider(abstract), PriceSnapshot, PriceHistory, PriceCache
│   ├── fees/                 # FeeRule, FeeEngine, Priority, FeeSnapshot
│   ├── liabilities/          # Debt, Receivable, Loan, Installment, BNPL, Check, Schedule
│   ├── future/               # Calendar, CashFlowForecast
│   ├── reports/              # SpendingByCategory, Allocation, P&L, Fees, Growth, RefValue
│   ├── budget/               # Budget, Goal, GoalProgress
│   ├── transaction/          # Transaction, QuickAdd parser, Category, Tag
│   ├── sms/                  # SmsParser, MerchantMatcher, SmartRule, DuplicateDetector
│   ├── analytics/            # Trend, Anomaly, FeeAnalysis (بدون AI)
│   └── common/               # Money, Quantity, Unit, Currency, Metadata
├── data/                     # Implementations
│   ├── local/                # Drift tables, queries, migrations
│   ├── remote/               # Supabase (auth/sync/backup)
│   ├── mappers/              # Entity <-> DTO/DB
│   ├── repositories/         # impl of domain interfaces
│   └── sync/                 # Outbox, SyncCoordinator, ConflictResolver
├── presentation/
│   ├── app/                  # App, Router(go_router), Theme, Localization
│   ├── screens/              # Dashboard, Transactions, Assets, Future, Profile, QuickAdd(s)
│   ├── widgets/              # Cards, Charts, Empty/Error/Loading states
│   └── viewmodels/           # Riverpod providers
├── services/                 # AuthService, AppLock, Security(crypto), Notification, Backup/Export
├── database/                 # Drift schema definitions, Migration plans, Seed
├── config/                   # AppConfig, FeatureFlags, Env
├── localization/             # fa_IR, en, RTL bindings
├── assets/                   # Vazirmatn font, icons, illustrations
└── test/                     # unit: domain (pure) + db + integration + golden-ish
```

**نکته:** ماژول‌های بند ۹۱ سند (core/database/authentication/ledger/...) در همین ساختار و به همان ترتیبِ منطقی پوشش داده می‌شوند؛ صرفاً با یک لایه‌بندی Domain/Presentation/Data که نیاز تست و مقیاس را برآورده کند.

---

## ۴. جریان داده (Data Flow) — نمونه‌های کلیدی

### ۴.۱ «خرید دارایی» (Asset Purchase) — مهم‌ترین مسیر
```
UI: { امت 20g نقره, 80,000 تومان, حساب=بانک, Fee rule~1% }
  │
  ▼
[UseCase: CreateAssetPurchase]
  │  1. Validate (موجودی حساب؟ short-position؟)
  │  2. PricingProvider.pull(assetType) → PriceSnapshot(price,srce,ts)
  │  3. FeeEngine.compute(rule,buy,${time,qty,amount}) → FeeSnapshot
  │  4. Build FinancialEvent(BUY)
  │       ├─ Ledger Entries:
  │       │     Credit (خروج) Bank        -80,000
  │       │     Debit  (ورود) Silver Lot  +20g   CostBasis=80,000/20
  │       │     Debit  (خروج) Fee          -800   (toman)
  │       │  (Transaction Snapshot ذخیره شد: price, feeRate, source, ts → تغییر Rule آینده اثر ندارد)
  │       ├─ Update Aggregate Snapshot (Bank balance, Silver quantity+costBasis)
  │       ├─ Audit Log entry
  │       └─ Sync Outbox entry (CREATE)
  │  5. Commit در یک Transaction اتمیک
```
`Ledger دوبل`: هر رویداد حداقل دو Entry با مجموع صفر دارد (احتیاطِ درستی).

### ۴.۲ «ثبت هزینهٔ ساده» (<۵s)
`UI QuickAdd { مبلغ, علت, حساب }` → UseCase CreateExpense → Event(EXPENSE) + Entry Debit(هزینه) / Credit(حساب) → Aggregate → Outbox.

### ۴.۳ «فروش بخشی از دارایی»
`UseCase: CreateAssetSale { qty }` → بازیابی Lots به روش (AI: Average پیش‌فرض) → محاسبهٔ CostBasis برخاسته، Realized P&L = درآمد - CostBasis - هزینه‌ها → Entry Credit(نقد) / Debit(دارایی) / Debit(Fee, Tax) → کاهش lot → Outbox.

### ۴.۴ آفلاین (Offline)
همهٔ بالا کاملاً Local است؛ Cloud کاملاً خاموش. اگر Sync فعال و اینترنت قطع باشد → رویداد فقط در Outbox می‌ماند و بعداً sync می‌شود (به‌ترتیب).

---

## ۵. استراتژی آفلاین (Offline Strategy)

- **منبع حقیقت:** SQLite محلی، همیشه. (بند ۳)
- **هر عمل مالی باید در <شبیه مومنت Local موفق شود** قبل از هر چیز Remote.
- **قانون:** هیچ عملیات مالی به اینترنت نیاز ندارد. Cloud فقط برای Sync/Backup/Auth.
- **لایه**
  - Domain (همه‌چیز) ✅ Online
  - Local DB ✅ Online
  - Sync Outbox ✅ Online
  - Price fetch ✅ (اگر منبع آفلاین نشد → Price Cache + برچسب «آخرین قیمت موجود» + Timestamp، بند ۸۲)
  - Auth/Profile Cloud ❌ اختیاری
- **Price offline cache:** آخرین Snapshot معتبر در `price_cache`؛ هرگز قیمت قدیمی به‌عنوان لحظه‌ای معرفی نمی‌شود.

---

## ۶. استراتژی همگام‌سازی (Sync Strategy)

### ۶.۱ مدل
- **Outbox-based**: هر تغییر → رکورد `sync_outbox`.
- **Revision**: هر جدول کاربر دارای `updated_at`/`revision`.
- **Conflict**: **Last-Write-Win** در سطح رکورد (C6)، + **Conflict Log** برای موارد حساس.
- **Idempotence**: هر sync payload دارای `event_id`/`row_id` + UUID تا duplicate باعث Double-apply نشود (مهم برای Sync و SMS).

### ۶.۲ ترتیب
`Save(Local) → enqueue Outbox → worker sync (در صورت اتصال) → اعمال در سرور → حل conflict → به‌روزرسانی state`.

### ۶.۳ امنیت Sync
- **هر کاربر فقط دادهٔ خودش** (row-level security + `user_id` روی همهٔ جدول).
- **جدا**: هیچ ارسال داده مالی به AI/آمار بدون رضایت صریح (بند ۶/۹۹).

---

## ۷. مدل رویداد و دفتر کل (Event + Ledger) — طراحی کلیدی

### ۷.۱ FinancialEvent
| فیلد | توضیح |
|---|---|
| `id` | UUID |
| `user_id` | مالک |
| `kind` | بند ۱۴ (Income/Expense/Transfer/AssetBuy/.../Other) |
| `status` | ACTIVE / REVERSED |
| `occurred_at` | زمان رخداد مالی |
| `currency, total_minor` | جمع مبلغ (برای محاسبات سریع) |
| `note, tags, metadata` | |
| `reference_event_id` | برای Reversal/linked |
| `created_at, updated_at` | برای Sync |

### ۷.۲ LedgerEntry (سند دوبل)
| فیلد | توضیح |
|---|---|
| `event_id` | |
| `side` | DEBIT / CREDIT |
| `account_id` / `asset_id` / `liability_id` | یکی (انکا) |
| `amount_minor` + `quantity` + `unit` + `currency` | |
| `created_at` | |

**قانون درستی:** مجموع `Debit − Credit == 0` در هر Event (به‌جز انواع خاص Override با تأیید).

### ۷.۳ Reversal (بند ۷۴/۱۰۵)
- حذف → Reversal Event جداگانه با `reference_event_id`.
- اصل Ledger **حذف نمی‌شود**؛ فقط علامت Status تغییر می‌کند.
- UI ساده: «برگردان» با امکان Undo.

### ۷.۴ Aggregate Snapshot (C1)
- موجودی فعلی هر موجودیت در `*_aggregate`.
- به‌روزرسانی اتمیک با هر Event؛ **بازسازی از Ledger** برای Audit در صورت نیاز.

---

## ۸. استراتژی امنیت (Security Strategy)
- **Location:** همه‌چیز Local؛ Cloud فقط اختیاری.
- **At-rest:** SQLCipher + کلید در `flutter_secure_storage` (بند ۷۲).
- **App Lock:** PIN (local_auth) + بیومتر، محلی (بند ۷۱/۷۰).
- **Auth Cloud:** Supabase (اختیاری)، JWT؛ بدون اینترنت برنامه کار می‌کند (C7).
- **Logging:** توسعه‌دهنده؛ بدون دادهٔ مالی در prod log (بند ۹۸).
- **Audit Log:** ویرایش/حذف/تعدیل/Override/FeeRuleChange/AccountChange (بند ۷۳).

---

## ۹. انتخاب‌های فنی (تأییدشده از C)
| انتخاب | ارزش |
|---|---|
| Flutter + Riverpod + go_router | UI RTL، DI، راهبری |
| Drift (SQLite) | type-safe، reactive، Migration |
| SQLCipher + secure_storage | Encryption at rest |
| supabase_flutter (اختیاری) | Auth/Sync/Backup |
| fl_chart | نمودار |
| Vazirmatn | فونت فارسی |
| local_auth | App Lock |
| flutter_local_notifications | اعلان‌ها |

---

## ۱۰. معیار Done فاز ۲
- [x] معماری لایه‌ای با Dependency Inversion
- [x] نقشهٔ ماژول‌ها (Module Map)
- [x] جریان داده برای Purchase/Expense/Sale
- [x] استراتژی آفلاین (Offline)
- [x] استراتژی Sync/Conflict
- [x] مدل Event + Ledger + Reversal + Snapshot
- [x] استراتژی امنیت
- [x] Stack نهایی

---

## ۱۱. گزارش پایان فاز ۲ (بند ۱۱۱)
1. **ساخته شد:** معماری کامل لایه‌ای، ماژول‌ها، جریان داده، آفلاین/Sync/امنیت.
2. **فایل‌ها:** `docs/phase-02-architecture.md`.
3. **Schema:** مدل منطقی Event/Ledger/Aggregate تشریح شد؛ جداول دقیق در فاز ۳.
4. **تصمیمات:** Dependency Inversion، Domain خالص، Snapshot+Replay، Outbox+LVW، SQLCipher، Supabase اختیاری.
5. **تست:** این فاز معماری است؛ تست‌های Domain از فاز ۷/۸.
6. **مشکلات:** همچنان R9 (toolchain برای Build).
7. **باقی‌مانده:** فاز ۳ — Database Architecture (ERD/Tables/Indexes/Migrations).
8. **پیشنهادها:** در فاز ۳، خوشه‌بندی جدول‌ها و تعیین `Integer/Aggregate` دقیق.
9. **ناسازگاری:** ندارد؛ با A–K و فاز ۱ هم‌راستا.

---

✅ **فاز ۲ کامل شد. نیازمند تأیید برای رفتن به فاز ۳ (Database Architecture) هستم.**
