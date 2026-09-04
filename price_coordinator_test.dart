import 'package:test/test.dart';
import 'package:wealth_core/wealth_core.dart';

class _MemCache implements PriceCachePort {
  final Map<String, OfflinePriceCacheEntry> _m = {};
  @override
  Future<OfflinePriceCacheEntry?> get(String id, String? aid) async =>
      _m['$id|$aid'];
  @override
  Future<void> put(PriceSnapshot s) async {
    _m['${s.assetTypeId}|${s.assetId}'] = OfflinePriceCacheEntry(
      assetTypeId: s.assetTypeId,
      assetId: s.assetId,
      lastPrice: s.price,
      currency: s.currency,
      sourceId: s.sourceId,
      lastObservedAt: s.observedAt,
      status: s.status,
    );
  }
}

void main() {
  group('PriceCoordinator — بند ۲۷-۳۱، ۸۲', () {
    test('منبع Manual برنده میشود', () async {
      final coord = PriceCoordinator(
        [const ManualPriceProvider({'GOLD': 3100000.0})],
        _MemCache(),
      );
      final res = await coord.resolve(
          const PriceRequest(assetTypeId: 'GOLD', unit: 'گرم'));
      expect(res.isOk, true);
      expect(res.snapshot!.price, 3100000.0);
      expect(res.fromCache, false);
      expect(res.isStale, false);
      expect(res.snapshot!.sourceId, 'MANUAL');
    });

    test('بعد از قطع منبع → کش آفلاین کهنه (بند ۸۲)', () async {
      final cache = _MemCache();
      await cache.put(PriceSnapshot(
        assetTypeId: 'SILVER',
        price: 4200000.0,
        currency: Currency.irt,
        unit: 'گرم',
        sourceId: 'MANUAL',
        observedAt: DateTime.now().toUtc(),
        status: PriceStatus.manual,
      ));
      final coord = PriceCoordinator([const ManualPriceProvider({})], cache);
      final res = await coord.resolve(
          const PriceRequest(assetTypeId: 'SILVER', unit: 'گرم'));
      expect(res.isOk, true);
      expect(res.fromCache, true);
      expect(res.isStale, true);
      expect(res.snapshot!.price, 4200000.0);
      expect(res.snapshot!.status, PriceStatus.stale);
    });

    test('بدون هیچ قیمتی → خطا', () async {
      final coord =
          PriceCoordinator([const ManualPriceProvider({})], _MemCache());
      final res = await coord.resolve(
          const PriceRequest(assetTypeId: 'COIN', unit: 'عدد'));
      expect(res.isError, true);
    });

    test('توزیع نامعتبر منبع → امتحان منبع بعدی', () async {
      var calls = 0;
      final failing = ApiPriceProvider((r) async {
        calls++;
        return Err(AppError('no_price', 'از دسترس خارج'));
      });
      final coord = PriceCoordinator(
          [failing, const ManualPriceProvider({'GOLD': 100.0})], _MemCache());
      final res = await coord.resolve(
          const PriceRequest(assetTypeId: 'GOLD', unit: 'گرم'));
      expect(res.isOk, true);
      expect(res.snapshot!.price, 100.0);
      expect(calls, 1);
    });
  });
}
