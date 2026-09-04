# فاز ۱۵ (مستر پرامپت) — Security + Backup + Sync

> **هم‌ترازی:** مستر پرامپت این را «فاز ۱۵» نامیده (بند ۱۰۰): Authentication · App Lock · Encryption · Backup · Restore · Sync · Conflict Resolution · Audit Logs.
> وضعیت: ✅ تحویل و سبز — `dart analyze` بدون مشکل، **89/89** تست (۹ جدید در این فاز).

---

## ۱. محدودهٔ صادقانه (چرا هستهٔ خالص + قرارداد)

اجرای واقعیِ رمزنگاری (SQLCipher)، خواندن SecureStorage، شبکهٔ Supabase و پس‌زمینهٔ Sync نیازمند Flutter/Plugin و رم ≥۴ گیگ است (بلاکرِ شناخته‌شده). بنابراین این فاز **منطق امنیت/اعتبارسنجی/تعارض را خالص و قابل‌تست** پیاده می‌کند و **قرارداد/ساختار** را برای پیاده‌سازیِ App در فاز ۱۶ آماده می‌کند.

## ۲. `security/security.dart` — هستهٔ خالص

### App Lock (بند ۷۱)
- `AppLockPolicy { enabled, method(pin/biometric), maxAttempts, coolDownSeconds }`.
- `AppLock.verify(pin)` → `LockResult { unlocked, remainingAttempts, coolDownRemainingSeconds }`. بعد از `maxAttempts` → **قفل موقت**.
- `AppLockPolicy.validPin` (۴ تا ۸ رقم).

### Auth (بند ۷۰)
- `AuthPolicy.validEmail` / `strongPassword` (≥۸، رقم+حرف).
- `localAccessAllowed()` → همیشه `true` (مشاهدهٔ Local حتی بدون اینترنت).

### Audit Trail (بند ۷۳)
- `AuditEventType { transactionEdit, transactionDelete, assetAdjust, feeRuleChange, priceOverride, accountChange, auth, backup, sync }`.
- `AuditTrail.record(...)` و پرس‌وجو `byUser`/`byType` با `beforeJson/afterJson/reason`.

### Backup (بند ۶۸)
- `BackupManifest { schemaVersion, createdAt, entityCount, entities, encrypted }`.

### Sync + Conflict (بند ۶۹)
- `SyncRecord { id, updatedAt, revision }`.
- `ConflictResolver.resolve(local, remote)` → **Last-Write-Wins** (رکوردمحور): برندهٔ آخرین‌زمان؛ در برابری، اولویتِ `revision`. `ConflictResolution { winner, loser, strategy:'lww', appliedLocalChange }`.

### Encryption (بند ۷۲)
- `KeyVault` (interface): `getOrCreateDatabaseKey`/`read`/`write` — پیاده‌سازیِ واقعی با `flutter_secure_storage` در App (کلید در SecureStorage سیستم‌عامل؛ نه هاردکد).

## ۳. تست‌ها (۹)

| موضوع | تعداد |
|---|---|
| AppLock (پین، قفل موقت، ریست، غیرفعال) | 4 |
| AuditTrail | 1 |
| ConflictResolver (LVW، برابری) | 2 |
| BackupManifest / Auth | 2 |

## ۴. فایل‌ها

```
pkgs/core/lib/src/security/security.dart
pkgs/core/lib/wealth_core.dart                 (export)
pkgs/core/test/security/security_test.dart     (9)
docs/phase-15-security-sync.md
```

> ⚠️ فعال‌سازی واقعی SQLCipher/Backup/Supabase/Sync در فاز ۱۶ (نصب/ساخت روی ماشین ≥۴ گیگ) است؛ قرارداد و منطق اینجا آماده است.
