import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:wealth_core/wealth_core.dart';

import '../../database/app_database.dart';
import '../domain/account_repository.dart';

/// پیاده‌سازی Drift برای AccountRepository — بند ۹۲ (UI به مستقیم DB دست نمی‌زند).
class AccountRepositoryImpl implements AccountRepository {
  final AppDatabase db;
  final Uuid _uuid = const Uuid();

  AccountRepositoryImpl(this.db);

  @override
  Future<Result<AccountSummary>> createAccount(AccountInput input) async {
    if (input.name.trim().isEmpty) {
      return const Err(AppError('empty_name', 'نام حساب الزامی است'));
    }
    final id = _uuid.v4();
    try {
      await db.transaction(() async {
        await db.into(db.accounts).insert(
              AccountsCompanion.insert(
                id: id,
                userId: '', // بعداً از Session
                name: input.name,
                type: input.type,
                currency: input.currency,
                balanceMinor: Value(input.balanceMinor),
                owner: Value(input.owner),
                notes: Value(input.notes),
              ),
            );
        await db.into(db.accountAggregates).insert(
              AccountAggregatesCompanion.insert(
                accountId: id,
                balanceMinor: Value(input.balanceMinor),
              ),
            );
      });
      return Ok(AccountSummary(
        id: id, name: input.name, type: input.type,
        currency: input.currency, balanceMinor: input.balanceMinor,
      ));
    } catch (e) {
      return Err(AppError('db_create_account', 'خطای ثبت حساب', e));
    }
  }

  @override
  Future<Result<List<AccountSummary>>> listAccounts(String userId) async {
    try {
      final rows = await (db.select(db.accounts)
            ..where((t) => t.isDeleted.equals(false)))
          .get();
      final list = rows
          .map((r) => AccountSummary(
                id: r.id, name: r.name, type: r.type,
                currency: r.currency, balanceMinor: r.balanceMinor,
              ))
          .toList();
      return Ok(list);
    } catch (e) {
      return Err(AppError('db_list_accounts', 'خطای خواندن حساب‌ها', e));
    }
  }

  @override
  Future<Result<AccountSummary>> getAccount(String id) async {
    try {
      final row = await (db.select(db.accounts)
            ..where((t) => t.id.equals(id)))
          .getSingleOrNull();
      if (row == null) {
        return const Err(AppError('account_not_found', 'حساب یافت نشد'));
      }
      return Ok(AccountSummary(
        id: row.id, name: row.name, type: row.type,
        currency: row.currency, balanceMinor: row.balanceMinor,
      ));
    } catch (e) {
      return Err(AppError('db_get_account', 'خطای خواندن حساب', e));
    }
  }

  @override
  Future<Result<bool>> updateBalance(String id, int deltaMinor) async {
    try {
      await db.transaction(() async {
        final agg = await (db.select(db.accountAggregates)
              ..where((t) => t.accountId.equals(id)))
            .getSingleOrNull();
        final newBal = (agg?.balanceMinor ?? 0) + deltaMinor;
        await (db.update(db.accountAggregates)..where((t) => t.accountId.equals(id)))
            .write(AccountAggregatesCompanion(
              balanceMinor: Value(newBal),
              updatedAt: Value(DateTime.now().toUtc()),
            ));
      });
      return const Ok(true);
    } catch (e) {
      return Err(AppError('db_update_balance', 'خطای به‌روزرسانی موجودی', e));
    }
  }

  @override
  Future<Result<bool>> softDelete(String id) async {
    try {
      await (db.update(db.accounts)..where((t) => t.id.equals(id)))
          .write(const AccountsCompanion(isDeleted: Value(true)));
      return const Ok(true);
    } catch (e) {
      return Err(AppError('db_soft_delete', 'خطای حذف حساب', e));
    }
  }
}
