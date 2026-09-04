/// هماهنگ‌کنندهٔ قیمت — انتخاب Provider، رزولوشن و Cache آفلاین (بند ۲۷-۳۱، ۸۲).
/// اولویت: Providers به ترتیب اولویت؛ سپس LIVE. اگر Live نشد → آخرین قیمت Local (کش).
/// هستهٔ خالص؛ قابل تست.
library;

import '../errors/result.dart';
import 'price.dart';
import 'price_provider.dart';

/// کش آفلاین (رابط) — پیاده‌سازی DB در data/.
abstract interface class PriceCachePort {
  Future<OfflinePriceCacheEntry?> get(String assetTypeId, String? assetId);
  Future<void> put(PriceSnapshot snapshot);
}

/// نتیجهٔ قیمت — شفاف: از کش؟ کهنه؟ (بند ۸۲)
class PriceResult {
  final PriceSnapshot? snapshot; // null یعنی خطا.
  final bool fromCache;
  final bool isStale; // واکشی از کش.
  final AppError? error;

  const PriceResult.ok(this.snapshot, {this.fromCache = false, this.isStale = false}) : error = null;
  const PriceResult.fail(this.error) : snapshot = null, fromCache = false, isStale = false;

  bool get isOk => error == null && snapshot != null;
  bool get isError => !isOk;
}

/// هماهنگ‌کنندهٔ قیمت.
class PriceCoordinator {
  final List<PriceProvider> _providers;
  final PriceCachePort _cache;

  const PriceCoordinator(this._providers, this._cache);

  /// قیمت لحظه‌ای — تلاش روی همهٔ Providers، در نهایت کش (بند ۸۲).
  Future<PriceResult> resolve(PriceRequest request) async {
    for (final p in _providers) {
      if (!p.supports(request.assetTypeId)) continue;
      try {
        final r = await p.fetchLive(request);
        if (r.isOk && r.value != null) {
          final snap = r.value!;
          await _cache.put(snap);
          return PriceResult.ok(snap);
        }
      } catch (_) {
        continue; // منبع در دسترس نیست — امتحان بعدی.
      }
    }
    // افتادن به کش — قیمت کهنه (بند ۸۲).
    final cached = await _cache.get(request.assetTypeId, request.assetId);
    if (cached != null) {
      final snap = PriceSnapshot(
        assetTypeId: cached.assetTypeId,
        assetId: cached.assetId,
        price: cached.lastPrice,
        currency: cached.currency,
        unit: request.unit,
        sourceId: cached.sourceId,
        status: PriceStatus.stale,
        observedAt: cached.lastObservedAt,
      );
      return PriceResult.ok(snap, fromCache: true, isStale: true);
    }
    return const PriceResult.fail(AppError.unknown);
  }

  /// قیمت تاریخ‌دار (As-of) برای واحد مرجع (بند ۵۷).
  Future<Result<PriceSnapshot>> asOf(
      PriceRequest request, DateTime asOf) async {
    for (final p in _providers) {
      if (!p.supports(request.assetTypeId)) continue;
      try {
        final r = await p.fetchAsOf(request, asOf);
        if (r.isOk) return r;
      } catch (_) {
        continue;
      }
    }
    return const Err(AppError.unknown);
  }
}
