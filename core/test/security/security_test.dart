import 'package:test/test.dart';
import 'package:wealth_core/wealth_core.dart';

void main() {
  group('AppLock / AppLockPolicy — بند ۷۱', () {
    test('پین معتبر', () {
      expect(AppLockPolicy.validPin('1234'), true);
      expect(AppLockPolicy.validPin('123'), false); // کوتاه.
      expect(AppLockPolicy.validPin('123456789'), false); // بلند.
      expect(AppLockPolicy.validPin('abcd'), false); // غیرعددی.
    });

    test('تلاشِ اشتباه → قفلِ موقت بعد از حد', () {
      const pol = AppLockPolicy(enabled: true, maxAttempts: 3, coolDownSeconds: 30);
      final lock = AppLock(pol);
      var r = lock.verify('0000', correct: false);
      expect(r.unlocked, false);
      expect(r.remainingAttempts, 2);
      r = lock.verify('0000', correct: false);
      expect(r.remainingAttempts, 1);
      r = lock.verify('0000', correct: false);
      expect(r.remainingAttempts, 0);
      r = lock.verify('0000', correct: false);
      expect(r.coolDownRemainingSeconds, 30); // قفلِ موقت.
    });

    test('پین درست → بازکردن و ریست', () {
      const pol = AppLockPolicy(enabled: true);
      final lock = AppLock(pol);
      lock.verify('0000', correct: false);
      final ok = lock.verify('1234', correct: true);
      expect(ok.unlocked, true);
      expect(ok.remainingAttempts, pol.maxAttempts);
    });

    test('قفل غیرفعال → همیشه باز', () {
      const pol = AppLockPolicy(enabled: false);
      final lock = AppLock(pol);
      expect(lock.verify('0000').unlocked, true);
    });
  });

  group('AuditTrail — بند ۷۳', () {
    test('ثبت و پرس‌وجو توسط کاربر', () {
      final trail = AuditTrail();
      trail.record(userId: 'u1', type: AuditEventType.transactionEdit, subjectId: 't1', beforeJson: '{"a":1}', afterJson: '{"a":2}', reason: 'مبلغ اصلاح شد');
      trail.record(userId: 'u2', type: AuditEventType.feeRuleChange, subjectId: 'f1');
      trail.record(userId: 'u1', type: AuditEventType.assetAdjust, subjectId: 'g1');
      expect(trail.length, 3);
      expect(trail.byUser('u1'), hasLength(2));
      expect(trail.byUser('u1').first.type, AuditEventType.assetAdjust); // آخرین.
      expect(trail.byType(AuditEventType.feeRuleChange), hasLength(1));
    });
  });

  group('ConflictResolver — بند ۶۹ (Last-Write-Wins)', () {
    test('برندهٔ آخرین‌زمان', () {
      const r = ConflictResolver();
      final local = SyncRecord('rec', DateTime.utc(2026, 9, 2), 'a');
      final remote = SyncRecord('rec', DateTime.utc(2026, 9, 3), 'a');
      final res = r.resolve(local, remote);
      expect(res.winnerRecordId, 'rec');
      expect(res.appliedLocalChange, false);
      expect(res.strategy, 'lww');
    });

    test('برابر → اولویتِ revision', () {
      const r = ConflictResolver();
      final res = r.resolve(SyncRecord('a', DateTime.utc(2026, 9, 3), 'z'),
          SyncRecord('a', DateTime.utc(2026, 9, 3), 'a'));
      expect(res.appliedLocalChange, true);
    });
  });

  group('Backup / Auth — بند ۶۸/۷۰', () {
    test('مانیفست بکاپ', () {
      const m = BackupManifest(schemaVersion: '1', entityCount: 12, entities: ['account', 'transaction'], encrypted: true);
      expect(m.entityCount, 12);
      expect(m.encrypted, true);
    });

    test('ایمیل/رمز قوی', () {
      expect(AuthPolicy.validEmail('a@b.com'), true);
      expect(AuthPolicy.validEmail('a@b'), false);
      expect(AuthPolicy.strongPassword('Pass1234'), true);
      expect(AuthPolicy.strongPassword('short'), false);
      expect(const AuthPolicy().localAccessAllowed(), true);
    });
  });
}
