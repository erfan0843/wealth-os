/// مدل قیمت — Snapshot، منبع، تاریخچه، کش آفلاین (بند ۲۷-۳۱، ۸۲).
/// هستهٔ خالص؛ قابل تست.
library;

import '../money/money.dart';

/// وضعیت منبع/قیمت (بند ۸۲).
enum PriceStatus { live, stale, manual, unknown }

/// یک عکس‌فوری قیمت در لحظه (bend 30).
class PriceSnapshot {
  final String assetTypeId;
  final String? assetId;
  final double price; // قیمت واحد
  final Currency currency;
  final String unit;
  final String sourceId; // MANUAL/API/CSV/CHARISMA/CUSTOM
  final PriceStatus status;
  final DateTime observedAt; // زمان تولید قیمت

  const PriceSnapshot({
    required this.assetTypeId,
    this.assetId,
    required this.price,
    required this.currency,
    required this.unit,
    required this.sourceId,
    required this.observedAt,
    this.status = PriceStatus.live,
  });

  /// برچسب وضعیت برای UI (بند ۸۲: هرگز قیمت قدیمی به‌عنوان لحظه‌ای).
  bool get isStale => status == PriceStatus.stale;
}

/// منبع قیمت (بند ۲۸).
class PriceSource {
  final String id;
  final String code; // MANUAL/API/CSV/CHARISMA/CUSTOM
  final String name;
  final int priority; // هرچه کمتر، بالاتر (بند ۳۵).
  final bool enabled;

  const PriceSource({
    required this.id,
    required this.code,
    required this.name,
    this.priority = 0,
    this.enabled = true,
  });
}

/// یک رکورد تاریخچهٔ قیمت (بند ۳۰).
class PriceHistoryEntry {
  final String assetTypeId;
  final String? assetId;
  final double price;
  final Currency currency;
  final String unit;
  final String sourceId;
  final PriceStatus sourceStatus;
  final DateTime observedAt;

  const PriceHistoryEntry({
    required this.assetTypeId,
    this.assetId,
    required this.price,
    required this.currency,
    required this.unit,
    required this.sourceId,
    required this.observedAt,
    this.sourceStatus = PriceStatus.live,
  });
}

/// یک مدخل کش آفلاین (بند ۳۱).
class OfflinePriceCacheEntry {
  final String assetTypeId;
  final String? assetId;
  final double lastPrice;
  final Currency currency;
  final String sourceId;
  final DateTime lastObservedAt;
  final PriceStatus status;

  const OfflinePriceCacheEntry({
    required this.assetTypeId,
    this.assetId,
    required this.lastPrice,
    required this.currency,
    required this.sourceId,
    required this.lastObservedAt,
    required this.status,
  });
}
