import 'package:wealth_core/wealth_core.dart';

/// قرارداد (interface) ذخیره‌سازی حساب — در `domain` (بند ۹۲).
/// پیاده‌سازی در `data/` با Drift. UI مستقیم با DB کار نمی‌کند.
abstract interface class AccountRepository {
  Future<Result<AccountSummary>> createAccount(AccountInput input);
  Future<Result<List<AccountSummary>>> listAccounts(String userId);
  Future<Result<AccountSummary>> getAccount(String id);
  Future<Result<bool>> updateBalance(String id, int deltaMinor);
  Future<Result<bool>> softDelete(String id);
}

/// مقدار ورودی ثبت حساب.
class AccountInput {
  final String name;
  final String type; // CASH/BANK/WALLET/BUSINESS/OTHER
  final String currency;
  final int balanceMinor;
  final String? owner;
  final String? notes;

  const AccountInput({
    required this.name,
    required this.type,
    required this.currency,
    this.balanceMinor = 0,
    this.owner,
    this.notes,
  });
}

/// نمای حساب برای UI.
class AccountSummary {
  final String id;
  final String name;
  final String type;
  final String currency;
  final int balanceMinor;

  const AccountSummary({
    required this.id,
    required this.name,
    required this.type,
    required this.currency,
    required this.balanceMinor,
  });

  String get balanceLabel => formatMoneyFa(balanceMinor, Currency.irt);
}
