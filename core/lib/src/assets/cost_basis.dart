/// مدیریت Cost Basis (بند ۲۳). روش‌ها: Average / FIFO / Specific.
/// Default = Average. هستهٔ خالص؛ قابل تست.
library;

import 'asset.dart';

/// نتیجهٔ محاسبهٔ هزینهٔ تمام‌شدهٔ یک فروش (کدام Lots مصرف شد).
class CostBasisResult {
  final double costOfSold; // کل هزینهٔ تمام‌شدهٔ مقدار فروخته‌شده
  final List<LotConsumption> consumed; // Lots مصرف‌شده
  const CostBasisResult(this.costOfSold, this.consumed);
}

/// یک Lot مصرف‌شده در فروش.
class LotConsumption {
  final String lotId;
  final double quantity;
  final double unitPrice;
  const LotConsumption(this.lotId, this.quantity, this.unitPrice);
}

/// محاسبه‌گر Cost Basis بر اساس روش انتخابی.
class CostBasisCalculator {
  const CostBasisCalculator();

  /// متوسط (Average): کل هزینه / کل موجودی.
  CostBasisResult average(
      List<AssetLot> openLots, double sellQty, List<AssetLot> allLots) {
    final totalQty = openLots.fold(0.0, (s, l) => s + l.quantity);
    final totalCost = openLots.fold(0.0, (s, l) => s + l.costBasisTotal);
    final avgPerUnit = totalQty == 0 ? 0.0 : totalCost / totalQty;
    final cost = avgPerUnit * sellQty;
    // در Average کل دهیدر به‌صورت میانگین، نه تفکیک Lot (اینجا تخمینی).
    return CostBasisResult(cost, []);
  }

  /// FIFO — اولین Lot ابتدا مصرف می‌شود.
  CostBasisResult fifo(List<AssetLot> openLots, double sellQty) {
    var remaining = sellQty;
    var totalCost = 0.0;
    final consumed = <LotConsumption>[];
    for (final lot in openLots) {
      if (remaining <= 0) break;
      final take = lot.quantity < remaining ? lot.quantity : remaining;
      totalCost += take * lot.unitPrice;
      consumed.add(LotConsumption(lot.id, take, lot.unitPrice));
      remaining -= take;
    }
    return CostBasisResult(totalCost, consumed);
  }

  /// Specific — Lot های مشخص‌شده (بند ۲۳).
  CostBasisResult specific(List<LotConsumption> picks, double sellQty) {
    var totalCost = 0.0;
    final consumed = <LotConsumption>[];
    var remaining = sellQty;
    for (final p in picks) {
      if (remaining <= 0) break;
      final take = p.quantity < remaining ? p.quantity : remaining;
      totalCost += take * p.unitPrice;
      consumed.add(LotConsumption(p.lotId, take, p.unitPrice));
      remaining -= take;
    }
    return CostBasisResult(totalCost, consumed);
  }

  /// انتخاب خودکار بر اساس روش (بند ۲۳، Default Average).
  CostBasisResult forMethod(
      CostMethod method, List<AssetLot> openLots, double sellQty,
      [List<LotConsumption>? picks]) {
    switch (method) {
      case CostMethod.fifo:
        return fifo(openLots, sellQty);
      case CostMethod.specific:
        return specific(picks ?? [], sellQty);
      case CostMethod.average:
        return average(openLots, sellQty, openLots);
    }
  }
}
