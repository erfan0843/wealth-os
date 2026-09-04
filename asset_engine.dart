/// موتور دارایی — خرید/فروش/تعدیل + P&L (بند ۲۴-۲۶).
/// هستهٔ خالص؛ قابل تست.
library;

import '../errors/result.dart';
import 'asset.dart';
import 'cost_basis.dart';

/// نتیجهٔ تعریف‌شدهٔ P&L (بند ۲۶).
class PnL {
  final double? unrealizedPercent;
  final double? unrealizedMinor; // ارزش فعلی − هزینهٔ فعلی
  final double? realizedMinor; // درآمد فروش − Cost Basis − هزینهٔ فروش
  final double totalCostBasis;
  final double currentValue;

  const PnL({
    this.unrealizedPercent,
    this.unrealizedMinor,
    this.realizedMinor,
    this.totalCostBasis = 0,
    this.currentValue = 0,
  });
}

/// کلاس نگهدارندهٔ وضعیت دارایی در طول عملیات.
class AssetState {
  final List<AssetLot> lots; // همهٔ Lots (باز و بسته)
  double get openQuantity =>
      lots.where((l) => l.isOpen).fold(0.0, (s, l) => s + l.quantity);
  double get totalCost =>
      lots.where((l) => l.isOpen).fold(0.0, (s, l) => s + l.costBasisTotal);
  double get avgCostPerUnit => openQuantity == 0 ? 0 : totalCost / openQuantity;

  AssetState(this.lots);
}

/// نتیجهٔ خرید.
class PurchaseResult {
  final AssetLot lot;
  final double newQuantity;
  final double newAvgCostPerUnit;
  const PurchaseResult(this.lot, this.newQuantity, this.newAvgCostPerUnit);
}

/// نتیجهٔ فروش.
class SaleResult {
  final double costOfSold; // Cost Basis مصرف‌شده
  final double realizedProfit; // درآمد − Cost Basis − هزینه (بند ۲۶)
  final double costBasisBefore;
  final double costBasisRemaining;
  const SaleResult(this.costOfSold, this.realizedProfit,
      this.costBasisBefore, this.costBasisRemaining);
}

/// موتور دارایی.
class AssetEngine {
  final CostBasisCalculator _costBasis;
  const AssetEngine([this._costBasis = const CostBasisCalculator()]);

  /// اعتبارسنجی: نمی‌توان بیش از موجودی فروخت مگر Short فعال (بند ۷۵).
  Result<void> validateSaleQuantity(
      Asset asset, AssetState state, double sellQty) {
    if (sellQty <= 0) {
      return const Err(AppError('invalid_quantity', 'مقدار نامعتبر است'));
    }
    final available = state.openQuantity;
    if (sellQty > available + 1e-9) {
      if (!asset.supportsShort) {
        return const Err(AppError(
            'insufficient_quantity', 'مقدار موجود برای فروش کافی نیست'));
      }
      // Short — فقط با تأیید صریح کاربر (بند ۷۵). در این سطح مجاز فرض می‌شود.
    }
    return const Ok(null);
  }

  /// ثبت خرید (بند ۲۴: Lot ایجاد، Cost Basis به‌روزرسانی).
  PurchaseResult buy({
    required Asset asset,
    required List<AssetLot> existingLots,
    required double qty,
    required double unitPrice,
    required double feePercent,
    required String newLotId,
    required DateTime occurredAt,
    required String sourceEventId,
  }) {
    if (qty <= 0 || unitPrice < 0) {
      throw ArgumentError('qty/unitPrice نامعتبر است');
    }
    // کارمزد درصدی روی مبلغ ناخالص.
    final gross = qty * unitPrice;
    final fee = gross * feePercent / 100;
    final totalCost = gross + fee;
    final lot = AssetLot(
      id: newLotId,
      assetId: asset.id,
      quantity: qty,
      unitPrice: unitPrice,
      costBasisTotal: totalCost,
      openedAt: occurredAt,
      sourceEventId: sourceEventId,
    );
    final all = [...existingLots, lot];
    final state = AssetState(all);
    return PurchaseResult(lot, state.openQuantity, state.avgCostPerUnit);
  }

  /// ثبت فروش (بند ۲۵): مقدار کاهش، Cost Basis مرتبط، Realized P&L.
  SaleResult sell({
    required Asset asset,
    required List<AssetLot> existingLots,
    required double qty,
    required double unitPrice,
    required double feePercent,
    required DateTime occurredAt,
  }) {
    final state = AssetState(existingLots);
    final method = asset.costMethod;
    // Cost Basis مصرف‌شده.
    final cb = _costBasis.forMethod(method, state.lots.where((l) => l.isOpen).toList(), qty);
    final gross = qty * unitPrice;
    final fee = gross * feePercent / 100;
    final saleProceeds = gross - fee;
    final realized = saleProceeds - cb.costOfSold; // بند ۲۶
    final remainingCost = state.totalCost - cb.costOfSold;
    return SaleResult(
        cb.costOfSold, realized, state.totalCost, remainingCost);
  }

  /// P&L تحقق‌نیافته: ارزش فعلی − هزینهٔ فعلی (بند ۲۶).
  PnL unrealized(AssetState state, double currentUnitPrice) {
    final value = state.openQuantity * currentUnitPrice;
    final cost = state.totalCost;
    final diff = value - cost;
    final pct = cost == 0 ? 0.0 : diff / cost * 100;
    return PnL(
      unrealizedMinor: diff,
      unrealizedPercent: pct,
      totalCostBasis: cost,
      currentValue: value,
    );
  }
}
