import 'package:flutter_test/flutter_test.dart';
import 'package:drift/native.dart';
import 'package:wealth_core/wealth_core.dart';
import 'package:wealth_os/database/app_database.dart';
import 'package:wealth_os/data/db/account_repository_impl.dart';
import 'package:wealth_os/data/domain/account_repository.dart';

void main() {
  late AppDatabase db;
  late AccountRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = AccountRepositoryImpl(db);
  });

  tearDown(() => db.close());

  group('AccountRepository', () {
    test('creates an account and aggregate', () async {
      final res = await repo.createAccount(const AccountInput(
        name: 'بانک ملت', type: 'BANK', currency: 'IRT', balanceMinor: 80000000,
      ));
      expect(res.isOk, isTrue);
      final acc = res.value!;
      expect(acc.name, 'بانک ملت');
    });

    test('lists accounts and excludes soft-deleted', () async {
      final a = await repo.createAccount(const AccountInput(name: 'A', type: 'CASH', currency: 'IRT'));
      final b = await repo.createAccount(const AccountInput(name: 'B', type: 'CASH', currency: 'IRT'));
      await repo.softDelete(b.value!.id);
      final list = await repo.listAccounts('');
      final names = list.value!.map((e) => e.name).toList();
      expect(names, contains('A'));
      expect(names, isNot(contains('B')));
      expect(a.isOk, isTrue);
    });

    test('rejects empty account name', () async {
      final res = await repo.createAccount(const AccountInput(name: '  ', type: 'CASH', currency: 'IRT'));
      expect(res.isErr, isTrue);
      expect(res.error!.code, 'empty_name');
    });

    test('updateBalance moves the aggregate', () async {
      final a = await repo.createAccount(const AccountInput(name: 'X', type: 'BANK', currency: 'IRT', balanceMinor: 1000));
      await repo.updateBalance(a.value!.id, 500);
      final got = await repo.getAccount(a.value!.id);
      expect(got.value!.balanceMinor, 1500);
    });
  });
}
