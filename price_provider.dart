/// استراتژی Provider قیمت (بند ۲۷-۲۹، ۸۲).
/// هر منبع قیمت به‌صورت Provider مستقل؛ منطق هر Provider پراکنده نیست.
/// عدم پایداری → افتادن به آخرین قیمت معتبر Local (بند ۸۲).
/// هستهٔ خالص؛ قابل تست.
library;

import '../errors/result.dart';
import '../money/money.dart';
import 'price.dart';

/// قرارداد یک Provider قیمت.
abstract interface class PriceProvider {
  bool supports(String assetTypeId);
  Future<Result<PriceSnapshot>> fetchLive(PriceRequest request);
  Future<Result<PriceSnapshot>> fetchAsOf(PriceRequest request, DateTime asOf);
}

/// درخواست قیمت.
class PriceRequest {
  final String assetTypeId;
  final String unit;
  final String? assetId;
  final String currencyCode;

  const PriceRequest({
    required this.assetTypeId,
    required this.unit,
    this.assetId,
    this.currencyCode = 'IRT',
  });
}

/// Provider دستی (بند ۲۷).
class ManualPriceProvider implements PriceProvider {
  final Map<String, double> _prices;
  const ManualPriceProvider(this._prices);

  @override
  bool supports(String assetTypeId) => _prices.containsKey(assetTypeId);

  @override
  Future<Result<PriceSnapshot>> fetchLive(PriceRequest r) async {
    final p = _prices[r.assetTypeId];
    if (p == null) {
      return const Err(AppError('no_price', 'قیمتی برای این دارایی ثبت نشده'));
    }
    return Ok(PriceSnapshot(
      assetTypeId: r.assetTypeId,
      assetId: r.assetId,
      price: p,
      currency: _currency(r.currencyCode),
      unit: r.unit,
      sourceId: 'MANUAL',
      observedAt: DateTime.now().toUtc(),
      status: PriceStatus.manual,
    ));
  }

  @override
  Future<Result<PriceSnapshot>> fetchAsOf(
      PriceRequest r, DateTime asOf) async {
    return fetchLive(r);
  }
}

/// Provider API عمومی (بند ۲۷) — بدون هاردکد URI؛ فقط قرارداد.
class ApiPriceProvider implements PriceProvider {
  final Future<Result<PriceSnapshot>> Function(PriceRequest) _invoke;
  const ApiPriceProvider(this._invoke);

  @override
  bool supports(String assetTypeId) => true;

  @override
  Future<Result<PriceSnapshot>> fetchLive(PriceRequest r) => _invoke(r);

  @override
  Future<Result<PriceSnapshot>> fetchAsOf(PriceRequest r, DateTime asOf) =>
      _invoke(r);
}

/// هماهنگی ارز.
Currency _currency(String code) {
  switch (code) {
    case 'USD':
      return Currency.usd;
    case 'EUR':
      return Currency.eur;
    default:
      return Currency.irt;
  }
}
