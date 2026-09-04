import 'package:test/test.dart';
import 'package:wealth_core/wealth_core.dart';

void main() {
  const eng = LiabilitiesEngine();

  Liability loan({int principal = 12000000, double rate = 0, int n = 12}) =>
      Liability(
        id: 'loan1',
        name: 'وام خودرو',
        kind: LiabilityKind.loan,
        principalMinor: principal,
        currency: Currency.irt,
        startDate: DateTime.utc(2025, 1, 1),
        installmentsCount: n,
        interestRatePercent: rate,
        frequency: RepaymentFrequency.monthly,
      );

  group('LiabilitiesEngine — بدهی/طلب/تعهدات (فاز ۱۱)', () {
    test('بدون بهره — قسط مساوی و مجموع اصل کامل', () {
      final s = eng.schedule(loan());
      expect(s.installments, hasLength(12));
      expect(s.principalTotalMinor, 12000000);
      expect(s.interestTotalMinor, 0);
      // قسط اول = ۱٬۰۰۰٬۰۰۰.
      expect(s.installments.first.principalMinor, 1000000);
      // جمع اصل = کل مبلغ.
      final sum =
          s.installments.fold<int>(0, (a, i) => a + i.principalMinor);
      expect(sum, 12000000);
    });

    test('با بهره — قسط مساوی، اصل+بهره، و مانده به صفر می‌رسد', () {
      final s = eng.schedule(loan(principal: 12000000, rate: 24, n: 12));
      expect(s.installments, hasLength(12));
      expect(s.interestTotalMinor, greaterThan(0));
      // همهٔ قسط‌ها برابر تقریبی هستند (قسط مساوی).
      final first = s.installments.first.totalMinor;
      final last = s.installments.last.totalMinor;
      // قسط مساوی — تفاوت فقط از گردکردن واحد جزئی است (<۱۰ تومن).
      expect((first - last).abs(), lessThan(10));
      // مجموع اصل = مبلغ.
      final sum =
          s.installments.fold<int>(0, (a, i) => a + i.principalMinor);
      expect(sum, 12000000);
    });

    test('اصل مانده — فقط قسط‌های پرداخت‌نشده شمرده می‌شود', () {
      final s = eng.schedule(loan());
      final p3 = [
        for (var i = 0; i < s.installments.length; i++)
          s.installments[i].index <= 3
              ? Installment(
                  index: s.installments[i].index,
                  dueDate: s.installments[i].dueDate,
                  principalMinor: s.installments[i].principalMinor,
                  interestMinor: s.installments[i].interestMinor,
                  status: InstallmentStatus.paid)
              : s.installments[i],
      ];
      expect(eng.outstandingPrincipalMinor(p3), 9000000);
    });

    test('وام خالص — بدهی منهای طلب', () {
      final debt = loan();
      final recv = Check(
        id: 'c1',
        kind: CheckKind.receivable,
        number: '1001',
        party: 'مشتری',
        amountMinor: 3000000,
        currency: Currency.irt,
        issueDate: DateTime.utc(2025, 2, 1),
        dueDate: DateTime.utc(2025, 3, 1),
      );
      final net = eng.netPositionMinor(debts: [debt], receivables: [recv]);
      expect(net, 9000000); // ۱۲٬۰۰۰٬۰۰۰ − ۳٬۰۰۰٬۰۰۰.
    });

    test('تشخیص قسط سررسیدشده (overdue)', () {
      final s = eng.schedule(loan());
      final past = s.installments[0];
      final now = DateTime.utc(2026, 6, 1);
      final after = Installment(
        index: past.index,
        dueDate: past.dueDate,
        principalMinor: past.principalMinor,
        interestMinor: past.interestMinor,
      );
      final before = Installment(
        index: 2,
        dueDate: DateTime.utc(2027, 6, 1), // هنوز موعد نرسیده.
        principalMinor: 1000000,
        interestMinor: 0,
      );
      final overdue = eng.overdueInstallments([after, before], now: now);
      expect(overdue, hasLength(1));
      expect(overdue.first.index, 1);
    });

    test('چک معوق — پرداختی و سررسید گذشته', () {
      final c = Check(
        id: 'c2',
        kind: CheckKind.receivable,
        number: '2002',
        party: 'مشتری',
        amountMinor: 5000000,
        currency: Currency.irt,
        issueDate: DateTime.utc(2026, 1, 1),
        dueDate: DateTime.utc(2026, 2, 1),
      );
      expect(c.isOverdue, true); // نسبت به now در آیندهٔ قبل از موعد.
      // بررسی: اگر سررسید در گذشته باشد معوق است.
      final overdue = eng.overdueChecks([c]);
      expect(overdue.length, 1);
    });

    test('تعهد دورهای — نزدیک‌ترین سررسید فعال', () {
      final cs = [
        RecurringCommitment(
          id: 'a',
          name: 'اجاره',
          amountMinor: 9000000,
          currency: Currency.irt,
          nextDue: DateTime.utc(2026, 9, 1),
        ),
        RecurringCommitment(
          id: 'b',
          name: 'اشتراک',
          amountMinor: 300000,
          currency: Currency.irt,
          nextDue: DateTime.utc(2026, 9, 20),
        ),
      ];
      expect(eng.nextCommitment(cs)!.id, 'a'); // نزدیک‌تر.
      expect(eng.recurringTotalMinor(cs, Currency.irt), 9300000);
    });

    test('تعهد دورهای غیرفعال در جمع و نزدیک‌ترین حذف می‌شود', () {
      final cs = [
        RecurringCommitment(
          id: 'x',
          name: 'متوقف',
          amountMinor: 9000000,
          currency: Currency.irt,
          nextDue: DateTime.utc(2026, 1, 1),
          enabled: false,
        ),
        RecurringCommitment(
          id: 'y',
          name: 'فعال',
          amountMinor: 200000,
          currency: Currency.irt,
          nextDue: DateTime.utc(2026, 10, 1),
        ),
      ];
      expect(eng.recurringTotalMinor(cs, Currency.irt), 200000);
      expect(eng.nextCommitment(cs)!.id, 'y');
    });
  });
}
