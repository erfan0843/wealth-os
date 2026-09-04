/// هستهٔ امنیت، اعتبارسنجی، بکاپ و هم‌گام‌سازی (فاز ۱۵ مستر).
/// - AppLockPolicy: PIN/بیومتر (بند ۷۱) — پالیسی قابل‌تست.
/// - AuthPolicy: ایمیل/رمز/بدون اینترنت برای مشاهدهٔ Local (بند ۷۰).
/// - AuditLog / AuditTrail: برای تغییرات حساس (بند ۷۳).
/// - BackupManifest: ساختار Backup Local/Cloud (بند ۶۸).
/// - ConflictResolver با Last-Write-Wins (بند ۶۹) — رکوردمحور.
/// - KeyVaultSpec: فقط قرارداد (کلید واقعی در SecureStorage سیستم‌عامل — بند ۷۲).
/// هستهٔ خالص؛ قابل تست.
library;

/// روش قفل برنامه (بند ۷۱).
enum LockMethod { pin, biometric }

/// سیاست قفل.
class AppLockPolicy {
  final bool enabled;
  final LockMethod method;
  final int maxAttempts; // تلاش مجاز قبل از قفل موقت.
  final int coolDownSeconds; // قفل موقت پس از تلاش اضافی.

  const AppLockPolicy({
    required this.enabled,
    this.method = LockMethod.pin,
    this.maxAttempts = 5,
    this.coolDownSeconds = 30,
  });

  /// آیا بعد از تعداد تلاشِ به‌دست‌آمده باید قفل موقت شود؟
  bool shouldCoolDown(int attempts) => attempts > maxAttempts;

  /// عدد پین معتبر است؟ (۴ تا ۸ رقم).
  static bool validPin(String pin) => RegExp(r'^\d{4,8}$').hasMatch(pin);
}

/// نتیجهٔ صحت‌سنجی پین.
class LockResult {
  final bool unlocked;
  final int remainingAttempts;
  final int coolDownRemainingSeconds;

  const LockResult({
    required this.unlocked,
    required this.remainingAttempts,
    required this.coolDownRemainingSeconds,
  });
}

/// صحت‌سنج سادهٔ تلاشِ قفل (بدنباله؛ فقط پالیسی، نه مخفی‌کردن واقعی رمز).
class AppLock {
  final AppLockPolicy _policy;
  AppLock(this._policy);

  int _failures = 0;

  LockResult verify(String pin, {bool correct = false}) {
    if (!_policy.enabled) {
      return const LockResult(unlocked: true, remainingAttempts: 4, coolDownRemainingSeconds: 0);
    }
    if (correct) {
      _failures = 0;
      return LockResult(unlocked: true, remainingAttempts: _policy.maxAttempts, coolDownRemainingSeconds: 0);
    }
    _failures++;
    final remaining = _policy.maxAttempts - _failures;
    final cool = _policy.shouldCoolDown(_failures) ? _policy.coolDownSeconds : 0;
    return LockResult(unlocked: false, remainingAttempts: remaining < 0 ? 0 : remaining, coolDownRemainingSeconds: cool);
  }
}

/// نوع تغییر حساس (بند ۷۳).
enum AuditEventType {
  transactionEdit, transactionDelete, assetAdjust, feeRuleChange,
  priceOverride, accountChange, auth, backup, sync,
}

class AuditEvent {
  final String id;
  final String userId;
  final AuditEventType type;
  final DateTime at;
  final String subjectId;
  final String? beforeJson;
  final String? afterJson;
  final String? reason;

  const AuditEvent({
    required this.id,
    required this.userId,
    required this.type,
    required this.at,
    required this.subjectId,
    this.beforeJson,
    this.afterJson,
    this.reason,
  });
}

/// نگهدارندهٔ Audit Trail (بند ۷۳) — ثبت و پرس‌وجو.
class AuditTrail {
  final List<AuditEvent> _events = [];

  void record({
    required String userId,
    required AuditEventType type,
    required String subjectId,
    String? beforeJson,
    String? afterJson,
    String? reason,
  }) {
    _events.add(AuditEvent(
      id: 'audit_$_counter',
      userId: userId,
      type: type,
      at: DateTime.now().toUtc(),
      subjectId: subjectId,
      beforeJson: beforeJson,
      afterJson: afterJson,
      reason: reason,
    ));
    _counter++;
  }

  int _counter = 0;

  /// رویدادهای یک کاربر، مرتب بر اساس زمان نزولی.
  List<AuditEvent> byUser(String userId) =>
      _events.where((e) => e.userId == userId).toList()
        ..sort((a, b) => b.at.compareTo(a.at));

  List<AuditEvent> byType(AuditEventType type) =>
      _events.where((e) => e.type == type).toList();

  int get length => _events.length;
}

/// نسخهٔ مدلِ بکاپ (بند ۶۸).
class BackupManifest {
  final String schemaVersion;
  final DateTime? createdAt;
  final int entityCount;
  final List<String> entities; // اسامی جداول/موجودیت‌ها.
  final bool encrypted; // رمزنگاری‌شده؟

  const BackupManifest({
    required this.schemaVersion,
    required this.entityCount,
    this.createdAt,
    this.entities = const [],
    this.encrypted = true,
  });
}

/// یک رکورد هم‌گام — برای مقایسه.
class SyncRecord {
  final String id;
  final DateTime updatedAt;
  final String revision; // string hash/lamport.

  const SyncRecord(this.id, this.updatedAt, this.revision);
}

/// نتیجهٔ تعارض.
class ConflictResolution {
  final String winnerRecordId;
  final String loserRecordId;
  final String strategy; // 'lww' / 'local' / 'remote'.
  final bool appliedLocalChange;

  const ConflictResolution({
    required this.winnerRecordId,
    required this.loserRecordId,
    required this.strategy,
    required this.appliedLocalChange,
  });
}

/// حل تعارض با Last-Write-Wins (بند ۶۹) — رکوردمحور.
class ConflictResolver {
  const ConflictResolver();

  /// دو نسخه از همان رکورد → برندهٔ آخرین‌زمان (LVW).
  ConflictResolution resolve(SyncRecord local, SyncRecord remote) {
    final localWins = local.updatedAt.isAfter(remote.updatedAt) ||
        (local.updatedAt == remote.updatedAt && local.revision.codeUnitAt(0) > remote.revision.codeUnitAt(0));
    return ConflictResolution(
      winnerRecordId: localWins ? local.id : remote.id,
      loserRecordId: localWins ? remote.id : local.id,
      strategy: 'lww',
      appliedLocalChange: localWins,
    );
  }
}

/// قراردادِ Vault کلید (بند ۷۲) — پیاده‌سازی با SecureStorage سیستم‌عامل در App.
abstract interface class KeyVault {
  Future<String?> getOrCreateDatabaseKey();
  Future<String?> read(String key);
  Future<void> write(String key, String value);
}

/// صحت‌سنجی رمز (بند ۷۰) — حداقل طول و از طریق بدون اینترنت برای Local.
class AuthPolicy {
  const AuthPolicy();

  static bool validEmail(String e) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(e);

  static bool strongPassword(String p) =>
      p.length >= 8 && RegExp(r'[0-9]').hasMatch(p) && RegExp(r'[A-Za-z]').hasMatch(p);

  /// بند ۷۰: مشاهدهٔ دادهٔ Local حتی بدون اینترنت.
  bool localAccessAllowed() => true;
}
