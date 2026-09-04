/// محاسبهٔ دارایی خالص و نقدینگی (بند ۱۷، ۱۸، C11).
/// طلب/بدهی در دارایی خالص، ولی نه در نقدینگی (C11).
/// خالص و قابل تست.
library;

import '../money/money.dart';

/// طبقهٔ نقدشوندگی.
enum LiquidityClass {
  liquid, // نقد + بانک + دارایی های نقد
  semiLiquid, // طلا/نقره/ارز (به‌سرعت نقدشدنی)
  nonLiquid; // ملک/خودرو/کسب‌وکار ...

  static LiquidityClass fromString(String s) {
    switch (s.toUpperCase()) {
      case 'LIQUID':
        return LiquidityClass.liquid;
      case 'SEMI_LIQUID':
        return LiquidityClass.semiLiquid;
      default:
        return LiquidityClass.nonLiquid;
    }
  }
}

/// یک آیتم دارایی یا تعهد برای محاسبه.
class WealthItem {
  final String id;
  final String name;
  final int valueMinor; // ارزش بالای کلین (بها)
  final Currency currency;
  final LiquidityClass liquidity; // فقط برای دارایی‌ها معنا دارد

  /// C11: طلب در دارایی خالص و کل دارایی لحاظ می‌شود، ولی در نقدینگی نه.
  final bool isReceivable;

  /// آیا این آیتم بدهی است؟ (برای تفکیک دارایی/بدهی — بند ۱۷).
  final bool isLiability;

  const WealthItem({
    required this.id,
    required this.name,
    required this.valueMinor,
    required this.currency,
    this.liquidity = LiquidityClass.liquid,
    this.isReceivable = false,
    this.isLiability = false,
  });
}

/// نتیجهٔ محاسبهٔ ثروت.
class NetWorthSnapshot {
  final Currency currency;
  final int cashMinor; // نقد + بانک (Liquid)
  final int liquidAssetsMinor; // کل نقدشونده
  final int totalAssetsMinor; // کل دارایی‌ها
  final int totalLiabilitiesMinor; // کل بدهی‌ها
  final int receivablesMinor; // طلب‌ها
  final int netWorthMinor; // totalAssets - totalLiabilities

  const NetWorthSnapshot({
    required this.currency,
    required this.cashMinor,
    required this.liquidAssetsMinor,
    required this.totalAssetsMinor,
    required this.totalLiabilitiesMinor,
    required this.receivablesMinor,
    required this.netWorthMinor,
  });

  String get netWorthLabel => formatMoneyFa(netWorthMinor, currency);
  String get totalAssetsLabel => formatMoneyFa(totalAssetsMinor, currency);
  String get totalLiabilitiesLabel => formatMoneyFa(totalLiabilitiesMinor, currency);
  String get cashLabel => formatMoneyFa(cashMinor, currency);
}

/// ماشین‌حساب دارایی خالص.
class NetWorthCalculator {
  const NetWorthCalculator();

  /// `assets` شامل نقد/بانک + همهٔ دارایی‌ها + طلب‌ها.
  /// `liabilities` شامل بدهی‌ها.
  NetWorthSnapshot calculate({
    required List<WealthItem> assets,
    required List<WealthItem> liabilities,
    required Currency currency,
  }) {
    var cash = 0, liquid = 0, totalAssets = 0, receivables = 0;
    for (final a in assets) {
      totalAssets += a.valueMinor;
      if (a.isReceivable) {
        // C11: طلب در نقدینگی حساب نمی‌شود؛ فقط در کل دارایی و خالص.
        receivables += a.valueMinor;
        continue;
      }
      if (a.liquidity == LiquidityClass.liquid) {
        cash += a.valueMinor;
        liquid += a.valueMinor;
      } else if (a.liquidity == LiquidityClass.semiLiquid) {
        liquid += a.valueMinor;
      }
    }
    var totalLiabilities = 0;
    for (final l in liabilities) {
      totalLiabilities += l.valueMinor;
    }
    return NetWorthSnapshot(
      currency: currency,
      cashMinor: cash,
      liquidAssetsMinor: liquid,
      totalAssetsMinor: totalAssets,
      totalLiabilitiesMinor: totalLiabilities,
      receivablesMinor: receivables,
      netWorthMinor: totalAssets - totalLiabilities,
    );
  }
}
