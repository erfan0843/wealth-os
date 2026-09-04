/// مدل ژنریک دارایی، نوع دارایی و Lot (بند ۱۹-۲۳).
/// هستهٔ خالص؛ قابل تست.
library;

import '../ledger/networth.dart';

/// نوع دارایی (بند ۱۹). Generic — یک موتور برای همه.
class AssetType {
  final String code; // GOLD/SILVER/COIN/CURRENCY/STOCK/FUND/CRYPTO/PROPERTY/VEHICLE/BUSINESS/EQUIPMENT/CUSTOM
  final String displayName;
  final String defaultUnit; // gram/dollar/share/token/piece/m2/vehicle...
  final LiquidityClass liquidity;
  final bool supportsShort; // بند ۷۵: فروش بیش از موجودی فقط با تأیید صریح
  final int decimalPrecision;
  final Map<String, dynamic> metadataSchema; // بند ۲۱

  const AssetType({
    required this.code,
    required this.displayName,
    required this.defaultUnit,
    this.liquidity = LiquidityClass.semiLiquid,
    this.supportsShort = false,
    this.decimalPrecision = 2,
    this.metadataSchema = const {},
  });
}

/// یک دارایی مشخص (مثلاً «نقرهٔ خریداری‌شده»).
class Asset {
  final String id;
  final String assetTypeCode;
  final String name;
  final String unit;
  final double currentQuantity; // موجودی فعلی (Snapshot)
  final double currentCostBasisPerUnit; // میانگین هزینهٔ تمام‌شده هر واحد
  final CostMethod costMethod; // AVG/FIFO/SPECIFIC (بند ۲۳)
  final bool supportsShort; // بند ۷۵: فروش بیش از موجودی فقط با تأیید صریح
  final Map<String, dynamic> metadata; // بند ۲۱

  const Asset({
    required this.id,
    required this.assetTypeCode,
    required this.name,
    required this.unit,
    this.currentQuantity = 0,
    this.currentCostBasisPerUnit = 0,
    this.costMethod = CostMethod.average,
    this.supportsShort = false,
    this.metadata = const {},
  });
}

/// روش محاسبهٔ Cost Basis (بند ۲۳). Default: Average. آمادهٔ دیگر روش‌ها.
enum CostMethod { average, fifo, specific }

/// Lot — یک نوبت خرید (بند 22); تاریخچهٔ قیمت خرید حفظ می‌شود.
class AssetLot {
  final String id;
  final String assetId;
  final double quantity;
  final double unitPrice; // قیمت هر واحد برای این Lot
  final double costBasisTotal; // quantity * unitPrice
  final DateTime openedAt;
  final DateTime? closedAt;
  final String? sourceEventId;

  const AssetLot({
    required this.id,
    required this.assetId,
    required this.quantity,
    required this.unitPrice,
    required this.costBasisTotal,
    required this.openedAt,
    this.closedAt,
    this.sourceEventId,
  });

  /// Lot باز است یا بسته.
  bool get isOpen => closedAt == null;
}
